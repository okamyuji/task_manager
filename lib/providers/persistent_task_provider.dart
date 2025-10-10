import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task.dart';
import '../repositories/task_local_repository.dart';

part 'persistent_task_provider.g.dart';

/// 永続化タスク一覧の状態管理プロバイダー
@riverpod
class PersistentTaskList extends _$PersistentTaskList {
  @override
  Future<List<Task>> build() async {
    final repository = ref.watch(taskLocalRepositoryProvider);
    return await repository.getAllTasks();
  }

  /// タスクを追加
  Future<void> addTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskLocalRepositoryProvider);
      await repository.createTask(task);
      return await repository.getAllTasks();
    });
  }

  /// タスクを更新
  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskLocalRepositoryProvider);
      await repository.updateTask(task);
      return await repository.getAllTasks();
    });
  }

  /// タスクを削除
  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskLocalRepositoryProvider);
      await repository.deleteTask(taskId);
      return await repository.getAllTasks();
    });
  }

  /// タスクの完了状態を切り替え
  Future<void> toggleTaskCompletion(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskLocalRepositoryProvider);
      final task = await repository.getTaskById(taskId);
      if (task == null) throw Exception('Task not found');

      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: task.isCompleted ? null : DateTime.now(),
      );
      await repository.updateTask(updatedTask);
      return await repository.getAllTasks();
    });
  }

  /// タスクを検索
  Future<void> searchTasks(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskLocalRepositoryProvider);
      return await repository.searchTasks(query);
    });
  }
}
