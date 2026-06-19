// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remembered_user_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RememberedUserContext {

 String get email; String get serverId; bool get rememberMe;
/// Create a copy of RememberedUserContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RememberedUserContextCopyWith<RememberedUserContext> get copyWith => _$RememberedUserContextCopyWithImpl<RememberedUserContext>(this as RememberedUserContext, _$identity);

  /// Serializes this RememberedUserContext to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RememberedUserContext&&(identical(other.email, email) || other.email == email)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.rememberMe, rememberMe) || other.rememberMe == rememberMe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,serverId,rememberMe);

@override
String toString() {
  return 'RememberedUserContext(email: $email, serverId: $serverId, rememberMe: $rememberMe)';
}


}

/// @nodoc
abstract mixin class $RememberedUserContextCopyWith<$Res>  {
  factory $RememberedUserContextCopyWith(RememberedUserContext value, $Res Function(RememberedUserContext) _then) = _$RememberedUserContextCopyWithImpl;
@useResult
$Res call({
 String email, String serverId, bool rememberMe
});




}
/// @nodoc
class _$RememberedUserContextCopyWithImpl<$Res>
    implements $RememberedUserContextCopyWith<$Res> {
  _$RememberedUserContextCopyWithImpl(this._self, this._then);

  final RememberedUserContext _self;
  final $Res Function(RememberedUserContext) _then;

/// Create a copy of RememberedUserContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? serverId = null,Object? rememberMe = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,rememberMe: null == rememberMe ? _self.rememberMe : rememberMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RememberedUserContext].
extension RememberedUserContextPatterns on RememberedUserContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RememberedUserContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RememberedUserContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RememberedUserContext value)  $default,){
final _that = this;
switch (_that) {
case _RememberedUserContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RememberedUserContext value)?  $default,){
final _that = this;
switch (_that) {
case _RememberedUserContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String serverId,  bool rememberMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RememberedUserContext() when $default != null:
return $default(_that.email,_that.serverId,_that.rememberMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String serverId,  bool rememberMe)  $default,) {final _that = this;
switch (_that) {
case _RememberedUserContext():
return $default(_that.email,_that.serverId,_that.rememberMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String serverId,  bool rememberMe)?  $default,) {final _that = this;
switch (_that) {
case _RememberedUserContext() when $default != null:
return $default(_that.email,_that.serverId,_that.rememberMe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RememberedUserContext implements RememberedUserContext {
  const _RememberedUserContext({required this.email, required this.serverId, required this.rememberMe});
  factory _RememberedUserContext.fromJson(Map<String, dynamic> json) => _$RememberedUserContextFromJson(json);

@override final  String email;
@override final  String serverId;
@override final  bool rememberMe;

/// Create a copy of RememberedUserContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RememberedUserContextCopyWith<_RememberedUserContext> get copyWith => __$RememberedUserContextCopyWithImpl<_RememberedUserContext>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RememberedUserContextToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RememberedUserContext&&(identical(other.email, email) || other.email == email)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.rememberMe, rememberMe) || other.rememberMe == rememberMe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,serverId,rememberMe);

@override
String toString() {
  return 'RememberedUserContext(email: $email, serverId: $serverId, rememberMe: $rememberMe)';
}


}

/// @nodoc
abstract mixin class _$RememberedUserContextCopyWith<$Res> implements $RememberedUserContextCopyWith<$Res> {
  factory _$RememberedUserContextCopyWith(_RememberedUserContext value, $Res Function(_RememberedUserContext) _then) = __$RememberedUserContextCopyWithImpl;
@override @useResult
$Res call({
 String email, String serverId, bool rememberMe
});




}
/// @nodoc
class __$RememberedUserContextCopyWithImpl<$Res>
    implements _$RememberedUserContextCopyWith<$Res> {
  __$RememberedUserContextCopyWithImpl(this._self, this._then);

  final _RememberedUserContext _self;
  final $Res Function(_RememberedUserContext) _then;

/// Create a copy of RememberedUserContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? serverId = null,Object? rememberMe = null,}) {
  return _then(_RememberedUserContext(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,rememberMe: null == rememberMe ? _self.rememberMe : rememberMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
