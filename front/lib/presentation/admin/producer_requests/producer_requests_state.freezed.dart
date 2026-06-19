// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_requests_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProducerRequestsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerRequestsState()';
}


}

/// @nodoc
class $ProducerRequestsStateCopyWith<$Res>  {
$ProducerRequestsStateCopyWith(ProducerRequestsState _, $Res Function(ProducerRequestsState) __);
}


/// Adds pattern-matching-related methods to [ProducerRequestsState].
extension ProducerRequestsStatePatterns on ProducerRequestsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProducerRequestsInitial value)?  initial,TResult Function( ProducerRequestsLoading value)?  loading,TResult Function( ProducerRequestsLoaded value)?  loaded,TResult Function( ProducerRequestsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProducerRequestsInitial() when initial != null:
return initial(_that);case ProducerRequestsLoading() when loading != null:
return loading(_that);case ProducerRequestsLoaded() when loaded != null:
return loaded(_that);case ProducerRequestsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProducerRequestsInitial value)  initial,required TResult Function( ProducerRequestsLoading value)  loading,required TResult Function( ProducerRequestsLoaded value)  loaded,required TResult Function( ProducerRequestsError value)  error,}){
final _that = this;
switch (_that) {
case ProducerRequestsInitial():
return initial(_that);case ProducerRequestsLoading():
return loading(_that);case ProducerRequestsLoaded():
return loaded(_that);case ProducerRequestsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProducerRequestsInitial value)?  initial,TResult? Function( ProducerRequestsLoading value)?  loading,TResult? Function( ProducerRequestsLoaded value)?  loaded,TResult? Function( ProducerRequestsError value)?  error,}){
final _that = this;
switch (_that) {
case ProducerRequestsInitial() when initial != null:
return initial(_that);case ProducerRequestsLoading() when loading != null:
return loading(_that);case ProducerRequestsLoaded() when loaded != null:
return loaded(_that);case ProducerRequestsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<AdminProducerRequest> requests,  ProducerRequestStatus? statusFilter,  bool actionInProgress,  String? actionError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProducerRequestsInitial() when initial != null:
return initial();case ProducerRequestsLoading() when loading != null:
return loading();case ProducerRequestsLoaded() when loaded != null:
return loaded(_that.requests,_that.statusFilter,_that.actionInProgress,_that.actionError);case ProducerRequestsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<AdminProducerRequest> requests,  ProducerRequestStatus? statusFilter,  bool actionInProgress,  String? actionError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ProducerRequestsInitial():
return initial();case ProducerRequestsLoading():
return loading();case ProducerRequestsLoaded():
return loaded(_that.requests,_that.statusFilter,_that.actionInProgress,_that.actionError);case ProducerRequestsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<AdminProducerRequest> requests,  ProducerRequestStatus? statusFilter,  bool actionInProgress,  String? actionError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ProducerRequestsInitial() when initial != null:
return initial();case ProducerRequestsLoading() when loading != null:
return loading();case ProducerRequestsLoaded() when loaded != null:
return loaded(_that.requests,_that.statusFilter,_that.actionInProgress,_that.actionError);case ProducerRequestsError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ProducerRequestsInitial implements ProducerRequestsState {
  const ProducerRequestsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerRequestsState.initial()';
}


}




/// @nodoc


class ProducerRequestsLoading implements ProducerRequestsState {
  const ProducerRequestsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerRequestsState.loading()';
}


}




/// @nodoc


class ProducerRequestsLoaded implements ProducerRequestsState {
  const ProducerRequestsLoaded({required final  List<AdminProducerRequest> requests, this.statusFilter, this.actionInProgress = false, this.actionError}): _requests = requests;
  

 final  List<AdminProducerRequest> _requests;
 List<AdminProducerRequest> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}

 final  ProducerRequestStatus? statusFilter;
@JsonKey() final  bool actionInProgress;
 final  String? actionError;

/// Create a copy of ProducerRequestsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestsLoadedCopyWith<ProducerRequestsLoaded> get copyWith => _$ProducerRequestsLoadedCopyWithImpl<ProducerRequestsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsLoaded&&const DeepCollectionEquality().equals(other._requests, _requests)&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.actionError, actionError) || other.actionError == actionError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_requests),statusFilter,actionInProgress,actionError);

@override
String toString() {
  return 'ProducerRequestsState.loaded(requests: $requests, statusFilter: $statusFilter, actionInProgress: $actionInProgress, actionError: $actionError)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestsLoadedCopyWith<$Res> implements $ProducerRequestsStateCopyWith<$Res> {
  factory $ProducerRequestsLoadedCopyWith(ProducerRequestsLoaded value, $Res Function(ProducerRequestsLoaded) _then) = _$ProducerRequestsLoadedCopyWithImpl;
@useResult
$Res call({
 List<AdminProducerRequest> requests, ProducerRequestStatus? statusFilter, bool actionInProgress, String? actionError
});




}
/// @nodoc
class _$ProducerRequestsLoadedCopyWithImpl<$Res>
    implements $ProducerRequestsLoadedCopyWith<$Res> {
  _$ProducerRequestsLoadedCopyWithImpl(this._self, this._then);

  final ProducerRequestsLoaded _self;
  final $Res Function(ProducerRequestsLoaded) _then;

/// Create a copy of ProducerRequestsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requests = null,Object? statusFilter = freezed,Object? actionInProgress = null,Object? actionError = freezed,}) {
  return _then(ProducerRequestsLoaded(
requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<AdminProducerRequest>,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as ProducerRequestStatus?,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ProducerRequestsError implements ProducerRequestsState {
  const ProducerRequestsError(this.message);
  

 final  String message;

/// Create a copy of ProducerRequestsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestsErrorCopyWith<ProducerRequestsError> get copyWith => _$ProducerRequestsErrorCopyWithImpl<ProducerRequestsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProducerRequestsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestsErrorCopyWith<$Res> implements $ProducerRequestsStateCopyWith<$Res> {
  factory $ProducerRequestsErrorCopyWith(ProducerRequestsError value, $Res Function(ProducerRequestsError) _then) = _$ProducerRequestsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProducerRequestsErrorCopyWithImpl<$Res>
    implements $ProducerRequestsErrorCopyWith<$Res> {
  _$ProducerRequestsErrorCopyWithImpl(this._self, this._then);

  final ProducerRequestsError _self;
  final $Res Function(ProducerRequestsError) _then;

/// Create a copy of ProducerRequestsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProducerRequestsError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
