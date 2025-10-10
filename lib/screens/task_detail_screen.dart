import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_formatter.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'edit_task_screen.dart';

/// タスク詳細画面
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskProvider(taskId));

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('タスク詳細')),
        body: const Center(child: Text('タスクが見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTaskScreen(task: task),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await _showDeleteConfirmDialog(context);
              if (confirmed == true && context.mounted) {
                await ref.read(taskListProvider.notifier).deleteTask(taskId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(task.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),

            // 完了状態
            Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    ref
                        .read(taskListProvider.notifier)
                        .toggleTaskCompletion(taskId);
                  },
                ),
                Text(
                  task.isCompleted ? '完了' : '未完了',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),

            const Divider(height: 32),

            // 優先度
            _buildInfoRow(
              context,
              icon: Icons.flag,
              label: '優先度',
              value: task.priority.displayName,
            ),

            // 作成日
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: '作成日',
              value: DateFormatter.formatDate(task.createdAt),
            ),

            // 期限
            if (task.dueDate != null)
              _buildInfoRow(
                context,
                icon: Icons.event,
                label: '期限',
                value: DateFormatter.formatDateTime(task.dueDate!),
              ),

            // 完了日
            if (task.completedAt != null)
              _buildInfoRow(
                context,
                icon: Icons.check_circle,
                label: '完了日',
                value: DateFormatter.formatDateTime(task.completedAt!),
              ),

            const Divider(height: 32),

            // タグ
            if (task.tags.isNotEmpty) ...[
              Text('タグ', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: task.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 説明
            Text('説明', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              task.description.isEmpty ? '説明がありません' : task.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: const Text('このタスクを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
