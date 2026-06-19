// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserListState()';
}


}

/// @nodoc
class $UserListStateCopyWith<$Res>  {
$UserListStateCopyWith(UserListState _, $Res Function(UserListState) __);
}


/// Adds pattern-matching-related methods to [UserListState].
extension UserListStatePatterns on UserListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserListInitial value)?  initial,TResult Function( UserListLoading value)?  loading,TResult Function( UserListLoaded value)?  loaded,TResult Function( UserListError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserListInitial() when initial != null:
return initial(_that);case UserListLoading() when loading != null:
return loading(_that);case UserListLoaded() when loaded != null:
return loaded(_that);case UserListError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserListInitial value)  initial,required TResult Function( UserListLoading value)  loading,required TResult Function( UserListLoaded value)  loaded,required TResult Function( UserListError value)  error,}){
final _that = this;
switch (_that) {
case UserListInitial():
return initial(_that);case UserListLoading():
return loading(_that);case UserListLoaded():
return loaded(_that);case UserListError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserListInitial value)?  initial,TResult? Function( UserListLoading value)?  loading,TResult? Function( UserListLoaded value)?  loaded,TResult? Function( UserListError value)?  error,}){
final _that = this;
switch (_that) {
case UserListInitial() when initial != null:
return initial(_that);case UserListLoading() when loading != null:
return loading(_that);case UserListLoaded() when loaded != null:
return loaded(_that);case UserListError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Organization> allOrganizations,  List<ProducerAccount> allProducerAccounts,  List<UserRow> visibleRows,  int totalCount,  int currentPage,  int totalPages,  String searchQuery,  String? amapIdFilter,  String? producerIdFilter,  UserListRoleFilter? roleFilter,  UserDisplayStatus? statusFilter)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserListInitial() when initial != null:
return initial();case UserListLoading() when loading != null:
return loading();case UserListLoaded() when loaded != null:
return loaded(_that.allOrganizations,_that.allProducerAccounts,_that.visibleRows,_that.totalCount,_that.currentPage,_that.totalPages,_that.searchQuery,_that.amapIdFilter,_that.producerIdFilter,_that.roleFilter,_that.statusFilter);case UserListError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Organization> allOrganizations,  List<ProducerAccount> allProducerAccounts,  List<UserRow> visibleRows,  int totalCount,  int currentPage,  int totalPages,  String searchQuery,  String? amapIdFilter,  String? producerIdFilter,  UserListRoleFilter? roleFilter,  UserDisplayStatus? statusFilter)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case UserListInitial():
return initial();case UserListLoading():
return loading();case UserListLoaded():
return loaded(_that.allOrganizations,_that.allProducerAccounts,_that.visibleRows,_that.totalCount,_that.currentPage,_that.totalPages,_that.searchQuery,_that.amapIdFilter,_that.producerIdFilter,_that.roleFilter,_that.statusFilter);case UserListError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Organization> allOrganizations,  List<ProducerAccount> allProducerAccounts,  List<UserRow> visibleRows,  int totalCount,  int currentPage,  int totalPages,  String searchQuery,  String? amapIdFilter,  String? producerIdFilter,  UserListRoleFilter? roleFilter,  UserDisplayStatus? statusFilter)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case UserListInitial() when initial != null:
return initial();case UserListLoading() when loading != null:
return loading();case UserListLoaded() when loaded != null:
return loaded(_that.allOrganizations,_that.allProducerAccounts,_that.visibleRows,_that.totalCount,_that.currentPage,_that.totalPages,_that.searchQuery,_that.amapIdFilter,_that.producerIdFilter,_that.roleFilter,_that.statusFilter);case UserListError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class UserListInitial implements UserListState {
  const UserListInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserListState.initial()';
}


}




/// @nodoc


class UserListLoading implements UserListState {
  const UserListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserListState.loading()';
}


}




/// @nodoc


class UserListLoaded implements UserListState {
  const UserListLoaded({required final  List<Organization> allOrganizations, required final  List<ProducerAccount> allProducerAccounts, required final  List<UserRow> visibleRows, required this.totalCount, required this.currentPage, required this.totalPages, this.searchQuery = '', this.amapIdFilter, this.producerIdFilter, this.roleFilter, this.statusFilter}): _allOrganizations = allOrganizations,_allProducerAccounts = allProducerAccounts,_visibleRows = visibleRows;
  

/// All organisations available for the AMAP filter dropdown.
 final  List<Organization> _allOrganizations;
/// All organisations available for the AMAP filter dropdown.
 List<Organization> get allOrganizations {
  if (_allOrganizations is EqualUnmodifiableListView) return _allOrganizations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allOrganizations);
}

/// All producer accounts available for the Producteur filter dropdown.
 final  List<ProducerAccount> _allProducerAccounts;
/// All producer accounts available for the Producteur filter dropdown.
 List<ProducerAccount> get allProducerAccounts {
  if (_allProducerAccounts is EqualUnmodifiableListView) return _allProducerAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allProducerAccounts);
}

/// Rows visible on the current page (after filtering + pagination).
 final  List<UserRow> _visibleRows;
