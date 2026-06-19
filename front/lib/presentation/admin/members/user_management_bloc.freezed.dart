// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_management_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserManagementEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserManagementEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementEvent()';
}


}

/// @nodoc
class $UserManagementEventCopyWith<$Res>  {
$UserManagementEventCopyWith(UserManagementEvent _, $Res Function(UserManagementEvent) __);
}


/// Adds pattern-matching-related methods to [UserManagementEvent].
extension UserManagementEventPatterns on UserManagementEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadRequested value)?  loadRequested,TResult Function( _SearchChanged value)?  searchChanged,TResult Function( _RoleFilterChanged value)?  roleFilterChanged,TResult Function( _InvitationStatusFilterChanged value)?  invitationStatusFilterChanged,TResult Function( _UserStatusFilterChanged value)?  userStatusFilterChanged,TResult Function( _EditRolesRequested value)?  editRolesRequested,TResult Function( _RoleToggled value)?  roleToggled,TResult Function( _SaveRolesRequested value)?  saveRolesRequested,TResult Function( _EditCancelled value)?  editCancelled,TResult Function( _ShowInviteForm value)?  showInviteForm,TResult Function( _InviteFirstNameChanged value)?  inviteFirstNameChanged,TResult Function( _InviteLastNameChanged value)?  inviteLastNameChanged,TResult Function( _InviteEmailChanged value)?  inviteEmailChanged,TResult Function( _InviteRoleToggled value)?  inviteRoleToggled,TResult Function( _ResendInvitationRequested value)?  resendInvitationRequested,TResult Function( _DeleteInvitationRequested value)?  deleteInvitationRequested,TResult Function( _ResendAllPendingRequested value)?  resendAllPendingRequested,TResult Function( _SubmitInvitation value)?  submitInvitation,TResult Function( _DismissInviteForm value)?  dismissInviteForm,TResult Function( _FeedbackDismissed value)?  feedbackDismissed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadRequested() when loadRequested != null:
return loadRequested(_that);case _SearchChanged() when searchChanged != null:
return searchChanged(_that);case _RoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that);case _InvitationStatusFilterChanged() when invitationStatusFilterChanged != null:
return invitationStatusFilterChanged(_that);case _UserStatusFilterChanged() when userStatusFilterChanged != null:
return userStatusFilterChanged(_that);case _EditRolesRequested() when editRolesRequested != null:
return editRolesRequested(_that);case _RoleToggled() when roleToggled != null:
return roleToggled(_that);case _SaveRolesRequested() when saveRolesRequested != null:
return saveRolesRequested(_that);case _EditCancelled() when editCancelled != null:
return editCancelled(_that);case _ShowInviteForm() when showInviteForm != null:
return showInviteForm(_that);case _InviteFirstNameChanged() when inviteFirstNameChanged != null:
return inviteFirstNameChanged(_that);case _InviteLastNameChanged() when inviteLastNameChanged != null:
return inviteLastNameChanged(_that);case _InviteEmailChanged() when inviteEmailChanged != null:
return inviteEmailChanged(_that);case _InviteRoleToggled() when inviteRoleToggled != null:
return inviteRoleToggled(_that);case _ResendInvitationRequested() when resendInvitationRequested != null:
return resendInvitationRequested(_that);case _DeleteInvitationRequested() when deleteInvitationRequested != null:
return deleteInvitationRequested(_that);case _ResendAllPendingRequested() when resendAllPendingRequested != null:
return resendAllPendingRequested(_that);case _SubmitInvitation() when submitInvitation != null:
return submitInvitation(_that);case _DismissInviteForm() when dismissInviteForm != null:
return dismissInviteForm(_that);case _FeedbackDismissed() when feedbackDismissed != null:
return feedbackDismissed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadRequested value)  loadRequested,required TResult Function( _SearchChanged value)  searchChanged,required TResult Function( _RoleFilterChanged value)  roleFilterChanged,required TResult Function( _InvitationStatusFilterChanged value)  invitationStatusFilterChanged,required TResult Function( _UserStatusFilterChanged value)  userStatusFilterChanged,required TResult Function( _EditRolesRequested value)  editRolesRequested,required TResult Function( _RoleToggled value)  roleToggled,required TResult Function( _SaveRolesRequested value)  saveRolesRequested,required TResult Function( _EditCancelled value)  editCancelled,required TResult Function( _ShowInviteForm value)  showInviteForm,required TResult Function( _InviteFirstNameChanged value)  inviteFirstNameChanged,required TResult Function( _InviteLastNameChanged value)  inviteLastNameChanged,required TResult Function( _InviteEmailChanged value)  inviteEmailChanged,required TResult Function( _InviteRoleToggled value)  inviteRoleToggled,required TResult Function( _ResendInvitationRequested value)  resendInvitationRequested,required TResult Function( _DeleteInvitationRequested value)  deleteInvitationRequested,required TResult Function( _ResendAllPendingRequested value)  resendAllPendingRequested,required TResult Function( _SubmitInvitation value)  submitInvitation,required TResult Function( _DismissInviteForm value)  dismissInviteForm,required TResult Function( _FeedbackDismissed value)  feedbackDismissed,}){
final _that = this;
switch (_that) {
case _LoadRequested():
return loadRequested(_that);case _SearchChanged():
return searchChanged(_that);case _RoleFilterChanged():
return roleFilterChanged(_that);case _InvitationStatusFilterChanged():
return invitationStatusFilterChanged(_that);case _UserStatusFilterChanged():
return userStatusFilterChanged(_that);case _EditRolesRequested():
return editRolesRequested(_that);case _RoleToggled():
return roleToggled(_that);case _SaveRolesRequested():
return saveRolesRequested(_that);case _EditCancelled():
return editCancelled(_that);case _ShowInviteForm():
return showInviteForm(_that);case _InviteFirstNameChanged():
return inviteFirstNameChanged(_that);case _InviteLastNameChanged():
return inviteLastNameChanged(_that);case _InviteEmailChanged():
return inviteEmailChanged(_that);case _InviteRoleToggled():
return inviteRoleToggled(_that);case _ResendInvitationRequested():
return resendInvitationRequested(_that);case _DeleteInvitationRequested():
return deleteInvitationRequested(_that);case _ResendAllPendingRequested():
return resendAllPendingRequested(_that);case _SubmitInvitation():
return submitInvitation(_that);case _DismissInviteForm():
return dismissInviteForm(_that);case _FeedbackDismissed():
return feedbackDismissed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadRequested value)?  loadRequested,TResult? Function( _SearchChanged value)?  searchChanged,TResult? Function( _RoleFilterChanged value)?  roleFilterChanged,TResult? Function( _InvitationStatusFilterChanged value)?  invitationStatusFilterChanged,TResult? Function( _UserStatusFilterChanged value)?  userStatusFilterChanged,TResult? Function( _EditRolesRequested value)?  editRolesRequested,TResult? Function( _RoleToggled value)?  roleToggled,TResult? Function( _SaveRolesRequested value)?  saveRolesRequested,TResult? Function( _EditCancelled value)?  editCancelled,TResult? Function( _ShowInviteForm value)?  showInviteForm,TResult? Function( _InviteFirstNameChanged value)?  inviteFirstNameChanged,TResult? Function( _InviteLastNameChanged value)?  inviteLastNameChanged,TResult? Function( _InviteEmailChanged value)?  inviteEmailChanged,TResult? Function( _InviteRoleToggled value)?  inviteRoleToggled,TResult? Function( _ResendInvitationRequested value)?  resendInvitationRequested,TResult? Function( _DeleteInvitationRequested value)?  deleteInvitationRequested,TResult? Function( _ResendAllPendingRequested value)?  resendAllPendingRequested,TResult? Function( _SubmitInvitation value)?  submitInvitation,TResult? Function( _DismissInviteForm value)?  dismissInviteForm,TResult? Function( _FeedbackDismissed value)?  feedbackDismissed,}){
final _that = this;
switch (_that) {
case _LoadRequested() when loadRequested != null:
return loadRequested(_that);case _SearchChanged() when searchChanged != null:
return searchChanged(_that);case _RoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that);case _InvitationStatusFilterChanged() when invitationStatusFilterChanged != null:
return invitationStatusFilterChanged(_that);case _UserStatusFilterChanged() when userStatusFilterChanged != null:
return userStatusFilterChanged(_that);case _EditRolesRequested() when editRolesRequested != null:
return editRolesRequested(_that);case _RoleToggled() when roleToggled != null:
return roleToggled(_that);case _SaveRolesRequested() when saveRolesRequested != null:
return saveRolesRequested(_that);case _EditCancelled() when editCancelled != null:
return editCancelled(_that);case _ShowInviteForm() when showInviteForm != null:
return showInviteForm(_that);case _InviteFirstNameChanged() when inviteFirstNameChanged != null:
return inviteFirstNameChanged(_that);case _InviteLastNameChanged() when inviteLastNameChanged != null:
return inviteLastNameChanged(_that);case _InviteEmailChanged() when inviteEmailChanged != null:
return inviteEmailChanged(_that);case _InviteRoleToggled() when inviteRoleToggled != null:
return inviteRoleToggled(_that);case _ResendInvitationRequested() when resendInvitationRequested != null:
return resendInvitationRequested(_that);case _DeleteInvitationRequested() when deleteInvitationRequested != null:
return deleteInvitationRequested(_that);case _ResendAllPendingRequested() when resendAllPendingRequested != null:
return resendAllPendingRequested(_that);case _SubmitInvitation() when submitInvitation != null:
return submitInvitation(_that);case _DismissInviteForm() when dismissInviteForm != null:
return dismissInviteForm(_that);case _FeedbackDismissed() when feedbackDismissed != null:
return feedbackDismissed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadRequested,TResult Function( String query)?  searchChanged,TResult Function( Role? role)?  roleFilterChanged,TResult Function( InvitationStatusFilter filter)?  invitationStatusFilterChanged,TResult Function( UserStatusFilter filter)?  userStatusFilterChanged,TResult Function( Member member)?  editRolesRequested,TResult Function( Role role,  bool isChecked)?  roleToggled,TResult Function()?  saveRolesRequested,TResult Function()?  editCancelled,TResult Function()?  showInviteForm,TResult Function( String value)?  inviteFirstNameChanged,TResult Function( String value)?  inviteLastNameChanged,TResult Function( String value)?  inviteEmailChanged,TResult Function( Role role,  bool isChecked)?  inviteRoleToggled,TResult Function( MemberInvitation invitation)?  resendInvitationRequested,TResult Function( MemberInvitation invitation)?  deleteInvitationRequested,TResult Function( String? customEmailSubject,  String? customEmailBody)?  resendAllPendingRequested,TResult Function()?  submitInvitation,TResult Function()?  dismissInviteForm,TResult Function()?  feedbackDismissed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadRequested() when loadRequested != null:
return loadRequested();case _SearchChanged() when searchChanged != null:
return searchChanged(_that.query);case _RoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that.role);case _InvitationStatusFilterChanged() when invitationStatusFilterChanged != null:
return invitationStatusFilterChanged(_that.filter);case _UserStatusFilterChanged() when userStatusFilterChanged != null:
return userStatusFilterChanged(_that.filter);case _EditRolesRequested() when editRolesRequested != null:
return editRolesRequested(_that.member);case _RoleToggled() when roleToggled != null:
return roleToggled(_that.role,_that.isChecked);case _SaveRolesRequested() when saveRolesRequested != null:
return saveRolesRequested();case _EditCancelled() when editCancelled != null:
return editCancelled();case _ShowInviteForm() when showInviteForm != null:
return showInviteForm();case _InviteFirstNameChanged() when inviteFirstNameChanged != null:
return inviteFirstNameChanged(_that.value);case _InviteLastNameChanged() when inviteLastNameChanged != null:
return inviteLastNameChanged(_that.value);case _InviteEmailChanged() when inviteEmailChanged != null:
return inviteEmailChanged(_that.value);case _InviteRoleToggled() when inviteRoleToggled != null:
return inviteRoleToggled(_that.role,_that.isChecked);case _ResendInvitationRequested() when resendInvitationRequested != null:
return resendInvitationRequested(_that.invitation);case _DeleteInvitationRequested() when deleteInvitationRequested != null:
return deleteInvitationRequested(_that.invitation);case _ResendAllPendingRequested() when resendAllPendingRequested != null:
return resendAllPendingRequested(_that.customEmailSubject,_that.customEmailBody);case _SubmitInvitation() when submitInvitation != null:
return submitInvitation();case _DismissInviteForm() when dismissInviteForm != null:
return dismissInviteForm();case _FeedbackDismissed() when feedbackDismissed != null:
return feedbackDismissed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadRequested,required TResult Function( String query)  searchChanged,required TResult Function( Role? role)  roleFilterChanged,required TResult Function( InvitationStatusFilter filter)  invitationStatusFilterChanged,required TResult Function( UserStatusFilter filter)  userStatusFilterChanged,required TResult Function( Member member)  editRolesRequested,required TResult Function( Role role,  bool isChecked)  roleToggled,required TResult Function()  saveRolesRequested,required TResult Function()  editCancelled,required TResult Function()  showInviteForm,required TResult Function( String value)  inviteFirstNameChanged,required TResult Function( String value)  inviteLastNameChanged,required TResult Function( String value)  inviteEmailChanged,required TResult Function( Role role,  bool isChecked)  inviteRoleToggled,required TResult Function( MemberInvitation invitation)  resendInvitationRequested,required TResult Function( MemberInvitation invitation)  deleteInvitationRequested,required TResult Function( String? customEmailSubject,  String? customEmailBody)  resendAllPendingRequested,required TResult Function()  submitInvitation,required TResult Function()  dismissInviteForm,required TResult Function()  feedbackDismissed,}) {final _that = this;
switch (_that) {
case _LoadRequested():
return loadRequested();case _SearchChanged():
return searchChanged(_that.query);case _RoleFilterChanged():
return roleFilterChanged(_that.role);case _InvitationStatusFilterChanged():
return invitationStatusFilterChanged(_that.filter);case _UserStatusFilterChanged():
return userStatusFilterChanged(_that.filter);case _EditRolesRequested():
return editRolesRequested(_that.member);case _RoleToggled():
return roleToggled(_that.role,_that.isChecked);case _SaveRolesRequested():
return saveRolesRequested();case _EditCancelled():
return editCancelled();case _ShowInviteForm():
return showInviteForm();case _InviteFirstNameChanged():
return inviteFirstNameChanged(_that.value);case _InviteLastNameChanged():
return inviteLastNameChanged(_that.value);case _InviteEmailChanged():
return inviteEmailChanged(_that.value);case _InviteRoleToggled():
return inviteRoleToggled(_that.role,_that.isChecked);case _ResendInvitationRequested():
return resendInvitationRequested(_that.invitation);case _DeleteInvitationRequested():
return deleteInvitationRequested(_that.invitation);case _ResendAllPendingRequested():
return resendAllPendingRequested(_that.customEmailSubject,_that.customEmailBody);case _SubmitInvitation():
return submitInvitation();case _DismissInviteForm():
return dismissInviteForm();case _FeedbackDismissed():
return feedbackDismissed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadRequested,TResult? Function( String query)?  searchChanged,TResult? Function( Role? role)?  roleFilterChanged,TResult? Function( InvitationStatusFilter filter)?  invitationStatusFilterChanged,TResult? Function( UserStatusFilter filter)?  userStatusFilterChanged,TResult? Function( Member member)?  editRolesRequested,TResult? Function( Role role,  bool isChecked)?  roleToggled,TResult? Function()?  saveRolesRequested,TResult? Function()?  editCancelled,TResult? Function()?  showInviteForm,TResult? Function( String value)?  inviteFirstNameChanged,TResult? Function( String value)?  inviteLastNameChanged,TResult? Function( String value)?  inviteEmailChanged,TResult? Function( Role role,  bool isChecked)?  inviteRoleToggled,TResult? Function( MemberInvitation invitation)?  resendInvitationRequested,TResult? Function( MemberInvitation invitation)?  deleteInvitationRequested,TResult? Function( String? customEmailSubject,  String? customEmailBody)?  resendAllPendingRequested,TResult? Function()?  submitInvitation,TResult? Function()?  dismissInviteForm,TResult? Function()?  feedbackDismissed,}) {final _that = this;
switch (_that) {
case _LoadRequested() when loadRequested != null:
return loadRequested();case _SearchChanged() when searchChanged != null:
return searchChanged(_that.query);case _RoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that.role);case _InvitationStatusFilterChanged() when invitationStatusFilterChanged != null:
return invitationStatusFilterChanged(_that.filter);case _UserStatusFilterChanged() when userStatusFilterChanged != null:
return userStatusFilterChanged(_that.filter);case _EditRolesRequested() when editRolesRequested != null:
return editRolesRequested(_that.member);case _RoleToggled() when roleToggled != null:
return roleToggled(_that.role,_that.isChecked);case _SaveRolesRequested() when saveRolesRequested != null:
return saveRolesRequested();case _EditCancelled() when editCancelled != null:
return editCancelled();case _ShowInviteForm() when showInviteForm != null:
return showInviteForm();case _InviteFirstNameChanged() when inviteFirstNameChanged != null:
return inviteFirstNameChanged(_that.value);case _InviteLastNameChanged() when inviteLastNameChanged != null:
return inviteLastNameChanged(_that.value);case _InviteEmailChanged() when inviteEmailChanged != null:
return inviteEmailChanged(_that.value);case _InviteRoleToggled() when inviteRoleToggled != null:
return inviteRoleToggled(_that.role,_that.isChecked);case _ResendInvitationRequested() when resendInvitationRequested != null:
return resendInvitationRequested(_that.invitation);case _DeleteInvitationRequested() when deleteInvitationRequested != null:
return deleteInvitationRequested(_that.invitation);case _ResendAllPendingRequested() when resendAllPendingRequested != null:
return resendAllPendingRequested(_that.customEmailSubject,_that.customEmailBody);case _SubmitInvitation() when submitInvitation != null:
return submitInvitation();case _DismissInviteForm() when dismissInviteForm != null:
return dismissInviteForm();case _FeedbackDismissed() when feedbackDismissed != null:
return feedbackDismissed();case _:
  return null;

}
}

}

