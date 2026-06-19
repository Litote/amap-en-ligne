// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthStarted value)?  started,TResult Function( AuthSessionChanged value)?  sessionChanged,TResult Function( AuthOrganizationIdChanged value)?  organizationIdChanged,TResult Function( AuthMemberNameUpdated value)?  memberNameUpdated,TResult Function( AuthMemberRolesUpdated value)?  memberRolesUpdated,TResult Function( AuthLoginSubmitted value)?  loginSubmitted,TResult Function( AuthLogoutRequested value)?  logoutRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthStarted() when started != null:
return started(_that);case AuthSessionChanged() when sessionChanged != null:
return sessionChanged(_that);case AuthOrganizationIdChanged() when organizationIdChanged != null:
return organizationIdChanged(_that);case AuthMemberNameUpdated() when memberNameUpdated != null:
return memberNameUpdated(_that);case AuthMemberRolesUpdated() when memberRolesUpdated != null:
return memberRolesUpdated(_that);case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that);case AuthLogoutRequested() when logoutRequested != null:
return logoutRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthStarted value)  started,required TResult Function( AuthSessionChanged value)  sessionChanged,required TResult Function( AuthOrganizationIdChanged value)  organizationIdChanged,required TResult Function( AuthMemberNameUpdated value)  memberNameUpdated,required TResult Function( AuthMemberRolesUpdated value)  memberRolesUpdated,required TResult Function( AuthLoginSubmitted value)  loginSubmitted,required TResult Function( AuthLogoutRequested value)  logoutRequested,}){
final _that = this;
switch (_that) {
case AuthStarted():
return started(_that);case AuthSessionChanged():
return sessionChanged(_that);case AuthOrganizationIdChanged():
return organizationIdChanged(_that);case AuthMemberNameUpdated():
return memberNameUpdated(_that);case AuthMemberRolesUpdated():
return memberRolesUpdated(_that);case AuthLoginSubmitted():
return loginSubmitted(_that);case AuthLogoutRequested():
return logoutRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthStarted value)?  started,TResult? Function( AuthSessionChanged value)?  sessionChanged,TResult? Function( AuthOrganizationIdChanged value)?  organizationIdChanged,TResult? Function( AuthMemberNameUpdated value)?  memberNameUpdated,TResult? Function( AuthMemberRolesUpdated value)?  memberRolesUpdated,TResult? Function( AuthLoginSubmitted value)?  loginSubmitted,TResult? Function( AuthLogoutRequested value)?  logoutRequested,}){
final _that = this;
switch (_that) {
case AuthStarted() when started != null:
return started(_that);case AuthSessionChanged() when sessionChanged != null:
return sessionChanged(_that);case AuthOrganizationIdChanged() when organizationIdChanged != null:
return organizationIdChanged(_that);case AuthMemberNameUpdated() when memberNameUpdated != null:
return memberNameUpdated(_that);case AuthMemberRolesUpdated() when memberRolesUpdated != null:
return memberRolesUpdated(_that);case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that);case AuthLogoutRequested() when logoutRequested != null:
return logoutRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( AuthState session)?  sessionChanged,TResult Function( String? organizationId)?  organizationIdChanged,TResult Function( String? firstName,  String? lastName)?  memberNameUpdated,TResult Function( Set<Role> roles)?  memberRolesUpdated,TResult Function( String email,  String password,  bool rememberMe)?  loginSubmitted,TResult Function()?  logoutRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthStarted() when started != null:
return started();case AuthSessionChanged() when sessionChanged != null:
return sessionChanged(_that.session);case AuthOrganizationIdChanged() when organizationIdChanged != null:
return organizationIdChanged(_that.organizationId);case AuthMemberNameUpdated() when memberNameUpdated != null:
return memberNameUpdated(_that.firstName,_that.lastName);case AuthMemberRolesUpdated() when memberRolesUpdated != null:
return memberRolesUpdated(_that.roles);case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that.email,_that.password,_that.rememberMe);case AuthLogoutRequested() when logoutRequested != null:
return logoutRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( AuthState session)  sessionChanged,required TResult Function( String? organizationId)  organizationIdChanged,required TResult Function( String? firstName,  String? lastName)  memberNameUpdated,required TResult Function( Set<Role> roles)  memberRolesUpdated,required TResult Function( String email,  String password,  bool rememberMe)  loginSubmitted,required TResult Function()  logoutRequested,}) {final _that = this;
switch (_that) {
case AuthStarted():
return started();case AuthSessionChanged():
return sessionChanged(_that.session);case AuthOrganizationIdChanged():
return organizationIdChanged(_that.organizationId);case AuthMemberNameUpdated():
return memberNameUpdated(_that.firstName,_that.lastName);case AuthMemberRolesUpdated():
return memberRolesUpdated(_that.roles);case AuthLoginSubmitted():
return loginSubmitted(_that.email,_that.password,_that.rememberMe);case AuthLogoutRequested():
return logoutRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( AuthState session)?  sessionChanged,TResult? Function( String? organizationId)?  organizationIdChanged,TResult? Function( String? firstName,  String? lastName)?  memberNameUpdated,TResult? Function( Set<Role> roles)?  memberRolesUpdated,TResult? Function( String email,  String password,  bool rememberMe)?  loginSubmitted,TResult? Function()?  logoutRequested,}) {final _that = this;
switch (_that) {
case AuthStarted() when started != null:
return started();case AuthSessionChanged() when sessionChanged != null:
return sessionChanged(_that.session);case AuthOrganizationIdChanged() when organizationIdChanged != null:
return organizationIdChanged(_that.organizationId);case AuthMemberNameUpdated() when memberNameUpdated != null:
return memberNameUpdated(_that.firstName,_that.lastName);case AuthMemberRolesUpdated() when memberRolesUpdated != null:
return memberRolesUpdated(_that.roles);case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that.email,_that.password,_that.rememberMe);case AuthLogoutRequested() when logoutRequested != null:
return logoutRequested();case _:
  return null;

}
}

}

