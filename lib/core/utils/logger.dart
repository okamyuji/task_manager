import 'package:flutter/foundation.dart';

/// ログ出力用のユーティリティクラス
class Logger {
  Logger._();

  /// デバッグログ
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
      if (error != null) debugPrint('[ERROR] $error');
      if (stackTrace != null) debugPrint('[STACK] $stackTrace');
    }
  }

  /// 情報ログ
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// エラーログ
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('[ERROR DETAIL] $error');
    if (stackTrace != null) debugPrint('[STACK TRACE] $stackTrace');
  }
}
