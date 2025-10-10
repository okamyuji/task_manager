import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// タスクモデル
@freezed
sealed class Task with _$Task {
  const Task._(); // カスタムメソッドのためのprivateコンストラクタ

  const factory Task({
    required String id,
    required String title,
    required String description,
    required DateTime createdAt,
    DateTime? dueDate,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
    @Default([]) List<String> tags,
    @Default(TaskPriority.medium) TaskPriority priority,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

/// タスクの優先度
enum TaskPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// TaskPriorityの拡張メソッド
extension TaskPriorityExtension on TaskPriority {
  /// 優先度の表示名を取得
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '緊急';
    }
  }

  /// 優先度に応じた色を取得
  String get colorCode {
    switch (this) {
      case TaskPriority.low:
        return '#4CAF50'; // Green
      case TaskPriority.medium:
        return '#2196F3'; // Blue
      case TaskPriority.high:
        return '#FF9800'; // Orange
      case TaskPriority.urgent:
        return '#F44336'; // Red
    }
  }
}
