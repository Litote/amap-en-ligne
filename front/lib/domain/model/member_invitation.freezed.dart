// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_invitation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberInvitation {

@JsonKey(name: 'invitation_id') String get invitationId;@JsonKey(name: 'organization_id') String get organizationId; String get email;@JsonKey(name: 'first_name') String get firstName;@JsonKey(name: 'last_name') String get lastName; Set<Role> get roles; InvitationStatus get status;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'expires_at') String get expiresAt;@JsonKey(name: 'resend_requested_at') String? get resendRequestedAt;@JsonKey(name: 'activated_at') String? get activatedAt;@JsonKey(name: 'custom_email_subject') String? get customEmailSubject;@JsonKey(name: 'custom_email_body') String? get customEmailBody;
/// Create a copy of MemberInvitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberInvitationCopyWith<MemberInvitation> get copyWith => _$MemberInvitationCopyWithImpl<MemberInvitation>(this as MemberInvitation, _$identity);

  /// Serializes this MemberInvitation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberInvitation&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resendRequestedAt, resendRequestedAt) || other.resendRequestedAt == resendRequestedAt)&&(identical(other.activatedAt, activatedAt) || other.activatedAt == activatedAt)&&(identical(other.customEmailSubject, customEmailSubject) || other.customEmailSubject == customEmailSubject)&&(identical(other.customEmailBody, customEmailBody) || other.customEmailBody == customEmailBody));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,invitationId,organizationId,email,firstName,lastName,const DeepCollectionEquality().hash(roles),status,createdAt,expiresAt,resendRequestedAt,activatedAt,customEmailSubject,customEmailBody);

@override
String toString() {
  return 'MemberInvitation(invitationId: $invitationId, organizationId: $organizationId, email: $email, firstName: $firstName, lastName: $lastName, roles: $roles, status: $status, createdAt: $createdAt, expiresAt: $expiresAt, resendRequestedAt: $resendRequestedAt, activatedAt: $activatedAt, customEmailSubject: $customEmailSubject, customEmailBody: $customEmailBody)';
}


}

/// @nodoc
abstract mixin class $MemberInvitationCopyWith<$Res>  {
  factory $MemberInvitationCopyWith(MemberInvitation value, $Res Function(MemberInvitation) _then) = _$MemberInvitationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'invitation_id') String invitationId,@JsonKey(name: 'organization_id') String organizationId, String email,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, Set<Role> roles, InvitationStatus status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'expires_at') String expiresAt,@JsonKey(name: 'resend_requested_at') String? resendRequestedAt,@JsonKey(name: 'activated_at') String? activatedAt,@JsonKey(name: 'custom_email_subject') String? customEmailSubject,@JsonKey(name: 'custom_email_body') String? customEmailBody
});




}
/// @nodoc
class _$MemberInvitationCopyWithImpl<$Res>
    implements $MemberInvitationCopyWith<$Res> {
  _$MemberInvitationCopyWithImpl(this._self, this._then);

  final MemberInvitation _self;
  final $Res Function(MemberInvitation) _then;

/// Create a copy of MemberInvitation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invitationId = null,Object? organizationId = null,Object? email = null,Object? firstName = null,Object? lastName = null,Object? roles = null,Object? status = null,Object? createdAt = null,Object? expiresAt = null,Object? resendRequestedAt = freezed,Object? activatedAt = freezed,Object? customEmailSubject = freezed,Object? customEmailBody = freezed,}) {
  return _then(_self.copyWith(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Set<Role>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvitationStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,resendRequestedAt: freezed == resendRequestedAt ? _self.resendRequestedAt : resendRequestedAt // ignore: cast_nullable_to_non_nullable
as String?,activatedAt: freezed == activatedAt ? _self.activatedAt : activatedAt // ignore: cast_nullable_to_non_nullable
as String?,customEmailSubject: freezed == customEmailSubject ? _self.customEmailSubject : customEmailSubject // ignore: cast_nullable_to_non_nullable
as String?,customEmailBody: freezed == customEmailBody ? _self.customEmailBody : customEmailBody // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberInvitation].
extension MemberInvitationPatterns on MemberInvitation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberInvitation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberInvitation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberInvitation value)  $default,){
final _that = this;
switch (_that) {
case _MemberInvitation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberInvitation value)?  $default,){
final _that = this;
switch (_that) {
case _MemberInvitation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'invitation_id')  String invitationId, @JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  Set<Role> roles,  InvitationStatus status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt, @JsonKey(name: 'activated_at')  String? activatedAt, @JsonKey(name: 'custom_email_subject')  String? customEmailSubject, @JsonKey(name: 'custom_email_body')  String? customEmailBody)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberInvitation() when $default != null:
return $default(_that.invitationId,_that.organizationId,_that.email,_that.firstName,_that.lastName,_that.roles,_that.status,_that.createdAt,_that.expiresAt,_that.resendRequestedAt,_that.activatedAt,_that.customEmailSubject,_that.customEmailBody);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'invitation_id')  String invitationId, @JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  Set<Role> roles,  InvitationStatus status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt, @JsonKey(name: 'activated_at')  String? activatedAt, @JsonKey(name: 'custom_email_subject')  String? customEmailSubject, @JsonKey(name: 'custom_email_body')  String? customEmailBody)  $default,) {final _that = this;
switch (_that) {
case _MemberInvitation():
return $default(_that.invitationId,_that.organizationId,_that.email,_that.firstName,_that.lastName,_that.roles,_that.status,_that.createdAt,_that.expiresAt,_that.resendRequestedAt,_that.activatedAt,_that.customEmailSubject,_that.customEmailBody);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'invitation_id')  String invitationId, @JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  Set<Role> roles,  InvitationStatus status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt, @JsonKey(name: 'activated_at')  String? activatedAt, @JsonKey(name: 'custom_email_subject')  String? customEmailSubject, @JsonKey(name: 'custom_email_body')  String? customEmailBody)?  $default,) {final _that = this;
switch (_that) {
case _MemberInvitation() when $default != null:
return $default(_that.invitationId,_that.organizationId,_that.email,_that.firstName,_that.lastName,_that.roles,_that.status,_that.createdAt,_that.expiresAt,_that.resendRequestedAt,_that.activatedAt,_that.customEmailSubject,_that.customEmailBody);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberInvitation implements MemberInvitation {
  const _MemberInvitation({@JsonKey(name: 'invitation_id') required this.invitationId, @JsonKey(name: 'organization_id') required this.organizationId, required this.email, @JsonKey(name: 'first_name') required this.firstName, @JsonKey(name: 'last_name') required this.lastName, required final  Set<Role> roles, required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'expires_at') required this.expiresAt, @JsonKey(name: 'resend_requested_at') this.resendRequestedAt, @JsonKey(name: 'activated_at') this.activatedAt, @JsonKey(name: 'custom_email_subject') this.customEmailSubject, @JsonKey(name: 'custom_email_body') this.customEmailBody}): _roles = roles;
  factory _MemberInvitation.fromJson(Map<String, dynamic> json) => _$MemberInvitationFromJson(json);

@override@JsonKey(name: 'invitation_id') final  String invitationId;
@override@JsonKey(name: 'organization_id') final  String organizationId;
@override final  String email;
@override@JsonKey(name: 'first_name') final  String firstName;
@override@JsonKey(name: 'last_name') final  String lastName;
 final  Set<Role> _roles;
@override Set<Role> get roles {
  if (_roles is EqualUnmodifiableSetView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_roles);
}

@override final  InvitationStatus status;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'expires_at') final  String expiresAt;
@override@JsonKey(name: 'resend_requested_at') final  String? resendRequestedAt;
@override@JsonKey(name: 'activated_at') final  String? activatedAt;
@override@JsonKey(name: 'custom_email_subject') final  String? customEmailSubject;
@override@JsonKey(name: 'custom_email_body') final  String? customEmailBody;

/// Create a copy of MemberInvitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberInvitationCopyWith<_MemberInvitation> get copyWith => __$MemberInvitationCopyWithImpl<_MemberInvitation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberInvitationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberInvitation&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resendRequestedAt, resendRequestedAt) || other.resendRequestedAt == resendRequestedAt)&&(identical(other.activatedAt, activatedAt) || other.activatedAt == activatedAt)&&(identical(other.customEmailSubject, customEmailSubject) || other.customEmailSubject == customEmailSubject)&&(identical(other.customEmailBody, customEmailBody) || other.customEmailBody == customEmailBody));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,invitationId,organizationId,email,firstName,lastName,const DeepCollectionEquality().hash(_roles),status,createdAt,expiresAt,resendRequestedAt,activatedAt,customEmailSubject,customEmailBody);

@override
String toString() {
  return 'MemberInvitation(invitationId: $invitationId, organizationId: $organizationId, email: $email, firstName: $firstName, lastName: $lastName, roles: $roles, status: $status, createdAt: $createdAt, expiresAt: $expiresAt, resendRequestedAt: $resendRequestedAt, activatedAt: $activatedAt, customEmailSubject: $customEmailSubject, customEmailBody: $customEmailBody)';
}


}

