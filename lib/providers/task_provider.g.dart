// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// タスク一覧の状態管理プロバイダー（APIベース）

@ProviderFor(TaskList)
const taskListProvider = TaskListProvider._();

/// タスク一覧の状態管理プロバイダー（APIベース）
final class TaskListProvider
    extends $AsyncNotifierProvider<TaskList, List<Task>> {
  /// タスク一覧の状態管理プロバイダー（APIベース）
  const TaskListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskListHash();

  @$internal
  @override
  TaskList create() => TaskList();
}

String _$taskListHash() => r'2c21792af9dd9b77f0b7560064f4e9ac1d6875d9';

/// タスク一覧の状態管理プロバイダー（APIベース）

abstract class _$TaskList extends $AsyncNotifier<List<Task>> {
  FutureOr<List<Task>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Task>>, List<Task>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Task>>, List<Task>>,
              AsyncValue<List<Task>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 特定のタスクを取得するプロバイダー

@ProviderFor(task)
const taskProvider = TaskFamily._();

/// 特定のタスクを取得するプロバイダー

final class TaskProvider extends $FunctionalProvider<Task?, Task?, Task?>
    with $Provider<Task?> {
  /// 特定のタスクを取得するプロバイダー
  const TaskProvider._({
    required TaskFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'taskProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskHash();

  @override
  String toString() {
    return r'taskProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Task?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Task? create(Ref ref) {
    final argument = this.argument as String;
    return task(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Task? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Task?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TaskProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskHash() => r'd109f5ab40717b4817cb820b6beda5840accd46e';

/// 特定のタスクを取得するプロバイダー

final class TaskFamily extends $Family
    with $FunctionalFamilyOverride<Task?, String> {
  const TaskFamily._()
    : super(
        retry: null,
        name: r'taskProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 特定のタスクを取得するプロバイダー

  TaskProvider call(String taskId) =>
      TaskProvider._(argument: taskId, from: this);

  @override
  String toString() => r'taskProvider';
}

/// 完了済みタスクのフィルタリング

@ProviderFor(completedTasks)
const completedTasksProvider = CompletedTasksProvider._();

/// 完了済みタスクのフィルタリング

final class CompletedTasksProvider
    extends $FunctionalProvider<List<Task>, List<Task>, List<Task>>
    with $Provider<List<Task>> {
  /// 完了済みタスクのフィルタリング
  const CompletedTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'completedTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$completedTasksHash();

  @$internal
  @override
  $ProviderElement<List<Task>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Task> create(Ref ref) {
    return completedTasks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Task> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Task>>(value),
    );
  }
}

String _$completedTasksHash() => r'9edaf210190c8eb2d6a089db88f2a941c69b53dd';

/// 未完了タスクのフィルタリング

@ProviderFor(incompleteTasks)
const incompleteTasksProvider = IncompleteTasksProvider._();

/// 未完了タスクのフィルタリング

final class IncompleteTasksProvider
    extends $FunctionalProvider<List<Task>, List<Task>, List<Task>>
    with $Provider<List<Task>> {
  /// 未完了タスクのフィルタリング
  const IncompleteTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incompleteTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incompleteTasksHash();

  @$internal
  @override
  $ProviderElement<List<Task>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Task> create(Ref ref) {
    return incompleteTasks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Task> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Task>>(value),
    );
  }
}

String _$incompleteTasksHash() => r'e42a2f5b3d3d2ba45651ffe0d0ab0353e7718691';
