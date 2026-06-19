// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPreferences {

@JsonKey(name: 'email_notifications_enabled') bool get emailNotificationsEnabled;@JsonKey(name: 'push_notifications_enabled') bool get pushNotificationsEnabled;@JsonKey(name: 'last_updated_instant') String get lastUpdatedInstant;
/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPreferencesCopyWith<UserPreferences> get copyWith => _$UserPreferencesCopyWithImpl<UserPreferences>(this as UserPreferences, _$identity);

  /// Serializes this UserPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferences&&(identical(other.emailNotificationsEnabled, emailNotificationsEnabled) || other.emailNotificationsEnabled == emailNotificationsEnabled)&&(identical(other.pushNotificationsEnabled, pushNotificationsEnabled) || other.pushNotificationsEnabled == pushNotificationsEnabled)&&(identical(other.lastUpdatedInstant, lastUpdatedInstant) || other.lastUpdatedInstant == lastUpdatedInstant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,emailNotificationsEnabled,pushNotificationsEnabled,lastUpdatedInstant);

@override
String toString() {
  return 'UserPreferences(emailNotificationsEnabled: $emailNotificationsEnabled, pushNotificationsEnabled: $pushNotificationsEnabled, lastUpdatedInstant: $lastUpdatedInstant)';
}


}

/// @nodoc
abstract mixin class $UserPreferencesCopyWith<$Res>  {
  factory $UserPreferencesCopyWith(UserPreferences value, $Res Function(UserPreferences) _then) = _$UserPreferencesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'email_notifications_enabled') bool emailNotificationsEnabled,@JsonKey(name: 'push_notifications_enabled') bool pushNotificationsEnabled,@JsonKey(name: 'last_updated_instant') String lastUpdatedInstant
});




}
/// @nodoc
class _$UserPreferencesCopyWithImpl<$Res>
    implements $UserPreferencesCopyWith<$Res> {
  _$UserPreferencesCopyWithImpl(this._self, this._then);

  final UserPreferences _self;
  final $Res Function(UserPreferences) _then;

/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emailNotificationsEnabled = null,Object? pushNotificationsEnabled = null,Object? lastUpdatedInstant = null,}) {
  return _then(_self.copyWith(
emailNotificationsEnabled: null == emailNotificationsEnabled ? _self.emailNotificationsEnabled : emailNotificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,pushNotificationsEnabled: null == pushNotificationsEnabled ? _self.pushNotificationsEnabled : pushNotificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastUpdatedInstant: null == lastUpdatedInstant ? _self.lastUpdatedInstant : lastUpdatedInstant // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPreferences].
extension UserPreferencesPatterns on UserPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPreferences value)  $default,){
final _that = this;
switch (_that) {
case _UserPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'email_notifications_enabled')  bool emailNotificationsEnabled, @JsonKey(name: 'push_notifications_enabled')  bool pushNotificationsEnabled, @JsonKey(name: 'last_updated_instant')  String lastUpdatedInstant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
return $default(_that.emailNotificationsEnabled,_that.pushNotificationsEnabled,_that.lastUpdatedInstant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'email_notifications_enabled')  bool emailNotificationsEnabled, @JsonKey(name: 'push_notifications_enabled')  bool pushNotificationsEnabled, @JsonKey(name: 'last_updated_instant')  String lastUpdatedInstant)  $default,) {final _that = this;
switch (_that) {
case _UserPreferences():
return $default(_that.emailNotificationsEnabled,_that.pushNotificationsEnabled,_that.lastUpdatedInstant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'email_notifications_enabled')  bool emailNotificationsEnabled, @JsonKey(name: 'push_notifications_enabled')  bool pushNotificationsEnabled, @JsonKey(name: 'last_updated_instant')  String lastUpdatedInstant)?  $default,) {final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
return $default(_that.emailNotificationsEnabled,_that.pushNotificationsEnabled,_that.lastUpdatedInstant);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPreferences implements UserPreferences {
  const _UserPreferences({@JsonKey(name: 'email_notifications_enabled') this.emailNotificationsEnabled = true, @JsonKey(name: 'push_notifications_enabled') this.pushNotificationsEnabled = true, @JsonKey(name: 'last_updated_instant') required this.lastUpdatedInstant});
  factory _UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);

@override@JsonKey(name: 'email_notifications_enabled') final  bool emailNotificationsEnabled;
@override@JsonKey(name: 'push_notifications_enabled') final  bool pushNotificationsEnabled;
@override@JsonKey(name: 'last_updated_instant') final  String lastUpdatedInstant;

/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesCopyWith<_UserPreferences> get copyWith => __$UserPreferencesCopyWithImpl<_UserPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferences&&(identical(other.emailNotificationsEnabled, emailNotificationsEnabled) || other.emailNotificationsEnabled == emailNotificationsEnabled)&&(identical(other.pushNotificationsEnabled, pushNotificationsEnabled) || other.pushNotificationsEnabled == pushNotificationsEnabled)&&(identical(other.lastUpdatedInstant, lastUpdatedInstant) || other.lastUpdatedInstant == lastUpdatedInstant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,emailNotificationsEnabled,pushNotificationsEnabled,lastUpdatedInstant);

@override
String toString() {
  return 'UserPreferences(emailNotificationsEnabled: $emailNotificationsEnabled, pushNotificationsEnabled: $pushNotificationsEnabled, lastUpdatedInstant: $lastUpdatedInstant)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesCopyWith<$Res> implements $UserPreferencesCopyWith<$Res> {
  factory _$UserPreferencesCopyWith(_UserPreferences value, $Res Function(_UserPreferences) _then) = __$UserPreferencesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'email_notifications_enabled') bool emailNotificationsEnabled,@JsonKey(name: 'push_notifications_enabled') bool pushNotificationsEnabled,@JsonKey(name: 'last_updated_instant') String lastUpdatedInstant
});




}
/// @nodoc
class __$UserPreferencesCopyWithImpl<$Res>
    implements _$UserPreferencesCopyWith<$Res> {
  __$UserPreferencesCopyWithImpl(this._self, this._then);

  final _UserPreferences _self;
  final $Res Function(_UserPreferences) _then;

/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emailNotificationsEnabled = null,Object? pushNotificationsEnabled = null,Object? lastUpdatedInstant = null,}) {
  return _then(_UserPreferences(
emailNotificationsEnabled: null == emailNotificationsEnabled ? _self.emailNotificationsEnabled : emailNotificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,pushNotificationsEnabled: null == pushNotificationsEnabled ? _self.pushNotificationsEnabled : pushNotificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastUpdatedInstant: null == lastUpdatedInstant ? _self.lastUpdatedInstant : lastUpdatedInstant // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