/// @nodoc


class AuthStarted implements AuthEvent {
  const AuthStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.started()';
}


}




/// @nodoc


class AuthSessionChanged implements AuthEvent {
  const AuthSessionChanged(this.session);
  

 final  AuthState session;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionChangedCopyWith<AuthSessionChanged> get copyWith => _$AuthSessionChangedCopyWithImpl<AuthSessionChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSessionChanged&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'AuthEvent.sessionChanged(session: $session)';
}


}

/// @nodoc
abstract mixin class $AuthSessionChangedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthSessionChangedCopyWith(AuthSessionChanged value, $Res Function(AuthSessionChanged) _then) = _$AuthSessionChangedCopyWithImpl;
@useResult
$Res call({
 AuthState session
});


$AuthStateCopyWith<$Res> get session;

}
/// @nodoc
class _$AuthSessionChangedCopyWithImpl<$Res>
    implements $AuthSessionChangedCopyWith<$Res> {
  _$AuthSessionChangedCopyWithImpl(this._self, this._then);

  final AuthSessionChanged _self;
  final $Res Function(AuthSessionChanged) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(AuthSessionChanged(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as AuthState,
  ));
}

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthStateCopyWith<$Res> get session {
  
  return $AuthStateCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class AuthOrganizationIdChanged implements AuthEvent {
  const AuthOrganizationIdChanged(this.organizationId);
  

 final  String? organizationId;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthOrganizationIdChangedCopyWith<AuthOrganizationIdChanged> get copyWith => _$AuthOrganizationIdChangedCopyWithImpl<AuthOrganizationIdChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthOrganizationIdChanged&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId);

@override
String toString() {
  return 'AuthEvent.organizationIdChanged(organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class $AuthOrganizationIdChangedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthOrganizationIdChangedCopyWith(AuthOrganizationIdChanged value, $Res Function(AuthOrganizationIdChanged) _then) = _$AuthOrganizationIdChangedCopyWithImpl;
@useResult
$Res call({
 String? organizationId
});




}
/// @nodoc
class _$AuthOrganizationIdChangedCopyWithImpl<$Res>
    implements $AuthOrganizationIdChangedCopyWith<$Res> {
  _$AuthOrganizationIdChangedCopyWithImpl(this._self, this._then);

  final AuthOrganizationIdChanged _self;
  final $Res Function(AuthOrganizationIdChanged) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationId = freezed,}) {
  return _then(AuthOrganizationIdChanged(
freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AuthMemberNameUpdated implements AuthEvent {
  const AuthMemberNameUpdated(this.firstName, this.lastName);
  

 final  String? firstName;
 final  String? lastName;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthMemberNameUpdatedCopyWith<AuthMemberNameUpdated> get copyWith => _$AuthMemberNameUpdatedCopyWithImpl<AuthMemberNameUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthMemberNameUpdated&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName));
}


@override
int get hashCode => Object.hash(runtimeType,firstName,lastName);

@override
String toString() {
  return 'AuthEvent.memberNameUpdated(firstName: $firstName, lastName: $lastName)';
}


}

