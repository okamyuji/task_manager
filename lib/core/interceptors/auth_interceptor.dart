import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 認証インターセプター
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // アクセストークンを取得してヘッダーに追加
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401エラー（認証エラー）の場合は、トークンをリフレッシュ
    if (err.response?.statusCode == 401) {
      try {
        // リフレッシュトークンを取得
        final refreshToken = await _storage.read(key: _refreshTokenKey);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // トークンリフレッシュAPIを呼び出し
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(
              headers: {'Authorization': 'Bearer $refreshToken'},
            ),
          );

          // 新しいアクセストークンを保存
          final newAccessToken = response.data['accessToken'] as String;
          await _storage.write(key: _accessTokenKey, value: newAccessToken);

          // 元のリクエストを再試行
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';

          final cloneReq = await _dio.fetch(opts);
          return handler.resolve(cloneReq);
        }
      } catch (e) {
        // リフレッシュ失敗時はトークンをクリア
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
      }
    }

    handler.next(err);
  }
}
