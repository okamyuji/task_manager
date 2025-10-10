// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persistent_task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 永続化タスク一覧の状態管理プロバイダー

@ProviderFor(PersistentTaskList)
const persistentTaskListProvider = PersistentTaskListProvider._();

/// 永続化タスク一覧の状態管理プロバイダー
final class PersistentTaskListProvider
    extends $AsyncNotifierProvider<PersistentTaskList, List<Task>> {
  /// 永続化タスク一覧の状態管理プロバイダー
  const PersistentTaskListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'persistentTaskListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$persistentTaskListHash();

  @$internal
  @override
  PersistentTaskList create() => PersistentTaskList();
}

String _$persistentTaskListHash() =>
    r'f9032bd251736611aa1645ed3d84b5c01f6ffafe';

/// 永続化タスク一覧の状態管理プロバイダー

abstract class _$PersistentTaskList extends $AsyncNotifier<List<Task>> {
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
