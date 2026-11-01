// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_upload_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 画像アップロードプロバイダー

@ProviderFor(ImageUpload)
final imageUploadProvider = ImageUploadProvider._();

/// 画像アップロードプロバイダー
final class ImageUploadProvider
    extends $NotifierProvider<ImageUpload, ImageUploadState> {
  /// 画像アップロードプロバイダー
  ImageUploadProvider._()
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

String _$imageUploadHash() => r'308f97d47b7b8854a638d481ee54af62c060b2fe';

/// 画像アップロードプロバイダー

abstract class _$ImageUpload extends $Notifier<ImageUploadState> {
  ImageUploadState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ImageUploadState, ImageUploadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImageUploadState, ImageUploadState>,
              ImageUploadState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
