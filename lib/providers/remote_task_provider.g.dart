// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// リモートタスク一覧の状態管理プロバイダー

@ProviderFor(RemoteTaskList)
const remoteTaskListProvider = RemoteTaskListProvider._();

/// リモートタスク一覧の状態管理プロバイダー
final class RemoteTaskListProvider
    extends $AsyncNotifierProvider<RemoteTaskList, List<Task>> {
  /// リモートタスク一覧の状態管理プロバイダー
  const RemoteTaskListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteTaskListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteTaskListHash();

  @$internal
  @override
  RemoteTaskList create() => RemoteTaskList();
}

String _$remoteTaskListHash() => r'1d633ca4671aec97712e2eae1dc53d872e021524';

/// リモートタスク一覧の状態管理プロバイダー

abstract class _$RemoteTaskList extends $AsyncNotifier<List<Task>> {
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
