// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForgotPasswordEvent {

 String get email;
/// Create a copy of ForgotPasswordEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordEventCopyWith<ForgotPasswordEvent> get copyWith => _$ForgotPasswordEventCopyWithImpl<ForgotPasswordEvent>(this as ForgotPasswordEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordEvent&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'ForgotPasswordEvent(email: $email)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordEventCopyWith<$Res>  {
  factory $ForgotPasswordEventCopyWith(ForgotPasswordEvent value, $Res Function(ForgotPasswordEvent) _then) = _$ForgotPasswordEventCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$ForgotPasswordEventCopyWithImpl<$Res>
    implements $ForgotPasswordEventCopyWith<$Res> {
  _$ForgotPasswordEventCopyWithImpl(this._self, this._then);

  final ForgotPasswordEvent _self;
  final $Res Function(ForgotPasswordEvent) _then;

/// Create a copy of ForgotPasswordEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ForgotPasswordEvent].
extension ForgotPasswordEventPatterns on ForgotPasswordEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ForgotPasswordResetRequested value)?  resetRequested,TResult Function( ForgotPasswordConfirmRequested value)?  confirmRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ForgotPasswordResetRequested() when resetRequested != null:
return resetRequested(_that);case ForgotPasswordConfirmRequested() when confirmRequested != null:
return confirmRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ForgotPasswordResetRequested value)  resetRequested,required TResult Function( ForgotPasswordConfirmRequested value)  confirmRequested,}){
final _that = this;
switch (_that) {
case ForgotPasswordResetRequested():
return resetRequested(_that);case ForgotPasswordConfirmRequested():
return confirmRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ForgotPasswordResetRequested value)?  resetRequested,TResult? Function( ForgotPasswordConfirmRequested value)?  confirmRequested,}){
final _that = this;
switch (_that) {
case ForgotPasswordResetRequested() when resetRequested != null:
return resetRequested(_that);case ForgotPasswordConfirmRequested() when confirmRequested != null:
return confirmRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String email,  String? redirectTo)?  resetRequested,TResult Function( String email,  String token,  String newPassword)?  confirmRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ForgotPasswordResetRequested() when resetRequested != null:
return resetRequested(_that.email,_that.redirectTo);case ForgotPasswordConfirmRequested() when confirmRequested != null:
return confirmRequested(_that.email,_that.token,_that.newPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String email,  String? redirectTo)  resetRequested,required TResult Function( String email,  String token,  String newPassword)  confirmRequested,}) {final _that = this;
switch (_that) {
case ForgotPasswordResetRequested():
return resetRequested(_that.email,_that.redirectTo);case ForgotPasswordConfirmRequested():
return confirmRequested(_that.email,_that.token,_that.newPassword);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String email,  String? redirectTo)?  resetRequested,TResult? Function( String email,  String token,  String newPassword)?  confirmRequested,}) {final _that = this;
switch (_that) {
case ForgotPasswordResetRequested() when resetRequested != null:
return resetRequested(_that.email,_that.redirectTo);case ForgotPasswordConfirmRequested() when confirmRequested != null:
return confirmRequested(_that.email,_that.token,_that.newPassword);case _:
  return null;

}
}

}

/// @nodoc


class ForgotPasswordResetRequested implements ForgotPasswordEvent {
  const ForgotPasswordResetRequested({required this.email, this.redirectTo});
  

@override final  String email;
 final  String? redirectTo;

/// Create a copy of ForgotPasswordEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordResetRequestedCopyWith<ForgotPasswordResetRequested> get copyWith => _$ForgotPasswordResetRequestedCopyWithImpl<ForgotPasswordResetRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordResetRequested&&(identical(other.email, email) || other.email == email)&&(identical(other.redirectTo, redirectTo) || other.redirectTo == redirectTo));
}


@override
int get hashCode => Object.hash(runtimeType,email,redirectTo);

@override
String toString() {
  return 'ForgotPasswordEvent.resetRequested(email: $email, redirectTo: $redirectTo)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordResetRequestedCopyWith<$Res> implements $ForgotPasswordEventCopyWith<$Res> {
  factory $ForgotPasswordResetRequestedCopyWith(ForgotPasswordResetRequested value, $Res Function(ForgotPasswordResetRequested) _then) = _$ForgotPasswordResetRequestedCopyWithImpl;
@override @useResult
$Res call({
 String email, String? redirectTo
});




}
/// @nodoc
class _$ForgotPasswordResetRequestedCopyWithImpl<$Res>
    implements $ForgotPasswordResetRequestedCopyWith<$Res> {
  _$ForgotPasswordResetRequestedCopyWithImpl(this._self, this._then);

  final ForgotPasswordResetRequested _self;
  final $Res Function(ForgotPasswordResetRequested) _then;

/// Create a copy of ForgotPasswordEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? redirectTo = freezed,}) {
  return _then(ForgotPasswordResetRequested(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,redirectTo: freezed == redirectTo ? _self.redirectTo : redirectTo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ForgotPasswordConfirmRequested implements ForgotPasswordEvent {
  const ForgotPasswordConfirmRequested({required this.email, required this.token, required this.newPassword});
  

@override final  String email;
 final  String token;
 final  String newPassword;

/// Create a copy of ForgotPasswordEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordConfirmRequestedCopyWith<ForgotPasswordConfirmRequested> get copyWith => _$ForgotPasswordConfirmRequestedCopyWithImpl<ForgotPasswordConfirmRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordConfirmRequested&&(identical(other.email, email) || other.email == email)&&(identical(other.token, token) || other.token == token)&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword));
}


@override
int get hashCode => Object.hash(runtimeType,email,token,newPassword);

@override
String toString() {
  return 'ForgotPasswordEvent.confirmRequested(email: $email, token: $token, newPassword: $newPassword)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordConfirmRequestedCopyWith<$Res> implements $ForgotPasswordEventCopyWith<$Res> {
  factory $ForgotPasswordConfirmRequestedCopyWith(ForgotPasswordConfirmRequested value, $Res Function(ForgotPasswordConfirmRequested) _then) = _$ForgotPasswordConfirmRequestedCopyWithImpl;
@override @useResult
$Res call({
 String email, String token, String newPassword
});




}
/// @nodoc
class _$ForgotPasswordConfirmRequestedCopyWithImpl<$Res>
    implements $ForgotPasswordConfirmRequestedCopyWith<$Res> {
  _$ForgotPasswordConfirmRequestedCopyWithImpl(this._self, this._then);

  final ForgotPasswordConfirmRequested _self;
  final $Res Function(ForgotPasswordConfirmRequested) _then;

/// Create a copy of ForgotPasswordEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? token = null,Object? newPassword = null,}) {
  return _then(ForgotPasswordConfirmRequested(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
