// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_detail_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserDetailEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserDetailEvent()';
}


}

/// @nodoc
class $UserDetailEventCopyWith<$Res>  {
$UserDetailEventCopyWith(UserDetailEvent _, $Res Function(UserDetailEvent) __);
}


/// Adds pattern-matching-related methods to [UserDetailEvent].
extension UserDetailEventPatterns on UserDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserDetailLoadRequested value)?  loaded,TResult Function( UserDetailMembershipRolesChanged value)?  membershipRolesChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserDetailLoadRequested() when loaded != null:
return loaded(_that);case UserDetailMembershipRolesChanged() when membershipRolesChanged != null:
return membershipRolesChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserDetailLoadRequested value)  loaded,required TResult Function( UserDetailMembershipRolesChanged value)  membershipRolesChanged,}){
final _that = this;
switch (_that) {
case UserDetailLoadRequested():
return loaded(_that);case UserDetailMembershipRolesChanged():
return membershipRolesChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserDetailLoadRequested value)?  loaded,TResult? Function( UserDetailMembershipRolesChanged value)?  membershipRolesChanged,}){
final _that = this;
switch (_that) {
case UserDetailLoadRequested() when loaded != null:
return loaded(_that);case UserDetailMembershipRolesChanged() when membershipRolesChanged != null:
return membershipRolesChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String userId)?  loaded,TResult Function( String memberId,  String organizationId,  Set<Role> newRoles)?  membershipRolesChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserDetailLoadRequested() when loaded != null:
return loaded(_that.userId);case UserDetailMembershipRolesChanged() when membershipRolesChanged != null:
return membershipRolesChanged(_that.memberId,_that.organizationId,_that.newRoles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String userId)  loaded,required TResult Function( String memberId,  String organizationId,  Set<Role> newRoles)  membershipRolesChanged,}) {final _that = this;
switch (_that) {
case UserDetailLoadRequested():
return loaded(_that.userId);case UserDetailMembershipRolesChanged():
return membershipRolesChanged(_that.memberId,_that.organizationId,_that.newRoles);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String userId)?  loaded,TResult? Function( String memberId,  String organizationId,  Set<Role> newRoles)?  membershipRolesChanged,}) {final _that = this;
switch (_that) {
case UserDetailLoadRequested() when loaded != null:
return loaded(_that.userId);case UserDetailMembershipRolesChanged() when membershipRolesChanged != null:
return membershipRolesChanged(_that.memberId,_that.organizationId,_that.newRoles);case _:
  return null;

}
}

}

/// @nodoc


class UserDetailLoadRequested implements UserDetailEvent {
  const UserDetailLoadRequested(this.userId);
  

 final  String userId;

/// Create a copy of UserDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDetailLoadRequestedCopyWith<UserDetailLoadRequested> get copyWith => _$UserDetailLoadRequestedCopyWithImpl<UserDetailLoadRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailLoadRequested&&(identical(other.userId, userId) || other.userId == userId));
}


@override
int get hashCode => Object.hash(runtimeType,userId);

@override
String toString() {
  return 'UserDetailEvent.loaded(userId: $userId)';
}


}

/// @nodoc
abstract mixin class $UserDetailLoadRequestedCopyWith<$Res> implements $UserDetailEventCopyWith<$Res> {
  factory $UserDetailLoadRequestedCopyWith(UserDetailLoadRequested value, $Res Function(UserDetailLoadRequested) _then) = _$UserDetailLoadRequestedCopyWithImpl;
@useResult
$Res call({
 String userId
});




}
/// @nodoc
class _$UserDetailLoadRequestedCopyWithImpl<$Res>
    implements $UserDetailLoadRequestedCopyWith<$Res> {
  _$UserDetailLoadRequestedCopyWithImpl(this._self, this._then);

  final UserDetailLoadRequested _self;
  final $Res Function(UserDetailLoadRequested) _then;

/// Create a copy of UserDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userId = null,}) {
  return _then(UserDetailLoadRequested(
null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UserDetailMembershipRolesChanged implements UserDetailEvent {
  const UserDetailMembershipRolesChanged({required this.memberId, required this.organizationId, required final  Set<Role> newRoles}): _newRoles = newRoles;
  

 final  String memberId;
 final  String organizationId;
 final  Set<Role> _newRoles;
 Set<Role> get newRoles {
  if (_newRoles is EqualUnmodifiableSetView) return _newRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_newRoles);
}


/// Create a copy of UserDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDetailMembershipRolesChangedCopyWith<UserDetailMembershipRolesChanged> get copyWith => _$UserDetailMembershipRolesChangedCopyWithImpl<UserDetailMembershipRolesChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailMembershipRolesChanged&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other._newRoles, _newRoles));
}


@override
int get hashCode => Object.hash(runtimeType,memberId,organizationId,const DeepCollectionEquality().hash(_newRoles));

@override
String toString() {
  return 'UserDetailEvent.membershipRolesChanged(memberId: $memberId, organizationId: $organizationId, newRoles: $newRoles)';
}


}

/// @nodoc
abstract mixin class $UserDetailMembershipRolesChangedCopyWith<$Res> implements $UserDetailEventCopyWith<$Res> {
  factory $UserDetailMembershipRolesChangedCopyWith(UserDetailMembershipRolesChanged value, $Res Function(UserDetailMembershipRolesChanged) _then) = _$UserDetailMembershipRolesChangedCopyWithImpl;
@useResult
$Res call({
 String memberId, String organizationId, Set<Role> newRoles
});




}
/// @nodoc
class _$UserDetailMembershipRolesChangedCopyWithImpl<$Res>
    implements $UserDetailMembershipRolesChangedCopyWith<$Res> {
  _$UserDetailMembershipRolesChangedCopyWithImpl(this._self, this._then);

  final UserDetailMembershipRolesChanged _self;
  final $Res Function(UserDetailMembershipRolesChanged) _then;

/// Create a copy of UserDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? memberId = null,Object? organizationId = null,Object? newRoles = null,}) {
  return _then(UserDetailMembershipRolesChanged(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,newRoles: null == newRoles ? _self._newRoles : newRoles // ignore: cast_nullable_to_non_nullable
as Set<Role>,
  ));
}


}

// dart format on
