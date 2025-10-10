/// アプリケーション全体で使用する定数
class AppConstants {
  AppConstants._();

  /// API関連の定数
  static const String apiBaseUrl = 'http://192.168.0.16:8080';
  static const int apiTimeout = 30000;

  /// ローカルストレージのキー
  static const String storageKeyToken = 'auth_token';
  static const String storageKeyUser = 'user_data';

  /// その他の定数
  static const int maxRetryCount = 3;
}
