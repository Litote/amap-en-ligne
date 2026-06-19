// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_creation_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrganizationCreationRequest {

@JsonKey(name: 'organization_name') String get organizationName; String get timezone;@JsonKey(name: 'default_language') String get defaultLanguage;@JsonKey(name: 'admin_first_name') String get adminFirstName;@JsonKey(name: 'admin_last_name') String get adminLastName;@JsonKey(name: 'admin_email') String get adminEmail;@JsonKey(name: 'organization_type') OrganizationType get organizationType;@JsonKey(name: 'submitter_comment') String? get submitterComment;
/// Create a copy of OrganizationCreationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationCreationRequestCopyWith<OrganizationCreationRequest> get copyWith => _$OrganizationCreationRequestCopyWithImpl<OrganizationCreationRequest>(this as OrganizationCreationRequest, _$identity);

  /// Serializes this OrganizationCreationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationCreationRequest&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.organizationType, organizationType) || other.organizationType == organizationType)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organizationName,timezone,defaultLanguage,adminFirstName,adminLastName,adminEmail,organizationType,submitterComment);

@override
String toString() {
  return 'OrganizationCreationRequest(organizationName: $organizationName, timezone: $timezone, defaultLanguage: $defaultLanguage, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, organizationType: $organizationType, submitterComment: $submitterComment)';
}


}