/// Rows visible on the current page (after filtering + pagination).
 List<UserRow> get visibleRows {
  if (_visibleRows is EqualUnmodifiableListView) return _visibleRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visibleRows);
}

/// Total number of rows matching the current filters (before pagination).
 final  int totalCount;
/// Current 1-based page number.
 final  int currentPage;
/// Total number of pages (50 rows per page).
 final  int totalPages;
// --- active filter state ---
@JsonKey() final  String searchQuery;
 final  String? amapIdFilter;
 final  String? producerIdFilter;
 final  UserListRoleFilter? roleFilter;
 final  UserDisplayStatus? statusFilter;

/// Create a copy of UserListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListLoadedCopyWith<UserListLoaded> get copyWith => _$UserListLoadedCopyWithImpl<UserListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListLoaded&&const DeepCollectionEquality().equals(other._allOrganizations, _allOrganizations)&&const DeepCollectionEquality().equals(other._allProducerAccounts, _allProducerAccounts)&&const DeepCollectionEquality().equals(other._visibleRows, _visibleRows)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.amapIdFilter, amapIdFilter) || other.amapIdFilter == amapIdFilter)&&(identical(other.producerIdFilter, producerIdFilter) || other.producerIdFilter == producerIdFilter)&&(identical(other.roleFilter, roleFilter) || other.roleFilter == roleFilter)&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allOrganizations),const DeepCollectionEquality().hash(_allProducerAccounts),const DeepCollectionEquality().hash(_visibleRows),totalCount,currentPage,totalPages,searchQuery,amapIdFilter,producerIdFilter,roleFilter,statusFilter);

@override
String toString() {
  return 'UserListState.loaded(allOrganizations: $allOrganizations, allProducerAccounts: $allProducerAccounts, visibleRows: $visibleRows, totalCount: $totalCount, currentPage: $currentPage, totalPages: $totalPages, searchQuery: $searchQuery, amapIdFilter: $amapIdFilter, producerIdFilter: $producerIdFilter, roleFilter: $roleFilter, statusFilter: $statusFilter)';
}


}

/// @nodoc
abstract mixin class $UserListLoadedCopyWith<$Res> implements $UserListStateCopyWith<$Res> {
  factory $UserListLoadedCopyWith(UserListLoaded value, $Res Function(UserListLoaded) _then) = _$UserListLoadedCopyWithImpl;
@useResult
$Res call({
 List<Organization> allOrganizations, List<ProducerAccount> allProducerAccounts, List<UserRow> visibleRows, int totalCount, int currentPage, int totalPages, String searchQuery, String? amapIdFilter, String? producerIdFilter, UserListRoleFilter? roleFilter, UserDisplayStatus? statusFilter
});




}
/// @nodoc
class _$UserListLoadedCopyWithImpl<$Res>
    implements $UserListLoadedCopyWith<$Res> {
  _$UserListLoadedCopyWithImpl(this._self, this._then);

  final UserListLoaded _self;
  final $Res Function(UserListLoaded) _then;

/// Create a copy of UserListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? allOrganizations = null,Object? allProducerAccounts = null,Object? visibleRows = null,Object? totalCount = null,Object? currentPage = null,Object? totalPages = null,Object? searchQuery = null,Object? amapIdFilter = freezed,Object? producerIdFilter = freezed,Object? roleFilter = freezed,Object? statusFilter = freezed,}) {
  return _then(UserListLoaded(
allOrganizations: null == allOrganizations ? _self._allOrganizations : allOrganizations // ignore: cast_nullable_to_non_nullable
as List<Organization>,allProducerAccounts: null == allProducerAccounts ? _self._allProducerAccounts : allProducerAccounts // ignore: cast_nullable_to_non_nullable
as List<ProducerAccount>,visibleRows: null == visibleRows ? _self._visibleRows : visibleRows // ignore: cast_nullable_to_non_nullable
as List<UserRow>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,amapIdFilter: freezed == amapIdFilter ? _self.amapIdFilter : amapIdFilter // ignore: cast_nullable_to_non_nullable
as String?,producerIdFilter: freezed == producerIdFilter ? _self.producerIdFilter : producerIdFilter // ignore: cast_nullable_to_non_nullable
as String?,roleFilter: freezed == roleFilter ? _self.roleFilter : roleFilter // ignore: cast_nullable_to_non_nullable
as UserListRoleFilter?,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as UserDisplayStatus?,
  ));
}


}

/// @nodoc


class UserListError implements UserListState {
  const UserListError(this.message);
  

 final  String message;

/// Create a copy of UserListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListErrorCopyWith<UserListError> get copyWith => _$UserListErrorCopyWithImpl<UserListError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'UserListState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $UserListErrorCopyWith<$Res> implements $UserListStateCopyWith<$Res> {
  factory $UserListErrorCopyWith(UserListError value, $Res Function(UserListError) _then) = _$UserListErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$UserListErrorCopyWithImpl<$Res>
    implements $UserListErrorCopyWith<$Res> {
  _$UserListErrorCopyWithImpl(this._self, this._then);

  final UserListError _self;
  final $Res Function(UserListError) _then;

/// Create a copy of UserListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(UserListError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
