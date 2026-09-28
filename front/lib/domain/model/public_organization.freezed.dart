// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_organization.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PublicOrganization {

@JsonKey(name: 'organization_id') String get organizationId; String get name;@JsonKey(name: 'active_status') bool get activeStatus;
/// Create a copy of PublicOrganization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicOrganizationCopyWith<PublicOrganization> get copyWith => _$PublicOrganizationCopyWithImpl<PublicOrganization>(this as PublicOrganization, _$identity);

  /// Serializes this PublicOrganization to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PublicOrganization;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicOrganization&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.activeStatus, _this.activeStatus) || other.activeStatus == _this.activeStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PublicOrganization;
  return Object.hash(runtimeType,_this.organizationId,_this.name,_this.activeStatus);
}

@override
String toString() {
  final _this = this as PublicOrganization;
  return 'PublicOrganization(organizationId: ${_this.organizationId}, name: ${_this.name}, activeStatus: ${_this.activeStatus})';
}


}

/// @nodoc
abstract mixin class $PublicOrganizationCopyWith<$Res>  {
  factory $PublicOrganizationCopyWith(PublicOrganization value, $Res Function(PublicOrganization) _then) = _$PublicOrganizationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId, String name,@JsonKey(name: 'active_status') bool activeStatus
});




}
/// @nodoc
class _$PublicOrganizationCopyWithImpl<$Res>
    implements $PublicOrganizationCopyWith<$Res> {
  _$PublicOrganizationCopyWithImpl(this._self, this._then);

  final PublicOrganization _self;
  final $Res Function(PublicOrganization) _then;

/// Create a copy of PublicOrganization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? name = null,Object? activeStatus = null,}) {
  return _then(PublicOrganization(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,activeStatus: null == activeStatus ? _self.activeStatus : activeStatus // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PublicOrganization].
extension PublicOrganizationPatterns on PublicOrganization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicOrganization value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicOrganization() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicOrganization value)  $default,){
final _that = this;
switch (_that) {
case _PublicOrganization():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicOrganization value)?  $default,){
final _that = this;
switch (_that) {
case _PublicOrganization() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'active_status')  bool activeStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicOrganization() when $default != null:
return $default(_that.organizationId,_that.name,_that.activeStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'active_status')  bool activeStatus)  $default,) {final _that = this;
switch (_that) {
case _PublicOrganization():
return $default(_that.organizationId,_that.name,_that.activeStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'active_status')  bool activeStatus)?  $default,) {final _that = this;
switch (_that) {
case _PublicOrganization() when $default != null:
return $default(_that.organizationId,_that.name,_that.activeStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PublicOrganization implements PublicOrganization {
  const _PublicOrganization({@JsonKey(name: 'organization_id') required this.organizationId, required this.name, @JsonKey(name: 'active_status') this.activeStatus = true});
  factory _PublicOrganization.fromJson(Map<String, dynamic> json) => _$PublicOrganizationFromJson(json);

@override@JsonKey(name: 'organization_id') final  String organizationId;
@override final  String name;
@override@JsonKey(name: 'active_status') final  bool activeStatus;

/// Create a copy of PublicOrganization
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicOrganizationCopyWith<_PublicOrganization> get copyWith => __$PublicOrganizationCopyWithImpl<_PublicOrganization>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicOrganizationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicOrganization&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.activeStatus, activeStatus) || other.activeStatus == activeStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,name,activeStatus);
}

@override
String toString() {
    return 'PublicOrganization(organizationId: $organizationId, name: $name, activeStatus: $activeStatus)';
}


}

/// @nodoc
abstract mixin class _$PublicOrganizationCopyWith<$Res> implements $PublicOrganizationCopyWith<$Res> {
  factory _$PublicOrganizationCopyWith(_PublicOrganization value, $Res Function(_PublicOrganization) _then) = __$PublicOrganizationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId, String name,@JsonKey(name: 'active_status') bool activeStatus
});




}
/// @nodoc
class __$PublicOrganizationCopyWithImpl<$Res>
    implements _$PublicOrganizationCopyWith<$Res> {
  __$PublicOrganizationCopyWithImpl(this._self, this._then);

  final _PublicOrganization _self;
  final $Res Function(_PublicOrganization) _then;

/// Create a copy of PublicOrganization
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? name = null,Object? activeStatus = null,}) {
  return _then(_PublicOrganization(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,activeStatus: null == activeStatus ? _self.activeStatus : activeStatus // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
