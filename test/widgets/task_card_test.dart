import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/widgets/task_card.dart';

void main() {
  group('TaskCard Widget Tests', () {
    testWidgets('タスクの情報が正しく表示される', (tester) async {
      final task = Task(
        id: '1',
        title: 'テストタスク',
        description: 'テスト説明',
        createdAt: DateTime.now(),
        priority: TaskPriority.high,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: task, onTap: () {}, onToggleComplete: () {}),
          ),
        ),
      );

      expect(find.text('テストタスク'), findsOneWidget);
      expect(find.text('テスト説明'), findsOneWidget);
    });

    testWidgets('完了状態のタスクはチェックボックスが選択されている', (tester) async {
      final task = Task(
        id: '1',
        title: 'テストタスク',
        description: 'テスト説明',
        createdAt: DateTime.now(),
        isCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: task, onTap: () {}, onToggleComplete: () {}),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('チェックボックスをタップすると onToggleComplete が呼ばれる', (tester) async {
      final task = Task(
        id: '1',
        title: 'テストタスク',
        description: 'テスト説明',
        createdAt: DateTime.now(),
      );

      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              onTap: () {},
              onToggleComplete: () {
                toggleCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      expect(toggleCalled, true);
    });

    testWidgets('カードをタップすると onTap が呼ばれる', (tester) async {
      final task = Task(
        id: '1',
        title: 'テストタスク',
        description: 'テスト説明',
        createdAt: DateTime.now(),
      );

      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              onTap: () {
                tapCalled = true;
              },
              onToggleComplete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      expect(tapCalled, true);
    });

    testWidgets('優先度に応じた色が表示される', (tester) async {
      for (final priority in TaskPriority.values) {
        final task = Task(
          id: '1',
          title: 'テストタスク',
          description: 'テスト説明',
          createdAt: DateTime.now(),
          priority: priority,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TaskCard(task: task, onTap: () {}, onToggleComplete: () {}),
            ),
          ),
        );

        // 優先度バッジが表示されていることを確認
        expect(find.text(priority.displayName), findsOneWidget);

        await tester.pumpAndSettle();
      }
    });
  });
}
