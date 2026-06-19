// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_producer_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminProducerRequest {

@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'producer_name') String get producerName;@JsonKey(name: 'admin_first_name') String get adminFirstName;@JsonKey(name: 'admin_last_name') String get adminLastName;@JsonKey(name: 'admin_email') String get adminEmail; ProducerRequestStatus get status;@JsonKey(name: 'submitted_at') String get submittedAt;@JsonKey(name: 'reviewed_at') String? get reviewedAt;@JsonKey(name: 'review_comment') String? get reviewComment;@JsonKey(name: 'submitter_comment') String? get submitterComment;@JsonKey(name: 'resend_requested_at') String? get resendRequestedAt;
/// Create a copy of AdminProducerRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminProducerRequestCopyWith<AdminProducerRequest> get copyWith => _$AdminProducerRequestCopyWithImpl<AdminProducerRequest>(this as AdminProducerRequest, _$identity);

  /// Serializes this AdminProducerRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminProducerRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.producerName, producerName) || other.producerName == producerName)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewComment, reviewComment) || other.reviewComment == reviewComment)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment)&&(identical(other.resendRequestedAt, resendRequestedAt) || other.resendRequestedAt == resendRequestedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,producerName,adminFirstName,adminLastName,adminEmail,status,submittedAt,reviewedAt,reviewComment,submitterComment,resendRequestedAt);

@override
String toString() {
  return 'AdminProducerRequest(requestId: $requestId, producerName: $producerName, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, status: $status, submittedAt: $submittedAt, reviewedAt: $reviewedAt, reviewComment: $reviewComment, submitterComment: $submitterComment, resendRequestedAt: $resendRequestedAt)';
}


}

/// @nodoc
abstract mixin class $AdminProducerRequestCopyWith<$Res>  {
  factory $AdminProducerRequestCopyWith(AdminProducerRequest value, $Res Function(AdminProducerRequest) _then) = _$AdminProducerRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'producer_name') String producerName,@JsonKey(name: 'admin_first_name') String adminFirstName,@JsonKey(name: 'admin_last_name') String adminLastName,@JsonKey(name: 'admin_email') String adminEmail, ProducerRequestStatus status,@JsonKey(name: 'submitted_at') String submittedAt,@JsonKey(name: 'reviewed_at') String? reviewedAt,@JsonKey(name: 'review_comment') String? reviewComment,@JsonKey(name: 'submitter_comment') String? submitterComment,@JsonKey(name: 'resend_requested_at') String? resendRequestedAt
});




}
/// @nodoc
class _$AdminProducerRequestCopyWithImpl<$Res>
    implements $AdminProducerRequestCopyWith<$Res> {
  _$AdminProducerRequestCopyWithImpl(this._self, this._then);

  final AdminProducerRequest _self;
  final $Res Function(AdminProducerRequest) _then;

/// Create a copy of AdminProducerRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? producerName = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? status = null,Object? submittedAt = null,Object? reviewedAt = freezed,Object? reviewComment = freezed,Object? submitterComment = freezed,Object? resendRequestedAt = freezed,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,producerName: null == producerName ? _self.producerName : producerName // ignore: cast_nullable_to_non_nullable
as String,adminFirstName: null == adminFirstName ? _self.adminFirstName : adminFirstName // ignore: cast_nullable_to_non_nullable
as String,adminLastName: null == adminLastName ? _self.adminLastName : adminLastName // ignore: cast_nullable_to_non_nullable
as String,adminEmail: null == adminEmail ? _self.adminEmail : adminEmail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProducerRequestStatus,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,reviewComment: freezed == reviewComment ? _self.reviewComment : reviewComment // ignore: cast_nullable_to_non_nullable
as String?,submitterComment: freezed == submitterComment ? _self.submitterComment : submitterComment // ignore: cast_nullable_to_non_nullable
as String?,resendRequestedAt: freezed == resendRequestedAt ? _self.resendRequestedAt : resendRequestedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminProducerRequest].
extension AdminProducerRequestPatterns on AdminProducerRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminProducerRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminProducerRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminProducerRequest value)  $default,){
final _that = this;
switch (_that) {
case _AdminProducerRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminProducerRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AdminProducerRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'producer_name')  String producerName, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail,  ProducerRequestStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'review_comment')  String? reviewComment, @JsonKey(name: 'submitter_comment')  String? submitterComment, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminProducerRequest() when $default != null:
return $default(_that.requestId,_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.status,_that.submittedAt,_that.reviewedAt,_that.reviewComment,_that.submitterComment,_that.resendRequestedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'producer_name')  String producerName, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail,  ProducerRequestStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'review_comment')  String? reviewComment, @JsonKey(name: 'submitter_comment')  String? submitterComment, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt)  $default,) {final _that = this;
switch (_that) {
case _AdminProducerRequest():
return $default(_that.requestId,_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.status,_that.submittedAt,_that.reviewedAt,_that.reviewComment,_that.submitterComment,_that.resendRequestedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'producer_name')  String producerName, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail,  ProducerRequestStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'review_comment')  String? reviewComment, @JsonKey(name: 'submitter_comment')  String? submitterComment, @JsonKey(name: 'resend_requested_at')  String? resendRequestedAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminProducerRequest() when $default != null:
return $default(_that.requestId,_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.status,_that.submittedAt,_that.reviewedAt,_that.reviewComment,_that.submitterComment,_that.resendRequestedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminProducerRequest implements AdminProducerRequest {
  const _AdminProducerRequest({@JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'producer_name') required this.producerName, @JsonKey(name: 'admin_first_name') required this.adminFirstName, @JsonKey(name: 'admin_last_name') required this.adminLastName, @JsonKey(name: 'admin_email') required this.adminEmail, required this.status, @JsonKey(name: 'submitted_at') required this.submittedAt, @JsonKey(name: 'reviewed_at') this.reviewedAt, @JsonKey(name: 'review_comment') this.reviewComment, @JsonKey(name: 'submitter_comment') this.submitterComment, @JsonKey(name: 'resend_requested_at') this.resendRequestedAt});
  factory _AdminProducerRequest.fromJson(Map<String, dynamic> json) => _$AdminProducerRequestFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'producer_name') final  String producerName;
@override@JsonKey(name: 'admin_first_name') final  String adminFirstName;
@override@JsonKey(name: 'admin_last_name') final  String adminLastName;
@override@JsonKey(name: 'admin_email') final  String adminEmail;
@override final  ProducerRequestStatus status;
@override@JsonKey(name: 'submitted_at') final  String submittedAt;
@override@JsonKey(name: 'reviewed_at') final  String? reviewedAt;
@override@JsonKey(name: 'review_comment') final  String? reviewComment;
@override@JsonKey(name: 'submitter_comment') final  String? submitterComment;
@override@JsonKey(name: 'resend_requested_at') final  String? resendRequestedAt;

/// Create a copy of AdminProducerRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminProducerRequestCopyWith<_AdminProducerRequest> get copyWith => __$AdminProducerRequestCopyWithImpl<_AdminProducerRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminProducerRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminProducerRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.producerName, producerName) || other.producerName == producerName)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewComment, reviewComment) || other.reviewComment == reviewComment)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment)&&(identical(other.resendRequestedAt, resendRequestedAt) || other.resendRequestedAt == resendRequestedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,producerName,adminFirstName,adminLastName,adminEmail,status,submittedAt,reviewedAt,reviewComment,submitterComment,resendRequestedAt);

@override
String toString() {
  return 'AdminProducerRequest(requestId: $requestId, producerName: $producerName, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, status: $status, submittedAt: $submittedAt, reviewedAt: $reviewedAt, reviewComment: $reviewComment, submitterComment: $submitterComment, resendRequestedAt: $resendRequestedAt)';
}


}

