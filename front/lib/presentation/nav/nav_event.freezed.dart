// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nav_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NavEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NavEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NavEvent()';
}


}

/// @nodoc
class $NavEventCopyWith<$Res>  {
$NavEventCopyWith(NavEvent _, $Res Function(NavEvent) __);
}


/// Adds pattern-matching-related methods to [NavEvent].
extension NavEventPatterns on NavEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NavOpened value)?  opened,TResult Function( NavClosed value)?  closed,TResult Function( NavRoleChanged value)?  roleChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NavOpened() when opened != null:
return opened(_that);case NavClosed() when closed != null:
return closed(_that);case NavRoleChanged() when roleChanged != null:
return roleChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NavOpened value)  opened,required TResult Function( NavClosed value)  closed,required TResult Function( NavRoleChanged value)  roleChanged,}){
final _that = this;
switch (_that) {
case NavOpened():
return opened(_that);case NavClosed():
return closed(_that);case NavRoleChanged():
return roleChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NavOpened value)?  opened,TResult? Function( NavClosed value)?  closed,TResult? Function( NavRoleChanged value)?  roleChanged,}){
final _that = this;
switch (_that) {
case NavOpened() when opened != null:
return opened(_that);case NavClosed() when closed != null:
return closed(_that);case NavRoleChanged() when roleChanged != null:
return roleChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  opened,TResult Function()?  closed,TResult Function( UserRole role,  Set<Role> memberRoles)?  roleChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NavOpened() when opened != null:
return opened();case NavClosed() when closed != null:
return closed();case NavRoleChanged() when roleChanged != null:
return roleChanged(_that.role,_that.memberRoles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  opened,required TResult Function()  closed,required TResult Function( UserRole role,  Set<Role> memberRoles)  roleChanged,}) {final _that = this;
switch (_that) {
case NavOpened():
return opened();case NavClosed():
return closed();case NavRoleChanged():
return roleChanged(_that.role,_that.memberRoles);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  opened,TResult? Function()?  closed,TResult? Function( UserRole role,  Set<Role> memberRoles)?  roleChanged,}) {final _that = this;
switch (_that) {
case NavOpened() when opened != null:
return opened();case NavClosed() when closed != null:
return closed();case NavRoleChanged() when roleChanged != null:
return roleChanged(_that.role,_that.memberRoles);case _:
  return null;

}
}

}

/// @nodoc


class NavOpened implements NavEvent {
  const NavOpened();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NavOpened);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NavEvent.opened()';
}


}




/// @nodoc


class NavClosed implements NavEvent {
  const NavClosed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NavClosed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NavEvent.closed()';
}


}




/// @nodoc


class NavRoleChanged implements NavEvent {
  const NavRoleChanged({required this.role, required final  Set<Role> memberRoles}): _memberRoles = memberRoles;
  

 final  UserRole role;
 final  Set<Role> _memberRoles;
 Set<Role> get memberRoles {
  if (_memberRoles is EqualUnmodifiableSetView) return _memberRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_memberRoles);
}


/// Create a copy of NavEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NavRoleChangedCopyWith<NavRoleChanged> get copyWith => _$NavRoleChangedCopyWithImpl<NavRoleChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NavRoleChanged&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._memberRoles, _memberRoles));
}


@override
int get hashCode => Object.hash(runtimeType,role,const DeepCollectionEquality().hash(_memberRoles));

@override
String toString() {
  return 'NavEvent.roleChanged(role: $role, memberRoles: $memberRoles)';
}


}

/// @nodoc
abstract mixin class $NavRoleChangedCopyWith<$Res> implements $NavEventCopyWith<$Res> {
  factory $NavRoleChangedCopyWith(NavRoleChanged value, $Res Function(NavRoleChanged) _then) = _$NavRoleChangedCopyWithImpl;
@useResult
$Res call({
 UserRole role, Set<Role> memberRoles
});




}
/// @nodoc
class _$NavRoleChangedCopyWithImpl<$Res>
    implements $NavRoleChangedCopyWith<$Res> {
  _$NavRoleChangedCopyWithImpl(this._self, this._then);

  final NavRoleChanged _self;
  final $Res Function(NavRoleChanged) _then;

/// Create a copy of NavEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? role = null,Object? memberRoles = null,}) {
  return _then(NavRoleChanged(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,memberRoles: null == memberRoles ? _self._memberRoles : memberRoles // ignore: cast_nullable_to_non_nullable
as Set<Role>,
  ));
}


}

// dart format on
