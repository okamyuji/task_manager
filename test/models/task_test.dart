import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('Task を作成できる', () {
      final task = Task(
        id: '1',
        title: 'テストタスク',
        description: 'テスト説明',
        createdAt: DateTime.now(),
      );

      expect(task.id, '1');
      expect(task.title, 'テストタスク');
      expect(task.description, 'テスト説明');
      expect(task.isCompleted, false);
      expect(task.priority, TaskPriority.medium);
    });

    test('copyWith でタスクをコピーできる', () {
      final task = Task(
        id: '1',
        title: 'テストタスク',
        description: 'テスト説明',
        createdAt: DateTime.now(),
      );

      final updatedTask = task.copyWith(title: '更新されたタスク');

      expect(updatedTask.id, '1');
      expect(updatedTask.title, '更新されたタスク');
      expect(updatedTask.description, 'テスト説明');
    });

    test('JSON からタスクを作成できる', () {
      final json = {
        'id': '1',
        'title': 'テストタスク',
        'description': 'テスト説明',
        'createdAt': DateTime.now().toIso8601String(),
        'isCompleted': false,
        'tags': <String>[],
        'priority': 'medium',
      };

      final task = Task.fromJson(json);

      expect(task.id, '1');
      expect(task.title, 'テストタスク');
      expect(task.description, 'テスト説明');
      expect(task.isCompleted, false);
      expect(task.priority, TaskPriority.medium);
    });

    test('タスクを JSON に変換できる', () {
      final task = Task(
        id: '1',
        title: 'テストタスク',
        description: 'テスト説明',
        createdAt: DateTime.now(),
        priority: TaskPriority.high,
      );

      final json = task.toJson();

      expect(json['id'], '1');
      expect(json['title'], 'テストタスク');
      expect(json['description'], 'テスト説明');
      expect(json['isCompleted'], false);
      expect(json['priority'], 'high');
    });
  });

  group('TaskPriority Extension Tests', () {
    test('displayName が正しく返される', () {
      expect(TaskPriority.low.displayName, '低');
      expect(TaskPriority.medium.displayName, '中');
      expect(TaskPriority.high.displayName, '高');
      expect(TaskPriority.urgent.displayName, '緊急');
    });

    test('colorCode が正しく返される', () {
      expect(TaskPriority.low.colorCode, '#4CAF50');
      expect(TaskPriority.medium.colorCode, '#2196F3');
      expect(TaskPriority.high.colorCode, '#FF9800');
      expect(TaskPriority.urgent.colorCode, '#F44336');
    });
  });
}
