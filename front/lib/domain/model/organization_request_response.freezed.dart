// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_request_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrganizationRequestResponse {

@JsonKey(name: 'request_id') String get requestId; String get status;
/// Create a copy of OrganizationRequestResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationRequestResponseCopyWith<OrganizationRequestResponse> get copyWith => _$OrganizationRequestResponseCopyWithImpl<OrganizationRequestResponse>(this as OrganizationRequestResponse, _$identity);

  /// Serializes this OrganizationRequestResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationRequestResponse&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,status);

@override
String toString() {
  return 'OrganizationRequestResponse(requestId: $requestId, status: $status)';
}


}

/// @nodoc
abstract mixin class $OrganizationRequestResponseCopyWith<$Res>  {
  factory $OrganizationRequestResponseCopyWith(OrganizationRequestResponse value, $Res Function(OrganizationRequestResponse) _then) = _$OrganizationRequestResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId, String status
});




}
/// @nodoc
class _$OrganizationRequestResponseCopyWithImpl<$Res>
    implements $OrganizationRequestResponseCopyWith<$Res> {
  _$OrganizationRequestResponseCopyWithImpl(this._self, this._then);

  final OrganizationRequestResponse _self;
  final $Res Function(OrganizationRequestResponse) _then;

/// Create a copy of OrganizationRequestResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? status = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationRequestResponse].
extension OrganizationRequestResponsePatterns on OrganizationRequestResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationRequestResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationRequestResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationRequestResponse value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationRequestResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationRequestResponse value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationRequestResponse() when $default != null:
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
case _OrganizationRequestResponse() when $default != null:
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
case _OrganizationRequestResponse():
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
case _OrganizationRequestResponse() when $default != null:
return $default(_that.requestId,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrganizationRequestResponse implements OrganizationRequestResponse {
  const _OrganizationRequestResponse({@JsonKey(name: 'request_id') required this.requestId, required this.status});
  factory _OrganizationRequestResponse.fromJson(Map<String, dynamic> json) => _$OrganizationRequestResponseFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override final  String status;

/// Create a copy of OrganizationRequestResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationRequestResponseCopyWith<_OrganizationRequestResponse> get copyWith => __$OrganizationRequestResponseCopyWithImpl<_OrganizationRequestResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrganizationRequestResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationRequestResponse&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,status);

@override
String toString() {
  return 'OrganizationRequestResponse(requestId: $requestId, status: $status)';
}


}

/// @nodoc
abstract mixin class _$OrganizationRequestResponseCopyWith<$Res> implements $OrganizationRequestResponseCopyWith<$Res> {
  factory _$OrganizationRequestResponseCopyWith(_OrganizationRequestResponse value, $Res Function(_OrganizationRequestResponse) _then) = __$OrganizationRequestResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId, String status
});




}
/// @nodoc
class __$OrganizationRequestResponseCopyWithImpl<$Res>
    implements _$OrganizationRequestResponseCopyWith<$Res> {
  __$OrganizationRequestResponseCopyWithImpl(this._self, this._then);

  final _OrganizationRequestResponse _self;
  final $Res Function(_OrganizationRequestResponse) _then;

/// Create a copy of OrganizationRequestResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? status = null,}) {
  return _then(_OrganizationRequestResponse(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
