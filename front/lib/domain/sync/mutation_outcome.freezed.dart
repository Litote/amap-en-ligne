// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mutation_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MutationOutcome {

@JsonKey(name: 'client_op_id') String get clientOpId; MutationStatus get status;@JsonKey(name: 'server_entity_id') String? get serverEntityId; MutationError? get error;
/// Create a copy of MutationOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationOutcomeCopyWith<MutationOutcome> get copyWith => _$MutationOutcomeCopyWithImpl<MutationOutcome>(this as MutationOutcome, _$identity);

  /// Serializes this MutationOutcome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationOutcome&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.status, status) || other.status == status)&&(identical(other.serverEntityId, serverEntityId) || other.serverEntityId == serverEntityId)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientOpId,status,serverEntityId,error);

@override
String toString() {
  return 'MutationOutcome(clientOpId: $clientOpId, status: $status, serverEntityId: $serverEntityId, error: $error)';
}


}

/// @nodoc
abstract mixin class $MutationOutcomeCopyWith<$Res>  {
  factory $MutationOutcomeCopyWith(MutationOutcome value, $Res Function(MutationOutcome) _then) = _$MutationOutcomeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'client_op_id') String clientOpId, MutationStatus status,@JsonKey(name: 'server_entity_id') String? serverEntityId, MutationError? error
});


$MutationErrorCopyWith<$Res>? get error;

}
/// @nodoc
class _$MutationOutcomeCopyWithImpl<$Res>
    implements $MutationOutcomeCopyWith<$Res> {
  _$MutationOutcomeCopyWithImpl(this._self, this._then);

  final MutationOutcome _self;
  final $Res Function(MutationOutcome) _then;

/// Create a copy of MutationOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientOpId = null,Object? status = null,Object? serverEntityId = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MutationStatus,serverEntityId: freezed == serverEntityId ? _self.serverEntityId : serverEntityId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as MutationError?,
  ));
}
/// Create a copy of MutationOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MutationErrorCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $MutationErrorCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// Adds pattern-matching-related methods to [MutationOutcome].
extension MutationOutcomePatterns on MutationOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MutationOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MutationOutcome() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MutationOutcome value)  $default,){
final _that = this;
switch (_that) {
case _MutationOutcome():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MutationOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _MutationOutcome() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'client_op_id')  String clientOpId,  MutationStatus status, @JsonKey(name: 'server_entity_id')  String? serverEntityId,  MutationError? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MutationOutcome() when $default != null:
return $default(_that.clientOpId,_that.status,_that.serverEntityId,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'client_op_id')  String clientOpId,  MutationStatus status, @JsonKey(name: 'server_entity_id')  String? serverEntityId,  MutationError? error)  $default,) {final _that = this;
switch (_that) {
case _MutationOutcome():
return $default(_that.clientOpId,_that.status,_that.serverEntityId,_that.error);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'client_op_id')  String clientOpId,  MutationStatus status, @JsonKey(name: 'server_entity_id')  String? serverEntityId,  MutationError? error)?  $default,) {final _that = this;
switch (_that) {
case _MutationOutcome() when $default != null:
return $default(_that.clientOpId,_that.status,_that.serverEntityId,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MutationOutcome implements MutationOutcome {
  const _MutationOutcome({@JsonKey(name: 'client_op_id') required this.clientOpId, required this.status, @JsonKey(name: 'server_entity_id') this.serverEntityId, this.error});
  factory _MutationOutcome.fromJson(Map<String, dynamic> json) => _$MutationOutcomeFromJson(json);

@override@JsonKey(name: 'client_op_id') final  String clientOpId;
@override final  MutationStatus status;
@override@JsonKey(name: 'server_entity_id') final  String? serverEntityId;
@override final  MutationError? error;

/// Create a copy of MutationOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MutationOutcomeCopyWith<_MutationOutcome> get copyWith => __$MutationOutcomeCopyWithImpl<_MutationOutcome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MutationOutcomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MutationOutcome&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.status, status) || other.status == status)&&(identical(other.serverEntityId, serverEntityId) || other.serverEntityId == serverEntityId)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientOpId,status,serverEntityId,error);

@override
String toString() {
  return 'MutationOutcome(clientOpId: $clientOpId, status: $status, serverEntityId: $serverEntityId, error: $error)';
}


}

/// @nodoc
abstract mixin class _$MutationOutcomeCopyWith<$Res> implements $MutationOutcomeCopyWith<$Res> {
  factory _$MutationOutcomeCopyWith(_MutationOutcome value, $Res Function(_MutationOutcome) _then) = __$MutationOutcomeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'client_op_id') String clientOpId, MutationStatus status,@JsonKey(name: 'server_entity_id') String? serverEntityId, MutationError? error
});


@override $MutationErrorCopyWith<$Res>? get error;

}
/// @nodoc
class __$MutationOutcomeCopyWithImpl<$Res>
    implements _$MutationOutcomeCopyWith<$Res> {
  __$MutationOutcomeCopyWithImpl(this._self, this._then);

  final _MutationOutcome _self;
  final $Res Function(_MutationOutcome) _then;

/// Create a copy of MutationOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientOpId = null,Object? status = null,Object? serverEntityId = freezed,Object? error = freezed,}) {
  return _then(_MutationOutcome(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MutationStatus,serverEntityId: freezed == serverEntityId ? _self.serverEntityId : serverEntityId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as MutationError?,
  ));
}