/// @nodoc


class _LoadRequested implements UserManagementEvent {
  const _LoadRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementEvent.loadRequested()';
}


}




/// @nodoc


class _SearchChanged implements UserManagementEvent {
  const _SearchChanged(this.query);
  

 final  String query;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchChangedCopyWith<_SearchChanged> get copyWith => __$SearchChangedCopyWithImpl<_SearchChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchChanged&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'UserManagementEvent.searchChanged(query: $query)';
}


}

/// @nodoc
abstract mixin class _$SearchChangedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$SearchChangedCopyWith(_SearchChanged value, $Res Function(_SearchChanged) _then) = __$SearchChangedCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class __$SearchChangedCopyWithImpl<$Res>
    implements _$SearchChangedCopyWith<$Res> {
  __$SearchChangedCopyWithImpl(this._self, this._then);

  final _SearchChanged _self;
  final $Res Function(_SearchChanged) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(_SearchChanged(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _RoleFilterChanged implements UserManagementEvent {
  const _RoleFilterChanged(this.role);
  

 final  Role? role;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoleFilterChangedCopyWith<_RoleFilterChanged> get copyWith => __$RoleFilterChangedCopyWithImpl<_RoleFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoleFilterChanged&&(identical(other.role, role) || other.role == role));
}


@override
int get hashCode => Object.hash(runtimeType,role);

@override
String toString() {
  return 'UserManagementEvent.roleFilterChanged(role: $role)';
}


}

/// @nodoc
abstract mixin class _$RoleFilterChangedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$RoleFilterChangedCopyWith(_RoleFilterChanged value, $Res Function(_RoleFilterChanged) _then) = __$RoleFilterChangedCopyWithImpl;
@useResult
$Res call({
 Role? role
});




}
/// @nodoc
class __$RoleFilterChangedCopyWithImpl<$Res>
    implements _$RoleFilterChangedCopyWith<$Res> {
  __$RoleFilterChangedCopyWithImpl(this._self, this._then);

  final _RoleFilterChanged _self;
  final $Res Function(_RoleFilterChanged) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? role = freezed,}) {
  return _then(_RoleFilterChanged(
freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as Role?,
  ));
}


}

