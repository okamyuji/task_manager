// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_upload_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 画像アップロードプロバイダー

@ProviderFor(ImageUpload)
const imageUploadProvider = ImageUploadProvider._();

/// 画像アップロードプロバイダー
final class ImageUploadProvider
    extends $NotifierProvider<ImageUpload, ImageUploadState> {
  /// 画像アップロードプロバイダー
  const ImageUploadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageUploadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageUploadHash();

  @$internal
  @override
  ImageUpload create() => ImageUpload();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageUploadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageUploadState>(value),
    );
  }
}

String _$imageUploadHash() => r'a4e23027a5648e82d9d250a3b8a49548f9411457';

/// 画像アップロードプロバイダー

abstract class _$ImageUpload extends $Notifier<ImageUploadState> {
  ImageUploadState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ImageUploadState, ImageUploadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImageUploadState, ImageUploadState>,
              ImageUploadState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
