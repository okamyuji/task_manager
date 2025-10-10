import 'package:hive/hive.dart';

import 'task.dart';

/// Hive用のタスクモデル
class TaskHive extends HiveObject {
  late String id;
  late String title;
  late String description;
  late DateTime createdAt;
  DateTime? dueDate;
  late bool isCompleted;
  DateTime? completedAt;
  late List<String> tags;
  late String priority; // TaskPriorityをStringとして保存

  TaskHive();

  /// TaskからTaskHiveに変換
  factory TaskHive.fromTask(Task task) {
    return TaskHive()
      ..id = task.id
      ..title = task.title
      ..description = task.description
      ..createdAt = task.createdAt
      ..dueDate = task.dueDate
      ..isCompleted = task.isCompleted
      ..completedAt = task.completedAt
      ..tags = List<String>.from(task.tags)
      ..priority = task.priority.name;
  }

  /// TaskHiveからTaskに変換
  Task toTask() {
    return Task(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      dueDate: dueDate,
      isCompleted: isCompleted,
      completedAt: completedAt,
      tags: tags,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == priority,
        orElse: () => TaskPriority.medium,
      ),
    );
  }
}

/// TaskHive用のTypeAdapter（手動実装）
class TaskHiveAdapter extends TypeAdapter<TaskHive> {
  @override
  final int typeId = 0;

  @override
  TaskHive read(BinaryReader reader) {
    final task = TaskHive()
      ..id = reader.readString()
      ..title = reader.readString()
      ..description = reader.readString()
      ..createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt())
      ..dueDate = reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null
      ..isCompleted = reader.readBool()
      ..completedAt = reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null
      ..tags = (reader.readList()).cast<String>()
      ..priority = reader.readString();
    return task;
  }

  @override
  void write(BinaryWriter writer, TaskHive obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    // dueDate
    writer.writeBool(obj.dueDate != null);
    if (obj.dueDate != null) {
      writer.writeInt(obj.dueDate!.millisecondsSinceEpoch);
    }

    writer.writeBool(obj.isCompleted);

    // completedAt
    writer.writeBool(obj.completedAt != null);
    if (obj.completedAt != null) {
      writer.writeInt(obj.completedAt!.millisecondsSinceEpoch);
    }

    writer.writeList(obj.tags);
    writer.writeString(obj.priority);
  }
}