/// @nodoc


class _InvitationStatusFilterChanged implements UserManagementEvent {
  const _InvitationStatusFilterChanged(this.filter);
  

 final  InvitationStatusFilter filter;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationStatusFilterChangedCopyWith<_InvitationStatusFilterChanged> get copyWith => __$InvitationStatusFilterChangedCopyWithImpl<_InvitationStatusFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationStatusFilterChanged&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,filter);

@override
String toString() {
  return 'UserManagementEvent.invitationStatusFilterChanged(filter: $filter)';
}


}

/// @nodoc
abstract mixin class _$InvitationStatusFilterChangedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$InvitationStatusFilterChangedCopyWith(_InvitationStatusFilterChanged value, $Res Function(_InvitationStatusFilterChanged) _then) = __$InvitationStatusFilterChangedCopyWithImpl;
@useResult
$Res call({
 InvitationStatusFilter filter
});




}
/// @nodoc
class __$InvitationStatusFilterChangedCopyWithImpl<$Res>
    implements _$InvitationStatusFilterChangedCopyWith<$Res> {
  __$InvitationStatusFilterChangedCopyWithImpl(this._self, this._then);

  final _InvitationStatusFilterChanged _self;
  final $Res Function(_InvitationStatusFilterChanged) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filter = null,}) {
  return _then(_InvitationStatusFilterChanged(
null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as InvitationStatusFilter,
  ));
}


}

