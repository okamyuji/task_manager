import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task.dart';
import '../repositories/api_client.dart';

part 'remote_task_provider.g.dart';

/// リモートタスク一覧の状態管理プロバイダー
@riverpod
class RemoteTaskList extends _$RemoteTaskList {
  @override
  Future<List<Task>> build() async {
    // APIからタスク一覧を取得
    try {
      final apiClient = ref.watch(apiClientProvider);
      return await apiClient.getTasks();
    } catch (e) {
      // エラー時は空リストを返す（実際のAPIがない場合）
      return [];
    }
  }

  /// タスクを追加
  Future<void> addTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      final newTask = await apiClient.createTask(task);
      final tasks = state.value ?? [];
      return [...tasks, newTask];
    });
  }

  /// タスクを更新
  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      final updatedTask = await apiClient.updateTask(task.id, task);
      final tasks = state.value ?? [];
      return tasks.map((t) => t.id == task.id ? updatedTask : t).toList();
    });
  }

  /// タスクを削除
  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteTask(taskId);
      final tasks = state.value ?? [];
      return tasks.where((t) => t.id != taskId).toList();
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
