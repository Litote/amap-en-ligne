// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceToken {

@JsonKey(name: 'device_token_id') String get deviceTokenId;@JsonKey(name: 'recipient_scope') String get recipientScope; DevicePlatform get platform; String get token;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'last_seen_at') String get lastSeenAt;
/// Create a copy of DeviceToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceTokenCopyWith<DeviceToken> get copyWith => _$DeviceTokenCopyWithImpl<DeviceToken>(this as DeviceToken, _$identity);

  /// Serializes this DeviceToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceToken&&(identical(other.deviceTokenId, deviceTokenId) || other.deviceTokenId == deviceTokenId)&&(identical(other.recipientScope, recipientScope) || other.recipientScope == recipientScope)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.token, token) || other.token == token)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceTokenId,recipientScope,platform,token,createdAt,lastSeenAt);

@override
String toString() {
  return 'DeviceToken(deviceTokenId: $deviceTokenId, recipientScope: $recipientScope, platform: $platform, token: $token, createdAt: $createdAt, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class $DeviceTokenCopyWith<$Res>  {
  factory $DeviceTokenCopyWith(DeviceToken value, $Res Function(DeviceToken) _then) = _$DeviceTokenCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'device_token_id') String deviceTokenId,@JsonKey(name: 'recipient_scope') String recipientScope, DevicePlatform platform, String token,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'last_seen_at') String lastSeenAt
});




}
/// @nodoc
class _$DeviceTokenCopyWithImpl<$Res>
    implements $DeviceTokenCopyWith<$Res> {
  _$DeviceTokenCopyWithImpl(this._self, this._then);

  final DeviceToken _self;
  final $Res Function(DeviceToken) _then;

/// Create a copy of DeviceToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceTokenId = null,Object? recipientScope = null,Object? platform = null,Object? token = null,Object? createdAt = null,Object? lastSeenAt = null,}) {
  return _then(_self.copyWith(
deviceTokenId: null == deviceTokenId ? _self.deviceTokenId : deviceTokenId // ignore: cast_nullable_to_non_nullable
as String,recipientScope: null == recipientScope ? _self.recipientScope : recipientScope // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as DevicePlatform,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceToken].
extension DeviceTokenPatterns on DeviceToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceToken value)  $default,){
final _that = this;
switch (_that) {
case _DeviceToken():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceToken value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_token_id')  String deviceTokenId, @JsonKey(name: 'recipient_scope')  String recipientScope,  DevicePlatform platform,  String token, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'last_seen_at')  String lastSeenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceToken() when $default != null:
return $default(_that.deviceTokenId,_that.recipientScope,_that.platform,_that.token,_that.createdAt,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_token_id')  String deviceTokenId, @JsonKey(name: 'recipient_scope')  String recipientScope,  DevicePlatform platform,  String token, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'last_seen_at')  String lastSeenAt)  $default,) {final _that = this;
switch (_that) {
case _DeviceToken():
return $default(_that.deviceTokenId,_that.recipientScope,_that.platform,_that.token,_that.createdAt,_that.lastSeenAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'device_token_id')  String deviceTokenId, @JsonKey(name: 'recipient_scope')  String recipientScope,  DevicePlatform platform,  String token, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'last_seen_at')  String lastSeenAt)?  $default,) {final _that = this;
switch (_that) {
case _DeviceToken() when $default != null:
return $default(_that.deviceTokenId,_that.recipientScope,_that.platform,_that.token,_that.createdAt,_that.lastSeenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceToken implements DeviceToken {
  const _DeviceToken({@JsonKey(name: 'device_token_id') required this.deviceTokenId, @JsonKey(name: 'recipient_scope') required this.recipientScope, required this.platform, required this.token, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'last_seen_at') required this.lastSeenAt});
  factory _DeviceToken.fromJson(Map<String, dynamic> json) => _$DeviceTokenFromJson(json);

@override@JsonKey(name: 'device_token_id') final  String deviceTokenId;
@override@JsonKey(name: 'recipient_scope') final  String recipientScope;
@override final  DevicePlatform platform;
@override final  String token;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'last_seen_at') final  String lastSeenAt;

/// Create a copy of DeviceToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceTokenCopyWith<_DeviceToken> get copyWith => __$DeviceTokenCopyWithImpl<_DeviceToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceTokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceToken&&(identical(other.deviceTokenId, deviceTokenId) || other.deviceTokenId == deviceTokenId)&&(identical(other.recipientScope, recipientScope) || other.recipientScope == recipientScope)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.token, token) || other.token == token)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceTokenId,recipientScope,platform,token,createdAt,lastSeenAt);

@override
String toString() {
  return 'DeviceToken(deviceTokenId: $deviceTokenId, recipientScope: $recipientScope, platform: $platform, token: $token, createdAt: $createdAt, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class _$DeviceTokenCopyWith<$Res> implements $DeviceTokenCopyWith<$Res> {
  factory _$DeviceTokenCopyWith(_DeviceToken value, $Res Function(_DeviceToken) _then) = __$DeviceTokenCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'device_token_id') String deviceTokenId,@JsonKey(name: 'recipient_scope') String recipientScope, DevicePlatform platform, String token,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'last_seen_at') String lastSeenAt
});




}
/// @nodoc
class __$DeviceTokenCopyWithImpl<$Res>
    implements _$DeviceTokenCopyWith<$Res> {
  __$DeviceTokenCopyWithImpl(this._self, this._then);

  final _DeviceToken _self;
  final $Res Function(_DeviceToken) _then;

/// Create a copy of DeviceToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceTokenId = null,Object? recipientScope = null,Object? platform = null,Object? token = null,Object? createdAt = null,Object? lastSeenAt = null,}) {
  return _then(_DeviceToken(
deviceTokenId: null == deviceTokenId ? _self.deviceTokenId : deviceTokenId // ignore: cast_nullable_to_non_nullable
as String,recipientScope: null == recipientScope ? _self.recipientScope : recipientScope // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as DevicePlatform,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