/// @nodoc


class _UserStatusFilterChanged implements UserManagementEvent {
  const _UserStatusFilterChanged(this.filter);
  

 final  UserStatusFilter filter;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserStatusFilterChangedCopyWith<_UserStatusFilterChanged> get copyWith => __$UserStatusFilterChangedCopyWithImpl<_UserStatusFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserStatusFilterChanged&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,filter);

@override
String toString() {
  return 'UserManagementEvent.userStatusFilterChanged(filter: $filter)';
}


}

/// @nodoc
abstract mixin class _$UserStatusFilterChangedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$UserStatusFilterChangedCopyWith(_UserStatusFilterChanged value, $Res Function(_UserStatusFilterChanged) _then) = __$UserStatusFilterChangedCopyWithImpl;
@useResult
$Res call({
 UserStatusFilter filter
});




}
/// @nodoc
class __$UserStatusFilterChangedCopyWithImpl<$Res>
    implements _$UserStatusFilterChangedCopyWith<$Res> {
  __$UserStatusFilterChangedCopyWithImpl(this._self, this._then);

  final _UserStatusFilterChanged _self;
  final $Res Function(_UserStatusFilterChanged) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filter = null,}) {
  return _then(_UserStatusFilterChanged(
null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as UserStatusFilter,
  ));
}


}

/// @nodoc


class _EditRolesRequested implements UserManagementEvent {
  const _EditRolesRequested(this.member);
  

 final  Member member;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditRolesRequestedCopyWith<_EditRolesRequested> get copyWith => __$EditRolesRequestedCopyWithImpl<_EditRolesRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditRolesRequested&&(identical(other.member, member) || other.member == member));
}


@override
int get hashCode => Object.hash(runtimeType,member);

@override
String toString() {
  return 'UserManagementEvent.editRolesRequested(member: $member)';
}


}

/// @nodoc
abstract mixin class _$EditRolesRequestedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$EditRolesRequestedCopyWith(_EditRolesRequested value, $Res Function(_EditRolesRequested) _then) = __$EditRolesRequestedCopyWithImpl;
@useResult
$Res call({
 Member member
});


$MemberCopyWith<$Res> get member;

}
/// @nodoc
class __$EditRolesRequestedCopyWithImpl<$Res>
    implements _$EditRolesRequestedCopyWith<$Res> {
  __$EditRolesRequestedCopyWithImpl(this._self, this._then);

  final _EditRolesRequested _self;
  final $Res Function(_EditRolesRequested) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? member = null,}) {
  return _then(_EditRolesRequested(
null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as Member,
  ));
}

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberCopyWith<$Res> get member {
  
  return $MemberCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}
}

/// @nodoc


class _RoleToggled implements UserManagementEvent {
  const _RoleToggled(this.role, this.isChecked);
  

 final  Role role;
 final  bool isChecked;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoleToggledCopyWith<_RoleToggled> get copyWith => __$RoleToggledCopyWithImpl<_RoleToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoleToggled&&(identical(other.role, role) || other.role == role)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked));
}


@override
int get hashCode => Object.hash(runtimeType,role,isChecked);

@override
String toString() {
  return 'UserManagementEvent.roleToggled(role: $role, isChecked: $isChecked)';
}


}

/// @nodoc
abstract mixin class _$RoleToggledCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$RoleToggledCopyWith(_RoleToggled value, $Res Function(_RoleToggled) _then) = __$RoleToggledCopyWithImpl;
@useResult
$Res call({
 Role role, bool isChecked
});




}
/// @nodoc
class __$RoleToggledCopyWithImpl<$Res>
    implements _$RoleToggledCopyWith<$Res> {
  __$RoleToggledCopyWithImpl(this._self, this._then);

  final _RoleToggled _self;
  final $Res Function(_RoleToggled) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? role = null,Object? isChecked = null,}) {
  return _then(_RoleToggled(
null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as Role,null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _SaveRolesRequested implements UserManagementEvent {
  const _SaveRolesRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveRolesRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementEvent.saveRolesRequested()';
}


}




/// @nodoc


class _EditCancelled implements UserManagementEvent {
  const _EditCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementEvent.editCancelled()';
}


}




/// @nodoc


class _ShowInviteForm implements UserManagementEvent {
  const _ShowInviteForm();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowInviteForm);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementEvent.showInviteForm()';
}


}




/// @nodoc


class _InviteFirstNameChanged implements UserManagementEvent {
  const _InviteFirstNameChanged(this.value);
  

 final  String value;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteFirstNameChangedCopyWith<_InviteFirstNameChanged> get copyWith => __$InviteFirstNameChangedCopyWithImpl<_InviteFirstNameChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteFirstNameChanged&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'UserManagementEvent.inviteFirstNameChanged(value: $value)';
}


}

