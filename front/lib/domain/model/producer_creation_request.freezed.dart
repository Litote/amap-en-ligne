// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_creation_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProducerCreationRequest {

@JsonKey(name: 'producer_name') String get producerName;@JsonKey(name: 'admin_first_name') String get adminFirstName;@JsonKey(name: 'admin_last_name') String get adminLastName;@JsonKey(name: 'admin_email') String get adminEmail;@JsonKey(name: 'submitter_comment') String? get submitterComment;
/// Create a copy of ProducerCreationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerCreationRequestCopyWith<ProducerCreationRequest> get copyWith => _$ProducerCreationRequestCopyWithImpl<ProducerCreationRequest>(this as ProducerCreationRequest, _$identity);

  /// Serializes this ProducerCreationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerCreationRequest&&(identical(other.producerName, producerName) || other.producerName == producerName)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,producerName,adminFirstName,adminLastName,adminEmail,submitterComment);

@override
String toString() {
  return 'ProducerCreationRequest(producerName: $producerName, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, submitterComment: $submitterComment)';
}


}

/// @nodoc
abstract mixin class $ProducerCreationRequestCopyWith<$Res>  {
  factory $ProducerCreationRequestCopyWith(ProducerCreationRequest value, $Res Function(ProducerCreationRequest) _then) = _$ProducerCreationRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'producer_name') String producerName,@JsonKey(name: 'admin_first_name') String adminFirstName,@JsonKey(name: 'admin_last_name') String adminLastName,@JsonKey(name: 'admin_email') String adminEmail,@JsonKey(name: 'submitter_comment') String? submitterComment
});




}
/// @nodoc
class _$ProducerCreationRequestCopyWithImpl<$Res>
    implements $ProducerCreationRequestCopyWith<$Res> {
  _$ProducerCreationRequestCopyWithImpl(this._self, this._then);

  final ProducerCreationRequest _self;
  final $Res Function(ProducerCreationRequest) _then;

/// Create a copy of ProducerCreationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? producerName = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? submitterComment = freezed,}) {
  return _then(_self.copyWith(
producerName: null == producerName ? _self.producerName : producerName // ignore: cast_nullable_to_non_nullable
as String,adminFirstName: null == adminFirstName ? _self.adminFirstName : adminFirstName // ignore: cast_nullable_to_non_nullable
as String,adminLastName: null == adminLastName ? _self.adminLastName : adminLastName // ignore: cast_nullable_to_non_nullable
as String,adminEmail: null == adminEmail ? _self.adminEmail : adminEmail // ignore: cast_nullable_to_non_nullable
as String,submitterComment: freezed == submitterComment ? _self.submitterComment : submitterComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProducerCreationRequest].
extension ProducerCreationRequestPatterns on ProducerCreationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerCreationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerCreationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerCreationRequest value)  $default,){
final _that = this;
switch (_that) {
case _ProducerCreationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerCreationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerCreationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'producer_name')  String producerName, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail, @JsonKey(name: 'submitter_comment')  String? submitterComment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerCreationRequest() when $default != null:
return $default(_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.submitterComment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'producer_name')  String producerName, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail, @JsonKey(name: 'submitter_comment')  String? submitterComment)  $default,) {final _that = this;
switch (_that) {
case _ProducerCreationRequest():
return $default(_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.submitterComment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'producer_name')  String producerName, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail, @JsonKey(name: 'submitter_comment')  String? submitterComment)?  $default,) {final _that = this;
switch (_that) {
case _ProducerCreationRequest() when $default != null:
return $default(_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.submitterComment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProducerCreationRequest implements ProducerCreationRequest {
  const _ProducerCreationRequest({@JsonKey(name: 'producer_name') required this.producerName, @JsonKey(name: 'admin_first_name') required this.adminFirstName, @JsonKey(name: 'admin_last_name') required this.adminLastName, @JsonKey(name: 'admin_email') required this.adminEmail, @JsonKey(name: 'submitter_comment') this.submitterComment});
  factory _ProducerCreationRequest.fromJson(Map<String, dynamic> json) => _$ProducerCreationRequestFromJson(json);

@override@JsonKey(name: 'producer_name') final  String producerName;
@override@JsonKey(name: 'admin_first_name') final  String adminFirstName;
@override@JsonKey(name: 'admin_last_name') final  String adminLastName;
@override@JsonKey(name: 'admin_email') final  String adminEmail;
@override@JsonKey(name: 'submitter_comment') final  String? submitterComment;

/// Create a copy of ProducerCreationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerCreationRequestCopyWith<_ProducerCreationRequest> get copyWith => __$ProducerCreationRequestCopyWithImpl<_ProducerCreationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProducerCreationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerCreationRequest&&(identical(other.producerName, producerName) || other.producerName == producerName)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,producerName,adminFirstName,adminLastName,adminEmail,submitterComment);

@override
String toString() {
  return 'ProducerCreationRequest(producerName: $producerName, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, submitterComment: $submitterComment)';
}


}

/// @nodoc
abstract mixin class _$ProducerCreationRequestCopyWith<$Res> implements $ProducerCreationRequestCopyWith<$Res> {
  factory _$ProducerCreationRequestCopyWith(_ProducerCreationRequest value, $Res Function(_ProducerCreationRequest) _then) = __$ProducerCreationRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'producer_name') String producerName,@JsonKey(name: 'admin_first_name') String adminFirstName,@JsonKey(name: 'admin_last_name') String adminLastName,@JsonKey(name: 'admin_email') String adminEmail,@JsonKey(name: 'submitter_comment') String? submitterComment
});




}
/// @nodoc
class __$ProducerCreationRequestCopyWithImpl<$Res>
    implements _$ProducerCreationRequestCopyWith<$Res> {
  __$ProducerCreationRequestCopyWithImpl(this._self, this._then);

  final _ProducerCreationRequest _self;
  final $Res Function(_ProducerCreationRequest) _then;

/// Create a copy of ProducerCreationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? producerName = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? submitterComment = freezed,}) {
  return _then(_ProducerCreationRequest(
producerName: null == producerName ? _self.producerName : producerName // ignore: cast_nullable_to_non_nullable
as String,adminFirstName: null == adminFirstName ? _self.adminFirstName : adminFirstName // ignore: cast_nullable_to_non_nullable
as String,adminLastName: null == adminLastName ? _self.adminLastName : adminLastName // ignore: cast_nullable_to_non_nullable
as String,adminEmail: null == adminEmail ? _self.adminEmail : adminEmail // ignore: cast_nullable_to_non_nullable
as String,submitterComment: freezed == submitterComment ? _self.submitterComment : submitterComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
