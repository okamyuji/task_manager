import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/remote_task_provider.dart';
import '../widgets/error_banner.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';

/// リモートタスク一覧画面
class RemoteTaskListScreen extends ConsumerWidget {
  const RemoteTaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(remoteTaskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('リモートタスク'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(remoteTaskListProvider);
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'リモートタスクがありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'APIサーバーに接続してタスクを取得します',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(remoteTaskListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
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
                        .read(remoteTaskListProvider.notifier)
                        .toggleTaskCompletion(task.id);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorBanner(
          message: 'リモートタスクの読み込みに失敗しました',
          error: error,
          onRetry: () {
            ref.invalidate(remoteTaskListProvider);
          },
        ),
      ),
    );
  }
}