/// @nodoc
abstract mixin class _$InviteFirstNameChangedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$InviteFirstNameChangedCopyWith(_InviteFirstNameChanged value, $Res Function(_InviteFirstNameChanged) _then) = __$InviteFirstNameChangedCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class __$InviteFirstNameChangedCopyWithImpl<$Res>
    implements _$InviteFirstNameChangedCopyWith<$Res> {
  __$InviteFirstNameChangedCopyWithImpl(this._self, this._then);

  final _InviteFirstNameChanged _self;
  final $Res Function(_InviteFirstNameChanged) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_InviteFirstNameChanged(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _InviteLastNameChanged implements UserManagementEvent {
  const _InviteLastNameChanged(this.value);
  

 final  String value;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteLastNameChangedCopyWith<_InviteLastNameChanged> get copyWith => __$InviteLastNameChangedCopyWithImpl<_InviteLastNameChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteLastNameChanged&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'UserManagementEvent.inviteLastNameChanged(value: $value)';
}


}

/// @nodoc
abstract mixin class _$InviteLastNameChangedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$InviteLastNameChangedCopyWith(_InviteLastNameChanged value, $Res Function(_InviteLastNameChanged) _then) = __$InviteLastNameChangedCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class __$InviteLastNameChangedCopyWithImpl<$Res>
    implements _$InviteLastNameChangedCopyWith<$Res> {
  __$InviteLastNameChangedCopyWithImpl(this._self, this._then);

  final _InviteLastNameChanged _self;
  final $Res Function(_InviteLastNameChanged) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_InviteLastNameChanged(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _InviteEmailChanged implements UserManagementEvent {
  const _InviteEmailChanged(this.value);
  

 final  String value;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteEmailChangedCopyWith<_InviteEmailChanged> get copyWith => __$InviteEmailChangedCopyWithImpl<_InviteEmailChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteEmailChanged&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'UserManagementEvent.inviteEmailChanged(value: $value)';
}


}

/// @nodoc
abstract mixin class _$InviteEmailChangedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$InviteEmailChangedCopyWith(_InviteEmailChanged value, $Res Function(_InviteEmailChanged) _then) = __$InviteEmailChangedCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class __$InviteEmailChangedCopyWithImpl<$Res>
    implements _$InviteEmailChangedCopyWith<$Res> {
  __$InviteEmailChangedCopyWithImpl(this._self, this._then);

  final _InviteEmailChanged _self;
  final $Res Function(_InviteEmailChanged) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_InviteEmailChanged(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _InviteRoleToggled implements UserManagementEvent {
  const _InviteRoleToggled(this.role, this.isChecked);
  

 final  Role role;
 final  bool isChecked;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteRoleToggledCopyWith<_InviteRoleToggled> get copyWith => __$InviteRoleToggledCopyWithImpl<_InviteRoleToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteRoleToggled&&(identical(other.role, role) || other.role == role)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked));
}


@override
int get hashCode => Object.hash(runtimeType,role,isChecked);

@override
String toString() {
  return 'UserManagementEvent.inviteRoleToggled(role: $role, isChecked: $isChecked)';
}


}

/// @nodoc
abstract mixin class _$InviteRoleToggledCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$InviteRoleToggledCopyWith(_InviteRoleToggled value, $Res Function(_InviteRoleToggled) _then) = __$InviteRoleToggledCopyWithImpl;
@useResult
$Res call({
 Role role, bool isChecked
});




}
/// @nodoc
class __$InviteRoleToggledCopyWithImpl<$Res>
    implements _$InviteRoleToggledCopyWith<$Res> {
  __$InviteRoleToggledCopyWithImpl(this._self, this._then);

  final _InviteRoleToggled _self;
  final $Res Function(_InviteRoleToggled) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? role = null,Object? isChecked = null,}) {
  return _then(_InviteRoleToggled(
null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as Role,null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _ResendInvitationRequested implements UserManagementEvent {
  const _ResendInvitationRequested(this.invitation);
  

 final  MemberInvitation invitation;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResendInvitationRequestedCopyWith<_ResendInvitationRequested> get copyWith => __$ResendInvitationRequestedCopyWithImpl<_ResendInvitationRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResendInvitationRequested&&(identical(other.invitation, invitation) || other.invitation == invitation));
}


@override
int get hashCode => Object.hash(runtimeType,invitation);

@override
String toString() {
  return 'UserManagementEvent.resendInvitationRequested(invitation: $invitation)';
}


}

/// @nodoc
abstract mixin class _$ResendInvitationRequestedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$ResendInvitationRequestedCopyWith(_ResendInvitationRequested value, $Res Function(_ResendInvitationRequested) _then) = __$ResendInvitationRequestedCopyWithImpl;
@useResult
$Res call({
 MemberInvitation invitation
});


$MemberInvitationCopyWith<$Res> get invitation;

}
/// @nodoc
class __$ResendInvitationRequestedCopyWithImpl<$Res>
    implements _$ResendInvitationRequestedCopyWith<$Res> {
  __$ResendInvitationRequestedCopyWithImpl(this._self, this._then);

  final _ResendInvitationRequested _self;
  final $Res Function(_ResendInvitationRequested) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? invitation = null,}) {
  return _then(_ResendInvitationRequested(
null == invitation ? _self.invitation : invitation // ignore: cast_nullable_to_non_nullable
as MemberInvitation,
  ));
}

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberInvitationCopyWith<$Res> get invitation {
  
  return $MemberInvitationCopyWith<$Res>(_self.invitation, (value) {
    return _then(_self.copyWith(invitation: value));
  });
}
}

/// @nodoc


class _DeleteInvitationRequested implements UserManagementEvent {
  const _DeleteInvitationRequested(this.invitation);
  

 final  MemberInvitation invitation;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteInvitationRequestedCopyWith<_DeleteInvitationRequested> get copyWith => __$DeleteInvitationRequestedCopyWithImpl<_DeleteInvitationRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteInvitationRequested&&(identical(other.invitation, invitation) || other.invitation == invitation));
}


@override
int get hashCode => Object.hash(runtimeType,invitation);

@override
String toString() {
  return 'UserManagementEvent.deleteInvitationRequested(invitation: $invitation)';
}


}

/// @nodoc
abstract mixin class _$DeleteInvitationRequestedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$DeleteInvitationRequestedCopyWith(_DeleteInvitationRequested value, $Res Function(_DeleteInvitationRequested) _then) = __$DeleteInvitationRequestedCopyWithImpl;
@useResult
$Res call({
 MemberInvitation invitation
});


$MemberInvitationCopyWith<$Res> get invitation;

}
/// @nodoc
class __$DeleteInvitationRequestedCopyWithImpl<$Res>
    implements _$DeleteInvitationRequestedCopyWith<$Res> {
  __$DeleteInvitationRequestedCopyWithImpl(this._self, this._then);

  final _DeleteInvitationRequested _self;
  final $Res Function(_DeleteInvitationRequested) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? invitation = null,}) {
  return _then(_DeleteInvitationRequested(
null == invitation ? _self.invitation : invitation // ignore: cast_nullable_to_non_nullable
as MemberInvitation,
  ));
}

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberInvitationCopyWith<$Res> get invitation {
  
  return $MemberInvitationCopyWith<$Res>(_self.invitation, (value) {
    return _then(_self.copyWith(invitation: value));
  });
}
}

/// @nodoc


class _ResendAllPendingRequested implements UserManagementEvent {
  const _ResendAllPendingRequested({this.customEmailSubject, this.customEmailBody});
  

