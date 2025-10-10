// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_upload_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImageUploadState {

 bool get isUploading; double get progress; String? get uploadedUrl; String? get errorMessage;
/// Create a copy of ImageUploadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageUploadStateCopyWith<ImageUploadState> get copyWith => _$ImageUploadStateCopyWithImpl<ImageUploadState>(this as ImageUploadState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageUploadState&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.uploadedUrl, uploadedUrl) || other.uploadedUrl == uploadedUrl)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isUploading,progress,uploadedUrl,errorMessage);

@override
String toString() {
  return 'ImageUploadState(isUploading: $isUploading, progress: $progress, uploadedUrl: $uploadedUrl, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ImageUploadStateCopyWith<$Res>  {
  factory $ImageUploadStateCopyWith(ImageUploadState value, $Res Function(ImageUploadState) _then) = _$ImageUploadStateCopyWithImpl;
@useResult
$Res call({
 bool isUploading, double progress, String? uploadedUrl, String? errorMessage
});




}
/// @nodoc
class _$ImageUploadStateCopyWithImpl<$Res>
    implements $ImageUploadStateCopyWith<$Res> {
  _$ImageUploadStateCopyWithImpl(this._self, this._then);

  final ImageUploadState _self;
  final $Res Function(ImageUploadState) _then;

/// Create a copy of ImageUploadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isUploading = null,Object? progress = null,Object? uploadedUrl = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,uploadedUrl: freezed == uploadedUrl ? _self.uploadedUrl : uploadedUrl // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageUploadState].
extension ImageUploadStatePatterns on ImageUploadState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageUploadState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageUploadState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageUploadState value)  $default,){
final _that = this;
switch (_that) {
case _ImageUploadState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageUploadState value)?  $default,){
final _that = this;
switch (_that) {
case _ImageUploadState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isUploading,  double progress,  String? uploadedUrl,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageUploadState() when $default != null:
return $default(_that.isUploading,_that.progress,_that.uploadedUrl,_that.errorMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isUploading,  double progress,  String? uploadedUrl,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ImageUploadState():
return $default(_that.isUploading,_that.progress,_that.uploadedUrl,_that.errorMessage);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isUploading,  double progress,  String? uploadedUrl,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ImageUploadState() when $default != null:
return $default(_that.isUploading,_that.progress,_that.uploadedUrl,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ImageUploadState implements ImageUploadState {
  const _ImageUploadState({this.isUploading = false, this.progress = 0.0, this.uploadedUrl, this.errorMessage});
  

@override@JsonKey() final  bool isUploading;
@override@JsonKey() final  double progress;
@override final  String? uploadedUrl;
@override final  String? errorMessage;

/// Create a copy of ImageUploadState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageUploadStateCopyWith<_ImageUploadState> get copyWith => __$ImageUploadStateCopyWithImpl<_ImageUploadState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageUploadState&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.uploadedUrl, uploadedUrl) || other.uploadedUrl == uploadedUrl)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isUploading,progress,uploadedUrl,errorMessage);

@override
String toString() {
  return 'ImageUploadState(isUploading: $isUploading, progress: $progress, uploadedUrl: $uploadedUrl, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ImageUploadStateCopyWith<$Res> implements $ImageUploadStateCopyWith<$Res> {
  factory _$ImageUploadStateCopyWith(_ImageUploadState value, $Res Function(_ImageUploadState) _then) = __$ImageUploadStateCopyWithImpl;
@override @useResult
$Res call({
 bool isUploading, double progress, String? uploadedUrl, String? errorMessage
});




}
/// @nodoc
class __$ImageUploadStateCopyWithImpl<$Res>
    implements _$ImageUploadStateCopyWith<$Res> {
  __$ImageUploadStateCopyWithImpl(this._self, this._then);

  final _ImageUploadState _self;
  final $Res Function(_ImageUploadState) _then;

/// Create a copy of ImageUploadState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isUploading = null,Object? progress = null,Object? uploadedUrl = freezed,Object? errorMessage = freezed,}) {
  return _then(_ImageUploadState(
isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,uploadedUrl: freezed == uploadedUrl ? _self.uploadedUrl : uploadedUrl // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
