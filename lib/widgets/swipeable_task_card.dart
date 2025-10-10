import 'package:flutter/material.dart';

import '../models/task.dart';
import 'animated_task_card.dart';

/// スワイプ可能なタスクカード
class SwipeableTaskCard extends StatelessWidget {
  const SwipeableTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 右スワイプ：完了/未完了を切り替え
          onToggleComplete();
          return false;
        } else {
          // 左スワイプ：削除確認
          return await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('削除確認'),
                content: Text('「${task.title}」を削除しますか？'),
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
              );
            },
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('「${task.title}」を削除しました')));
        }
      },
      child: AnimatedTaskCard(
        task: task,
        onTap: onTap,
        onToggleComplete: onToggleComplete,
      ),
    );
  }
}