 final  String? customEmailSubject;
 final  String? customEmailBody;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResendAllPendingRequestedCopyWith<_ResendAllPendingRequested> get copyWith => __$ResendAllPendingRequestedCopyWithImpl<_ResendAllPendingRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResendAllPendingRequested&&(identical(other.customEmailSubject, customEmailSubject) || other.customEmailSubject == customEmailSubject)&&(identical(other.customEmailBody, customEmailBody) || other.customEmailBody == customEmailBody));
}


@override
int get hashCode => Object.hash(runtimeType,customEmailSubject,customEmailBody);

@override
String toString() {
  return 'UserManagementEvent.resendAllPendingRequested(customEmailSubject: $customEmailSubject, customEmailBody: $customEmailBody)';
}


}

/// @nodoc
abstract mixin class _$ResendAllPendingRequestedCopyWith<$Res> implements $UserManagementEventCopyWith<$Res> {
  factory _$ResendAllPendingRequestedCopyWith(_ResendAllPendingRequested value, $Res Function(_ResendAllPendingRequested) _then) = __$ResendAllPendingRequestedCopyWithImpl;
@useResult
$Res call({
 String? customEmailSubject, String? customEmailBody
});




}
/// @nodoc
class __$ResendAllPendingRequestedCopyWithImpl<$Res>
    implements _$ResendAllPendingRequestedCopyWith<$Res> {
  __$ResendAllPendingRequestedCopyWithImpl(this._self, this._then);

  final _ResendAllPendingRequested _self;
  final $Res Function(_ResendAllPendingRequested) _then;

/// Create a copy of UserManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? customEmailSubject = freezed,Object? customEmailBody = freezed,}) {
  return _then(_ResendAllPendingRequested(
customEmailSubject: freezed == customEmailSubject ? _self.customEmailSubject : customEmailSubject // ignore: cast_nullable_to_non_nullable
as String?,customEmailBody: freezed == customEmailBody ? _self.customEmailBody : customEmailBody // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _SubmitInvitation implements UserManagementEvent {
  const _SubmitInvitation();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmitInvitation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementEvent.submitInvitation()';
}


}




/// @nodoc


class _DismissInviteForm implements UserManagementEvent {
  const _DismissInviteForm();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DismissInviteForm);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementEvent.dismissInviteForm()';
}


}




/// @nodoc


class _FeedbackDismissed implements UserManagementEvent {
  const _FeedbackDismissed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackDismissed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementEvent.feedbackDismissed()';
}


}




/// @nodoc
mixin _$UserManagementState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserManagementState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementState()';
}


}

/// @nodoc
class $UserManagementStateCopyWith<$Res>  {
$UserManagementStateCopyWith(UserManagementState _, $Res Function(UserManagementState) __);
}


/// Adds pattern-matching-related methods to [UserManagementState].
extension UserManagementStatePatterns on UserManagementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserManagementInitial value)?  initial,TResult Function( UserManagementLoading value)?  loading,TResult Function( UserManagementLoaded value)?  loaded,TResult Function( UserManagementError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserManagementInitial() when initial != null:
return initial(_that);case UserManagementLoading() when loading != null:
return loading(_that);case UserManagementLoaded() when loaded != null:
return loaded(_that);case UserManagementError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserManagementInitial value)  initial,required TResult Function( UserManagementLoading value)  loading,required TResult Function( UserManagementLoaded value)  loaded,required TResult Function( UserManagementError value)  error,}){
final _that = this;
switch (_that) {
case UserManagementInitial():
return initial(_that);case UserManagementLoading():
return loading(_that);case UserManagementLoaded():
return loaded(_that);case UserManagementError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserManagementInitial value)?  initial,TResult? Function( UserManagementLoading value)?  loading,TResult? Function( UserManagementLoaded value)?  loaded,TResult? Function( UserManagementError value)?  error,}){
final _that = this;
switch (_that) {
case UserManagementInitial() when initial != null:
return initial(_that);case UserManagementLoading() when loading != null:
return loading(_that);case UserManagementLoaded() when loaded != null:
return loaded(_that);case UserManagementError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Member> members,  List<MemberInvitation> memberInvitations,  String searchQuery,  Role? roleFilter,  InvitationStatusFilter invitationStatusFilter,  UserStatusFilter userStatusFilter,  Member? editingMember,  Set<Role> pendingRoles,  bool saving,  bool showingInviteForm,  String inviteFirstName,  String inviteLastName,  String inviteEmail,  Set<Role> inviteRoles,  bool inviting,  Set<String> resendingInvitationIds,  Set<String> deletingInvitationIds,  bool resendingAllPending,  String? inviteError,  bool inviteSuccess,  String? feedbackMessage,  bool feedbackIsError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserManagementInitial() when initial != null:
return initial();case UserManagementLoading() when loading != null:
return loading();case UserManagementLoaded() when loaded != null:
return loaded(_that.members,_that.memberInvitations,_that.searchQuery,_that.roleFilter,_that.invitationStatusFilter,_that.userStatusFilter,_that.editingMember,_that.pendingRoles,_that.saving,_that.showingInviteForm,_that.inviteFirstName,_that.inviteLastName,_that.inviteEmail,_that.inviteRoles,_that.inviting,_that.resendingInvitationIds,_that.deletingInvitationIds,_that.resendingAllPending,_that.inviteError,_that.inviteSuccess,_that.feedbackMessage,_that.feedbackIsError);case UserManagementError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Member> members,  List<MemberInvitation> memberInvitations,  String searchQuery,  Role? roleFilter,  InvitationStatusFilter invitationStatusFilter,  UserStatusFilter userStatusFilter,  Member? editingMember,  Set<Role> pendingRoles,  bool saving,  bool showingInviteForm,  String inviteFirstName,  String inviteLastName,  String inviteEmail,  Set<Role> inviteRoles,  bool inviting,  Set<String> resendingInvitationIds,  Set<String> deletingInvitationIds,  bool resendingAllPending,  String? inviteError,  bool inviteSuccess,  String? feedbackMessage,  bool feedbackIsError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case UserManagementInitial():
return initial();case UserManagementLoading():
return loading();case UserManagementLoaded():
return loaded(_that.members,_that.memberInvitations,_that.searchQuery,_that.roleFilter,_that.invitationStatusFilter,_that.userStatusFilter,_that.editingMember,_that.pendingRoles,_that.saving,_that.showingInviteForm,_that.inviteFirstName,_that.inviteLastName,_that.inviteEmail,_that.inviteRoles,_that.inviting,_that.resendingInvitationIds,_that.deletingInvitationIds,_that.resendingAllPending,_that.inviteError,_that.inviteSuccess,_that.feedbackMessage,_that.feedbackIsError);case UserManagementError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Member> members,  List<MemberInvitation> memberInvitations,  String searchQuery,  Role? roleFilter,  InvitationStatusFilter invitationStatusFilter,  UserStatusFilter userStatusFilter,  Member? editingMember,  Set<Role> pendingRoles,  bool saving,  bool showingInviteForm,  String inviteFirstName,  String inviteLastName,  String inviteEmail,  Set<Role> inviteRoles,  bool inviting,  Set<String> resendingInvitationIds,  Set<String> deletingInvitationIds,  bool resendingAllPending,  String? inviteError,  bool inviteSuccess,  String? feedbackMessage,  bool feedbackIsError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case UserManagementInitial() when initial != null:
return initial();case UserManagementLoading() when loading != null:
return loading();case UserManagementLoaded() when loaded != null:
return loaded(_that.members,_that.memberInvitations,_that.searchQuery,_that.roleFilter,_that.invitationStatusFilter,_that.userStatusFilter,_that.editingMember,_that.pendingRoles,_that.saving,_that.showingInviteForm,_that.inviteFirstName,_that.inviteLastName,_that.inviteEmail,_that.inviteRoles,_that.inviting,_that.resendingInvitationIds,_that.deletingInvitationIds,_that.resendingAllPending,_that.inviteError,_that.inviteSuccess,_that.feedbackMessage,_that.feedbackIsError);case UserManagementError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class UserManagementInitial implements UserManagementState {
  const UserManagementInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserManagementInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementState.initial()';
}


}




/// @nodoc


class UserManagementLoading implements UserManagementState {
  const UserManagementLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserManagementLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserManagementState.loading()';
}


}




