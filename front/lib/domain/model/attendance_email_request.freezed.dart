// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_email_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceEmailRequest {

@JsonKey(name: 'attendance_email_request_id') String get attendanceEmailRequestId;@JsonKey(name: 'organization_id') String get organizationId;@JsonKey(name: 'delivery_id') String get deliveryId;@JsonKey(name: 'recipient_email') String get recipientEmail;// ISO-8601 instant string, e.g. "2026-06-04T10:00:00Z".
@JsonKey(name: 'requested_at') String get requestedAt;// ISO-8601 instant string; null/absent until the email has been sent.
@JsonKey(name: 'sent_at') String? get sentAt;
/// Create a copy of AttendanceEmailRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceEmailRequestCopyWith<AttendanceEmailRequest> get copyWith => _$AttendanceEmailRequestCopyWithImpl<AttendanceEmailRequest>(this as AttendanceEmailRequest, _$identity);

  /// Serializes this AttendanceEmailRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceEmailRequest&&(identical(other.attendanceEmailRequestId, attendanceEmailRequestId) || other.attendanceEmailRequestId == attendanceEmailRequestId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.recipientEmail, recipientEmail) || other.recipientEmail == recipientEmail)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attendanceEmailRequestId,organizationId,deliveryId,recipientEmail,requestedAt,sentAt);

