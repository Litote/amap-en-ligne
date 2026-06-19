// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_join_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberJoinRequest {

@JsonKey(name: 'organization_id') String get organizationId; String get email;@JsonKey(name: 'first_name') String get firstName;@JsonKey(name: 'last_name') String get lastName;
/// Create a copy of MemberJoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberJoinRequestCopyWith<MemberJoinRequest> get copyWith => _$MemberJoinRequestCopyWithImpl<MemberJoinRequest>(this as MemberJoinRequest, _$identity);

  /// Serializes this MemberJoinRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberJoinRequest&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organizationId,email,firstName,lastName);

@override
String toString() {
  return 'MemberJoinRequest(organizationId: $organizationId, email: $email, firstName: $firstName, lastName: $lastName)';
}


}

/// @nodoc
abstract mixin class $MemberJoinRequestCopyWith<$Res>  {
  factory $MemberJoinRequestCopyWith(MemberJoinRequest value, $Res Function(MemberJoinRequest) _then) = _$MemberJoinRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId, String email,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName
});




}
/// @nodoc
class _$MemberJoinRequestCopyWithImpl<$Res>
    implements $MemberJoinRequestCopyWith<$Res> {
  _$MemberJoinRequestCopyWithImpl(this._self, this._then);

  final MemberJoinRequest _self;
  final $Res Function(MemberJoinRequest) _then;

/// Create a copy of MemberJoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? email = null,Object? firstName = null,Object? lastName = null,}) {
  return _then(_self.copyWith(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberJoinRequest].
extension MemberJoinRequestPatterns on MemberJoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberJoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberJoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberJoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _MemberJoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberJoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MemberJoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberJoinRequest() when $default != null:
return $default(_that.organizationId,_that.email,_that.firstName,_that.lastName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName)  $default,) {final _that = this;
switch (_that) {
case _MemberJoinRequest():
return $default(_that.organizationId,_that.email,_that.firstName,_that.lastName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName)?  $default,) {final _that = this;
switch (_that) {
case _MemberJoinRequest() when $default != null:
return $default(_that.organizationId,_that.email,_that.firstName,_that.lastName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberJoinRequest implements MemberJoinRequest {
  const _MemberJoinRequest({@JsonKey(name: 'organization_id') required this.organizationId, required this.email, @JsonKey(name: 'first_name') required this.firstName, @JsonKey(name: 'last_name') required this.lastName});
  factory _MemberJoinRequest.fromJson(Map<String, dynamic> json) => _$MemberJoinRequestFromJson(json);

@override@JsonKey(name: 'organization_id') final  String organizationId;
@override final  String email;
@override@JsonKey(name: 'first_name') final  String firstName;
@override@JsonKey(name: 'last_name') final  String lastName;

/// Create a copy of MemberJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberJoinRequestCopyWith<_MemberJoinRequest> get copyWith => __$MemberJoinRequestCopyWithImpl<_MemberJoinRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberJoinRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberJoinRequest&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organizationId,email,firstName,lastName);

@override
String toString() {
  return 'MemberJoinRequest(organizationId: $organizationId, email: $email, firstName: $firstName, lastName: $lastName)';
}


}

/// @nodoc
abstract mixin class _$MemberJoinRequestCopyWith<$Res> implements $MemberJoinRequestCopyWith<$Res> {
  factory _$MemberJoinRequestCopyWith(_MemberJoinRequest value, $Res Function(_MemberJoinRequest) _then) = __$MemberJoinRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId, String email,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName
});




}
/// @nodoc
class __$MemberJoinRequestCopyWithImpl<$Res>
    implements _$MemberJoinRequestCopyWith<$Res> {
  __$MemberJoinRequestCopyWithImpl(this._self, this._then);

  final _MemberJoinRequest _self;
  final $Res Function(_MemberJoinRequest) _then;

/// Create a copy of MemberJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? email = null,Object? firstName = null,Object? lastName = null,}) {
  return _then(_MemberJoinRequest(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MemberJoinRequestResponse {

@JsonKey(name: 'request_id') String get requestId; String get status;
/// Create a copy of MemberJoinRequestResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberJoinRequestResponseCopyWith<MemberJoinRequestResponse> get copyWith => _$MemberJoinRequestResponseCopyWithImpl<MemberJoinRequestResponse>(this as MemberJoinRequestResponse, _$identity);

  /// Serializes this MemberJoinRequestResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberJoinRequestResponse&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,status);

@override
String toString() {
  return 'MemberJoinRequestResponse(requestId: $requestId, status: $status)';
}


}

/// @nodoc
abstract mixin class $MemberJoinRequestResponseCopyWith<$Res>  {
  factory $MemberJoinRequestResponseCopyWith(MemberJoinRequestResponse value, $Res Function(MemberJoinRequestResponse) _then) = _$MemberJoinRequestResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId, String status
});




}
/// @nodoc
class _$MemberJoinRequestResponseCopyWithImpl<$Res>
    implements $MemberJoinRequestResponseCopyWith<$Res> {
  _$MemberJoinRequestResponseCopyWithImpl(this._self, this._then);

  final MemberJoinRequestResponse _self;
  final $Res Function(MemberJoinRequestResponse) _then;

/// Create a copy of MemberJoinRequestResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? status = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberJoinRequestResponse].
extension MemberJoinRequestResponsePatterns on MemberJoinRequestResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberJoinRequestResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberJoinRequestResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberJoinRequestResponse value)  $default,){
final _that = this;
switch (_that) {
case _MemberJoinRequestResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberJoinRequestResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MemberJoinRequestResponse() when $default != null:
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
case _MemberJoinRequestResponse() when $default != null:
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
case _MemberJoinRequestResponse():
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
case _MemberJoinRequestResponse() when $default != null:
return $default(_that.requestId,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberJoinRequestResponse implements MemberJoinRequestResponse {
  const _MemberJoinRequestResponse({@JsonKey(name: 'request_id') required this.requestId, required this.status});
  factory _MemberJoinRequestResponse.fromJson(Map<String, dynamic> json) => _$MemberJoinRequestResponseFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override final  String status;

/// Create a copy of MemberJoinRequestResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberJoinRequestResponseCopyWith<_MemberJoinRequestResponse> get copyWith => __$MemberJoinRequestResponseCopyWithImpl<_MemberJoinRequestResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberJoinRequestResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberJoinRequestResponse&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,status);

@override
String toString() {
  return 'MemberJoinRequestResponse(requestId: $requestId, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MemberJoinRequestResponseCopyWith<$Res> implements $MemberJoinRequestResponseCopyWith<$Res> {
  factory _$MemberJoinRequestResponseCopyWith(_MemberJoinRequestResponse value, $Res Function(_MemberJoinRequestResponse) _then) = __$MemberJoinRequestResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId, String status
});




}
/// @nodoc
class __$MemberJoinRequestResponseCopyWithImpl<$Res>
    implements _$MemberJoinRequestResponseCopyWith<$Res> {
  __$MemberJoinRequestResponseCopyWithImpl(this._self, this._then);

  final _MemberJoinRequestResponse _self;
  final $Res Function(_MemberJoinRequestResponse) _then;

/// Create a copy of MemberJoinRequestResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? status = null,}) {
  return _then(_MemberJoinRequestResponse(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