/// @nodoc


class UserManagementLoaded implements UserManagementState {
  const UserManagementLoaded({required final  List<Member> members, final  List<MemberInvitation> memberInvitations = const <MemberInvitation>[], this.searchQuery = '', this.roleFilter, this.invitationStatusFilter = InvitationStatusFilter.active, this.userStatusFilter = UserStatusFilter.active, this.editingMember, final  Set<Role> pendingRoles = const <Role>{}, this.saving = false, this.showingInviteForm = false, this.inviteFirstName = '', this.inviteLastName = '', this.inviteEmail = '', final  Set<Role> inviteRoles = const <Role>{}, this.inviting = false, final  Set<String> resendingInvitationIds = const <String>{}, final  Set<String> deletingInvitationIds = const <String>{}, this.resendingAllPending = false, this.inviteError, this.inviteSuccess = false, this.feedbackMessage, this.feedbackIsError = false}): _members = members,_memberInvitations = memberInvitations,_pendingRoles = pendingRoles,_inviteRoles = inviteRoles,_resendingInvitationIds = resendingInvitationIds,_deletingInvitationIds = deletingInvitationIds;
  

 final  List<Member> _members;
 List<Member> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

 final  List<MemberInvitation> _memberInvitations;
@JsonKey() List<MemberInvitation> get memberInvitations {
  if (_memberInvitations is EqualUnmodifiableListView) return _memberInvitations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberInvitations);
}

@JsonKey() final  String searchQuery;
 final  Role? roleFilter;
@JsonKey() final  InvitationStatusFilter invitationStatusFilter;
@JsonKey() final  UserStatusFilter userStatusFilter;
 final  Member? editingMember;
 final  Set<Role> _pendingRoles;
@JsonKey() Set<Role> get pendingRoles {
  if (_pendingRoles is EqualUnmodifiableSetView) return _pendingRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_pendingRoles);
}

@JsonKey() final  bool saving;
@JsonKey() final  bool showingInviteForm;
@JsonKey() final  String inviteFirstName;
@JsonKey() final  String inviteLastName;
@JsonKey() final  String inviteEmail;
 final  Set<Role> _inviteRoles;
@JsonKey() Set<Role> get inviteRoles {
  if (_inviteRoles is EqualUnmodifiableSetView) return _inviteRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_inviteRoles);
}

@JsonKey() final  bool inviting;
 final  Set<String> _resendingInvitationIds;
@JsonKey() Set<String> get resendingInvitationIds {
  if (_resendingInvitationIds is EqualUnmodifiableSetView) return _resendingInvitationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resendingInvitationIds);
}

 final  Set<String> _deletingInvitationIds;
@JsonKey() Set<String> get deletingInvitationIds {
  if (_deletingInvitationIds is EqualUnmodifiableSetView) return _deletingInvitationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_deletingInvitationIds);
}

@JsonKey() final  bool resendingAllPending;
 final  String? inviteError;
@JsonKey() final  bool inviteSuccess;
 final  String? feedbackMessage;
@JsonKey() final  bool feedbackIsError;

/// Create a copy of UserManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserManagementLoadedCopyWith<UserManagementLoaded> get copyWith => _$UserManagementLoadedCopyWithImpl<UserManagementLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserManagementLoaded&&const DeepCollectionEquality().equals(other._members, _members)&&const DeepCollectionEquality().equals(other._memberInvitations, _memberInvitations)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.roleFilter, roleFilter) || other.roleFilter == roleFilter)&&(identical(other.invitationStatusFilter, invitationStatusFilter) || other.invitationStatusFilter == invitationStatusFilter)&&(identical(other.userStatusFilter, userStatusFilter) || other.userStatusFilter == userStatusFilter)&&(identical(other.editingMember, editingMember) || other.editingMember == editingMember)&&const DeepCollectionEquality().equals(other._pendingRoles, _pendingRoles)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.showingInviteForm, showingInviteForm) || other.showingInviteForm == showingInviteForm)&&(identical(other.inviteFirstName, inviteFirstName) || other.inviteFirstName == inviteFirstName)&&(identical(other.inviteLastName, inviteLastName) || other.inviteLastName == inviteLastName)&&(identical(other.inviteEmail, inviteEmail) || other.inviteEmail == inviteEmail)&&const DeepCollectionEquality().equals(other._inviteRoles, _inviteRoles)&&(identical(other.inviting, inviting) || other.inviting == inviting)&&const DeepCollectionEquality().equals(other._resendingInvitationIds, _resendingInvitationIds)&&const DeepCollectionEquality().equals(other._deletingInvitationIds, _deletingInvitationIds)&&(identical(other.resendingAllPending, resendingAllPending) || other.resendingAllPending == resendingAllPending)&&(identical(other.inviteError, inviteError) || other.inviteError == inviteError)&&(identical(other.inviteSuccess, inviteSuccess) || other.inviteSuccess == inviteSuccess)&&(identical(other.feedbackMessage, feedbackMessage) || other.feedbackMessage == feedbackMessage)&&(identical(other.feedbackIsError, feedbackIsError) || other.feedbackIsError == feedbackIsError));
}


@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_memberInvitations),searchQuery,roleFilter,invitationStatusFilter,userStatusFilter,editingMember,const DeepCollectionEquality().hash(_pendingRoles),saving,showingInviteForm,inviteFirstName,inviteLastName,inviteEmail,const DeepCollectionEquality().hash(_inviteRoles),inviting,const DeepCollectionEquality().hash(_resendingInvitationIds),const DeepCollectionEquality().hash(_deletingInvitationIds),resendingAllPending,inviteError,inviteSuccess,feedbackMessage,feedbackIsError]);

