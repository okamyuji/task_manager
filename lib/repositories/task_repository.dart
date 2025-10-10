import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task.dart';

part 'task_repository.g.dart';

/// タスクリポジトリのプロバイダー
@riverpod
TaskRepository taskRepository(Ref ref) {
  return TaskRepository();
}

/// タスクのデータ操作を担当するリポジトリ
class TaskRepository {
  // インメモリストレージ（実際の実装ではHiveやAPIを使用）
  final List<Task> _tasks = [
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

  /// すべてのタスクを取得
  Future<List<Task>> getAllTasks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_tasks);
  }

  /// すべてのタスクを取得（getTasks()エイリアス）
  Future<List<Task>> getTasks() => getAllTasks();

  /// タスクIDでタスクを取得
  Future<Task?> getTaskById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  /// タスクを取得（getTask()エイリアス）
  Future<Task?> getTask(String id) => getTaskById(id);

  /// タスクを作成
  Future<Task> createTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newTask = task.copyWith(
      id: task.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : task.id,
    );
    _tasks.add(newTask);
    return newTask;
  }

  /// タスクを追加（addTask()エイリアス）
  Future<Task> addTask(Task task) => createTask(task);

  /// タスクを更新
  Future<Task> updateTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      return task;
    }
    throw Exception('Task not found: ${task.id}');
  }

  /// タスクを削除
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final initialLength = _tasks.length;
    _tasks.removeWhere((task) => task.id == id);
    if (_tasks.length == initialLength) {
      throw Exception('Task not found: $id');
    }
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

  /// 期限でタスクを検索
  Future<List<Task>> getTasksByDueDate(DateTime date) async {
    final tasks = await getAllTasks();
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDate = task.dueDate!;
      return dueDate.year == date.year &&
          dueDate.month == date.month &&
          dueDate.day == date.day;
    }).toList();
  }
}
