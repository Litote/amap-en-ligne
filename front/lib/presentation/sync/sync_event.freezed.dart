// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent()';
}


}

/// @nodoc
class $SyncEventCopyWith<$Res>  {
$SyncEventCopyWith(SyncEvent _, $Res Function(SyncEvent) __);
}


/// Adds pattern-matching-related methods to [SyncEvent].
extension SyncEventPatterns on SyncEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SyncRequested value)?  requested,TResult Function( SyncStarted value)?  started,TResult Function( ConnectivityRestored value)?  connectivityRestored,TResult Function( MutationApplied value)?  mutationApplied,TResult Function( FullSyncRequested value)?  fullSyncRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SyncRequested() when requested != null:
return requested(_that);case SyncStarted() when started != null:
return started(_that);case ConnectivityRestored() when connectivityRestored != null:
return connectivityRestored(_that);case MutationApplied() when mutationApplied != null:
return mutationApplied(_that);case FullSyncRequested() when fullSyncRequested != null:
return fullSyncRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SyncRequested value)  requested,required TResult Function( SyncStarted value)  started,required TResult Function( ConnectivityRestored value)  connectivityRestored,required TResult Function( MutationApplied value)  mutationApplied,required TResult Function( FullSyncRequested value)  fullSyncRequested,}){
final _that = this;
switch (_that) {
case SyncRequested():
return requested(_that);case SyncStarted():
return started(_that);case ConnectivityRestored():
return connectivityRestored(_that);case MutationApplied():
return mutationApplied(_that);case FullSyncRequested():
return fullSyncRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SyncRequested value)?  requested,TResult? Function( SyncStarted value)?  started,TResult? Function( ConnectivityRestored value)?  connectivityRestored,TResult? Function( MutationApplied value)?  mutationApplied,TResult? Function( FullSyncRequested value)?  fullSyncRequested,}){
final _that = this;
switch (_that) {
case SyncRequested() when requested != null:
return requested(_that);case SyncStarted() when started != null:
return started(_that);case ConnectivityRestored() when connectivityRestored != null:
return connectivityRestored(_that);case MutationApplied() when mutationApplied != null:
return mutationApplied(_that);case FullSyncRequested() when fullSyncRequested != null:
return fullSyncRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  requested,TResult Function()?  started,TResult Function()?  connectivityRestored,TResult Function()?  mutationApplied,TResult Function()?  fullSyncRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SyncRequested() when requested != null:
return requested();case SyncStarted() when started != null:
return started();case ConnectivityRestored() when connectivityRestored != null:
return connectivityRestored();case MutationApplied() when mutationApplied != null:
return mutationApplied();case FullSyncRequested() when fullSyncRequested != null:
return fullSyncRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  requested,required TResult Function()  started,required TResult Function()  connectivityRestored,required TResult Function()  mutationApplied,required TResult Function()  fullSyncRequested,}) {final _that = this;
switch (_that) {
case SyncRequested():
return requested();case SyncStarted():
return started();case ConnectivityRestored():
return connectivityRestored();case MutationApplied():
return mutationApplied();case FullSyncRequested():
return fullSyncRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  requested,TResult? Function()?  started,TResult? Function()?  connectivityRestored,TResult? Function()?  mutationApplied,TResult? Function()?  fullSyncRequested,}) {final _that = this;
switch (_that) {
case SyncRequested() when requested != null:
return requested();case SyncStarted() when started != null:
return started();case ConnectivityRestored() when connectivityRestored != null:
return connectivityRestored();case MutationApplied() when mutationApplied != null:
return mutationApplied();case FullSyncRequested() when fullSyncRequested != null:
return fullSyncRequested();case _:
  return null;

}
}

}

/// @nodoc


class SyncRequested implements SyncEvent {
  const SyncRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent.requested()';
}


}




/// @nodoc


class SyncStarted implements SyncEvent {
  const SyncStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent.started()';
}


}




/// @nodoc


class ConnectivityRestored implements SyncEvent {
  const ConnectivityRestored();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectivityRestored);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent.connectivityRestored()';
}


}




/// @nodoc


class MutationApplied implements SyncEvent {
  const MutationApplied();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationApplied);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent.mutationApplied()';
}


}




/// @nodoc


class FullSyncRequested implements SyncEvent {
  const FullSyncRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FullSyncRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent.fullSyncRequested()';
}


}




// dart format on
