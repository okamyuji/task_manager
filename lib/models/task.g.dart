// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map json) => $checkedCreate('_Task', json, (
  $checkedConvert,
) {
  final val = _Task(
    id: $checkedConvert('id', (v) => v as String),
    title: $checkedConvert('title', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    dueDate: $checkedConvert(
      'dueDate',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    isCompleted: $checkedConvert('isCompleted', (v) => v as bool? ?? false),
    completedAt: $checkedConvert(
      'completedAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    tags: $checkedConvert(
      'tags',
      (v) =>
          (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    ),
    priority: $checkedConvert(
      'priority',
      (v) =>
          $enumDecodeNullable(_$TaskPriorityEnumMap, v) ?? TaskPriority.medium,
    ),
    imageUrl: $checkedConvert('imageUrl', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'createdAt': instance.createdAt.toIso8601String(),
  'dueDate': instance.dueDate?.toIso8601String(),
  'isCompleted': instance.isCompleted,
  'completedAt': instance.completedAt?.toIso8601String(),
  'tags': instance.tags,
  'priority': _$TaskPriorityEnumMap[instance.priority]!,
  'imageUrl': instance.imageUrl,
};

const _$TaskPriorityEnumMap = {
  TaskPriority.low: 'low',
  TaskPriority.medium: 'medium',
  TaskPriority.high: 'high',
  TaskPriority.urgent: 'urgent',
};
