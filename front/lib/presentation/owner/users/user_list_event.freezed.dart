// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_list_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserListEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserListEvent()';
}


}

/// @nodoc
class $UserListEventCopyWith<$Res>  {
$UserListEventCopyWith(UserListEvent _, $Res Function(UserListEvent) __);
}


/// Adds pattern-matching-related methods to [UserListEvent].
extension UserListEventPatterns on UserListEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserListLoadRequested value)?  loaded,TResult Function( UserListSearchQueryChanged value)?  searchQueryChanged,TResult Function( UserListAmapFilterChanged value)?  amapFilterChanged,TResult Function( UserListProducerFilterChanged value)?  producerFilterChanged,TResult Function( UserListRoleFilterChanged value)?  roleFilterChanged,TResult Function( UserListStatusFilterChanged value)?  statusFilterChanged,TResult Function( UserListPageChanged value)?  pageChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserListLoadRequested() when loaded != null:
return loaded(_that);case UserListSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that);case UserListAmapFilterChanged() when amapFilterChanged != null:
return amapFilterChanged(_that);case UserListProducerFilterChanged() when producerFilterChanged != null:
return producerFilterChanged(_that);case UserListRoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that);case UserListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that);case UserListPageChanged() when pageChanged != null:
return pageChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserListLoadRequested value)  loaded,required TResult Function( UserListSearchQueryChanged value)  searchQueryChanged,required TResult Function( UserListAmapFilterChanged value)  amapFilterChanged,required TResult Function( UserListProducerFilterChanged value)  producerFilterChanged,required TResult Function( UserListRoleFilterChanged value)  roleFilterChanged,required TResult Function( UserListStatusFilterChanged value)  statusFilterChanged,required TResult Function( UserListPageChanged value)  pageChanged,}){
final _that = this;
switch (_that) {
case UserListLoadRequested():
return loaded(_that);case UserListSearchQueryChanged():
return searchQueryChanged(_that);case UserListAmapFilterChanged():
return amapFilterChanged(_that);case UserListProducerFilterChanged():
return producerFilterChanged(_that);case UserListRoleFilterChanged():
return roleFilterChanged(_that);case UserListStatusFilterChanged():
return statusFilterChanged(_that);case UserListPageChanged():
return pageChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserListLoadRequested value)?  loaded,TResult? Function( UserListSearchQueryChanged value)?  searchQueryChanged,TResult? Function( UserListAmapFilterChanged value)?  amapFilterChanged,TResult? Function( UserListProducerFilterChanged value)?  producerFilterChanged,TResult? Function( UserListRoleFilterChanged value)?  roleFilterChanged,TResult? Function( UserListStatusFilterChanged value)?  statusFilterChanged,TResult? Function( UserListPageChanged value)?  pageChanged,}){
final _that = this;
switch (_that) {
case UserListLoadRequested() when loaded != null:
return loaded(_that);case UserListSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that);case UserListAmapFilterChanged() when amapFilterChanged != null:
return amapFilterChanged(_that);case UserListProducerFilterChanged() when producerFilterChanged != null:
return producerFilterChanged(_that);case UserListRoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that);case UserListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that);case UserListPageChanged() when pageChanged != null:
return pageChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loaded,TResult Function( String query)?  searchQueryChanged,TResult Function( String? organizationId)?  amapFilterChanged,TResult Function( String? organizationId)?  producerFilterChanged,TResult Function( UserListRoleFilter? filter)?  roleFilterChanged,TResult Function( UserDisplayStatus? status)?  statusFilterChanged,TResult Function( int page)?  pageChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserListLoadRequested() when loaded != null:
return loaded();case UserListSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that.query);case UserListAmapFilterChanged() when amapFilterChanged != null:
return amapFilterChanged(_that.organizationId);case UserListProducerFilterChanged() when producerFilterChanged != null:
return producerFilterChanged(_that.organizationId);case UserListRoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that.filter);case UserListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that.status);case UserListPageChanged() when pageChanged != null:
return pageChanged(_that.page);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loaded,required TResult Function( String query)  searchQueryChanged,required TResult Function( String? organizationId)  amapFilterChanged,required TResult Function( String? organizationId)  producerFilterChanged,required TResult Function( UserListRoleFilter? filter)  roleFilterChanged,required TResult Function( UserDisplayStatus? status)  statusFilterChanged,required TResult Function( int page)  pageChanged,}) {final _that = this;
switch (_that) {
case UserListLoadRequested():
return loaded();case UserListSearchQueryChanged():
return searchQueryChanged(_that.query);case UserListAmapFilterChanged():
return amapFilterChanged(_that.organizationId);case UserListProducerFilterChanged():
return producerFilterChanged(_that.organizationId);case UserListRoleFilterChanged():
return roleFilterChanged(_that.filter);case UserListStatusFilterChanged():
return statusFilterChanged(_that.status);case UserListPageChanged():
return pageChanged(_that.page);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loaded,TResult? Function( String query)?  searchQueryChanged,TResult? Function( String? organizationId)?  amapFilterChanged,TResult? Function( String? organizationId)?  producerFilterChanged,TResult? Function( UserListRoleFilter? filter)?  roleFilterChanged,TResult? Function( UserDisplayStatus? status)?  statusFilterChanged,TResult? Function( int page)?  pageChanged,}) {final _that = this;
switch (_that) {
case UserListLoadRequested() when loaded != null:
return loaded();case UserListSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that.query);case UserListAmapFilterChanged() when amapFilterChanged != null:
return amapFilterChanged(_that.organizationId);case UserListProducerFilterChanged() when producerFilterChanged != null:
return producerFilterChanged(_that.organizationId);case UserListRoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that.filter);case UserListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that.status);case UserListPageChanged() when pageChanged != null:
return pageChanged(_that.page);case _:
  return null;

}
}

}

