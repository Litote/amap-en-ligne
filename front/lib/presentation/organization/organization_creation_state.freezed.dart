// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_creation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationCreationState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationCreationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrganizationCreationState()';
}


}

/// @nodoc
class $OrganizationCreationStateCopyWith<$Res>  {
$OrganizationCreationStateCopyWith(OrganizationCreationState _, $Res Function(OrganizationCreationState) __);
}


/// Adds pattern-matching-related methods to [OrganizationCreationState].
extension OrganizationCreationStatePatterns on OrganizationCreationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrganizationCreationInitial value)?  initial,TResult Function( OrganizationCreationSubmitting value)?  submitting,TResult Function( OrganizationCreationSuccess value)?  success,TResult Function( OrganizationCreationError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrganizationCreationInitial() when initial != null:
return initial(_that);case OrganizationCreationSubmitting() when submitting != null:
return submitting(_that);case OrganizationCreationSuccess() when success != null:
return success(_that);case OrganizationCreationError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrganizationCreationInitial value)  initial,required TResult Function( OrganizationCreationSubmitting value)  submitting,required TResult Function( OrganizationCreationSuccess value)  success,required TResult Function( OrganizationCreationError value)  error,}){
final _that = this;
switch (_that) {
case OrganizationCreationInitial():
return initial(_that);case OrganizationCreationSubmitting():
return submitting(_that);case OrganizationCreationSuccess():
return success(_that);case OrganizationCreationError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrganizationCreationInitial value)?  initial,TResult? Function( OrganizationCreationSubmitting value)?  submitting,TResult? Function( OrganizationCreationSuccess value)?  success,TResult? Function( OrganizationCreationError value)?  error,}){
final _that = this;
switch (_that) {
case OrganizationCreationInitial() when initial != null:
return initial(_that);case OrganizationCreationSubmitting() when submitting != null:
return submitting(_that);case OrganizationCreationSuccess() when success != null:
return success(_that);case OrganizationCreationError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( OrganizationRequestResponse response)?  success,TResult Function( String message,  OrganizationConflictField? conflictField)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrganizationCreationInitial() when initial != null:
return initial();case OrganizationCreationSubmitting() when submitting != null:
return submitting();case OrganizationCreationSuccess() when success != null:
return success(_that.response);case OrganizationCreationError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( OrganizationRequestResponse response)  success,required TResult Function( String message,  OrganizationConflictField? conflictField)  error,}) {final _that = this;
switch (_that) {
case OrganizationCreationInitial():
return initial();case OrganizationCreationSubmitting():
return submitting();case OrganizationCreationSuccess():
return success(_that.response);case OrganizationCreationError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( OrganizationRequestResponse response)?  success,TResult? Function( String message,  OrganizationConflictField? conflictField)?  error,}) {final _that = this;
switch (_that) {
case OrganizationCreationInitial() when initial != null:
return initial();case OrganizationCreationSubmitting() when submitting != null:
return submitting();case OrganizationCreationSuccess() when success != null:
return success(_that.response);case OrganizationCreationError() when error != null:
return error(_that.message,_that.conflictField);case _:
  return null;

}
}

}

/// @nodoc


class OrganizationCreationInitial implements OrganizationCreationState {
  const OrganizationCreationInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationCreationInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrganizationCreationState.initial()';
}


}




/// @nodoc


class OrganizationCreationSubmitting implements OrganizationCreationState {
  const OrganizationCreationSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationCreationSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrganizationCreationState.submitting()';
}


}




/// @nodoc


class OrganizationCreationSuccess implements OrganizationCreationState {
  const OrganizationCreationSuccess({required this.response});
  

 final  OrganizationRequestResponse response;

/// Create a copy of OrganizationCreationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationCreationSuccessCopyWith<OrganizationCreationSuccess> get copyWith => _$OrganizationCreationSuccessCopyWithImpl<OrganizationCreationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationCreationSuccess&&(identical(other.response, response) || other.response == response));
}


@override
int get hashCode => Object.hash(runtimeType,response);

@override
String toString() {
  return 'OrganizationCreationState.success(response: $response)';
}


}

/// @nodoc
abstract mixin class $OrganizationCreationSuccessCopyWith<$Res> implements $OrganizationCreationStateCopyWith<$Res> {
  factory $OrganizationCreationSuccessCopyWith(OrganizationCreationSuccess value, $Res Function(OrganizationCreationSuccess) _then) = _$OrganizationCreationSuccessCopyWithImpl;
@useResult
$Res call({
 OrganizationRequestResponse response
});


$OrganizationRequestResponseCopyWith<$Res> get response;

}
/// @nodoc
class _$OrganizationCreationSuccessCopyWithImpl<$Res>
    implements $OrganizationCreationSuccessCopyWith<$Res> {
  _$OrganizationCreationSuccessCopyWithImpl(this._self, this._then);

  final OrganizationCreationSuccess _self;
  final $Res Function(OrganizationCreationSuccess) _then;

/// Create a copy of OrganizationCreationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? response = null,}) {
  return _then(OrganizationCreationSuccess(
response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as OrganizationRequestResponse,
  ));
}

/// Create a copy of OrganizationCreationState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationRequestResponseCopyWith<$Res> get response {
  
  return $OrganizationRequestResponseCopyWith<$Res>(_self.response, (value) {
    return _then(_self.copyWith(response: value));
  });
}
}

/// @nodoc


class OrganizationCreationError implements OrganizationCreationState {
  const OrganizationCreationError({required this.message, this.conflictField});
  

 final  String message;
 final  OrganizationConflictField? conflictField;

/// Create a copy of OrganizationCreationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationCreationErrorCopyWith<OrganizationCreationError> get copyWith => _$OrganizationCreationErrorCopyWithImpl<OrganizationCreationError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationCreationError&&(identical(other.message, message) || other.message == message)&&(identical(other.conflictField, conflictField) || other.conflictField == conflictField));
}


@override
int get hashCode => Object.hash(runtimeType,message,conflictField);

@override
String toString() {
  return 'OrganizationCreationState.error(message: $message, conflictField: $conflictField)';
}


}

/// @nodoc
abstract mixin class $OrganizationCreationErrorCopyWith<$Res> implements $OrganizationCreationStateCopyWith<$Res> {
  factory $OrganizationCreationErrorCopyWith(OrganizationCreationError value, $Res Function(OrganizationCreationError) _then) = _$OrganizationCreationErrorCopyWithImpl;
@useResult
$Res call({
 String message, OrganizationConflictField? conflictField
});




}
/// @nodoc
class _$OrganizationCreationErrorCopyWithImpl<$Res>
    implements $OrganizationCreationErrorCopyWith<$Res> {
  _$OrganizationCreationErrorCopyWithImpl(this._self, this._then);

  final OrganizationCreationError _self;
  final $Res Function(OrganizationCreationError) _then;

/// Create a copy of OrganizationCreationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? conflictField = freezed,}) {
  return _then(OrganizationCreationError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,conflictField: freezed == conflictField ? _self.conflictField : conflictField // ignore: cast_nullable_to_non_nullable
as OrganizationConflictField?,
  ));
}


}

// dart format on
