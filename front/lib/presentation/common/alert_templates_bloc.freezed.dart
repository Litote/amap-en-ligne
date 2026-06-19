// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alert_templates_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlertTemplatesEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlertTemplatesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlertTemplatesEvent()';
}


}

/// @nodoc
class $AlertTemplatesEventCopyWith<$Res>  {
$AlertTemplatesEventCopyWith(AlertTemplatesEvent _, $Res Function(AlertTemplatesEvent) __);
}


/// Adds pattern-matching-related methods to [AlertTemplatesEvent].
extension AlertTemplatesEventPatterns on AlertTemplatesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _AlertTemplatesLoaded value)?  loaded,TResult Function( _AlertTemplatesSaved value)?  saved,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlertTemplatesLoaded() when loaded != null:
return loaded(_that);case _AlertTemplatesSaved() when saved != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _AlertTemplatesLoaded value)  loaded,required TResult Function( _AlertTemplatesSaved value)  saved,}){
final _that = this;
switch (_that) {
case _AlertTemplatesLoaded():
return loaded(_that);case _AlertTemplatesSaved():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _AlertTemplatesLoaded value)?  loaded,TResult? Function( _AlertTemplatesSaved value)?  saved,}){
final _that = this;
switch (_that) {
case _AlertTemplatesLoaded() when loaded != null:
return loaded(_that);case _AlertTemplatesSaved() when saved != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Organization? organization)?  loaded,TResult Function( Map<NotificationCategory, NotificationCopyOverride> overrides)?  saved,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlertTemplatesLoaded() when loaded != null:
return loaded(_that.organization);case _AlertTemplatesSaved() when saved != null:
return saved(_that.overrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Organization? organization)  loaded,required TResult Function( Map<NotificationCategory, NotificationCopyOverride> overrides)  saved,}) {final _that = this;
switch (_that) {
case _AlertTemplatesLoaded():
return loaded(_that.organization);case _AlertTemplatesSaved():
return saved(_that.overrides);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Organization? organization)?  loaded,TResult? Function( Map<NotificationCategory, NotificationCopyOverride> overrides)?  saved,}) {final _that = this;
switch (_that) {
case _AlertTemplatesLoaded() when loaded != null:
return loaded(_that.organization);case _AlertTemplatesSaved() when saved != null:
return saved(_that.overrides);case _:
  return null;

}
}

}

/// @nodoc


class _AlertTemplatesLoaded implements AlertTemplatesEvent {
  const _AlertTemplatesLoaded(this.organization);
  

 final  Organization? organization;

/// Create a copy of AlertTemplatesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlertTemplatesLoadedCopyWith<_AlertTemplatesLoaded> get copyWith => __$AlertTemplatesLoadedCopyWithImpl<_AlertTemplatesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlertTemplatesLoaded&&(identical(other.organization, organization) || other.organization == organization));
}


@override
int get hashCode => Object.hash(runtimeType,organization);

@override
String toString() {
  return 'AlertTemplatesEvent.loaded(organization: $organization)';
}


}

/// @nodoc
abstract mixin class _$AlertTemplatesLoadedCopyWith<$Res> implements $AlertTemplatesEventCopyWith<$Res> {
  factory _$AlertTemplatesLoadedCopyWith(_AlertTemplatesLoaded value, $Res Function(_AlertTemplatesLoaded) _then) = __$AlertTemplatesLoadedCopyWithImpl;
@useResult
$Res call({
 Organization? organization
});


$OrganizationCopyWith<$Res>? get organization;

}
/// @nodoc
class __$AlertTemplatesLoadedCopyWithImpl<$Res>
    implements _$AlertTemplatesLoadedCopyWith<$Res> {
  __$AlertTemplatesLoadedCopyWithImpl(this._self, this._then);

  final _AlertTemplatesLoaded _self;
  final $Res Function(_AlertTemplatesLoaded) _then;

/// Create a copy of AlertTemplatesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = freezed,}) {
  return _then(_AlertTemplatesLoaded(
freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization?,
  ));
}

/// Create a copy of AlertTemplatesEvent
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


class _AlertTemplatesSaved implements AlertTemplatesEvent {
  const _AlertTemplatesSaved(final  Map<NotificationCategory, NotificationCopyOverride> overrides): _overrides = overrides;
  

 final  Map<NotificationCategory, NotificationCopyOverride> _overrides;
 Map<NotificationCategory, NotificationCopyOverride> get overrides {
  if (_overrides is EqualUnmodifiableMapView) return _overrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_overrides);
}


/// Create a copy of AlertTemplatesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlertTemplatesSavedCopyWith<_AlertTemplatesSaved> get copyWith => __$AlertTemplatesSavedCopyWithImpl<_AlertTemplatesSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlertTemplatesSaved&&const DeepCollectionEquality().equals(other._overrides, _overrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_overrides));

@override
String toString() {
  return 'AlertTemplatesEvent.saved(overrides: $overrides)';
}


}

/// @nodoc
abstract mixin class _$AlertTemplatesSavedCopyWith<$Res> implements $AlertTemplatesEventCopyWith<$Res> {
  factory _$AlertTemplatesSavedCopyWith(_AlertTemplatesSaved value, $Res Function(_AlertTemplatesSaved) _then) = __$AlertTemplatesSavedCopyWithImpl;
@useResult
$Res call({
 Map<NotificationCategory, NotificationCopyOverride> overrides
});




}
/// @nodoc
class __$AlertTemplatesSavedCopyWithImpl<$Res>
    implements _$AlertTemplatesSavedCopyWith<$Res> {
  __$AlertTemplatesSavedCopyWithImpl(this._self, this._then);

  final _AlertTemplatesSaved _self;
  final $Res Function(_AlertTemplatesSaved) _then;

/// Create a copy of AlertTemplatesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? overrides = null,}) {
  return _then(_AlertTemplatesSaved(
null == overrides ? _self._overrides : overrides // ignore: cast_nullable_to_non_nullable
as Map<NotificationCategory, NotificationCopyOverride>,
  ));
}


}