/// @nodoc
abstract mixin class $OrganizationCreationRequestCopyWith<$Res>  {
  factory $OrganizationCreationRequestCopyWith(OrganizationCreationRequest value, $Res Function(OrganizationCreationRequest) _then) = _$OrganizationCreationRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'organization_name') String organizationName, String timezone,@JsonKey(name: 'default_language') String defaultLanguage,@JsonKey(name: 'admin_first_name') String adminFirstName,@JsonKey(name: 'admin_last_name') String adminLastName,@JsonKey(name: 'admin_email') String adminEmail,@JsonKey(name: 'organization_type') OrganizationType organizationType,@JsonKey(name: 'submitter_comment') String? submitterComment
});




}
/// @nodoc
class _$OrganizationCreationRequestCopyWithImpl<$Res>
    implements $OrganizationCreationRequestCopyWith<$Res> {
  _$OrganizationCreationRequestCopyWithImpl(this._self, this._then);

  final OrganizationCreationRequest _self;
  final $Res Function(OrganizationCreationRequest) _then;

/// Create a copy of OrganizationCreationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationName = null,Object? timezone = null,Object? defaultLanguage = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? organizationType = null,Object? submitterComment = freezed,}) {
  return _then(_self.copyWith(
organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,adminFirstName: null == adminFirstName ? _self.adminFirstName : adminFirstName // ignore: cast_nullable_to_non_nullable
as String,adminLastName: null == adminLastName ? _self.adminLastName : adminLastName // ignore: cast_nullable_to_non_nullable
as String,adminEmail: null == adminEmail ? _self.adminEmail : adminEmail // ignore: cast_nullable_to_non_nullable
as String,organizationType: null == organizationType ? _self.organizationType : organizationType // ignore: cast_nullable_to_non_nullable
as OrganizationType,submitterComment: freezed == submitterComment ? _self.submitterComment : submitterComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationCreationRequest].
extension OrganizationCreationRequestPatterns on OrganizationCreationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationCreationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationCreationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationCreationRequest value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationCreationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationCreationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationCreationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_name')  String organizationName,  String timezone, @JsonKey(name: 'default_language')  String defaultLanguage, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail, @JsonKey(name: 'organization_type')  OrganizationType organizationType, @JsonKey(name: 'submitter_comment')  String? submitterComment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationCreationRequest() when $default != null:
return $default(_that.organizationName,_that.timezone,_that.defaultLanguage,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.organizationType,_that.submitterComment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_name')  String organizationName,  String timezone, @JsonKey(name: 'default_language')  String defaultLanguage, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail, @JsonKey(name: 'organization_type')  OrganizationType organizationType, @JsonKey(name: 'submitter_comment')  String? submitterComment)  $default,) {final _that = this;
switch (_that) {
case _OrganizationCreationRequest():
return $default(_that.organizationName,_that.timezone,_that.defaultLanguage,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.organizationType,_that.submitterComment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'organization_name')  String organizationName,  String timezone, @JsonKey(name: 'default_language')  String defaultLanguage, @JsonKey(name: 'admin_first_name')  String adminFirstName, @JsonKey(name: 'admin_last_name')  String adminLastName, @JsonKey(name: 'admin_email')  String adminEmail, @JsonKey(name: 'organization_type')  OrganizationType organizationType, @JsonKey(name: 'submitter_comment')  String? submitterComment)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationCreationRequest() when $default != null:
return $default(_that.organizationName,_that.timezone,_that.defaultLanguage,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.organizationType,_that.submitterComment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrganizationCreationRequest implements OrganizationCreationRequest {
  const _OrganizationCreationRequest({@JsonKey(name: 'organization_name') required this.organizationName, required this.timezone, @JsonKey(name: 'default_language') required this.defaultLanguage, @JsonKey(name: 'admin_first_name') required this.adminFirstName, @JsonKey(name: 'admin_last_name') required this.adminLastName, @JsonKey(name: 'admin_email') required this.adminEmail, @JsonKey(name: 'organization_type') required this.organizationType, @JsonKey(name: 'submitter_comment') this.submitterComment});
  factory _OrganizationCreationRequest.fromJson(Map<String, dynamic> json) => _$OrganizationCreationRequestFromJson(json);

@override@JsonKey(name: 'organization_name') final  String organizationName;
@override final  String timezone;
@override@JsonKey(name: 'default_language') final  String defaultLanguage;
@override@JsonKey(name: 'admin_first_name') final  String adminFirstName;
@override@JsonKey(name: 'admin_last_name') final  String adminLastName;
@override@JsonKey(name: 'admin_email') final  String adminEmail;
@override@JsonKey(name: 'organization_type') final  OrganizationType organizationType;
@override@JsonKey(name: 'submitter_comment') final  String? submitterComment;

/// Create a copy of OrganizationCreationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationCreationRequestCopyWith<_OrganizationCreationRequest> get copyWith => __$OrganizationCreationRequestCopyWithImpl<_OrganizationCreationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrganizationCreationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationCreationRequest&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.organizationType, organizationType) || other.organizationType == organizationType)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organizationName,timezone,defaultLanguage,adminFirstName,adminLastName,adminEmail,organizationType,submitterComment);

@override
String toString() {
  return 'OrganizationCreationRequest(organizationName: $organizationName, timezone: $timezone, defaultLanguage: $defaultLanguage, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, organizationType: $organizationType, submitterComment: $submitterComment)';
}


}

/// @nodoc
abstract mixin class _$OrganizationCreationRequestCopyWith<$Res> implements $OrganizationCreationRequestCopyWith<$Res> {
  factory _$OrganizationCreationRequestCopyWith(_OrganizationCreationRequest value, $Res Function(_OrganizationCreationRequest) _then) = __$OrganizationCreationRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'organization_name') String organizationName, String timezone,@JsonKey(name: 'default_language') String defaultLanguage,@JsonKey(name: 'admin_first_name') String adminFirstName,@JsonKey(name: 'admin_last_name') String adminLastName,@JsonKey(name: 'admin_email') String adminEmail,@JsonKey(name: 'organization_type') OrganizationType organizationType,@JsonKey(name: 'submitter_comment') String? submitterComment
});




}
/// @nodoc
class __$OrganizationCreationRequestCopyWithImpl<$Res>
    implements _$OrganizationCreationRequestCopyWith<$Res> {
  __$OrganizationCreationRequestCopyWithImpl(this._self, this._then);

  final _OrganizationCreationRequest _self;
  final $Res Function(_OrganizationCreationRequest) _then;

/// Create a copy of OrganizationCreationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationName = null,Object? timezone = null,Object? defaultLanguage = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? organizationType = null,Object? submitterComment = freezed,}) {
  return _then(_OrganizationCreationRequest(
organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,adminFirstName: null == adminFirstName ? _self.adminFirstName : adminFirstName // ignore: cast_nullable_to_non_nullable
as String,adminLastName: null == adminLastName ? _self.adminLastName : adminLastName // ignore: cast_nullable_to_non_nullable
as String,adminEmail: null == adminEmail ? _self.adminEmail : adminEmail // ignore: cast_nullable_to_non_nullable
as String,organizationType: null == organizationType ? _self.organizationType : organizationType // ignore: cast_nullable_to_non_nullable
as OrganizationType,submitterComment: freezed == submitterComment ? _self.submitterComment : submitterComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
