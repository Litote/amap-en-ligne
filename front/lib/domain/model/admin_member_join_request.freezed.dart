// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_member_join_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminMemberJoinRequest {

@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'organization_id') String get organizationId; String get email;@JsonKey(name: 'first_name') String get firstName;@JsonKey(name: 'last_name') String get lastName; MemberJoinRequestStatus get status;@JsonKey(name: 'submitted_at') String get submittedAt;@JsonKey(name: 'reviewed_at') String? get reviewedAt;@JsonKey(name: 'review_comment') String? get reviewComment;
/// Create a copy of AdminMemberJoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminMemberJoinRequestCopyWith<AdminMemberJoinRequest> get copyWith => _$AdminMemberJoinRequestCopyWithImpl<AdminMemberJoinRequest>(this as AdminMemberJoinRequest, _$identity);

  /// Serializes this AdminMemberJoinRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminMemberJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewComment, reviewComment) || other.reviewComment == reviewComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,organizationId,email,firstName,lastName,status,submittedAt,reviewedAt,reviewComment);

@override
String toString() {
  return 'AdminMemberJoinRequest(requestId: $requestId, organizationId: $organizationId, email: $email, firstName: $firstName, lastName: $lastName, status: $status, submittedAt: $submittedAt, reviewedAt: $reviewedAt, reviewComment: $reviewComment)';
}


}

/// @nodoc
abstract mixin class $AdminMemberJoinRequestCopyWith<$Res>  {
  factory $AdminMemberJoinRequestCopyWith(AdminMemberJoinRequest value, $Res Function(AdminMemberJoinRequest) _then) = _$AdminMemberJoinRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'organization_id') String organizationId, String email,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, MemberJoinRequestStatus status,@JsonKey(name: 'submitted_at') String submittedAt,@JsonKey(name: 'reviewed_at') String? reviewedAt,@JsonKey(name: 'review_comment') String? reviewComment
});




}
/// @nodoc
class _$AdminMemberJoinRequestCopyWithImpl<$Res>
    implements $AdminMemberJoinRequestCopyWith<$Res> {
  _$AdminMemberJoinRequestCopyWithImpl(this._self, this._then);

  final AdminMemberJoinRequest _self;
  final $Res Function(AdminMemberJoinRequest) _then;

/// Create a copy of AdminMemberJoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? organizationId = null,Object? email = null,Object? firstName = null,Object? lastName = null,Object? status = null,Object? submittedAt = null,Object? reviewedAt = freezed,Object? reviewComment = freezed,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MemberJoinRequestStatus,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,reviewComment: freezed == reviewComment ? _self.reviewComment : reviewComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminMemberJoinRequest].
extension AdminMemberJoinRequestPatterns on AdminMemberJoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminMemberJoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminMemberJoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminMemberJoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _AdminMemberJoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminMemberJoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AdminMemberJoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  MemberJoinRequestStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'review_comment')  String? reviewComment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminMemberJoinRequest() when $default != null:
return $default(_that.requestId,_that.organizationId,_that.email,_that.firstName,_that.lastName,_that.status,_that.submittedAt,_that.reviewedAt,_that.reviewComment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  MemberJoinRequestStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'review_comment')  String? reviewComment)  $default,) {final _that = this;
switch (_that) {
case _AdminMemberJoinRequest():
return $default(_that.requestId,_that.organizationId,_that.email,_that.firstName,_that.lastName,_that.status,_that.submittedAt,_that.reviewedAt,_that.reviewComment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'organization_id')  String organizationId,  String email, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  MemberJoinRequestStatus status, @JsonKey(name: 'submitted_at')  String submittedAt, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'review_comment')  String? reviewComment)?  $default,) {final _that = this;
switch (_that) {
case _AdminMemberJoinRequest() when $default != null:
return $default(_that.requestId,_that.organizationId,_that.email,_that.firstName,_that.lastName,_that.status,_that.submittedAt,_that.reviewedAt,_that.reviewComment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminMemberJoinRequest implements AdminMemberJoinRequest {
  const _AdminMemberJoinRequest({@JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'organization_id') required this.organizationId, required this.email, @JsonKey(name: 'first_name') required this.firstName, @JsonKey(name: 'last_name') required this.lastName, required this.status, @JsonKey(name: 'submitted_at') required this.submittedAt, @JsonKey(name: 'reviewed_at') this.reviewedAt, @JsonKey(name: 'review_comment') this.reviewComment});
  factory _AdminMemberJoinRequest.fromJson(Map<String, dynamic> json) => _$AdminMemberJoinRequestFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'organization_id') final  String organizationId;
@override final  String email;
@override@JsonKey(name: 'first_name') final  String firstName;
@override@JsonKey(name: 'last_name') final  String lastName;
@override final  MemberJoinRequestStatus status;
@override@JsonKey(name: 'submitted_at') final  String submittedAt;
@override@JsonKey(name: 'reviewed_at') final  String? reviewedAt;
@override@JsonKey(name: 'review_comment') final  String? reviewComment;

/// Create a copy of AdminMemberJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminMemberJoinRequestCopyWith<_AdminMemberJoinRequest> get copyWith => __$AdminMemberJoinRequestCopyWithImpl<_AdminMemberJoinRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminMemberJoinRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminMemberJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewComment, reviewComment) || other.reviewComment == reviewComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,organizationId,email,firstName,lastName,status,submittedAt,reviewedAt,reviewComment);

@override
String toString() {
  return 'AdminMemberJoinRequest(requestId: $requestId, organizationId: $organizationId, email: $email, firstName: $firstName, lastName: $lastName, status: $status, submittedAt: $submittedAt, reviewedAt: $reviewedAt, reviewComment: $reviewComment)';
}


}

/// @nodoc
abstract mixin class _$AdminMemberJoinRequestCopyWith<$Res> implements $AdminMemberJoinRequestCopyWith<$Res> {
  factory _$AdminMemberJoinRequestCopyWith(_AdminMemberJoinRequest value, $Res Function(_AdminMemberJoinRequest) _then) = __$AdminMemberJoinRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'organization_id') String organizationId, String email,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, MemberJoinRequestStatus status,@JsonKey(name: 'submitted_at') String submittedAt,@JsonKey(name: 'reviewed_at') String? reviewedAt,@JsonKey(name: 'review_comment') String? reviewComment
});




}
/// @nodoc
class __$AdminMemberJoinRequestCopyWithImpl<$Res>
    implements _$AdminMemberJoinRequestCopyWith<$Res> {
  __$AdminMemberJoinRequestCopyWithImpl(this._self, this._then);

  final _AdminMemberJoinRequest _self;
  final $Res Function(_AdminMemberJoinRequest) _then;

/// Create a copy of AdminMemberJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? organizationId = null,Object? email = null,Object? firstName = null,Object? lastName = null,Object? status = null,Object? submittedAt = null,Object? reviewedAt = freezed,Object? reviewComment = freezed,}) {
  return _then(_AdminMemberJoinRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MemberJoinRequestStatus,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,reviewComment: freezed == reviewComment ? _self.reviewComment : reviewComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