/// @nodoc
mixin _$AlertTemplatesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlertTemplatesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlertTemplatesState()';
}


}

/// @nodoc
class $AlertTemplatesStateCopyWith<$Res>  {
$AlertTemplatesStateCopyWith(AlertTemplatesState _, $Res Function(AlertTemplatesState) __);
}


/// Adds pattern-matching-related methods to [AlertTemplatesState].
extension AlertTemplatesStatePatterns on AlertTemplatesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AlertTemplatesLoading value)?  loading,TResult Function( AlertTemplatesMissing value)?  missing,TResult Function( AlertTemplatesReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AlertTemplatesLoading() when loading != null:
return loading(_that);case AlertTemplatesMissing() when missing != null:
return missing(_that);case AlertTemplatesReady() when ready != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AlertTemplatesLoading value)  loading,required TResult Function( AlertTemplatesMissing value)  missing,required TResult Function( AlertTemplatesReady value)  ready,}){
final _that = this;
switch (_that) {
case AlertTemplatesLoading():
return loading(_that);case AlertTemplatesMissing():
return missing(_that);case AlertTemplatesReady():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AlertTemplatesLoading value)?  loading,TResult? Function( AlertTemplatesMissing value)?  missing,TResult? Function( AlertTemplatesReady value)?  ready,}){
final _that = this;
switch (_that) {
case AlertTemplatesLoading() when loading != null:
return loading(_that);case AlertTemplatesMissing() when missing != null:
return missing(_that);case AlertTemplatesReady() when ready != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  missing,TResult Function( Organization organization,  AlertTemplatesSaveStatus saveStatus,  String? saveErrorMessage)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AlertTemplatesLoading() when loading != null:
return loading();case AlertTemplatesMissing() when missing != null:
return missing();case AlertTemplatesReady() when ready != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  missing,required TResult Function( Organization organization,  AlertTemplatesSaveStatus saveStatus,  String? saveErrorMessage)  ready,}) {final _that = this;
switch (_that) {
case AlertTemplatesLoading():
return loading();case AlertTemplatesMissing():
return missing();case AlertTemplatesReady():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  missing,TResult? Function( Organization organization,  AlertTemplatesSaveStatus saveStatus,  String? saveErrorMessage)?  ready,}) {final _that = this;
switch (_that) {
case AlertTemplatesLoading() when loading != null:
return loading();case AlertTemplatesMissing() when missing != null:
return missing();case AlertTemplatesReady() when ready != null:
return ready(_that.organization,_that.saveStatus,_that.saveErrorMessage);case _:
  return null;

}
}

}

/// @nodoc


class AlertTemplatesLoading implements AlertTemplatesState {
  const AlertTemplatesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlertTemplatesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlertTemplatesState.loading()';
}


}




/// @nodoc


class AlertTemplatesMissing implements AlertTemplatesState {
  const AlertTemplatesMissing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlertTemplatesMissing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlertTemplatesState.missing()';
}


}




/// @nodoc


class AlertTemplatesReady implements AlertTemplatesState {
  const AlertTemplatesReady({required this.organization, this.saveStatus = AlertTemplatesSaveStatus.idle, this.saveErrorMessage});
  

 final  Organization organization;
@JsonKey() final  AlertTemplatesSaveStatus saveStatus;
 final  String? saveErrorMessage;

/// Create a copy of AlertTemplatesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlertTemplatesReadyCopyWith<AlertTemplatesReady> get copyWith => _$AlertTemplatesReadyCopyWithImpl<AlertTemplatesReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlertTemplatesReady&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus)&&(identical(other.saveErrorMessage, saveErrorMessage) || other.saveErrorMessage == saveErrorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,organization,saveStatus,saveErrorMessage);

@override
String toString() {
  return 'AlertTemplatesState.ready(organization: $organization, saveStatus: $saveStatus, saveErrorMessage: $saveErrorMessage)';
}


}

/// @nodoc
abstract mixin class $AlertTemplatesReadyCopyWith<$Res> implements $AlertTemplatesStateCopyWith<$Res> {
  factory $AlertTemplatesReadyCopyWith(AlertTemplatesReady value, $Res Function(AlertTemplatesReady) _then) = _$AlertTemplatesReadyCopyWithImpl;
@useResult
$Res call({
 Organization organization, AlertTemplatesSaveStatus saveStatus, String? saveErrorMessage
});


$OrganizationCopyWith<$Res> get organization;

}
/// @nodoc
class _$AlertTemplatesReadyCopyWithImpl<$Res>
    implements $AlertTemplatesReadyCopyWith<$Res> {
  _$AlertTemplatesReadyCopyWithImpl(this._self, this._then);

  final AlertTemplatesReady _self;
  final $Res Function(AlertTemplatesReady) _then;

/// Create a copy of AlertTemplatesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? saveStatus = null,Object? saveErrorMessage = freezed,}) {
  return _then(AlertTemplatesReady(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as AlertTemplatesSaveStatus,saveErrorMessage: freezed == saveErrorMessage ? _self.saveErrorMessage : saveErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AlertTemplatesState
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
