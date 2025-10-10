import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task.dart';
import '../repositories/api_client.dart';

part 'task_provider.g.dart';

/// タスク一覧の状態管理プロバイダー（APIベース）
@riverpod
class TaskList extends _$TaskList {
  @override
  Future<List<Task>> build() async {
    // APIからタスク一覧を取得
    final apiClient = ref.watch(apiClientProvider);
    return await apiClient.getTasks();
  }

  /// タスクを追加
  Future<void> addTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.createTask(task);
      return await apiClient.getTasks();
    });
  }

  /// タスクを更新
  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.updateTask(task.id, task);
      return await apiClient.getTasks();
    });
  }

  /// タスクを削除
  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteTask(taskId);
      return await apiClient.getTasks();
    });
  }

  /// タスクの完了状態を切り替え
  Future<void> toggleTaskCompletion(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      final tasks = state.value ?? [];
      final task = tasks.firstWhere((t) => t.id == taskId);

      final updatedTask = task.isCompleted
          ? await apiClient.incompleteTask(taskId)
          : await apiClient.completeTask(taskId);

      return tasks.map((t) => t.id == taskId ? updatedTask : t).toList();
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
