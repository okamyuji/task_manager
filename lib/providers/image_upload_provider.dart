import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/image_cache_service.dart';

part 'image_upload_provider.freezed.dart';
part 'image_upload_provider.g.dart';

/// 画像アップロード状態
@freezed
sealed class ImageUploadState with _$ImageUploadState {
  const factory ImageUploadState({
    @Default(false) bool isUploading,
    @Default(0.0) double progress,
    String? uploadedUrl,
    String? errorMessage,
  }) = _ImageUploadState;
}

/// 画像アップロードプロバイダー
@riverpod
class ImageUpload extends _$ImageUpload {
  @override
  ImageUploadState build() {
    return const ImageUploadState();
  }

  /// カメラから画像を選択してアップロード
  Future<void> pickAndUploadFromCamera(String uploadUrl) async {
    state = state.copyWith(isUploading: true, progress: 0.0);

    try {
      final imageService = ref.read(imageCacheServiceProvider);
      final imageFile = await imageService.pickImageFromCamera();

      if (imageFile != null) {
        await _uploadImage(imageFile, uploadUrl);
      } else {
        state = state.copyWith(
          isUploading: false,
          errorMessage: '画像が選択されませんでした',
        );
      }
    } catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: e.toString());
    }
  }

  /// ギャラリーから画像を選択してアップロード
  Future<void> pickAndUploadFromGallery(String uploadUrl) async {
    state = state.copyWith(isUploading: true, progress: 0.0);

    try {
      final imageService = ref.read(imageCacheServiceProvider);
      final imageFile = await imageService.pickImageFromGallery();

      if (imageFile != null) {
        await _uploadImage(imageFile, uploadUrl);
      } else {
        state = state.copyWith(
          isUploading: false,
          errorMessage: '画像が選択されませんでした',
        );
      }
    } catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: e.toString());
    }
  }

  /// 画像をアップロード
  Future<void> _uploadImage(File imageFile, String uploadUrl) async {
    try {
      final imageService = ref.read(imageCacheServiceProvider);

      // 圧縮
      state = state.copyWith(progress: 0.3);
      final compressedBytes = await imageService.compressImage(imageFile);

      // キャッシュに保存
      state = state.copyWith(progress: 0.5);
      final cacheKey = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      imageService.saveToMemoryCache(cacheKey, compressedBytes);
      await imageService.saveToDiskCache(cacheKey, compressedBytes);

      // アップロード
      state = state.copyWith(progress: 0.7);
      final url = await imageService.uploadImage(imageFile, uploadUrl);

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        uploadedUrl: url,
      );
    } catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// リセット
  void reset() {
    state = const ImageUploadState();
  }

  /// アップロード済みURLを設定（編集画面用）
  void setUploadedUrl(String url) {
    state = state.copyWith(uploadedUrl: url);
  }
}
