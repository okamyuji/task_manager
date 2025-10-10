import 'package:flutter/material.dart';

import '../models/task.dart';

/// タスクフィルターの選択肢
enum TaskFilter {
  all,
  active,
  completed,
  lowPriority,
  mediumPriority,
  highPriority,
  urgentPriority,
}

extension TaskFilterExtension on TaskFilter {
  String get displayName {
    switch (this) {
      case TaskFilter.all:
        return 'すべて';
      case TaskFilter.active:
        return '未完了のみ';
      case TaskFilter.completed:
        return '完了済みのみ';
      case TaskFilter.lowPriority:
        return '優先度: 低';
      case TaskFilter.mediumPriority:
        return '優先度: 中';
      case TaskFilter.highPriority:
        return '優先度: 高';
      case TaskFilter.urgentPriority:
        return '優先度: 緊急';
    }
  }

  bool Function(Task) get filterFunction {
    switch (this) {
      case TaskFilter.all:
        return (task) => true;
      case TaskFilter.active:
        return (task) => !task.isCompleted;
      case TaskFilter.completed:
        return (task) => task.isCompleted;
      case TaskFilter.lowPriority:
        return (task) => task.priority == TaskPriority.low;
      case TaskFilter.mediumPriority:
        return (task) => task.priority == TaskPriority.medium;
      case TaskFilter.highPriority:
        return (task) => task.priority == TaskPriority.high;
      case TaskFilter.urgentPriority:
        return (task) => task.priority == TaskPriority.urgent;
    }
  }
}

/// フィルター選択ボトムシート
class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterSelected,
  });

  final TaskFilter currentFilter;
  final void Function(TaskFilter) onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('フィルター', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...TaskFilter.values.map((filter) {
              final isSelected = filter == currentFilter;
              return ListTile(
                title: Text(filter.displayName),
                trailing: isSelected ? const Icon(Icons.check) : null,
                selected: isSelected,
                onTap: () {
                  onFilterSelected(filter);
                  Navigator.of(context).pop();
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
