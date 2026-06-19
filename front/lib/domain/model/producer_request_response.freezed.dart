// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_request_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProducerRequestResponse {

@JsonKey(name: 'request_id') String get requestId; String get status;
/// Create a copy of ProducerRequestResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestResponseCopyWith<ProducerRequestResponse> get copyWith => _$ProducerRequestResponseCopyWithImpl<ProducerRequestResponse>(this as ProducerRequestResponse, _$identity);

  /// Serializes this ProducerRequestResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestResponse&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,status);

@override
String toString() {
  return 'ProducerRequestResponse(requestId: $requestId, status: $status)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestResponseCopyWith<$Res>  {
  factory $ProducerRequestResponseCopyWith(ProducerRequestResponse value, $Res Function(ProducerRequestResponse) _then) = _$ProducerRequestResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId, String status
});




}
/// @nodoc
class _$ProducerRequestResponseCopyWithImpl<$Res>
    implements $ProducerRequestResponseCopyWith<$Res> {
  _$ProducerRequestResponseCopyWithImpl(this._self, this._then);

  final ProducerRequestResponse _self;
  final $Res Function(ProducerRequestResponse) _then;

/// Create a copy of ProducerRequestResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? status = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProducerRequestResponse].
extension ProducerRequestResponsePatterns on ProducerRequestResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerRequestResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerRequestResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerRequestResponse value)  $default,){
final _that = this;
switch (_that) {
case _ProducerRequestResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerRequestResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerRequestResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerRequestResponse() when $default != null:
return $default(_that.requestId,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId,  String status)  $default,) {final _that = this;
switch (_that) {
case _ProducerRequestResponse():
return $default(_that.requestId,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'request_id')  String requestId,  String status)?  $default,) {final _that = this;
switch (_that) {
case _ProducerRequestResponse() when $default != null:
return $default(_that.requestId,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProducerRequestResponse implements ProducerRequestResponse {
  const _ProducerRequestResponse({@JsonKey(name: 'request_id') required this.requestId, required this.status});
  factory _ProducerRequestResponse.fromJson(Map<String, dynamic> json) => _$ProducerRequestResponseFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override final  String status;

/// Create a copy of ProducerRequestResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerRequestResponseCopyWith<_ProducerRequestResponse> get copyWith => __$ProducerRequestResponseCopyWithImpl<_ProducerRequestResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProducerRequestResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerRequestResponse&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,status);

@override
String toString() {
  return 'ProducerRequestResponse(requestId: $requestId, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ProducerRequestResponseCopyWith<$Res> implements $ProducerRequestResponseCopyWith<$Res> {
  factory _$ProducerRequestResponseCopyWith(_ProducerRequestResponse value, $Res Function(_ProducerRequestResponse) _then) = __$ProducerRequestResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId, String status
});




}
/// @nodoc
class __$ProducerRequestResponseCopyWithImpl<$Res>
    implements _$ProducerRequestResponseCopyWith<$Res> {
  __$ProducerRequestResponseCopyWithImpl(this._self, this._then);

  final _ProducerRequestResponse _self;
  final $Res Function(_ProducerRequestResponse) _then;

/// Create a copy of ProducerRequestResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? status = null,}) {
  return _then(_ProducerRequestResponse(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