@override
String toString() {
  return 'AttendanceEmailRequest(attendanceEmailRequestId: $attendanceEmailRequestId, organizationId: $organizationId, deliveryId: $deliveryId, recipientEmail: $recipientEmail, requestedAt: $requestedAt, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $AttendanceEmailRequestCopyWith<$Res>  {
  factory $AttendanceEmailRequestCopyWith(AttendanceEmailRequest value, $Res Function(AttendanceEmailRequest) _then) = _$AttendanceEmailRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'attendance_email_request_id') String attendanceEmailRequestId,@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'recipient_email') String recipientEmail,@JsonKey(name: 'requested_at') String requestedAt,@JsonKey(name: 'sent_at') String? sentAt
});




}
/// @nodoc
class _$AttendanceEmailRequestCopyWithImpl<$Res>
    implements $AttendanceEmailRequestCopyWith<$Res> {
  _$AttendanceEmailRequestCopyWithImpl(this._self, this._then);

  final AttendanceEmailRequest _self;
  final $Res Function(AttendanceEmailRequest) _then;

/// Create a copy of AttendanceEmailRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attendanceEmailRequestId = null,Object? organizationId = null,Object? deliveryId = null,Object? recipientEmail = null,Object? requestedAt = null,Object? sentAt = freezed,}) {
  return _then(_self.copyWith(
attendanceEmailRequestId: null == attendanceEmailRequestId ? _self.attendanceEmailRequestId : attendanceEmailRequestId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,recipientEmail: null == recipientEmail ? _self.recipientEmail : recipientEmail // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceEmailRequest].
extension AttendanceEmailRequestPatterns on AttendanceEmailRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceEmailRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceEmailRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceEmailRequest value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceEmailRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceEmailRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceEmailRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'attendance_email_request_id')  String attendanceEmailRequestId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'recipient_email')  String recipientEmail, @JsonKey(name: 'requested_at')  String requestedAt, @JsonKey(name: 'sent_at')  String? sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceEmailRequest() when $default != null:
return $default(_that.attendanceEmailRequestId,_that.organizationId,_that.deliveryId,_that.recipientEmail,_that.requestedAt,_that.sentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'attendance_email_request_id')  String attendanceEmailRequestId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'recipient_email')  String recipientEmail, @JsonKey(name: 'requested_at')  String requestedAt, @JsonKey(name: 'sent_at')  String? sentAt)  $default,) {final _that = this;
switch (_that) {
case _AttendanceEmailRequest():
return $default(_that.attendanceEmailRequestId,_that.organizationId,_that.deliveryId,_that.recipientEmail,_that.requestedAt,_that.sentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'attendance_email_request_id')  String attendanceEmailRequestId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'recipient_email')  String recipientEmail, @JsonKey(name: 'requested_at')  String requestedAt, @JsonKey(name: 'sent_at')  String? sentAt)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceEmailRequest() when $default != null:
return $default(_that.attendanceEmailRequestId,_that.organizationId,_that.deliveryId,_that.recipientEmail,_that.requestedAt,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceEmailRequest implements AttendanceEmailRequest {
  const _AttendanceEmailRequest({@JsonKey(name: 'attendance_email_request_id') required this.attendanceEmailRequestId, @JsonKey(name: 'organization_id') required this.organizationId, @JsonKey(name: 'delivery_id') required this.deliveryId, @JsonKey(name: 'recipient_email') required this.recipientEmail, @JsonKey(name: 'requested_at') required this.requestedAt, @JsonKey(name: 'sent_at') this.sentAt});
  factory _AttendanceEmailRequest.fromJson(Map<String, dynamic> json) => _$AttendanceEmailRequestFromJson(json);

@override@JsonKey(name: 'attendance_email_request_id') final  String attendanceEmailRequestId;
@override@JsonKey(name: 'organization_id') final  String organizationId;
@override@JsonKey(name: 'delivery_id') final  String deliveryId;
@override@JsonKey(name: 'recipient_email') final  String recipientEmail;
// ISO-8601 instant string, e.g. "2026-06-04T10:00:00Z".
@override@JsonKey(name: 'requested_at') final  String requestedAt;
// ISO-8601 instant string; null/absent until the email has been sent.
@override@JsonKey(name: 'sent_at') final  String? sentAt;

/// Create a copy of AttendanceEmailRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceEmailRequestCopyWith<_AttendanceEmailRequest> get copyWith => __$AttendanceEmailRequestCopyWithImpl<_AttendanceEmailRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceEmailRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceEmailRequest&&(identical(other.attendanceEmailRequestId, attendanceEmailRequestId) || other.attendanceEmailRequestId == attendanceEmailRequestId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.recipientEmail, recipientEmail) || other.recipientEmail == recipientEmail)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attendanceEmailRequestId,organizationId,deliveryId,recipientEmail,requestedAt,sentAt);

@override
String toString() {
  return 'AttendanceEmailRequest(attendanceEmailRequestId: $attendanceEmailRequestId, organizationId: $organizationId, deliveryId: $deliveryId, recipientEmail: $recipientEmail, requestedAt: $requestedAt, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$AttendanceEmailRequestCopyWith<$Res> implements $AttendanceEmailRequestCopyWith<$Res> {
  factory _$AttendanceEmailRequestCopyWith(_AttendanceEmailRequest value, $Res Function(_AttendanceEmailRequest) _then) = __$AttendanceEmailRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'attendance_email_request_id') String attendanceEmailRequestId,@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'recipient_email') String recipientEmail,@JsonKey(name: 'requested_at') String requestedAt,@JsonKey(name: 'sent_at') String? sentAt
});




}
/// @nodoc
class __$AttendanceEmailRequestCopyWithImpl<$Res>
    implements _$AttendanceEmailRequestCopyWith<$Res> {
  __$AttendanceEmailRequestCopyWithImpl(this._self, this._then);

  final _AttendanceEmailRequest _self;
  final $Res Function(_AttendanceEmailRequest) _then;

/// Create a copy of AttendanceEmailRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attendanceEmailRequestId = null,Object? organizationId = null,Object? deliveryId = null,Object? recipientEmail = null,Object? requestedAt = null,Object? sentAt = freezed,}) {
  return _then(_AttendanceEmailRequest(
attendanceEmailRequestId: null == attendanceEmailRequestId ? _self.attendanceEmailRequestId : attendanceEmailRequestId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,recipientEmail: null == recipientEmail ? _self.recipientEmail : recipientEmail // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
