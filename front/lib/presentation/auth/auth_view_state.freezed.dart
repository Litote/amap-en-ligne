// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_view_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthViewState {

 bool get initializing; bool get submitting; bool get logoutRequested; String? get producerId; String? get producerAccountId; String? get organizationId; bool get isAdmin; UserRole get role; Set<Role> get memberRoles; AuthError? get lastError;
/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthViewStateCopyWith<AuthViewState> get copyWith => _$AuthViewStateCopyWithImpl<AuthViewState>(this as AuthViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthViewState&&(identical(other.initializing, initializing) || other.initializing == initializing)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.logoutRequested, logoutRequested) || other.logoutRequested == logoutRequested)&&(identical(other.producerId, producerId) || other.producerId == producerId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.memberRoles, memberRoles)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode => Object.hash(runtimeType,initializing,submitting,logoutRequested,producerId,producerAccountId,organizationId,isAdmin,role,const DeepCollectionEquality().hash(memberRoles),lastError);

@override
String toString() {
  return 'AuthViewState(initializing: $initializing, submitting: $submitting, logoutRequested: $logoutRequested, producerId: $producerId, producerAccountId: $producerAccountId, organizationId: $organizationId, isAdmin: $isAdmin, role: $role, memberRoles: $memberRoles, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class $AuthViewStateCopyWith<$Res>  {
  factory $AuthViewStateCopyWith(AuthViewState value, $Res Function(AuthViewState) _then) = _$AuthViewStateCopyWithImpl;
@useResult
$Res call({
 bool initializing, bool submitting, bool logoutRequested, String? producerId, String? producerAccountId, String? organizationId, bool isAdmin, UserRole role, Set<Role> memberRoles, AuthError? lastError
});




}
/// @nodoc
class _$AuthViewStateCopyWithImpl<$Res>
    implements $AuthViewStateCopyWith<$Res> {
  _$AuthViewStateCopyWithImpl(this._self, this._then);

  final AuthViewState _self;
  final $Res Function(AuthViewState) _then;

/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? initializing = null,Object? submitting = null,Object? logoutRequested = null,Object? producerId = freezed,Object? producerAccountId = freezed,Object? organizationId = freezed,Object? isAdmin = null,Object? role = null,Object? memberRoles = null,Object? lastError = freezed,}) {
  return _then(_self.copyWith(
initializing: null == initializing ? _self.initializing : initializing // ignore: cast_nullable_to_non_nullable
as bool,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,logoutRequested: null == logoutRequested ? _self.logoutRequested : logoutRequested // ignore: cast_nullable_to_non_nullable
as bool,producerId: freezed == producerId ? _self.producerId : producerId // ignore: cast_nullable_to_non_nullable
as String?,producerAccountId: freezed == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String?,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,memberRoles: null == memberRoles ? _self.memberRoles : memberRoles // ignore: cast_nullable_to_non_nullable
as Set<Role>,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as AuthError?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthViewState].
extension AuthViewStatePatterns on AuthViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthViewState value)  $default,){
final _that = this;
switch (_that) {
case _AuthViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthViewState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool initializing,  bool submitting,  bool logoutRequested,  String? producerId,  String? producerAccountId,  String? organizationId,  bool isAdmin,  UserRole role,  Set<Role> memberRoles,  AuthError? lastError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthViewState() when $default != null:
return $default(_that.initializing,_that.submitting,_that.logoutRequested,_that.producerId,_that.producerAccountId,_that.organizationId,_that.isAdmin,_that.role,_that.memberRoles,_that.lastError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool initializing,  bool submitting,  bool logoutRequested,  String? producerId,  String? producerAccountId,  String? organizationId,  bool isAdmin,  UserRole role,  Set<Role> memberRoles,  AuthError? lastError)  $default,) {final _that = this;
switch (_that) {
case _AuthViewState():
return $default(_that.initializing,_that.submitting,_that.logoutRequested,_that.producerId,_that.producerAccountId,_that.organizationId,_that.isAdmin,_that.role,_that.memberRoles,_that.lastError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool initializing,  bool submitting,  bool logoutRequested,  String? producerId,  String? producerAccountId,  String? organizationId,  bool isAdmin,  UserRole role,  Set<Role> memberRoles,  AuthError? lastError)?  $default,) {final _that = this;
switch (_that) {
case _AuthViewState() when $default != null:
return $default(_that.initializing,_that.submitting,_that.logoutRequested,_that.producerId,_that.producerAccountId,_that.organizationId,_that.isAdmin,_that.role,_that.memberRoles,_that.lastError);case _:
  return null;

}
}

}

/// @nodoc


class _AuthViewState implements AuthViewState {
  const _AuthViewState({this.initializing = true, this.submitting = false, this.logoutRequested = false, this.producerId, this.producerAccountId, this.organizationId, this.isAdmin = false, this.role = UserRole.memberNoRole, final  Set<Role> memberRoles = const <Role>{}, this.lastError}): _memberRoles = memberRoles;
  

@override@JsonKey() final  bool initializing;
@override@JsonKey() final  bool submitting;
@override@JsonKey() final  bool logoutRequested;
@override final  String? producerId;
@override final  String? producerAccountId;
@override final  String? organizationId;
@override@JsonKey() final  bool isAdmin;
@override@JsonKey() final  UserRole role;
 final  Set<Role> _memberRoles;
@override@JsonKey() Set<Role> get memberRoles {
  if (_memberRoles is EqualUnmodifiableSetView) return _memberRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_memberRoles);
}

@override final  AuthError? lastError;

/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthViewStateCopyWith<_AuthViewState> get copyWith => __$AuthViewStateCopyWithImpl<_AuthViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthViewState&&(identical(other.initializing, initializing) || other.initializing == initializing)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.logoutRequested, logoutRequested) || other.logoutRequested == logoutRequested)&&(identical(other.producerId, producerId) || other.producerId == producerId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._memberRoles, _memberRoles)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode => Object.hash(runtimeType,initializing,submitting,logoutRequested,producerId,producerAccountId,organizationId,isAdmin,role,const DeepCollectionEquality().hash(_memberRoles),lastError);

