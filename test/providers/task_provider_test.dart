import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/providers/task_provider.dart';
import 'package:task_manager/repositories/api_client.dart';

/// サーバーに通信せず、メモリの中のタスクを返す API
class FakeApiClient implements ApiClient {
  FakeApiClient(this.tasks);

  final List<Task> tasks;

  @override
  Future<List<Task>> getTasks() async => List.of(tasks);

  @override
  Future<Task> completeTask(String id) async => _setCompleted(id, true);

  @override
  Future<Task> incompleteTask(String id) async => _setCompleted(id, false);

  Task _setCompleted(String id, bool done) {
    final i = tasks.indexWhere((t) => t.id == id);
    tasks[i] = tasks[i].copyWith(isCompleted: done);
    return tasks[i];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container() {
  final created = DateTime(2026, 1, 1);
  final fake = FakeApiClient([
    Task(id: '1', title: 'a', description: '', createdAt: created),
    Task(id: '2', title: 'b', description: '', createdAt: created),
    Task(id: '3', title: 'c', description: '', createdAt: created, isCompleted: true),
  ]);
  final container = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('TaskList Provider Tests', () {
    test('API が返したタスクを一覧にする', () async {
      final container = _container();

      final taskList = await container.read(taskListProvider.future);
      expect(taskList.map((t) => t.id), ['1', '2', '3']);
    });

    test('タスクの完了状態を切り替えられる', () async {
      final container = _container();

      final initialTasks = await container.read(taskListProvider.future);
      final notifier = container.read(taskListProvider.notifier);
      final taskId = initialTasks.first.id;
      final initialStatus = initialTasks.first.isCompleted;

      await notifier.toggleTaskCompletion(taskId);

      final updatedTasks = await container.read(taskListProvider.future);
      final updatedTask = updatedTasks.firstWhere((t) => t.id == taskId);
      expect(updatedTask.isCompleted, !initialStatus);
    });

    test('completedTasks 完了済みタスクのみを返す', () async {
      final container = _container();

      await container.read(taskListProvider.future);

      final completedTasks = container.read(completedTasksProvider);
      expect(completedTasks.map((t) => t.id), ['3']);
    });

    test('incompleteTasks 未完了タスクのみを返す', () async {
      final container = _container();

      await container.read(taskListProvider.future);

      final incompleteTasks = container.read(incompleteTasksProvider);
      expect(incompleteTasks.map((t) => t.id), ['1', '2']);
    });
  });
}
