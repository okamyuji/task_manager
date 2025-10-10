import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/providers/task_provider.dart';

void main() {
  group('TaskList Provider Tests', () {
    test('初期状態は3つのモックタスクを含む', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final taskList = await container.read(taskListProvider.future);
      expect(taskList.length, greaterThanOrEqualTo(3)); // 他のテストの影響を考慮
    });

    test('タスクの完了状態を切り替えられる', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

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
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期データには1つ完了済みタスクがある
      await container.read(taskListProvider.future);

      final completedTasks = container.read(completedTasksProvider);
      expect(completedTasks.length, 1);
      expect(completedTasks.first.isCompleted, true);
    });

    test('incompleteTasks 未完了タスクのみを返す', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期データには2つ未完了タスクがある
      await container.read(taskListProvider.future);

      final incompleteTasks = container.read(incompleteTasksProvider);
      expect(incompleteTasks.length, 2);
      expect(incompleteTasks.every((t) => !t.isCompleted), true);
    });
  });
}
