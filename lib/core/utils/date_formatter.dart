import 'package:intl/intl.dart';

/// 日付フォーマット用のユーティリティクラス
class DateFormatter {
  DateFormatter._();

  /// 日付フォーマッター (yyyy/MM/dd)
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

  /// 日時フォーマッター (yyyy/MM/dd HH:mm)
  static final DateFormat _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

  /// 時刻フォーマッター (HH:mm)
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// 日付を文字列に変換
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// 日時を文字列に変換
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// 時刻を文字列に変換
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  /// 相対的な日付表記を取得
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今日';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return formatDate(date);
    }
  }
}
