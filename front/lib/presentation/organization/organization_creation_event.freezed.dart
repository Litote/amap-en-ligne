// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_creation_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationCreationEvent {

 String get organizationName; String get timezone; String get defaultLanguage; String get adminFirstName; String get adminLastName; String get adminEmail; OrganizationType get organizationType; String? get submitterComment;
/// Create a copy of OrganizationCreationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationCreationEventCopyWith<OrganizationCreationEvent> get copyWith => _$OrganizationCreationEventCopyWithImpl<OrganizationCreationEvent>(this as OrganizationCreationEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationCreationEvent&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.organizationType, organizationType) || other.organizationType == organizationType)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment));
}


@override
int get hashCode => Object.hash(runtimeType,organizationName,timezone,defaultLanguage,adminFirstName,adminLastName,adminEmail,organizationType,submitterComment);

@override
String toString() {
  return 'OrganizationCreationEvent(organizationName: $organizationName, timezone: $timezone, defaultLanguage: $defaultLanguage, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, organizationType: $organizationType, submitterComment: $submitterComment)';
}


}

/// @nodoc
abstract mixin class $OrganizationCreationEventCopyWith<$Res>  {
  factory $OrganizationCreationEventCopyWith(OrganizationCreationEvent value, $Res Function(OrganizationCreationEvent) _then) = _$OrganizationCreationEventCopyWithImpl;
@useResult
$Res call({
 String organizationName, String timezone, String defaultLanguage, String adminFirstName, String adminLastName, String adminEmail, OrganizationType organizationType, String? submitterComment
});




}
/// @nodoc
class _$OrganizationCreationEventCopyWithImpl<$Res>
    implements $OrganizationCreationEventCopyWith<$Res> {
  _$OrganizationCreationEventCopyWithImpl(this._self, this._then);

  final OrganizationCreationEvent _self;
  final $Res Function(OrganizationCreationEvent) _then;

/// Create a copy of OrganizationCreationEvent
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


/// Adds pattern-matching-related methods to [OrganizationCreationEvent].
extension OrganizationCreationEventPatterns on OrganizationCreationEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrganizationCreationSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrganizationCreationSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrganizationCreationSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case OrganizationCreationSubmitted():
return submitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrganizationCreationSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case OrganizationCreationSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String organizationName,  String timezone,  String defaultLanguage,  String adminFirstName,  String adminLastName,  String adminEmail,  OrganizationType organizationType,  String? submitterComment)?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrganizationCreationSubmitted() when submitted != null:
return submitted(_that.organizationName,_that.timezone,_that.defaultLanguage,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.organizationType,_that.submitterComment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String organizationName,  String timezone,  String defaultLanguage,  String adminFirstName,  String adminLastName,  String adminEmail,  OrganizationType organizationType,  String? submitterComment)  submitted,}) {final _that = this;
switch (_that) {
case OrganizationCreationSubmitted():
return submitted(_that.organizationName,_that.timezone,_that.defaultLanguage,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.organizationType,_that.submitterComment);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String organizationName,  String timezone,  String defaultLanguage,  String adminFirstName,  String adminLastName,  String adminEmail,  OrganizationType organizationType,  String? submitterComment)?  submitted,}) {final _that = this;
switch (_that) {
case OrganizationCreationSubmitted() when submitted != null:
return submitted(_that.organizationName,_that.timezone,_that.defaultLanguage,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.organizationType,_that.submitterComment);case _:
  return null;

}
}

}

/// @nodoc


class OrganizationCreationSubmitted implements OrganizationCreationEvent {
  const OrganizationCreationSubmitted({required this.organizationName, required this.timezone, required this.defaultLanguage, required this.adminFirstName, required this.adminLastName, required this.adminEmail, required this.organizationType, this.submitterComment});
  

@override final  String organizationName;
@override final  String timezone;
@override final  String defaultLanguage;
@override final  String adminFirstName;
@override final  String adminLastName;
@override final  String adminEmail;
@override final  OrganizationType organizationType;
@override final  String? submitterComment;

/// Create a copy of OrganizationCreationEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationCreationSubmittedCopyWith<OrganizationCreationSubmitted> get copyWith => _$OrganizationCreationSubmittedCopyWithImpl<OrganizationCreationSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationCreationSubmitted&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.organizationType, organizationType) || other.organizationType == organizationType)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment));
}


@override
int get hashCode => Object.hash(runtimeType,organizationName,timezone,defaultLanguage,adminFirstName,adminLastName,adminEmail,organizationType,submitterComment);

@override
String toString() {
  return 'OrganizationCreationEvent.submitted(organizationName: $organizationName, timezone: $timezone, defaultLanguage: $defaultLanguage, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, organizationType: $organizationType, submitterComment: $submitterComment)';
}


}

/// @nodoc
abstract mixin class $OrganizationCreationSubmittedCopyWith<$Res> implements $OrganizationCreationEventCopyWith<$Res> {
  factory $OrganizationCreationSubmittedCopyWith(OrganizationCreationSubmitted value, $Res Function(OrganizationCreationSubmitted) _then) = _$OrganizationCreationSubmittedCopyWithImpl;
@override @useResult
$Res call({
 String organizationName, String timezone, String defaultLanguage, String adminFirstName, String adminLastName, String adminEmail, OrganizationType organizationType, String? submitterComment
});




}
/// @nodoc
class _$OrganizationCreationSubmittedCopyWithImpl<$Res>
    implements $OrganizationCreationSubmittedCopyWith<$Res> {
  _$OrganizationCreationSubmittedCopyWithImpl(this._self, this._then);

  final OrganizationCreationSubmitted _self;
  final $Res Function(OrganizationCreationSubmitted) _then;

/// Create a copy of OrganizationCreationEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationName = null,Object? timezone = null,Object? defaultLanguage = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? organizationType = null,Object? submitterComment = freezed,}) {
  return _then(OrganizationCreationSubmitted(
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
