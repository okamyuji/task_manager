import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task.dart';
import '../models/task_hive.dart';

part 'task_local_repository.g.dart';

/// タスクローカルリポジトリのプロバイダー
@riverpod
TaskLocalRepository taskLocalRepository(Ref ref) {
  return TaskLocalRepository();
}

/// ローカルタスクのデータ操作を担当するリポジトリ
class TaskLocalRepository {
  static const String _boxName = 'tasks';

  /// Hiveの初期化
  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskHiveAdapter());
    await Hive.openBox<TaskHive>(_boxName);
  }

  /// ボックスを取得
  Box<TaskHive> _getBox() {
    return Hive.box<TaskHive>(_boxName);
  }

  /// すべてのタスクを取得
  Future<List<Task>> getAllTasks() async {
    final box = _getBox();
    return box.values.map((taskHive) => taskHive.toTask()).toList();
  }

  /// タスクIDでタスクを取得
  Future<Task?> getTaskById(String id) async {
    final box = _getBox();
    final taskHive = box.values.where((t) => t.id == id).firstOrNull;
    return taskHive?.toTask();
  }

  /// タスクを作成
  Future<Task> createTask(Task task) async {
    final box = _getBox();
    final taskHive = TaskHive.fromTask(task);
    await box.put(task.id, taskHive);
    return task;
  }

  /// タスクを更新
  Future<Task> updateTask(Task task) async {
    final box = _getBox();
    final taskHive = TaskHive.fromTask(task);
    await box.put(task.id, taskHive);
    return task;
  }

  /// タスクを削除
  Future<void> deleteTask(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// 完了済みタスクを取得
  Future<List<Task>> getCompletedTasks() async {
    final tasks = await getAllTasks();
    return tasks.where((task) => task.isCompleted).toList();
  }

  /// 未完了タスクを取得
  Future<List<Task>> getIncompleteTasks() async {
    final tasks = await getAllTasks();
    return tasks.where((task) => !task.isCompleted).toList();
  }

  /// 優先度でタスクをフィルタリング
  Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    final tasks = await getAllTasks();
    return tasks.where((task) => task.priority == priority).toList();
  }

  /// タスクを検索
  Future<List<Task>> searchTasks(String query) async {
    final tasks = await getAllTasks();
    final lowercaseQuery = query.toLowerCase();
    return tasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// すべてのタスクを削除
  Future<void> clearAllTasks() async {
    final box = _getBox();
    await box.clear();
  }
}
