// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_cache_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 画像キャッシュサービスのプロバイダー

@ProviderFor(imageCacheService)
const imageCacheServiceProvider = ImageCacheServiceProvider._();

/// 画像キャッシュサービスのプロバイダー

final class ImageCacheServiceProvider
    extends
        $FunctionalProvider<
          ImageCacheService,
          ImageCacheService,
          ImageCacheService
        >
    with $Provider<ImageCacheService> {
  /// 画像キャッシュサービスのプロバイダー
  const ImageCacheServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageCacheServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageCacheServiceHash();

  @$internal
  @override
  $ProviderElement<ImageCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageCacheService create(Ref ref) {
    return imageCacheService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageCacheService>(value),
    );
  }
}

String _$imageCacheServiceHash() => r'cce93ea435aa7351bc1576a057f75f390f658010';