/// @nodoc


class UserListLoadRequested implements UserListEvent {
  const UserListLoadRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListLoadRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserListEvent.loaded()';
}


}




/// @nodoc


class UserListSearchQueryChanged implements UserListEvent {
  const UserListSearchQueryChanged(this.query);
  

 final  String query;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListSearchQueryChangedCopyWith<UserListSearchQueryChanged> get copyWith => _$UserListSearchQueryChangedCopyWithImpl<UserListSearchQueryChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListSearchQueryChanged&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'UserListEvent.searchQueryChanged(query: $query)';
}


}

/// @nodoc
abstract mixin class $UserListSearchQueryChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListSearchQueryChangedCopyWith(UserListSearchQueryChanged value, $Res Function(UserListSearchQueryChanged) _then) = _$UserListSearchQueryChangedCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$UserListSearchQueryChangedCopyWithImpl<$Res>
    implements $UserListSearchQueryChangedCopyWith<$Res> {
  _$UserListSearchQueryChangedCopyWithImpl(this._self, this._then);

  final UserListSearchQueryChanged _self;
  final $Res Function(UserListSearchQueryChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(UserListSearchQueryChanged(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UserListAmapFilterChanged implements UserListEvent {
  const UserListAmapFilterChanged(this.organizationId);
  

 final  String? organizationId;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListAmapFilterChangedCopyWith<UserListAmapFilterChanged> get copyWith => _$UserListAmapFilterChangedCopyWithImpl<UserListAmapFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListAmapFilterChanged&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId);

@override
String toString() {
  return 'UserListEvent.amapFilterChanged(organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class $UserListAmapFilterChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListAmapFilterChangedCopyWith(UserListAmapFilterChanged value, $Res Function(UserListAmapFilterChanged) _then) = _$UserListAmapFilterChangedCopyWithImpl;
@useResult
$Res call({
 String? organizationId
});




}
/// @nodoc
class _$UserListAmapFilterChangedCopyWithImpl<$Res>
    implements $UserListAmapFilterChangedCopyWith<$Res> {
  _$UserListAmapFilterChangedCopyWithImpl(this._self, this._then);

  final UserListAmapFilterChanged _self;
  final $Res Function(UserListAmapFilterChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationId = freezed,}) {
  return _then(UserListAmapFilterChanged(
freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UserListProducerFilterChanged implements UserListEvent {
  const UserListProducerFilterChanged(this.organizationId);
  

 final  String? organizationId;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListProducerFilterChangedCopyWith<UserListProducerFilterChanged> get copyWith => _$UserListProducerFilterChangedCopyWithImpl<UserListProducerFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListProducerFilterChanged&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId);

@override
String toString() {
  return 'UserListEvent.producerFilterChanged(organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class $UserListProducerFilterChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListProducerFilterChangedCopyWith(UserListProducerFilterChanged value, $Res Function(UserListProducerFilterChanged) _then) = _$UserListProducerFilterChangedCopyWithImpl;
@useResult
$Res call({
 String? organizationId
});




}
/// @nodoc
class _$UserListProducerFilterChangedCopyWithImpl<$Res>
    implements $UserListProducerFilterChangedCopyWith<$Res> {
  _$UserListProducerFilterChangedCopyWithImpl(this._self, this._then);

  final UserListProducerFilterChanged _self;
  final $Res Function(UserListProducerFilterChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationId = freezed,}) {
  return _then(UserListProducerFilterChanged(
freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UserListRoleFilterChanged implements UserListEvent {
  const UserListRoleFilterChanged(this.filter);
  

 final  UserListRoleFilter? filter;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListRoleFilterChangedCopyWith<UserListRoleFilterChanged> get copyWith => _$UserListRoleFilterChangedCopyWithImpl<UserListRoleFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListRoleFilterChanged&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,filter);

@override
String toString() {
  return 'UserListEvent.roleFilterChanged(filter: $filter)';
}


}

/// @nodoc
abstract mixin class $UserListRoleFilterChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListRoleFilterChangedCopyWith(UserListRoleFilterChanged value, $Res Function(UserListRoleFilterChanged) _then) = _$UserListRoleFilterChangedCopyWithImpl;
@useResult
$Res call({
 UserListRoleFilter? filter
});




}
/// @nodoc
class _$UserListRoleFilterChangedCopyWithImpl<$Res>
    implements $UserListRoleFilterChangedCopyWith<$Res> {
  _$UserListRoleFilterChangedCopyWithImpl(this._self, this._then);

  final UserListRoleFilterChanged _self;
  final $Res Function(UserListRoleFilterChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filter = freezed,}) {
  return _then(UserListRoleFilterChanged(
freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as UserListRoleFilter?,
  ));
}


}

/// @nodoc


class UserListStatusFilterChanged implements UserListEvent {
  const UserListStatusFilterChanged(this.status);
  

 final  UserDisplayStatus? status;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListStatusFilterChangedCopyWith<UserListStatusFilterChanged> get copyWith => _$UserListStatusFilterChangedCopyWithImpl<UserListStatusFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListStatusFilterChanged&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'UserListEvent.statusFilterChanged(status: $status)';
}


}

/// @nodoc
abstract mixin class $UserListStatusFilterChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListStatusFilterChangedCopyWith(UserListStatusFilterChanged value, $Res Function(UserListStatusFilterChanged) _then) = _$UserListStatusFilterChangedCopyWithImpl;
@useResult
$Res call({
 UserDisplayStatus? status
});




}
/// @nodoc
class _$UserListStatusFilterChangedCopyWithImpl<$Res>
    implements $UserListStatusFilterChangedCopyWith<$Res> {
  _$UserListStatusFilterChangedCopyWithImpl(this._self, this._then);

  final UserListStatusFilterChanged _self;
  final $Res Function(UserListStatusFilterChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(UserListStatusFilterChanged(
freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserDisplayStatus?,
  ));
}


}

/// @nodoc


class UserListPageChanged implements UserListEvent {
  const UserListPageChanged(this.page);
  

 final  int page;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListPageChangedCopyWith<UserListPageChanged> get copyWith => _$UserListPageChangedCopyWithImpl<UserListPageChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListPageChanged&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,page);

@override
String toString() {
  return 'UserListEvent.pageChanged(page: $page)';
}


}

/// @nodoc
abstract mixin class $UserListPageChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListPageChangedCopyWith(UserListPageChanged value, $Res Function(UserListPageChanged) _then) = _$UserListPageChangedCopyWithImpl;
@useResult
$Res call({
 int page
});




}
/// @nodoc
class _$UserListPageChangedCopyWithImpl<$Res>
    implements $UserListPageChangedCopyWith<$Res> {
  _$UserListPageChangedCopyWithImpl(this._self, this._then);

  final UserListPageChanged _self;
  final $Res Function(UserListPageChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? page = null,}) {
  return _then(UserListPageChanged(
null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