/// @nodoc
abstract mixin class $AuthMemberNameUpdatedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthMemberNameUpdatedCopyWith(AuthMemberNameUpdated value, $Res Function(AuthMemberNameUpdated) _then) = _$AuthMemberNameUpdatedCopyWithImpl;
@useResult
$Res call({
 String? firstName, String? lastName
});




}
/// @nodoc
class _$AuthMemberNameUpdatedCopyWithImpl<$Res>
    implements $AuthMemberNameUpdatedCopyWith<$Res> {
  _$AuthMemberNameUpdatedCopyWithImpl(this._self, this._then);

  final AuthMemberNameUpdated _self;
  final $Res Function(AuthMemberNameUpdated) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? firstName = freezed,Object? lastName = freezed,}) {
  return _then(AuthMemberNameUpdated(
freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AuthMemberRolesUpdated implements AuthEvent {
  const AuthMemberRolesUpdated(final  Set<Role> roles): _roles = roles;
  

 final  Set<Role> _roles;
 Set<Role> get roles {
  if (_roles is EqualUnmodifiableSetView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_roles);
}


/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthMemberRolesUpdatedCopyWith<AuthMemberRolesUpdated> get copyWith => _$AuthMemberRolesUpdatedCopyWithImpl<AuthMemberRolesUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthMemberRolesUpdated&&const DeepCollectionEquality().equals(other._roles, _roles));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_roles));

@override
String toString() {
  return 'AuthEvent.memberRolesUpdated(roles: $roles)';
}


}

/// @nodoc
abstract mixin class $AuthMemberRolesUpdatedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthMemberRolesUpdatedCopyWith(AuthMemberRolesUpdated value, $Res Function(AuthMemberRolesUpdated) _then) = _$AuthMemberRolesUpdatedCopyWithImpl;
@useResult
$Res call({
 Set<Role> roles
});




}
/// @nodoc
class _$AuthMemberRolesUpdatedCopyWithImpl<$Res>
    implements $AuthMemberRolesUpdatedCopyWith<$Res> {
  _$AuthMemberRolesUpdatedCopyWithImpl(this._self, this._then);

  final AuthMemberRolesUpdated _self;
  final $Res Function(AuthMemberRolesUpdated) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? roles = null,}) {
  return _then(AuthMemberRolesUpdated(
null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Set<Role>,
  ));
}


}

/// @nodoc


class AuthLoginSubmitted implements AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password, required this.rememberMe});
  

 final  String email;
 final  String password;
 final  bool rememberMe;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthLoginSubmittedCopyWith<AuthLoginSubmitted> get copyWith => _$AuthLoginSubmittedCopyWithImpl<AuthLoginSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLoginSubmitted&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.rememberMe, rememberMe) || other.rememberMe == rememberMe));
}


@override
int get hashCode => Object.hash(runtimeType,email,password,rememberMe);

@override
String toString() {
  return 'AuthEvent.loginSubmitted(email: $email, password: $password, rememberMe: $rememberMe)';
}


}

/// @nodoc
abstract mixin class $AuthLoginSubmittedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthLoginSubmittedCopyWith(AuthLoginSubmitted value, $Res Function(AuthLoginSubmitted) _then) = _$AuthLoginSubmittedCopyWithImpl;
@useResult
$Res call({
 String email, String password, bool rememberMe
});




}
/// @nodoc
class _$AuthLoginSubmittedCopyWithImpl<$Res>
    implements $AuthLoginSubmittedCopyWith<$Res> {
  _$AuthLoginSubmittedCopyWithImpl(this._self, this._then);

  final AuthLoginSubmitted _self;
  final $Res Function(AuthLoginSubmitted) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,Object? rememberMe = null,}) {
  return _then(AuthLoginSubmitted(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,rememberMe: null == rememberMe ? _self.rememberMe : rememberMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class AuthLogoutRequested implements AuthEvent {
  const AuthLogoutRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLogoutRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.logoutRequested()';
}


}




// dart format on
