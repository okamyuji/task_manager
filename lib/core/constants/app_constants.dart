import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// アプリケーション全体で使用する定数
class AppConstants {
  AppConstants._();

  /// API関連の定数
  /// プラットフォームに応じてベースURLを自動切り替え
  /// API_HOST環境変数でカスタマイズ可能
  ///
  /// 使用例:
  /// - 本番環境: --dart-define=API_HOST=example.com (自動的にHTTPS)
  /// - 開発環境: --dart-define=API_HOST=192.168.0.16:8080 (HTTP)
  /// - 完全URL指定: --dart-define=API_HOST=https://example.com:8443
  static String get apiBaseUrl {
    const host = String.fromEnvironment('API_HOST', defaultValue: '');

    if (host.isNotEmpty) {
      // API_HOSTが指定されている場合、スマート判定を使用
      final protocol = _getProtocol(host);
      final port = _getPort(host);
      final cleanHost = _cleanHost(host);
      return '$protocol://$cleanHost${port.isNotEmpty ? ':$port' : ''}';
    }

    // デフォルト設定（開発環境用）
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      // Androidエミュレーター用デフォルト
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      // iOSシミュレーター/実機用デフォルト
      return 'http://192.168.0.16:8080';
    } else {
      // その他（デスクトップ等）
      return 'http://localhost:8080';
    }
  }

  /// プロトコルを自動判定
  /// - 既にプロトコルが含まれている場合はそれを使用
  /// - ドメイン名（.dev, .com等）ならHTTPS
  /// - IPアドレスやlocalhostならHTTP
  static String _getProtocol(String host) {
    // 既にプロトコルが含まれている場合
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return host.split('://')[0];
    }

    // ドメイン名ならHTTPS、それ以外（IPアドレス等）はHTTP
    if (host.contains('.dev') ||
        host.contains('.com') ||
        host.contains('.net') ||
        host.contains('.io') ||
        host.contains('.app') ||
        host.contains('.org')) {
      return 'https';
    }

    return 'http';
  }

  /// ポート番号を抽出
  /// - ホスト文字列にポート番号が含まれている場合はそれを使用
  /// - それ以外は空文字（デフォルトポート）
  static String _getPort(String host) {
    // プロトコルを削除
    String clean = host.replaceFirst(RegExp(r'^https?://'), '');

    // ポート番号が含まれている場合
    if (clean.contains(':')) {
      final parts = clean.split(':');
      if (parts.length > 1) {
        final port = parts.last;
        // 数字のみの場合はポート番号として扱う
        if (RegExp(r'^\d+$').hasMatch(port)) {
          return port;
        }
      }
    }

    // デフォルトポート（HTTPS=443、HTTP=80は省略）
    return '';
  }

  /// ホスト名をクリーンアップ
  /// - プロトコルとポート番号を削除
  static String _cleanHost(String host) {
    // プロトコルを削除
    String clean = host.replaceFirst(RegExp(r'^https?://'), '');

    // ポート番号を削除
    if (clean.contains(':')) {
      clean = clean.split(':')[0];
    }

    return clean;
  }

  static const int apiTimeout = 30000;

  /// ローカルストレージのキー
  static const String storageKeyToken = 'auth_token';
  static const String storageKeyUser = 'user_data';

  /// その他の定数
  static const int maxRetryCount = 3;
}
