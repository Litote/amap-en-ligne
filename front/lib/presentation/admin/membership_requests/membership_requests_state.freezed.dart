// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership_requests_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MembershipRequestsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MembershipRequestsState()';
}


}

/// @nodoc
class $MembershipRequestsStateCopyWith<$Res>  {
$MembershipRequestsStateCopyWith(MembershipRequestsState _, $Res Function(MembershipRequestsState) __);
}


/// Adds pattern-matching-related methods to [MembershipRequestsState].
extension MembershipRequestsStatePatterns on MembershipRequestsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MembershipRequestsInitial value)?  initial,TResult Function( MembershipRequestsLoading value)?  loading,TResult Function( MembershipRequestsLoaded value)?  loaded,TResult Function( MembershipRequestsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MembershipRequestsInitial() when initial != null:
return initial(_that);case MembershipRequestsLoading() when loading != null:
return loading(_that);case MembershipRequestsLoaded() when loaded != null:
return loaded(_that);case MembershipRequestsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MembershipRequestsInitial value)  initial,required TResult Function( MembershipRequestsLoading value)  loading,required TResult Function( MembershipRequestsLoaded value)  loaded,required TResult Function( MembershipRequestsError value)  error,}){
final _that = this;
switch (_that) {
case MembershipRequestsInitial():
return initial(_that);case MembershipRequestsLoading():
return loading(_that);case MembershipRequestsLoaded():
return loaded(_that);case MembershipRequestsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MembershipRequestsInitial value)?  initial,TResult? Function( MembershipRequestsLoading value)?  loading,TResult? Function( MembershipRequestsLoaded value)?  loaded,TResult? Function( MembershipRequestsError value)?  error,}){
final _that = this;
switch (_that) {
case MembershipRequestsInitial() when initial != null:
return initial(_that);case MembershipRequestsLoading() when loading != null:
return loading(_that);case MembershipRequestsLoaded() when loaded != null:
return loaded(_that);case MembershipRequestsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<AdminMemberJoinRequest> requests,  MemberJoinRequestStatus? statusFilter,  bool actionInProgress,  String? actionError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MembershipRequestsInitial() when initial != null:
return initial();case MembershipRequestsLoading() when loading != null:
return loading();case MembershipRequestsLoaded() when loaded != null:
return loaded(_that.requests,_that.statusFilter,_that.actionInProgress,_that.actionError);case MembershipRequestsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<AdminMemberJoinRequest> requests,  MemberJoinRequestStatus? statusFilter,  bool actionInProgress,  String? actionError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case MembershipRequestsInitial():
return initial();case MembershipRequestsLoading():
return loading();case MembershipRequestsLoaded():
return loaded(_that.requests,_that.statusFilter,_that.actionInProgress,_that.actionError);case MembershipRequestsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<AdminMemberJoinRequest> requests,  MemberJoinRequestStatus? statusFilter,  bool actionInProgress,  String? actionError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case MembershipRequestsInitial() when initial != null:
return initial();case MembershipRequestsLoading() when loading != null:
return loading();case MembershipRequestsLoaded() when loaded != null:
return loaded(_that.requests,_that.statusFilter,_that.actionInProgress,_that.actionError);case MembershipRequestsError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class MembershipRequestsInitial implements MembershipRequestsState {
  const MembershipRequestsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MembershipRequestsState.initial()';
}


}




/// @nodoc


class MembershipRequestsLoading implements MembershipRequestsState {
  const MembershipRequestsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MembershipRequestsState.loading()';
}


}




/// @nodoc


class MembershipRequestsLoaded implements MembershipRequestsState {
  const MembershipRequestsLoaded({required final  List<AdminMemberJoinRequest> requests, this.statusFilter, this.actionInProgress = false, this.actionError}): _requests = requests;
  

 final  List<AdminMemberJoinRequest> _requests;
 List<AdminMemberJoinRequest> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}

 final  MemberJoinRequestStatus? statusFilter;
@JsonKey() final  bool actionInProgress;
 final  String? actionError;

/// Create a copy of MembershipRequestsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipRequestsLoadedCopyWith<MembershipRequestsLoaded> get copyWith => _$MembershipRequestsLoadedCopyWithImpl<MembershipRequestsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsLoaded&&const DeepCollectionEquality().equals(other._requests, _requests)&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.actionError, actionError) || other.actionError == actionError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_requests),statusFilter,actionInProgress,actionError);

@override
String toString() {
  return 'MembershipRequestsState.loaded(requests: $requests, statusFilter: $statusFilter, actionInProgress: $actionInProgress, actionError: $actionError)';
}


}

/// @nodoc
abstract mixin class $MembershipRequestsLoadedCopyWith<$Res> implements $MembershipRequestsStateCopyWith<$Res> {
  factory $MembershipRequestsLoadedCopyWith(MembershipRequestsLoaded value, $Res Function(MembershipRequestsLoaded) _then) = _$MembershipRequestsLoadedCopyWithImpl;
@useResult
$Res call({
 List<AdminMemberJoinRequest> requests, MemberJoinRequestStatus? statusFilter, bool actionInProgress, String? actionError
});




}
/// @nodoc
class _$MembershipRequestsLoadedCopyWithImpl<$Res>
    implements $MembershipRequestsLoadedCopyWith<$Res> {
  _$MembershipRequestsLoadedCopyWithImpl(this._self, this._then);

  final MembershipRequestsLoaded _self;
  final $Res Function(MembershipRequestsLoaded) _then;

/// Create a copy of MembershipRequestsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requests = null,Object? statusFilter = freezed,Object? actionInProgress = null,Object? actionError = freezed,}) {
  return _then(MembershipRequestsLoaded(
requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<AdminMemberJoinRequest>,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as MemberJoinRequestStatus?,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class MembershipRequestsError implements MembershipRequestsState {
  const MembershipRequestsError(this.message);
  

 final  String message;

/// Create a copy of MembershipRequestsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipRequestsErrorCopyWith<MembershipRequestsError> get copyWith => _$MembershipRequestsErrorCopyWithImpl<MembershipRequestsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'MembershipRequestsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $MembershipRequestsErrorCopyWith<$Res> implements $MembershipRequestsStateCopyWith<$Res> {
  factory $MembershipRequestsErrorCopyWith(MembershipRequestsError value, $Res Function(MembershipRequestsError) _then) = _$MembershipRequestsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$MembershipRequestsErrorCopyWithImpl<$Res>
    implements $MembershipRequestsErrorCopyWith<$Res> {
  _$MembershipRequestsErrorCopyWithImpl(this._self, this._then);

  final MembershipRequestsError _self;
  final $Res Function(MembershipRequestsError) _then;

/// Create a copy of MembershipRequestsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(MembershipRequestsError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
