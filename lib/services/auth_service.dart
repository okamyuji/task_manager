import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/app_constants.dart';

part 'auth_service.g.dart';

/// 認証サービスのプロバイダー
@riverpod
AuthService authService(Ref ref) {
  return AuthService();
}

/// 認証サービス
class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
    ),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  /// ログイン
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      await _saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        userId: data['userId'] as String,
      );

      return data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 登録
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );

      final data = response.data as Map<String, dynamic>;
      await _saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        userId: data['userId'] as String,
      );

      return data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// ログアウト
  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
  }

  /// アクセストークンを取得
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// リフレッシュトークンを取得
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// ユーザーIDを取得
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// ログイン状態を確認
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// トークンをリフレッシュ
  Future<String> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw Exception('Refresh token not found');
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      await _storage.write(key: _accessTokenKey, value: newAccessToken);

      return newAccessToken;
    } on DioException catch (e) {
      await logout(); // トークンリフレッシュに失敗したらログアウト
      throw _handleDioException(e);
    }
  }

  /// トークンを保存
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// DioExceptionを処理
  Exception _handleDioException(DioException e) {
    if (e.response != null) {
      final message =
          e.response?.data['message'] as String? ?? 'サーバーエラーが発生しました';
      return Exception(message);
    } else {
      return Exception('ネットワークエラーが発生しました');
    }
  }
}
