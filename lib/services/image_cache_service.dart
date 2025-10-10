import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_cache_service.g.dart';

/// 画像キャッシュサービスのプロバイダー
@riverpod
ImageCacheService imageCacheService(Ref ref) {
  return ImageCacheService();
}

/// 画像キャッシュサービス
class ImageCacheService {
  final ImagePicker _picker = ImagePicker();
  final Map<String, Uint8List> _memoryCache = {};
  static const int _maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  int _currentMemoryCacheSize = 0;

  /// カメラから画像を選択
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  /// ギャラリーから画像を選択
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  /// 画像を圧縮
  Future<Uint8List> compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('画像のデコードに失敗しました');
    }

    // リサイズ（最大1920px）
    img.Image resized = image;
    if (image.width > 1920 || image.height > 1920) {
      if (image.width > image.height) {
        resized = img.copyResize(image, width: 1920);
      } else {
        resized = img.copyResize(image, height: 1920);
      }
    }

    // JPEG形式でエンコード（品質85%）
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  /// メモリキャッシュに保存
  void saveToMemoryCache(String key, Uint8List data) {
    // キャッシュサイズチェック
    if (_currentMemoryCacheSize + data.length > _maxMemoryCacheSize) {
      clearMemoryCache();
    }

    _memoryCache[key] = data;
    _currentMemoryCacheSize += data.length;
  }

  /// メモリキャッシュから取得
  Uint8List? getFromMemoryCache(String key) {
    return _memoryCache[key];
  }

  /// メモリキャッシュをクリア
  void clearMemoryCache() {
    _memoryCache.clear();
    _currentMemoryCacheSize = 0;
  }

  /// ディスクキャッシュに保存
  Future<File> saveToDiskCache(String key, Uint8List data) async {
    final directory = await getTemporaryDirectory();
    final cacheDir = Directory('${directory.path}/image_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final file = File('${cacheDir.path}/$key');
    await file.writeAsBytes(data);
    return file;
  }

  /// ディスクキャッシュから取得
  Future<Uint8List?> getFromDiskCache(String key) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/image_cache/$key');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('ディスクキャッシュの読み込みエラー: $e');
    }
    return null;
  }

  /// ディスクキャッシュをクリア
  Future<void> clearDiskCache() async {
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/image_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('ディスクキャッシュのクリアエラー: $e');
    }
  }

  /// 画像をアップロード
  Future<String> uploadImage(File imageFile, String uploadUrl) async {
    final dio = Dio();
    final compressedBytes = await compressImage(imageFile);

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(compressedBytes, filename: 'upload.jpg'),
    });

    final response = await dio.post(uploadUrl, data: formData);
    return response.data['url'] as String;
  }
}
