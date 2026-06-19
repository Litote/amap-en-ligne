// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_requests_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdminRequestsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AdminRequestsState()';
}


}

/// @nodoc
class $AdminRequestsStateCopyWith<$Res>  {
$AdminRequestsStateCopyWith(AdminRequestsState _, $Res Function(AdminRequestsState) __);
}


/// Adds pattern-matching-related methods to [AdminRequestsState].
extension AdminRequestsStatePatterns on AdminRequestsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AdminRequestsInitial value)?  initial,TResult Function( AdminRequestsLoading value)?  loading,TResult Function( AdminRequestsLoaded value)?  loaded,TResult Function( AdminRequestsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AdminRequestsInitial() when initial != null:
return initial(_that);case AdminRequestsLoading() when loading != null:
return loading(_that);case AdminRequestsLoaded() when loaded != null:
return loaded(_that);case AdminRequestsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AdminRequestsInitial value)  initial,required TResult Function( AdminRequestsLoading value)  loading,required TResult Function( AdminRequestsLoaded value)  loaded,required TResult Function( AdminRequestsError value)  error,}){
final _that = this;
switch (_that) {
case AdminRequestsInitial():
return initial(_that);case AdminRequestsLoading():
return loading(_that);case AdminRequestsLoaded():
return loaded(_that);case AdminRequestsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AdminRequestsInitial value)?  initial,TResult? Function( AdminRequestsLoading value)?  loading,TResult? Function( AdminRequestsLoaded value)?  loaded,TResult? Function( AdminRequestsError value)?  error,}){
final _that = this;
switch (_that) {
case AdminRequestsInitial() when initial != null:
return initial(_that);case AdminRequestsLoading() when loading != null:
return loading(_that);case AdminRequestsLoaded() when loaded != null:
return loaded(_that);case AdminRequestsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<AdminOrganizationRequest> requests,  OrganizationRequestStatus? statusFilter,  OrganizationType organizationTypeFilter,  bool actionInProgress,  String? actionError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AdminRequestsInitial() when initial != null:
return initial();case AdminRequestsLoading() when loading != null:
return loading();case AdminRequestsLoaded() when loaded != null:
return loaded(_that.requests,_that.statusFilter,_that.organizationTypeFilter,_that.actionInProgress,_that.actionError);case AdminRequestsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<AdminOrganizationRequest> requests,  OrganizationRequestStatus? statusFilter,  OrganizationType organizationTypeFilter,  bool actionInProgress,  String? actionError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case AdminRequestsInitial():
return initial();case AdminRequestsLoading():
return loading();case AdminRequestsLoaded():
return loaded(_that.requests,_that.statusFilter,_that.organizationTypeFilter,_that.actionInProgress,_that.actionError);case AdminRequestsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<AdminOrganizationRequest> requests,  OrganizationRequestStatus? statusFilter,  OrganizationType organizationTypeFilter,  bool actionInProgress,  String? actionError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case AdminRequestsInitial() when initial != null:
return initial();case AdminRequestsLoading() when loading != null:
return loading();case AdminRequestsLoaded() when loaded != null:
return loaded(_that.requests,_that.statusFilter,_that.organizationTypeFilter,_that.actionInProgress,_that.actionError);case AdminRequestsError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class AdminRequestsInitial implements AdminRequestsState {
  const AdminRequestsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AdminRequestsState.initial()';
}


}




/// @nodoc


class AdminRequestsLoading implements AdminRequestsState {
  const AdminRequestsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AdminRequestsState.loading()';
}


}




/// @nodoc


class AdminRequestsLoaded implements AdminRequestsState {
  const AdminRequestsLoaded({required final  List<AdminOrganizationRequest> requests, this.statusFilter, this.organizationTypeFilter = OrganizationType.amap, this.actionInProgress = false, this.actionError}): _requests = requests;
  

 final  List<AdminOrganizationRequest> _requests;
 List<AdminOrganizationRequest> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}

 final  OrganizationRequestStatus? statusFilter;
@JsonKey() final  OrganizationType organizationTypeFilter;
@JsonKey() final  bool actionInProgress;
 final  String? actionError;

/// Create a copy of AdminRequestsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminRequestsLoadedCopyWith<AdminRequestsLoaded> get copyWith => _$AdminRequestsLoadedCopyWithImpl<AdminRequestsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsLoaded&&const DeepCollectionEquality().equals(other._requests, _requests)&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter)&&(identical(other.organizationTypeFilter, organizationTypeFilter) || other.organizationTypeFilter == organizationTypeFilter)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.actionError, actionError) || other.actionError == actionError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_requests),statusFilter,organizationTypeFilter,actionInProgress,actionError);

@override
String toString() {
  return 'AdminRequestsState.loaded(requests: $requests, statusFilter: $statusFilter, organizationTypeFilter: $organizationTypeFilter, actionInProgress: $actionInProgress, actionError: $actionError)';
}


}

/// @nodoc
abstract mixin class $AdminRequestsLoadedCopyWith<$Res> implements $AdminRequestsStateCopyWith<$Res> {
  factory $AdminRequestsLoadedCopyWith(AdminRequestsLoaded value, $Res Function(AdminRequestsLoaded) _then) = _$AdminRequestsLoadedCopyWithImpl;
@useResult
$Res call({
 List<AdminOrganizationRequest> requests, OrganizationRequestStatus? statusFilter, OrganizationType organizationTypeFilter, bool actionInProgress, String? actionError
});




}
/// @nodoc
class _$AdminRequestsLoadedCopyWithImpl<$Res>
    implements $AdminRequestsLoadedCopyWith<$Res> {
  _$AdminRequestsLoadedCopyWithImpl(this._self, this._then);

  final AdminRequestsLoaded _self;
  final $Res Function(AdminRequestsLoaded) _then;

/// Create a copy of AdminRequestsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requests = null,Object? statusFilter = freezed,Object? organizationTypeFilter = null,Object? actionInProgress = null,Object? actionError = freezed,}) {
  return _then(AdminRequestsLoaded(
requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<AdminOrganizationRequest>,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as OrganizationRequestStatus?,organizationTypeFilter: null == organizationTypeFilter ? _self.organizationTypeFilter : organizationTypeFilter // ignore: cast_nullable_to_non_nullable
as OrganizationType,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AdminRequestsError implements AdminRequestsState {
  const AdminRequestsError(this.message);
  

 final  String message;

/// Create a copy of AdminRequestsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminRequestsErrorCopyWith<AdminRequestsError> get copyWith => _$AdminRequestsErrorCopyWithImpl<AdminRequestsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AdminRequestsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $AdminRequestsErrorCopyWith<$Res> implements $AdminRequestsStateCopyWith<$Res> {
  factory $AdminRequestsErrorCopyWith(AdminRequestsError value, $Res Function(AdminRequestsError) _then) = _$AdminRequestsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AdminRequestsErrorCopyWithImpl<$Res>
    implements $AdminRequestsErrorCopyWith<$Res> {
  _$AdminRequestsErrorCopyWithImpl(this._self, this._then);

  final AdminRequestsError _self;
  final $Res Function(AdminRequestsError) _then;

/// Create a copy of AdminRequestsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AdminRequestsError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
