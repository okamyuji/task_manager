import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_provider.dart';
import '../widgets/error_banner.dart';
import '../widgets/swipeable_task_card.dart';
import 'add_task_screen.dart';
import 'filter_bottom_sheet.dart';
import 'task_detail_screen.dart';

/// タスク一覧画面
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  TaskFilter _currentFilter = TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentFilter == TaskFilter.all
              ? 'タスク一覧'
              : 'タスク一覧 (${_currentFilter.displayName})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => FilterBottomSheet(
                  currentFilter: _currentFilter,
                  onFilterSelected: (filter) {
                    setState(() {
                      _currentFilter = filter;
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (allTasks) {
          // フィルター適用
          final tasks = allTasks.where(_currentFilter.filterFunction).toList();

          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'タスクがありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(taskListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return SwipeableTaskCard(
                  task: task,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(taskId: task.id),
                      ),
                    );
                  },
                  onToggleComplete: () {
                    ref
                        .read(taskListProvider.notifier)
                        .toggleTaskCompletion(task.id);
                  },
                  onDelete: () {
                    ref.read(taskListProvider.notifier).deleteTask(task.id);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorBanner(
          message: 'タスクの読み込みに失敗しました',
          error: error,
          onRetry: () {
            ref.invalidate(taskListProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