/// @nodoc
abstract mixin class _$AdminProducerRequestCopyWith<$Res> implements $AdminProducerRequestCopyWith<$Res> {
  factory _$AdminProducerRequestCopyWith(_AdminProducerRequest value, $Res Function(_AdminProducerRequest) _then) = __$AdminProducerRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'producer_name') String producerName,@JsonKey(name: 'admin_first_name') String adminFirstName,@JsonKey(name: 'admin_last_name') String adminLastName,@JsonKey(name: 'admin_email') String adminEmail, ProducerRequestStatus status,@JsonKey(name: 'submitted_at') String submittedAt,@JsonKey(name: 'reviewed_at') String? reviewedAt,@JsonKey(name: 'review_comment') String? reviewComment,@JsonKey(name: 'submitter_comment') String? submitterComment,@JsonKey(name: 'resend_requested_at') String? resendRequestedAt
});




}
/// @nodoc
class __$AdminProducerRequestCopyWithImpl<$Res>
    implements _$AdminProducerRequestCopyWith<$Res> {
  __$AdminProducerRequestCopyWithImpl(this._self, this._then);

  final _AdminProducerRequest _self;
  final $Res Function(_AdminProducerRequest) _then;

/// Create a copy of AdminProducerRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? producerName = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? status = null,Object? submittedAt = null,Object? reviewedAt = freezed,Object? reviewComment = freezed,Object? submitterComment = freezed,Object? resendRequestedAt = freezed,}) {
  return _then(_AdminProducerRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,producerName: null == producerName ? _self.producerName : producerName // ignore: cast_nullable_to_non_nullable
as String,adminFirstName: null == adminFirstName ? _self.adminFirstName : adminFirstName // ignore: cast_nullable_to_non_nullable
as String,adminLastName: null == adminLastName ? _self.adminLastName : adminLastName // ignore: cast_nullable_to_non_nullable
as String,adminEmail: null == adminEmail ? _self.adminEmail : adminEmail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProducerRequestStatus,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,reviewComment: freezed == reviewComment ? _self.reviewComment : reviewComment // ignore: cast_nullable_to_non_nullable
as String?,submitterComment: freezed == submitterComment ? _self.submitterComment : submitterComment // ignore: cast_nullable_to_non_nullable
as String?,resendRequestedAt: freezed == resendRequestedAt ? _self.resendRequestedAt : resendRequestedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
