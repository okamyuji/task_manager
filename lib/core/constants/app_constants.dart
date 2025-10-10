import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// アプリケーション全体で使用する定数
class AppConstants {
  AppConstants._();

  /// API関連の定数
  /// プラットフォームに応じてベースURLを自動切り替え
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Web版（ブラウザ）
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      // Androidエミュレーター: 10.0.2.2
      // Android実機: 192.168.0.16（同じWi-Fiネットワークが必要）
      // 環境変数で切り替え可能にする
      const androidHost = String.fromEnvironment(
        'API_HOST',
        defaultValue: '10.0.2.2', // エミュレーター用デフォルト
      );
      return 'http://$androidHost:8080';
    } else if (Platform.isIOS) {
      // iOSシミュレーター/実機
      return 'http://192.168.0.16:8080';
    } else {
      // その他（デスクトップ等）
      return 'http://localhost:8080';
    }
  }

  static const int apiTimeout = 30000;

  /// ローカルストレージのキー
  static const String storageKeyToken = 'auth_token';
  static const String storageKeyUser = 'user_data';

  /// その他の定数
  static const int maxRetryCount = 3;
}