/// Create a copy of MutationOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MutationErrorCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $MutationErrorCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// @nodoc
mixin _$MutationError {

 MutationErrorCode get code; String get message;
/// Create a copy of MutationError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationErrorCopyWith<MutationError> get copyWith => _$MutationErrorCopyWithImpl<MutationError>(this as MutationError, _$identity);

  /// Serializes this MutationError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'MutationError(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $MutationErrorCopyWith<$Res>  {
  factory $MutationErrorCopyWith(MutationError value, $Res Function(MutationError) _then) = _$MutationErrorCopyWithImpl;
@useResult
$Res call({
 MutationErrorCode code, String message
});




}
/// @nodoc
class _$MutationErrorCopyWithImpl<$Res>
    implements $MutationErrorCopyWith<$Res> {
  _$MutationErrorCopyWithImpl(this._self, this._then);

  final MutationError _self;
  final $Res Function(MutationError) _then;

/// Create a copy of MutationError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as MutationErrorCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MutationError].
extension MutationErrorPatterns on MutationError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MutationError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MutationError() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MutationError value)  $default,){
final _that = this;
switch (_that) {
case _MutationError():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MutationError value)?  $default,){
final _that = this;
switch (_that) {
case _MutationError() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MutationErrorCode code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MutationError() when $default != null:
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MutationErrorCode code,  String message)  $default,) {final _that = this;
switch (_that) {
case _MutationError():
return $default(_that.code,_that.message);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MutationErrorCode code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _MutationError() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MutationError implements MutationError {
  const _MutationError({required this.code, required this.message});
  factory _MutationError.fromJson(Map<String, dynamic> json) => _$MutationErrorFromJson(json);

@override final  MutationErrorCode code;
@override final  String message;

/// Create a copy of MutationError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MutationErrorCopyWith<_MutationError> get copyWith => __$MutationErrorCopyWithImpl<_MutationError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MutationErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MutationError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'MutationError(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$MutationErrorCopyWith<$Res> implements $MutationErrorCopyWith<$Res> {
  factory _$MutationErrorCopyWith(_MutationError value, $Res Function(_MutationError) _then) = __$MutationErrorCopyWithImpl;
@override @useResult
$Res call({
 MutationErrorCode code, String message
});




}
/// @nodoc
class __$MutationErrorCopyWithImpl<$Res>
    implements _$MutationErrorCopyWith<$Res> {
  __$MutationErrorCopyWithImpl(this._self, this._then);

  final _MutationError _self;
  final $Res Function(_MutationError) _then;

/// Create a copy of MutationError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(_MutationError(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as MutationErrorCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