@override
String toString() {
  return 'AuthViewState(initializing: $initializing, submitting: $submitting, logoutRequested: $logoutRequested, producerId: $producerId, producerAccountId: $producerAccountId, organizationId: $organizationId, isAdmin: $isAdmin, role: $role, memberRoles: $memberRoles, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class _$AuthViewStateCopyWith<$Res> implements $AuthViewStateCopyWith<$Res> {
  factory _$AuthViewStateCopyWith(_AuthViewState value, $Res Function(_AuthViewState) _then) = __$AuthViewStateCopyWithImpl;
@override @useResult
$Res call({
 bool initializing, bool submitting, bool logoutRequested, String? producerId, String? producerAccountId, String? organizationId, bool isAdmin, UserRole role, Set<Role> memberRoles, AuthError? lastError
});




}
/// @nodoc
class __$AuthViewStateCopyWithImpl<$Res>
    implements _$AuthViewStateCopyWith<$Res> {
  __$AuthViewStateCopyWithImpl(this._self, this._then);

  final _AuthViewState _self;
  final $Res Function(_AuthViewState) _then;

/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? initializing = null,Object? submitting = null,Object? logoutRequested = null,Object? producerId = freezed,Object? producerAccountId = freezed,Object? organizationId = freezed,Object? isAdmin = null,Object? role = null,Object? memberRoles = null,Object? lastError = freezed,}) {
  return _then(_AuthViewState(
initializing: null == initializing ? _self.initializing : initializing // ignore: cast_nullable_to_non_nullable
as bool,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,logoutRequested: null == logoutRequested ? _self.logoutRequested : logoutRequested // ignore: cast_nullable_to_non_nullable
as bool,producerId: freezed == producerId ? _self.producerId : producerId // ignore: cast_nullable_to_non_nullable
as String?,producerAccountId: freezed == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String?,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,memberRoles: null == memberRoles ? _self._memberRoles : memberRoles // ignore: cast_nullable_to_non_nullable
as Set<Role>,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as AuthError?,
  ));
}


}

// dart format on
