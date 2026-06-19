// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_config_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrgConfigEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrgConfigEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrgConfigEvent()';
}


}

/// @nodoc
class $OrgConfigEventCopyWith<$Res>  {
$OrgConfigEventCopyWith(OrgConfigEvent _, $Res Function(OrgConfigEvent) __);
}


/// Adds pattern-matching-related methods to [OrgConfigEvent].
extension OrgConfigEventPatterns on OrgConfigEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _OrgConfigLoaded value)?  loaded,TResult Function( _OrgConfigSaved value)?  saved,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrgConfigLoaded() when loaded != null:
return loaded(_that);case _OrgConfigSaved() when saved != null:
return saved(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _OrgConfigLoaded value)  loaded,required TResult Function( _OrgConfigSaved value)  saved,}){
final _that = this;
switch (_that) {
case _OrgConfigLoaded():
return loaded(_that);case _OrgConfigSaved():
return saved(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _OrgConfigLoaded value)?  loaded,TResult? Function( _OrgConfigSaved value)?  saved,}){
final _that = this;
switch (_that) {
case _OrgConfigLoaded() when loaded != null:
return loaded(_that);case _OrgConfigSaved() when saved != null:
return saved(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Organization? organization)?  loaded,TResult Function( String name,  String contactEmail,  String? timezone,  String? defaultLanguage,  String? website)?  saved,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrgConfigLoaded() when loaded != null:
return loaded(_that.organization);case _OrgConfigSaved() when saved != null:
return saved(_that.name,_that.contactEmail,_that.timezone,_that.defaultLanguage,_that.website);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Organization? organization)  loaded,required TResult Function( String name,  String contactEmail,  String? timezone,  String? defaultLanguage,  String? website)  saved,}) {final _that = this;
switch (_that) {
case _OrgConfigLoaded():
return loaded(_that.organization);case _OrgConfigSaved():
return saved(_that.name,_that.contactEmail,_that.timezone,_that.defaultLanguage,_that.website);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Organization? organization)?  loaded,TResult? Function( String name,  String contactEmail,  String? timezone,  String? defaultLanguage,  String? website)?  saved,}) {final _that = this;
switch (_that) {
case _OrgConfigLoaded() when loaded != null:
return loaded(_that.organization);case _OrgConfigSaved() when saved != null:
return saved(_that.name,_that.contactEmail,_that.timezone,_that.defaultLanguage,_that.website);case _:
  return null;

}
}

}

/// @nodoc


class _OrgConfigLoaded implements OrgConfigEvent {
  const _OrgConfigLoaded(this.organization);
  

 final  Organization? organization;

/// Create a copy of OrgConfigEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrgConfigLoadedCopyWith<_OrgConfigLoaded> get copyWith => __$OrgConfigLoadedCopyWithImpl<_OrgConfigLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrgConfigLoaded&&(identical(other.organization, organization) || other.organization == organization));
}


@override
int get hashCode => Object.hash(runtimeType,organization);

@override
String toString() {
  return 'OrgConfigEvent.loaded(organization: $organization)';
}


}

/// @nodoc
abstract mixin class _$OrgConfigLoadedCopyWith<$Res> implements $OrgConfigEventCopyWith<$Res> {
  factory _$OrgConfigLoadedCopyWith(_OrgConfigLoaded value, $Res Function(_OrgConfigLoaded) _then) = __$OrgConfigLoadedCopyWithImpl;
@useResult
$Res call({
 Organization? organization
});


$OrganizationCopyWith<$Res>? get organization;

}
/// @nodoc
class __$OrgConfigLoadedCopyWithImpl<$Res>
    implements _$OrgConfigLoadedCopyWith<$Res> {
  __$OrgConfigLoadedCopyWithImpl(this._self, this._then);

  final _OrgConfigLoaded _self;
  final $Res Function(_OrgConfigLoaded) _then;

/// Create a copy of OrgConfigEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = freezed,}) {
  return _then(_OrgConfigLoaded(
freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization?,
  ));
}

/// Create a copy of OrgConfigEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get organization {
    if (_self.organization == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.organization!, (value) {
    return _then(_self.copyWith(organization: value));
  });
}
}

/// @nodoc


class _OrgConfigSaved implements OrgConfigEvent {
  const _OrgConfigSaved({required this.name, required this.contactEmail, this.timezone, this.defaultLanguage, this.website});
  

 final  String name;
 final  String contactEmail;
 final  String? timezone;
 final  String? defaultLanguage;
 final  String? website;

/// Create a copy of OrgConfigEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrgConfigSavedCopyWith<_OrgConfigSaved> get copyWith => __$OrgConfigSavedCopyWithImpl<_OrgConfigSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrgConfigSaved&&(identical(other.name, name) || other.name == name)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.website, website) || other.website == website));
}


@override
int get hashCode => Object.hash(runtimeType,name,contactEmail,timezone,defaultLanguage,website);

@override
String toString() {
  return 'OrgConfigEvent.saved(name: $name, contactEmail: $contactEmail, timezone: $timezone, defaultLanguage: $defaultLanguage, website: $website)';
}


}