@override
String toString() {
  return 'UserManagementState.loaded(members: $members, memberInvitations: $memberInvitations, searchQuery: $searchQuery, roleFilter: $roleFilter, invitationStatusFilter: $invitationStatusFilter, userStatusFilter: $userStatusFilter, editingMember: $editingMember, pendingRoles: $pendingRoles, saving: $saving, showingInviteForm: $showingInviteForm, inviteFirstName: $inviteFirstName, inviteLastName: $inviteLastName, inviteEmail: $inviteEmail, inviteRoles: $inviteRoles, inviting: $inviting, resendingInvitationIds: $resendingInvitationIds, deletingInvitationIds: $deletingInvitationIds, resendingAllPending: $resendingAllPending, inviteError: $inviteError, inviteSuccess: $inviteSuccess, feedbackMessage: $feedbackMessage, feedbackIsError: $feedbackIsError)';
}


}

/// @nodoc
abstract mixin class $UserManagementLoadedCopyWith<$Res> implements $UserManagementStateCopyWith<$Res> {
  factory $UserManagementLoadedCopyWith(UserManagementLoaded value, $Res Function(UserManagementLoaded) _then) = _$UserManagementLoadedCopyWithImpl;
@useResult
$Res call({
 List<Member> members, List<MemberInvitation> memberInvitations, String searchQuery, Role? roleFilter, InvitationStatusFilter invitationStatusFilter, UserStatusFilter userStatusFilter, Member? editingMember, Set<Role> pendingRoles, bool saving, bool showingInviteForm, String inviteFirstName, String inviteLastName, String inviteEmail, Set<Role> inviteRoles, bool inviting, Set<String> resendingInvitationIds, Set<String> deletingInvitationIds, bool resendingAllPending, String? inviteError, bool inviteSuccess, String? feedbackMessage, bool feedbackIsError
});


$MemberCopyWith<$Res>? get editingMember;

}
/// @nodoc
class _$UserManagementLoadedCopyWithImpl<$Res>
    implements $UserManagementLoadedCopyWith<$Res> {
  _$UserManagementLoadedCopyWithImpl(this._self, this._then);

  final UserManagementLoaded _self;
  final $Res Function(UserManagementLoaded) _then;

/// Create a copy of UserManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? members = null,Object? memberInvitations = null,Object? searchQuery = null,Object? roleFilter = freezed,Object? invitationStatusFilter = null,Object? userStatusFilter = null,Object? editingMember = freezed,Object? pendingRoles = null,Object? saving = null,Object? showingInviteForm = null,Object? inviteFirstName = null,Object? inviteLastName = null,Object? inviteEmail = null,Object? inviteRoles = null,Object? inviting = null,Object? resendingInvitationIds = null,Object? deletingInvitationIds = null,Object? resendingAllPending = null,Object? inviteError = freezed,Object? inviteSuccess = null,Object? feedbackMessage = freezed,Object? feedbackIsError = null,}) {
  return _then(UserManagementLoaded(
members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<Member>,memberInvitations: null == memberInvitations ? _self._memberInvitations : memberInvitations // ignore: cast_nullable_to_non_nullable
as List<MemberInvitation>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,roleFilter: freezed == roleFilter ? _self.roleFilter : roleFilter // ignore: cast_nullable_to_non_nullable
as Role?,invitationStatusFilter: null == invitationStatusFilter ? _self.invitationStatusFilter : invitationStatusFilter // ignore: cast_nullable_to_non_nullable
as InvitationStatusFilter,userStatusFilter: null == userStatusFilter ? _self.userStatusFilter : userStatusFilter // ignore: cast_nullable_to_non_nullable
as UserStatusFilter,editingMember: freezed == editingMember ? _self.editingMember : editingMember // ignore: cast_nullable_to_non_nullable
as Member?,pendingRoles: null == pendingRoles ? _self._pendingRoles : pendingRoles // ignore: cast_nullable_to_non_nullable
as Set<Role>,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,showingInviteForm: null == showingInviteForm ? _self.showingInviteForm : showingInviteForm // ignore: cast_nullable_to_non_nullable
as bool,inviteFirstName: null == inviteFirstName ? _self.inviteFirstName : inviteFirstName // ignore: cast_nullable_to_non_nullable
as String,inviteLastName: null == inviteLastName ? _self.inviteLastName : inviteLastName // ignore: cast_nullable_to_non_nullable
as String,inviteEmail: null == inviteEmail ? _self.inviteEmail : inviteEmail // ignore: cast_nullable_to_non_nullable
as String,inviteRoles: null == inviteRoles ? _self._inviteRoles : inviteRoles // ignore: cast_nullable_to_non_nullable
as Set<Role>,inviting: null == inviting ? _self.inviting : inviting // ignore: cast_nullable_to_non_nullable
as bool,resendingInvitationIds: null == resendingInvitationIds ? _self._resendingInvitationIds : resendingInvitationIds // ignore: cast_nullable_to_non_nullable
as Set<String>,deletingInvitationIds: null == deletingInvitationIds ? _self._deletingInvitationIds : deletingInvitationIds // ignore: cast_nullable_to_non_nullable
as Set<String>,resendingAllPending: null == resendingAllPending ? _self.resendingAllPending : resendingAllPending // ignore: cast_nullable_to_non_nullable
as bool,inviteError: freezed == inviteError ? _self.inviteError : inviteError // ignore: cast_nullable_to_non_nullable
as String?,inviteSuccess: null == inviteSuccess ? _self.inviteSuccess : inviteSuccess // ignore: cast_nullable_to_non_nullable
as bool,feedbackMessage: freezed == feedbackMessage ? _self.feedbackMessage : feedbackMessage // ignore: cast_nullable_to_non_nullable
as String?,feedbackIsError: null == feedbackIsError ? _self.feedbackIsError : feedbackIsError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of UserManagementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberCopyWith<$Res>? get editingMember {
    if (_self.editingMember == null) {
    return null;
  }

  return $MemberCopyWith<$Res>(_self.editingMember!, (value) {
    return _then(_self.copyWith(editingMember: value));
  });
}
}

/// @nodoc


class UserManagementError implements UserManagementState {
  const UserManagementError(this.message);
  

 final  String message;

/// Create a copy of UserManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserManagementErrorCopyWith<UserManagementError> get copyWith => _$UserManagementErrorCopyWithImpl<UserManagementError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserManagementError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'UserManagementState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $UserManagementErrorCopyWith<$Res> implements $UserManagementStateCopyWith<$Res> {
  factory $UserManagementErrorCopyWith(UserManagementError value, $Res Function(UserManagementError) _then) = _$UserManagementErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$UserManagementErrorCopyWithImpl<$Res>
    implements $UserManagementErrorCopyWith<$Res> {
  _$UserManagementErrorCopyWithImpl(this._self, this._then);

  final UserManagementError _self;
  final $Res Function(UserManagementError) _then;

/// Create a copy of UserManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(UserManagementError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
