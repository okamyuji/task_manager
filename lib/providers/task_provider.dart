import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';

part 'task_provider.g.dart';

/// タスク一覧の状態管理プロバイダー
@riverpod
class TaskList extends _$TaskList {
  @override
  Future<List<Task>> build() async {
    // 初期データをロード
    return [
      Task(
        id: '1',
        title: 'Flutterを学ぶ',
        description: '基本的な概念を理解する',
        createdAt: DateTime.now(),
        priority: TaskPriority.high,
      ),
      Task(
        id: '2',
        title: 'Riverpodを理解する',
        description: 'Provider、StateNotifierの違いを学ぶ',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        tags: ['学習', 'フレームワーク'],
      ),
      Task(
        id: '3',
        title: 'リスト表示を実装',
        description: 'ListViewとNavigationの使い方',
        createdAt: DateTime.now(),
        isCompleted: true,
      ),
    ];
  }

  /// タスクを追加
  Future<void> addTask(Task task) async {
    final repository = ref.read(taskRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addTask(task);
      return await repository.getTasks();
    });
  }

  /// タスクを更新
  Future<void> updateTask(Task task) async {
    final repository = ref.read(taskRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateTask(task);
      return await repository.getTasks();
    });
  }

  /// タスクを削除
  Future<void> deleteTask(String taskId) async {
    final repository = ref.read(taskRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteTask(taskId);
      return await repository.getTasks();
    });
  }

  /// タスクの完了状態を切り替え
  Future<void> toggleTaskCompletion(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tasks = state.value ?? [];
      return tasks.map((task) {
        if (task.id == taskId) {
          return task.copyWith(
            isCompleted: !task.isCompleted,
            completedAt: task.isCompleted ? null : DateTime.now(),
          );
        }
        return task;
      }).toList();
    });
  }
}

/// 特定のタスクを取得するプロバイダー
@riverpod
Task? task(Ref ref, String taskId) {
  final tasks = ref.watch(taskListProvider);
  return tasks.when(
    data: (tasks) => tasks.where((t) => t.id == taskId).firstOrNull,
    loading: () => null,
    error: (_, __) => null,
  );
}

/// 完了済みタスクのフィルタリング
@riverpod
List<Task> completedTasks(Ref ref) {
  final tasks = ref.watch(taskListProvider);
  return tasks.when(
    data: (tasks) => tasks.where((t) => t.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}

/// 未完了タスクのフィルタリング
@riverpod
List<Task> incompleteTasks(Ref ref) {
  final tasks = ref.watch(taskListProvider);
  return tasks.when(
    data: (tasks) => tasks.where((t) => !t.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}