/// @nodoc
abstract mixin class _$OrgConfigSavedCopyWith<$Res> implements $OrgConfigEventCopyWith<$Res> {
  factory _$OrgConfigSavedCopyWith(_OrgConfigSaved value, $Res Function(_OrgConfigSaved) _then) = __$OrgConfigSavedCopyWithImpl;
@useResult
$Res call({
 String name, String contactEmail, String? timezone, String? defaultLanguage, String? website
});




}
/// @nodoc
class __$OrgConfigSavedCopyWithImpl<$Res>
    implements _$OrgConfigSavedCopyWith<$Res> {
  __$OrgConfigSavedCopyWithImpl(this._self, this._then);

  final _OrgConfigSaved _self;
  final $Res Function(_OrgConfigSaved) _then;

/// Create a copy of OrgConfigEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? contactEmail = null,Object? timezone = freezed,Object? defaultLanguage = freezed,Object? website = freezed,}) {
  return _then(_OrgConfigSaved(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,defaultLanguage: freezed == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$OrgConfigState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrgConfigState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrgConfigState()';
}


}

/// @nodoc
class $OrgConfigStateCopyWith<$Res>  {
$OrgConfigStateCopyWith(OrgConfigState _, $Res Function(OrgConfigState) __);
}


/// Adds pattern-matching-related methods to [OrgConfigState].
extension OrgConfigStatePatterns on OrgConfigState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrgConfigLoading value)?  loading,TResult Function( OrgConfigMissing value)?  missing,TResult Function( OrgConfigReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrgConfigLoading() when loading != null:
return loading(_that);case OrgConfigMissing() when missing != null:
return missing(_that);case OrgConfigReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrgConfigLoading value)  loading,required TResult Function( OrgConfigMissing value)  missing,required TResult Function( OrgConfigReady value)  ready,}){
final _that = this;
switch (_that) {
case OrgConfigLoading():
return loading(_that);case OrgConfigMissing():
return missing(_that);case OrgConfigReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrgConfigLoading value)?  loading,TResult? Function( OrgConfigMissing value)?  missing,TResult? Function( OrgConfigReady value)?  ready,}){
final _that = this;
switch (_that) {
case OrgConfigLoading() when loading != null:
return loading(_that);case OrgConfigMissing() when missing != null:
return missing(_that);case OrgConfigReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  missing,TResult Function( Organization organization,  OrgConfigSaveStatus saveStatus,  String? saveErrorMessage)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrgConfigLoading() when loading != null:
return loading();case OrgConfigMissing() when missing != null:
return missing();case OrgConfigReady() when ready != null:
return ready(_that.organization,_that.saveStatus,_that.saveErrorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  missing,required TResult Function( Organization organization,  OrgConfigSaveStatus saveStatus,  String? saveErrorMessage)  ready,}) {final _that = this;
switch (_that) {
case OrgConfigLoading():
return loading();case OrgConfigMissing():
return missing();case OrgConfigReady():
return ready(_that.organization,_that.saveStatus,_that.saveErrorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  missing,TResult? Function( Organization organization,  OrgConfigSaveStatus saveStatus,  String? saveErrorMessage)?  ready,}) {final _that = this;
switch (_that) {
case OrgConfigLoading() when loading != null:
return loading();case OrgConfigMissing() when missing != null:
return missing();case OrgConfigReady() when ready != null:
return ready(_that.organization,_that.saveStatus,_that.saveErrorMessage);case _:
  return null;

}
}

}

/// @nodoc


class OrgConfigLoading implements OrgConfigState {
  const OrgConfigLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrgConfigLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrgConfigState.loading()';
}


}




/// @nodoc


class OrgConfigMissing implements OrgConfigState {
  const OrgConfigMissing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrgConfigMissing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrgConfigState.missing()';
}


}




/// @nodoc


class OrgConfigReady implements OrgConfigState {
  const OrgConfigReady({required this.organization, this.saveStatus = OrgConfigSaveStatus.idle, this.saveErrorMessage});
  

 final  Organization organization;
@JsonKey() final  OrgConfigSaveStatus saveStatus;
 final  String? saveErrorMessage;

/// Create a copy of OrgConfigState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrgConfigReadyCopyWith<OrgConfigReady> get copyWith => _$OrgConfigReadyCopyWithImpl<OrgConfigReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrgConfigReady&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus)&&(identical(other.saveErrorMessage, saveErrorMessage) || other.saveErrorMessage == saveErrorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,organization,saveStatus,saveErrorMessage);

@override
String toString() {
  return 'OrgConfigState.ready(organization: $organization, saveStatus: $saveStatus, saveErrorMessage: $saveErrorMessage)';
}


}

/// @nodoc
abstract mixin class $OrgConfigReadyCopyWith<$Res> implements $OrgConfigStateCopyWith<$Res> {
  factory $OrgConfigReadyCopyWith(OrgConfigReady value, $Res Function(OrgConfigReady) _then) = _$OrgConfigReadyCopyWithImpl;
@useResult
$Res call({
 Organization organization, OrgConfigSaveStatus saveStatus, String? saveErrorMessage
});


$OrganizationCopyWith<$Res> get organization;

}
/// @nodoc
class _$OrgConfigReadyCopyWithImpl<$Res>
    implements $OrgConfigReadyCopyWith<$Res> {
  _$OrgConfigReadyCopyWithImpl(this._self, this._then);

  final OrgConfigReady _self;
  final $Res Function(OrgConfigReady) _then;

/// Create a copy of OrgConfigState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? saveStatus = null,Object? saveErrorMessage = freezed,}) {
  return _then(OrgConfigReady(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as OrgConfigSaveStatus,saveErrorMessage: freezed == saveErrorMessage ? _self.saveErrorMessage : saveErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of OrgConfigState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get organization {
  
  return $OrganizationCopyWith<$Res>(_self.organization, (value) {
    return _then(_self.copyWith(organization: value));
  });
}
}

// dart format on
