// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'owner_invitation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OwnerInvitation {

@JsonKey(name: 'invitation_id') String get invitationId;@JsonKey(name: 'first_name') String get firstName;@JsonKey(name: 'last_name') String get lastName; String get email; InvitationStatus get status;@JsonKey(name: 'submitted_at') String get submittedAt;@JsonKey(name: 'resend_requested_at') String? get resendRequestedAt;@JsonKey(name: 'activated_at') String? get activatedAt;
/// Create a copy of OwnerInvitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnerInvitationCopyWith<OwnerInvitation> get copyWith => _$OwnerInvitationCopyWithImpl<OwnerInvitation>(this as OwnerInvitation, _$identity);

  /// Serializes this OwnerInvitation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnerInvitation&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.resendRequestedAt, resendRequestedAt) || other.resendRequestedAt == resendRequestedAt)&&(identical(other.activatedAt, activatedAt) || other.activatedAt == activatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,invitationId,firstName,lastName,email,status,submittedAt,resendRequestedAt,activatedAt);

@override
String toString() {
  return 'OwnerInvitation(invitationId: $invitationId, firstName: $firstName, lastName: $lastName, email: $email, status: $status, submittedAt: $submittedAt, resendRequestedAt: $resendRequestedAt, activatedAt: $activatedAt)';
}


}

/// @nodoc
abstract mixin class $OwnerInvitationCopyWith<$Res>  {
  factory $OwnerInvitationCopyWith(OwnerInvitation value, $Res Function(OwnerInvitation) _then) = _$OwnerInvitationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'invitation_id') String invitationId,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, String email, InvitationStatus status,@JsonKey(name: 'submitted_at') String submittedAt,@JsonKey(name: 'resend_requested_at') String? resendRequestedAt,@JsonKey(name: 'activated_at') String? activatedAt
});




}
/// @nodoc
class _$OwnerInvitationCopyWithImpl<$Res>
    implements $OwnerInvitationCopyWith<$Res> {
  _$OwnerInvitationCopyWithImpl(this._self, this._then);

  final OwnerInvitation _self;
  final $Res Function(OwnerInvitation) _then;

/// Create a copy of OwnerInvitation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invitationId = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? status = null,Object? submittedAt = null,Object? resendRequestedAt = freezed,Object? activatedAt = freezed,}) {
  return _then(_self.copyWith(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvitationStatus,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,resendRequestedAt: freezed == resendRequestedAt ? _self.resendRequestedAt : resendRequestedAt // ignore: cast_nullable_to_non_nullable
as String?,activatedAt: freezed == activatedAt ? _self.activatedAt : activatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OwnerInvitation].
extension OwnerInvitationPatterns on OwnerInvitation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnerInvitation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnerInvitation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnerInvitation value)  $default,){
final _that = this;
switch (_that) {
case _OwnerInvitation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnerInvitation value)?  $default,){
final _that = this;
switch (_that) {
case _OwnerInvitation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'invitation_id')  String invitationId, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String email,  InvitationStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt, @JsonKey(name: 'activated_at')  String? activatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnerInvitation() when $default != null:
return $default(_that.invitationId,_that.firstName,_that.lastName,_that.email,_that.status,_that.submittedAt,_that.resendRequestedAt,_that.activatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'invitation_id')  String invitationId, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String email,  InvitationStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt, @JsonKey(name: 'activated_at')  String? activatedAt)  $default,) {final _that = this;
switch (_that) {
case _OwnerInvitation():
return $default(_that.invitationId,_that.firstName,_that.lastName,_that.email,_that.status,_that.submittedAt,_that.resendRequestedAt,_that.activatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'invitation_id')  String invitationId, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String email,  InvitationStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt, @JsonKey(name: 'activated_at')  String? activatedAt)?  $default,) {final _that = this;
switch (_that) {
case _OwnerInvitation() when $default != null:
return $default(_that.invitationId,_that.firstName,_that.lastName,_that.email,_that.status,_that.submittedAt,_that.resendRequestedAt,_that.activatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OwnerInvitation implements OwnerInvitation {
  const _OwnerInvitation({@JsonKey(name: 'invitation_id') required this.invitationId, @JsonKey(name: 'first_name') required this.firstName, @JsonKey(name: 'last_name') required this.lastName, required this.email, required this.status, @JsonKey(name: 'submitted_at') required this.submittedAt, @JsonKey(name: 'resend_requested_at') this.resendRequestedAt, @JsonKey(name: 'activated_at') this.activatedAt});
  factory _OwnerInvitation.fromJson(Map<String, dynamic> json) => _$OwnerInvitationFromJson(json);

@override@JsonKey(name: 'invitation_id') final  String invitationId;
@override@JsonKey(name: 'first_name') final  String firstName;
@override@JsonKey(name: 'last_name') final  String lastName;
@override final  String email;
@override final  InvitationStatus status;
@override@JsonKey(name: 'submitted_at') final  String submittedAt;
@override@JsonKey(name: 'resend_requested_at') final  String? resendRequestedAt;
@override@JsonKey(name: 'activated_at') final  String? activatedAt;

/// Create a copy of OwnerInvitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnerInvitationCopyWith<_OwnerInvitation> get copyWith => __$OwnerInvitationCopyWithImpl<_OwnerInvitation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OwnerInvitationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnerInvitation&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.resendRequestedAt, resendRequestedAt) || other.resendRequestedAt == resendRequestedAt)&&(identical(other.activatedAt, activatedAt) || other.activatedAt == activatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,invitationId,firstName,lastName,email,status,submittedAt,resendRequestedAt,activatedAt);

@override
String toString() {
  return 'OwnerInvitation(invitationId: $invitationId, firstName: $firstName, lastName: $lastName, email: $email, status: $status, submittedAt: $submittedAt, resendRequestedAt: $resendRequestedAt, activatedAt: $activatedAt)';
}


}

/// @nodoc
abstract mixin class _$OwnerInvitationCopyWith<$Res> implements $OwnerInvitationCopyWith<$Res> {
  factory _$OwnerInvitationCopyWith(_OwnerInvitation value, $Res Function(_OwnerInvitation) _then) = __$OwnerInvitationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'invitation_id') String invitationId,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, String email, InvitationStatus status,@JsonKey(name: 'submitted_at') String submittedAt,@JsonKey(name: 'resend_requested_at') String? resendRequestedAt,@JsonKey(name: 'activated_at') String? activatedAt
});




}
/// @nodoc
class __$OwnerInvitationCopyWithImpl<$Res>
    implements _$OwnerInvitationCopyWith<$Res> {
  __$OwnerInvitationCopyWithImpl(this._self, this._then);

  final _OwnerInvitation _self;
  final $Res Function(_OwnerInvitation) _then;

/// Create a copy of OwnerInvitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invitationId = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? status = null,Object? submittedAt = null,Object? resendRequestedAt = freezed,Object? activatedAt = freezed,}) {
  return _then(_OwnerInvitation(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvitationStatus,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,resendRequestedAt: freezed == resendRequestedAt ? _self.resendRequestedAt : resendRequestedAt // ignore: cast_nullable_to_non_nullable
as String?,activatedAt: freezed == activatedAt ? _self.activatedAt : activatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
