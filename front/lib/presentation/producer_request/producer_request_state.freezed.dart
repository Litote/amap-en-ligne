// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_request_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProducerRequestState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerRequestState()';
}


}

/// @nodoc
class $ProducerRequestStateCopyWith<$Res>  {
$ProducerRequestStateCopyWith(ProducerRequestState _, $Res Function(ProducerRequestState) __);
}


/// Adds pattern-matching-related methods to [ProducerRequestState].
extension ProducerRequestStatePatterns on ProducerRequestState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProducerRequestInitial value)?  initial,TResult Function( ProducerRequestSubmitting value)?  submitting,TResult Function( ProducerRequestSuccess value)?  success,TResult Function( ProducerRequestError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProducerRequestInitial() when initial != null:
return initial(_that);case ProducerRequestSubmitting() when submitting != null:
return submitting(_that);case ProducerRequestSuccess() when success != null:
return success(_that);case ProducerRequestError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProducerRequestInitial value)  initial,required TResult Function( ProducerRequestSubmitting value)  submitting,required TResult Function( ProducerRequestSuccess value)  success,required TResult Function( ProducerRequestError value)  error,}){
final _that = this;
switch (_that) {
case ProducerRequestInitial():
return initial(_that);case ProducerRequestSubmitting():
return submitting(_that);case ProducerRequestSuccess():
return success(_that);case ProducerRequestError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProducerRequestInitial value)?  initial,TResult? Function( ProducerRequestSubmitting value)?  submitting,TResult? Function( ProducerRequestSuccess value)?  success,TResult? Function( ProducerRequestError value)?  error,}){
final _that = this;
switch (_that) {
case ProducerRequestInitial() when initial != null:
return initial(_that);case ProducerRequestSubmitting() when submitting != null:
return submitting(_that);case ProducerRequestSuccess() when success != null:
return success(_that);case ProducerRequestError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( ProducerRequestResponse response)?  success,TResult Function( String message,  ProducerConflictField? conflictField)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProducerRequestInitial() when initial != null:
return initial();case ProducerRequestSubmitting() when submitting != null:
return submitting();case ProducerRequestSuccess() when success != null:
return success(_that.response);case ProducerRequestError() when error != null:
return error(_that.message,_that.conflictField);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( ProducerRequestResponse response)  success,required TResult Function( String message,  ProducerConflictField? conflictField)  error,}) {final _that = this;
switch (_that) {
case ProducerRequestInitial():
return initial();case ProducerRequestSubmitting():
return submitting();case ProducerRequestSuccess():
return success(_that.response);case ProducerRequestError():
return error(_that.message,_that.conflictField);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( ProducerRequestResponse response)?  success,TResult? Function( String message,  ProducerConflictField? conflictField)?  error,}) {final _that = this;
switch (_that) {
case ProducerRequestInitial() when initial != null:
return initial();case ProducerRequestSubmitting() when submitting != null:
return submitting();case ProducerRequestSuccess() when success != null:
return success(_that.response);case ProducerRequestError() when error != null:
return error(_that.message,_that.conflictField);case _:
  return null;

}
}

}

/// @nodoc


class ProducerRequestInitial implements ProducerRequestState {
  const ProducerRequestInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerRequestState.initial()';
}


}




/// @nodoc


class ProducerRequestSubmitting implements ProducerRequestState {
  const ProducerRequestSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerRequestState.submitting()';
}


}




/// @nodoc


class ProducerRequestSuccess implements ProducerRequestState {
  const ProducerRequestSuccess({required this.response});
  

 final  ProducerRequestResponse response;

/// Create a copy of ProducerRequestState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestSuccessCopyWith<ProducerRequestSuccess> get copyWith => _$ProducerRequestSuccessCopyWithImpl<ProducerRequestSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestSuccess&&(identical(other.response, response) || other.response == response));
}


@override
int get hashCode => Object.hash(runtimeType,response);

@override
String toString() {
  return 'ProducerRequestState.success(response: $response)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestSuccessCopyWith<$Res> implements $ProducerRequestStateCopyWith<$Res> {
  factory $ProducerRequestSuccessCopyWith(ProducerRequestSuccess value, $Res Function(ProducerRequestSuccess) _then) = _$ProducerRequestSuccessCopyWithImpl;
@useResult
$Res call({
 ProducerRequestResponse response
});


$ProducerRequestResponseCopyWith<$Res> get response;

}
/// @nodoc
class _$ProducerRequestSuccessCopyWithImpl<$Res>
    implements $ProducerRequestSuccessCopyWith<$Res> {
  _$ProducerRequestSuccessCopyWithImpl(this._self, this._then);

  final ProducerRequestSuccess _self;
  final $Res Function(ProducerRequestSuccess) _then;

/// Create a copy of ProducerRequestState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? response = null,}) {
  return _then(ProducerRequestSuccess(
response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as ProducerRequestResponse,
  ));
}

/// Create a copy of ProducerRequestState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProducerRequestResponseCopyWith<$Res> get response {
  
  return $ProducerRequestResponseCopyWith<$Res>(_self.response, (value) {
    return _then(_self.copyWith(response: value));
  });
}
}

/// @nodoc


class ProducerRequestError implements ProducerRequestState {
  const ProducerRequestError({required this.message, this.conflictField});
  

 final  String message;
 final  ProducerConflictField? conflictField;

/// Create a copy of ProducerRequestState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestErrorCopyWith<ProducerRequestError> get copyWith => _$ProducerRequestErrorCopyWithImpl<ProducerRequestError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestError&&(identical(other.message, message) || other.message == message)&&(identical(other.conflictField, conflictField) || other.conflictField == conflictField));
}


@override
int get hashCode => Object.hash(runtimeType,message,conflictField);

@override
String toString() {
  return 'ProducerRequestState.error(message: $message, conflictField: $conflictField)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestErrorCopyWith<$Res> implements $ProducerRequestStateCopyWith<$Res> {
  factory $ProducerRequestErrorCopyWith(ProducerRequestError value, $Res Function(ProducerRequestError) _then) = _$ProducerRequestErrorCopyWithImpl;
@useResult
$Res call({
 String message, ProducerConflictField? conflictField
});




}
/// @nodoc
class _$ProducerRequestErrorCopyWithImpl<$Res>
    implements $ProducerRequestErrorCopyWith<$Res> {
  _$ProducerRequestErrorCopyWithImpl(this._self, this._then);

  final ProducerRequestError _self;
  final $Res Function(ProducerRequestError) _then;

/// Create a copy of ProducerRequestState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? conflictField = freezed,}) {
  return _then(ProducerRequestError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,conflictField: freezed == conflictField ? _self.conflictField : conflictField // ignore: cast_nullable_to_non_nullable
as ProducerConflictField?,
  ));
}


}

// dart format on
