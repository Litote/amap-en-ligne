// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState()';
}


}

/// @nodoc
class $SyncStateCopyWith<$Res>  {
$SyncStateCopyWith(SyncState _, $Res Function(SyncState) __);
}


/// Adds pattern-matching-related methods to [SyncState].
extension SyncStatePatterns on SyncState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SyncIdle value)?  idle,TResult Function( SyncRunning value)?  syncing,TResult Function( SyncSucceeded value)?  success,TResult Function( SyncFailed value)?  failure,TResult Function( SyncOffline value)?  offline,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle(_that);case SyncRunning() when syncing != null:
return syncing(_that);case SyncSucceeded() when success != null:
return success(_that);case SyncFailed() when failure != null:
return failure(_that);case SyncOffline() when offline != null:
return offline(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SyncIdle value)  idle,required TResult Function( SyncRunning value)  syncing,required TResult Function( SyncSucceeded value)  success,required TResult Function( SyncFailed value)  failure,required TResult Function( SyncOffline value)  offline,}){
final _that = this;
switch (_that) {
case SyncIdle():
return idle(_that);case SyncRunning():
return syncing(_that);case SyncSucceeded():
return success(_that);case SyncFailed():
return failure(_that);case SyncOffline():
return offline(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SyncIdle value)?  idle,TResult? Function( SyncRunning value)?  syncing,TResult? Function( SyncSucceeded value)?  success,TResult? Function( SyncFailed value)?  failure,TResult? Function( SyncOffline value)?  offline,}){
final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle(_that);case SyncRunning() when syncing != null:
return syncing(_that);case SyncSucceeded() when success != null:
return success(_that);case SyncFailed() when failure != null:
return failure(_that);case SyncOffline() when offline != null:
return offline(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  syncing,TResult Function( bool hasMore,  List<MutationOutcome> rejectedMutations)?  success,TResult Function( String message)?  failure,TResult Function()?  offline,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle();case SyncRunning() when syncing != null:
return syncing();case SyncSucceeded() when success != null:
return success(_that.hasMore,_that.rejectedMutations);case SyncFailed() when failure != null:
return failure(_that.message);case SyncOffline() when offline != null:
return offline();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  syncing,required TResult Function( bool hasMore,  List<MutationOutcome> rejectedMutations)  success,required TResult Function( String message)  failure,required TResult Function()  offline,}) {final _that = this;
switch (_that) {
case SyncIdle():
return idle();case SyncRunning():
return syncing();case SyncSucceeded():
return success(_that.hasMore,_that.rejectedMutations);case SyncFailed():
return failure(_that.message);case SyncOffline():
return offline();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  syncing,TResult? Function( bool hasMore,  List<MutationOutcome> rejectedMutations)?  success,TResult? Function( String message)?  failure,TResult? Function()?  offline,}) {final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle();case SyncRunning() when syncing != null:
return syncing();case SyncSucceeded() when success != null:
return success(_that.hasMore,_that.rejectedMutations);case SyncFailed() when failure != null:
return failure(_that.message);case SyncOffline() when offline != null:
return offline();case _:
  return null;

}
}

}

/// @nodoc


class SyncIdle implements SyncState {
  const SyncIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.idle()';
}


}




/// @nodoc


class SyncRunning implements SyncState {
  const SyncRunning();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncRunning);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.syncing()';
}


}




/// @nodoc


class SyncSucceeded implements SyncState {
  const SyncSucceeded({this.hasMore = false, final  List<MutationOutcome> rejectedMutations = const <MutationOutcome>[]}): _rejectedMutations = rejectedMutations;
  

@JsonKey() final  bool hasMore;
 final  List<MutationOutcome> _rejectedMutations;
@JsonKey() List<MutationOutcome> get rejectedMutations {
  if (_rejectedMutations is EqualUnmodifiableListView) return _rejectedMutations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rejectedMutations);
}


/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncSucceededCopyWith<SyncSucceeded> get copyWith => _$SyncSucceededCopyWithImpl<SyncSucceeded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncSucceeded&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&const DeepCollectionEquality().equals(other._rejectedMutations, _rejectedMutations));
}


@override
int get hashCode => Object.hash(runtimeType,hasMore,const DeepCollectionEquality().hash(_rejectedMutations));

@override
String toString() {
  return 'SyncState.success(hasMore: $hasMore, rejectedMutations: $rejectedMutations)';
}


}

/// @nodoc
abstract mixin class $SyncSucceededCopyWith<$Res> implements $SyncStateCopyWith<$Res> {
  factory $SyncSucceededCopyWith(SyncSucceeded value, $Res Function(SyncSucceeded) _then) = _$SyncSucceededCopyWithImpl;
@useResult
$Res call({
 bool hasMore, List<MutationOutcome> rejectedMutations
});




}
/// @nodoc
class _$SyncSucceededCopyWithImpl<$Res>
    implements $SyncSucceededCopyWith<$Res> {
  _$SyncSucceededCopyWithImpl(this._self, this._then);

  final SyncSucceeded _self;
  final $Res Function(SyncSucceeded) _then;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hasMore = null,Object? rejectedMutations = null,}) {
  return _then(SyncSucceeded(
hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,rejectedMutations: null == rejectedMutations ? _self._rejectedMutations : rejectedMutations // ignore: cast_nullable_to_non_nullable
as List<MutationOutcome>,
  ));
}


}

/// @nodoc


class SyncFailed implements SyncState {
  const SyncFailed(this.message);
  

 final  String message;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncFailedCopyWith<SyncFailed> get copyWith => _$SyncFailedCopyWithImpl<SyncFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SyncState.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $SyncFailedCopyWith<$Res> implements $SyncStateCopyWith<$Res> {
  factory $SyncFailedCopyWith(SyncFailed value, $Res Function(SyncFailed) _then) = _$SyncFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SyncFailedCopyWithImpl<$Res>
    implements $SyncFailedCopyWith<$Res> {
  _$SyncFailedCopyWithImpl(this._self, this._then);

  final SyncFailed _self;
  final $Res Function(SyncFailed) _then;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SyncFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SyncOffline implements SyncState {
  const SyncOffline();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncOffline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.offline()';
}


}




// dart format on