/// @nodoc
abstract mixin class _$MemberInvitationCopyWith<$Res> implements $MemberInvitationCopyWith<$Res> {
  factory _$MemberInvitationCopyWith(_MemberInvitation value, $Res Function(_MemberInvitation) _then) = __$MemberInvitationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'invitation_id') String invitationId,@JsonKey(name: 'organization_id') String organizationId, String email,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, Set<Role> roles, InvitationStatus status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'expires_at') String expiresAt,@JsonKey(name: 'resend_requested_at') String? resendRequestedAt,@JsonKey(name: 'activated_at') String? activatedAt,@JsonKey(name: 'custom_email_subject') String? customEmailSubject,@JsonKey(name: 'custom_email_body') String? customEmailBody
});




}
/// @nodoc
class __$MemberInvitationCopyWithImpl<$Res>
    implements _$MemberInvitationCopyWith<$Res> {
  __$MemberInvitationCopyWithImpl(this._self, this._then);

  final _MemberInvitation _self;
  final $Res Function(_MemberInvitation) _then;

/// Create a copy of MemberInvitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invitationId = null,Object? organizationId = null,Object? email = null,Object? firstName = null,Object? lastName = null,Object? roles = null,Object? status = null,Object? createdAt = null,Object? expiresAt = null,Object? resendRequestedAt = freezed,Object? activatedAt = freezed,Object? customEmailSubject = freezed,Object? customEmailBody = freezed,}) {
  return _then(_MemberInvitation(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Set<Role>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvitationStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,resendRequestedAt: freezed == resendRequestedAt ? _self.resendRequestedAt : resendRequestedAt // ignore: cast_nullable_to_non_nullable
as String?,activatedAt: freezed == activatedAt ? _self.activatedAt : activatedAt // ignore: cast_nullable_to_non_nullable
as String?,customEmailSubject: freezed == customEmailSubject ? _self.customEmailSubject : customEmailSubject // ignore: cast_nullable_to_non_nullable
as String?,customEmailBody: freezed == customEmailBody ? _self.customEmailBody : customEmailBody // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
