// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncOutcome()';
}


}

/// @nodoc
class $SyncOutcomeCopyWith<$Res>  {
$SyncOutcomeCopyWith(SyncOutcome _, $Res Function(SyncOutcome) __);
}


/// Adds pattern-matching-related methods to [SyncOutcome].
extension SyncOutcomePatterns on SyncOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SyncSuccess value)?  success,TResult Function( SyncFailure value)?  failure,TResult Function( SyncNetworkFailure value)?  networkFailure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SyncSuccess() when success != null:
return success(_that);case SyncFailure() when failure != null:
return failure(_that);case SyncNetworkFailure() when networkFailure != null:
return networkFailure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SyncSuccess value)  success,required TResult Function( SyncFailure value)  failure,required TResult Function( SyncNetworkFailure value)  networkFailure,}){
final _that = this;
switch (_that) {
case SyncSuccess():
return success(_that);case SyncFailure():
return failure(_that);case SyncNetworkFailure():
return networkFailure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SyncSuccess value)?  success,TResult? Function( SyncFailure value)?  failure,TResult? Function( SyncNetworkFailure value)?  networkFailure,}){
final _that = this;
switch (_that) {
case SyncSuccess() when success != null:
return success(_that);case SyncFailure() when failure != null:
return failure(_that);case SyncNetworkFailure() when networkFailure != null:
return networkFailure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool hasMore,  List<MutationOutcome> rejectedMutations,  bool memberOrOwnerUpdated)?  success,TResult Function( String message)?  failure,TResult Function()?  networkFailure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SyncSuccess() when success != null:
return success(_that.hasMore,_that.rejectedMutations,_that.memberOrOwnerUpdated);case SyncFailure() when failure != null:
return failure(_that.message);case SyncNetworkFailure() when networkFailure != null:
return networkFailure();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool hasMore,  List<MutationOutcome> rejectedMutations,  bool memberOrOwnerUpdated)  success,required TResult Function( String message)  failure,required TResult Function()  networkFailure,}) {final _that = this;
switch (_that) {
case SyncSuccess():
return success(_that.hasMore,_that.rejectedMutations,_that.memberOrOwnerUpdated);case SyncFailure():
return failure(_that.message);case SyncNetworkFailure():
return networkFailure();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool hasMore,  List<MutationOutcome> rejectedMutations,  bool memberOrOwnerUpdated)?  success,TResult? Function( String message)?  failure,TResult? Function()?  networkFailure,}) {final _that = this;
switch (_that) {
case SyncSuccess() when success != null:
return success(_that.hasMore,_that.rejectedMutations,_that.memberOrOwnerUpdated);case SyncFailure() when failure != null:
return failure(_that.message);case SyncNetworkFailure() when networkFailure != null:
return networkFailure();case _:
  return null;

}
}

}

/// @nodoc


class SyncSuccess implements SyncOutcome {
  const SyncSuccess({this.hasMore = false, final  List<MutationOutcome> rejectedMutations = const <MutationOutcome>[], this.memberOrOwnerUpdated = false}): _rejectedMutations = rejectedMutations;
  

@JsonKey() final  bool hasMore;
 final  List<MutationOutcome> _rejectedMutations;
@JsonKey() List<MutationOutcome> get rejectedMutations {
  if (_rejectedMutations is EqualUnmodifiableListView) return _rejectedMutations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rejectedMutations);
}

@JsonKey() final  bool memberOrOwnerUpdated;

/// Create a copy of SyncOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncSuccessCopyWith<SyncSuccess> get copyWith => _$SyncSuccessCopyWithImpl<SyncSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncSuccess&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&const DeepCollectionEquality().equals(other._rejectedMutations, _rejectedMutations)&&(identical(other.memberOrOwnerUpdated, memberOrOwnerUpdated) || other.memberOrOwnerUpdated == memberOrOwnerUpdated));
}


@override
int get hashCode => Object.hash(runtimeType,hasMore,const DeepCollectionEquality().hash(_rejectedMutations),memberOrOwnerUpdated);

@override
String toString() {
  return 'SyncOutcome.success(hasMore: $hasMore, rejectedMutations: $rejectedMutations, memberOrOwnerUpdated: $memberOrOwnerUpdated)';
}


}

/// @nodoc
abstract mixin class $SyncSuccessCopyWith<$Res> implements $SyncOutcomeCopyWith<$Res> {
  factory $SyncSuccessCopyWith(SyncSuccess value, $Res Function(SyncSuccess) _then) = _$SyncSuccessCopyWithImpl;
@useResult
$Res call({
 bool hasMore, List<MutationOutcome> rejectedMutations, bool memberOrOwnerUpdated
});




}
/// @nodoc
class _$SyncSuccessCopyWithImpl<$Res>
    implements $SyncSuccessCopyWith<$Res> {
  _$SyncSuccessCopyWithImpl(this._self, this._then);

  final SyncSuccess _self;
  final $Res Function(SyncSuccess) _then;

/// Create a copy of SyncOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hasMore = null,Object? rejectedMutations = null,Object? memberOrOwnerUpdated = null,}) {
  return _then(SyncSuccess(
hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,rejectedMutations: null == rejectedMutations ? _self._rejectedMutations : rejectedMutations // ignore: cast_nullable_to_non_nullable
as List<MutationOutcome>,memberOrOwnerUpdated: null == memberOrOwnerUpdated ? _self.memberOrOwnerUpdated : memberOrOwnerUpdated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class SyncFailure implements SyncOutcome {
  const SyncFailure(this.message);
  

 final  String message;

/// Create a copy of SyncOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncFailureCopyWith<SyncFailure> get copyWith => _$SyncFailureCopyWithImpl<SyncFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SyncOutcome.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $SyncFailureCopyWith<$Res> implements $SyncOutcomeCopyWith<$Res> {
  factory $SyncFailureCopyWith(SyncFailure value, $Res Function(SyncFailure) _then) = _$SyncFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SyncFailureCopyWithImpl<$Res>
    implements $SyncFailureCopyWith<$Res> {
  _$SyncFailureCopyWithImpl(this._self, this._then);

  final SyncFailure _self;
  final $Res Function(SyncFailure) _then;

/// Create a copy of SyncOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SyncFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SyncNetworkFailure implements SyncOutcome {
  const SyncNetworkFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncNetworkFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncOutcome.networkFailure()';
}


}




// dart format on
