// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_local_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// タスクローカルリポジトリのプロバイダー

@ProviderFor(taskLocalRepository)
const taskLocalRepositoryProvider = TaskLocalRepositoryProvider._();

/// タスクローカルリポジトリのプロバイダー

final class TaskLocalRepositoryProvider
    extends
        $FunctionalProvider<
          TaskLocalRepository,
          TaskLocalRepository,
          TaskLocalRepository
        >
    with $Provider<TaskLocalRepository> {
  /// タスクローカルリポジトリのプロバイダー
  const TaskLocalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskLocalRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskLocalRepositoryHash();

  @$internal
  @override
  $ProviderElement<TaskLocalRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TaskLocalRepository create(Ref ref) {
    return taskLocalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskLocalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskLocalRepository>(value),
    );
  }
}

String _$taskLocalRepositoryHash() =>
    r'4e213ad56b0c926d8e5dcf128c3dd494d6d328e2';
