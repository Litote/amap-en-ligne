// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_view_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForgotPasswordViewState {

 bool get codeSent; bool get submitting; bool get success; String? get email; AuthError? get lastError;
/// Create a copy of ForgotPasswordViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordViewStateCopyWith<ForgotPasswordViewState> get copyWith => _$ForgotPasswordViewStateCopyWithImpl<ForgotPasswordViewState>(this as ForgotPasswordViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordViewState&&(identical(other.codeSent, codeSent) || other.codeSent == codeSent)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.success, success) || other.success == success)&&(identical(other.email, email) || other.email == email)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode => Object.hash(runtimeType,codeSent,submitting,success,email,lastError);

@override
String toString() {
  return 'ForgotPasswordViewState(codeSent: $codeSent, submitting: $submitting, success: $success, email: $email, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordViewStateCopyWith<$Res>  {
  factory $ForgotPasswordViewStateCopyWith(ForgotPasswordViewState value, $Res Function(ForgotPasswordViewState) _then) = _$ForgotPasswordViewStateCopyWithImpl;
@useResult
$Res call({
 bool codeSent, bool submitting, bool success, String? email, AuthError? lastError
});




}
/// @nodoc
class _$ForgotPasswordViewStateCopyWithImpl<$Res>
    implements $ForgotPasswordViewStateCopyWith<$Res> {
  _$ForgotPasswordViewStateCopyWithImpl(this._self, this._then);

  final ForgotPasswordViewState _self;
  final $Res Function(ForgotPasswordViewState) _then;

/// Create a copy of ForgotPasswordViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? codeSent = null,Object? submitting = null,Object? success = null,Object? email = freezed,Object? lastError = freezed,}) {
  return _then(_self.copyWith(
codeSent: null == codeSent ? _self.codeSent : codeSent // ignore: cast_nullable_to_non_nullable
as bool,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as AuthError?,
  ));
}

}


/// Adds pattern-matching-related methods to [ForgotPasswordViewState].
extension ForgotPasswordViewStatePatterns on ForgotPasswordViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ForgotPasswordViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ForgotPasswordViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ForgotPasswordViewState value)  $default,){
final _that = this;
switch (_that) {
case _ForgotPasswordViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ForgotPasswordViewState value)?  $default,){
final _that = this;
switch (_that) {
case _ForgotPasswordViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool codeSent,  bool submitting,  bool success,  String? email,  AuthError? lastError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ForgotPasswordViewState() when $default != null:
return $default(_that.codeSent,_that.submitting,_that.success,_that.email,_that.lastError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool codeSent,  bool submitting,  bool success,  String? email,  AuthError? lastError)  $default,) {final _that = this;
switch (_that) {
case _ForgotPasswordViewState():
return $default(_that.codeSent,_that.submitting,_that.success,_that.email,_that.lastError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool codeSent,  bool submitting,  bool success,  String? email,  AuthError? lastError)?  $default,) {final _that = this;
switch (_that) {
case _ForgotPasswordViewState() when $default != null:
return $default(_that.codeSent,_that.submitting,_that.success,_that.email,_that.lastError);case _:
  return null;

}
}

}

/// @nodoc


class _ForgotPasswordViewState implements ForgotPasswordViewState {
  const _ForgotPasswordViewState({this.codeSent = false, this.submitting = false, this.success = false, this.email, this.lastError});
  

@override@JsonKey() final  bool codeSent;
@override@JsonKey() final  bool submitting;
@override@JsonKey() final  bool success;
@override final  String? email;
@override final  AuthError? lastError;

/// Create a copy of ForgotPasswordViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ForgotPasswordViewStateCopyWith<_ForgotPasswordViewState> get copyWith => __$ForgotPasswordViewStateCopyWithImpl<_ForgotPasswordViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ForgotPasswordViewState&&(identical(other.codeSent, codeSent) || other.codeSent == codeSent)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.success, success) || other.success == success)&&(identical(other.email, email) || other.email == email)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode => Object.hash(runtimeType,codeSent,submitting,success,email,lastError);

@override
String toString() {
  return 'ForgotPasswordViewState(codeSent: $codeSent, submitting: $submitting, success: $success, email: $email, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class _$ForgotPasswordViewStateCopyWith<$Res> implements $ForgotPasswordViewStateCopyWith<$Res> {
  factory _$ForgotPasswordViewStateCopyWith(_ForgotPasswordViewState value, $Res Function(_ForgotPasswordViewState) _then) = __$ForgotPasswordViewStateCopyWithImpl;
@override @useResult
$Res call({
 bool codeSent, bool submitting, bool success, String? email, AuthError? lastError
});




}
/// @nodoc
class __$ForgotPasswordViewStateCopyWithImpl<$Res>
    implements _$ForgotPasswordViewStateCopyWith<$Res> {
  __$ForgotPasswordViewStateCopyWithImpl(this._self, this._then);

  final _ForgotPasswordViewState _self;
  final $Res Function(_ForgotPasswordViewState) _then;

/// Create a copy of ForgotPasswordViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? codeSent = null,Object? submitting = null,Object? success = null,Object? email = freezed,Object? lastError = freezed,}) {
  return _then(_ForgotPasswordViewState(
codeSent: null == codeSent ? _self.codeSent : codeSent // ignore: cast_nullable_to_non_nullable
as bool,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as AuthError?,
  ));
}


}

// dart format on
