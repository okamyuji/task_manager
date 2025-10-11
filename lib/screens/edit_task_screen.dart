import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import '../models/task.dart';
import '../providers/image_upload_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/cached_image.dart';

/// タスク編集画面
class EditTaskScreen extends ConsumerStatefulWidget {
  const EditTaskScreen({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskPriority _selectedPriority;
  DateTime? _selectedDate;
  final List<String> _tags = [];
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _selectedPriority = widget.task.priority;
    _selectedDate = widget.task.dueDate;
    _tags.addAll(widget.task.tags);
    _tagController = TextEditingController();

    // 既存画像がある場合、アップロード状態に設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.task.imageUrl != null) {
        ref
            .read(imageUploadProvider.notifier)
            .setUploadedUrl(widget.task.imageUrl!);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
          initialTime: _selectedDate != null
              ? TimeOfDay.fromDateTime(_selectedDate!)
              : TimeOfDay.now(),
        );

        if (time != null && mounted) {
          setState(() {
            _selectedDate = DateTime(
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
          _selectedDate = DateTime(date.year, date.month, date.day, 0, 0);
        });
      }
    }
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final uploadState = ref.read(imageUploadProvider);

      final updatedTask = widget.task.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
        priority: _selectedPriority,
        tags: _tags,
        imageUrl: uploadState.uploadedUrl, // アップロードした画像URL
      );

      ref.read(taskListProvider.notifier).updateTask(updatedTask);

      // 画像アップロード状態をリセット
      ref.read(imageUploadProvider.notifier).reset();

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(imageUploadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク編集'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveTask),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
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
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '説明を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDate == null
                    ? '期限を設定'
                    : '期限: ${DateFormatter.formatDateTimeFlexible(_selectedDate!)}',
              ),
              trailing: _selectedDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                    )
                  : null,
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _selectedPriority,
              decoration: const InputDecoration(
                labelText: '優先度',
                prefixIcon: Icon(Icons.flag),
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPriority = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // 画像
            Text('画像', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ] else if (uploadState.isUploading) ...[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(value: uploadState.progress),
                    const SizedBox(height: 8),
                    Text('アップロード中... ${(uploadState.progress * 100).toInt()}%'),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final uploadUrl = '${AppConstants.apiBaseUrl}/upload';
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
                        final uploadUrl = '${AppConstants.apiBaseUrl}/upload';
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
            const SizedBox(height: 24),
            Text('タグ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._tags.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    onDeleted: () => _removeTag(entry.key),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'タグを追加',
                      prefixIcon: Icon(Icons.label),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addTag),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
