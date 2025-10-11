import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import '../models/task.dart';
import '../providers/image_upload_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/cached_image.dart';

/// タスク追加画面
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _uuid = const Uuid();

  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  final List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(imageUploadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク追加'),
        actions: [TextButton(onPressed: _saveTask, child: const Text('保存'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // タイトル
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: 'タスクのタイトルを入力',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'タイトルを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 説明
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                hintText: 'タスクの説明を入力',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 16),

            // 優先度
            DropdownButtonFormField<TaskPriority>(
              initialValue: _selectedPriority,
              decoration: const InputDecoration(
                labelText: '優先度',
                prefixIcon: Icon(Icons.flag),
              ),
              items: TaskPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPriority = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 期限
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(
                _selectedDueDate != null
                    ? DateFormatter.formatDateTimeFlexible(_selectedDueDate!)
                    : '期限を設定',
              ),
              trailing: _selectedDueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedDueDate = null;
                        });
                      },
                    )
                  : null,
              onTap: _selectDueDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),

            // 画像アップロード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('画像', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (uploadState.uploadedUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedImage(
                          imageUrl: uploadState.uploadedUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              ref.read(imageUploadProvider.notifier).reset();
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('削除'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ] else if (uploadState.isUploading) ...[
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              value: uploadState.progress,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'アップロード中... ${(uploadState.progress * 100).toInt()}%',
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final uploadUrl =
                                    '${AppConstants.apiBaseUrl}/upload';
                                ref
                                    .read(imageUploadProvider.notifier)
                                    .pickAndUploadFromCamera(uploadUrl);
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('カメラ'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final uploadUrl =
                                    '${AppConstants.apiBaseUrl}/upload';
                                ref
                                    .read(imageUploadProvider.notifier)
                                    .pickAndUploadFromGallery(uploadUrl);
                              },
                              icon: const Icon(Icons.photo_library),
                              label: const Text('ギャラリー'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (uploadState.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          uploadState.errorMessage!,
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // タグ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'タグ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton.icon(
                          onPressed: _addTag,
                          icon: const Icon(Icons.add),
                          label: const Text('追加'),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                onDeleted: () {
                                  setState(() {
                                    _tags.remove(tag);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      // 時刻も設定するか確認
      final includeTime = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('時刻も設定しますか？'),
          content: const Text('日付のみの場合は「日付のみ」を、\n時刻も指定する場合は「時刻も設定」を選択してください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('日付のみ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('時刻も設定'),
            ),
          ],
        ),
      );

      if (includeTime == null) return; // キャンセルされた場合

      if (includeTime) {
        // 時刻を選択
        if (!mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedDueDate != null
              ? TimeOfDay.fromDateTime(_selectedDueDate!)
              : TimeOfDay.now(),
        );

        if (time != null && mounted) {
          setState(() {
            _selectedDueDate = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
        }
      } else {
        // 日付のみ（時刻は0:00）
        setState(() {
          _selectedDueDate = DateTime(date.year, date.month, date.day, 0, 0);
        });
      }
    }
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タグを追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'タグ名',
            hintText: 'タグ名を入力',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final uploadState = ref.read(imageUploadProvider);

    final task = Task(
      id: _uuid.v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      createdAt: DateTime.now(),
      dueDate: _selectedDueDate,
      priority: _selectedPriority,
      tags: _tags,
      imageUrl: uploadState.uploadedUrl, // アップロードした画像URL
    );

    try {
      await ref.read(taskListProvider.notifier).addTask(task);

      // 画像アップロード状態をリセット
      ref.read(imageUploadProvider.notifier).reset();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('タスクを追加しました')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }
}
