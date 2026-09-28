// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberPreferences {

@JsonKey(name: 'delivery_reminders_enabled') bool get deliveryRemindersEnabled;@JsonKey(name: 'volunteer_alerts_enabled') bool get volunteerAlertsEnabled;@JsonKey(name: 'urgent_need_alerts_enabled') bool get urgentNeedAlertsEnabled;@JsonKey(name: 'incomplete_slot_reminders_enabled') bool get incompleteSlotRemindersEnabled;@JsonKey(name: 'planning_changes_alerts_enabled') bool get planningChangesAlertsEnabled;@JsonKey(name: 'last_updated_instant') String get lastUpdatedInstant;
/// Create a copy of MemberPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberPreferencesCopyWith<MemberPreferences> get copyWith => _$MemberPreferencesCopyWithImpl<MemberPreferences>(this as MemberPreferences, _$identity);

  /// Serializes this MemberPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberPreferences;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberPreferences&&(identical(other.deliveryRemindersEnabled, _this.deliveryRemindersEnabled) || other.deliveryRemindersEnabled == _this.deliveryRemindersEnabled)&&(identical(other.volunteerAlertsEnabled, _this.volunteerAlertsEnabled) || other.volunteerAlertsEnabled == _this.volunteerAlertsEnabled)&&(identical(other.urgentNeedAlertsEnabled, _this.urgentNeedAlertsEnabled) || other.urgentNeedAlertsEnabled == _this.urgentNeedAlertsEnabled)&&(identical(other.incompleteSlotRemindersEnabled, _this.incompleteSlotRemindersEnabled) || other.incompleteSlotRemindersEnabled == _this.incompleteSlotRemindersEnabled)&&(identical(other.planningChangesAlertsEnabled, _this.planningChangesAlertsEnabled) || other.planningChangesAlertsEnabled == _this.planningChangesAlertsEnabled)&&(identical(other.lastUpdatedInstant, _this.lastUpdatedInstant) || other.lastUpdatedInstant == _this.lastUpdatedInstant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberPreferences;
  return Object.hash(runtimeType,_this.deliveryRemindersEnabled,_this.volunteerAlertsEnabled,_this.urgentNeedAlertsEnabled,_this.incompleteSlotRemindersEnabled,_this.planningChangesAlertsEnabled,_this.lastUpdatedInstant);
}

@override
String toString() {
  final _this = this as MemberPreferences;
  return 'MemberPreferences(deliveryRemindersEnabled: ${_this.deliveryRemindersEnabled}, volunteerAlertsEnabled: ${_this.volunteerAlertsEnabled}, urgentNeedAlertsEnabled: ${_this.urgentNeedAlertsEnabled}, incompleteSlotRemindersEnabled: ${_this.incompleteSlotRemindersEnabled}, planningChangesAlertsEnabled: ${_this.planningChangesAlertsEnabled}, lastUpdatedInstant: ${_this.lastUpdatedInstant})';
}


}

/// @nodoc
abstract mixin class $MemberPreferencesCopyWith<$Res>  {
  factory $MemberPreferencesCopyWith(MemberPreferences value, $Res Function(MemberPreferences) _then) = _$MemberPreferencesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'delivery_reminders_enabled') bool deliveryRemindersEnabled,@JsonKey(name: 'volunteer_alerts_enabled') bool volunteerAlertsEnabled,@JsonKey(name: 'urgent_need_alerts_enabled') bool urgentNeedAlertsEnabled,@JsonKey(name: 'incomplete_slot_reminders_enabled') bool incompleteSlotRemindersEnabled,@JsonKey(name: 'planning_changes_alerts_enabled') bool planningChangesAlertsEnabled,@JsonKey(name: 'last_updated_instant') String lastUpdatedInstant
});




}
/// @nodoc
class _$MemberPreferencesCopyWithImpl<$Res>
    implements $MemberPreferencesCopyWith<$Res> {
  _$MemberPreferencesCopyWithImpl(this._self, this._then);

  final MemberPreferences _self;
  final $Res Function(MemberPreferences) _then;

/// Create a copy of MemberPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deliveryRemindersEnabled = null,Object? volunteerAlertsEnabled = null,Object? urgentNeedAlertsEnabled = null,Object? incompleteSlotRemindersEnabled = null,Object? planningChangesAlertsEnabled = null,Object? lastUpdatedInstant = null,}) {
  return _then(MemberPreferences(
deliveryRemindersEnabled: null == deliveryRemindersEnabled ? _self.deliveryRemindersEnabled : deliveryRemindersEnabled // ignore: cast_nullable_to_non_nullable
as bool,volunteerAlertsEnabled: null == volunteerAlertsEnabled ? _self.volunteerAlertsEnabled : volunteerAlertsEnabled // ignore: cast_nullable_to_non_nullable
as bool,urgentNeedAlertsEnabled: null == urgentNeedAlertsEnabled ? _self.urgentNeedAlertsEnabled : urgentNeedAlertsEnabled // ignore: cast_nullable_to_non_nullable
as bool,incompleteSlotRemindersEnabled: null == incompleteSlotRemindersEnabled ? _self.incompleteSlotRemindersEnabled : incompleteSlotRemindersEnabled // ignore: cast_nullable_to_non_nullable
as bool,planningChangesAlertsEnabled: null == planningChangesAlertsEnabled ? _self.planningChangesAlertsEnabled : planningChangesAlertsEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastUpdatedInstant: null == lastUpdatedInstant ? _self.lastUpdatedInstant : lastUpdatedInstant // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberPreferences].
extension MemberPreferencesPatterns on MemberPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberPreferences value)  $default,){
final _that = this;
switch (_that) {
case _MemberPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _MemberPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'delivery_reminders_enabled')  bool deliveryRemindersEnabled, @JsonKey(name: 'volunteer_alerts_enabled')  bool volunteerAlertsEnabled, @JsonKey(name: 'urgent_need_alerts_enabled')  bool urgentNeedAlertsEnabled, @JsonKey(name: 'incomplete_slot_reminders_enabled')  bool incompleteSlotRemindersEnabled, @JsonKey(name: 'planning_changes_alerts_enabled')  bool planningChangesAlertsEnabled, @JsonKey(name: 'last_updated_instant')  String lastUpdatedInstant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberPreferences() when $default != null:
return $default(_that.deliveryRemindersEnabled,_that.volunteerAlertsEnabled,_that.urgentNeedAlertsEnabled,_that.incompleteSlotRemindersEnabled,_that.planningChangesAlertsEnabled,_that.lastUpdatedInstant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'delivery_reminders_enabled')  bool deliveryRemindersEnabled, @JsonKey(name: 'volunteer_alerts_enabled')  bool volunteerAlertsEnabled, @JsonKey(name: 'urgent_need_alerts_enabled')  bool urgentNeedAlertsEnabled, @JsonKey(name: 'incomplete_slot_reminders_enabled')  bool incompleteSlotRemindersEnabled, @JsonKey(name: 'planning_changes_alerts_enabled')  bool planningChangesAlertsEnabled, @JsonKey(name: 'last_updated_instant')  String lastUpdatedInstant)  $default,) {final _that = this;
switch (_that) {
case _MemberPreferences():
return $default(_that.deliveryRemindersEnabled,_that.volunteerAlertsEnabled,_that.urgentNeedAlertsEnabled,_that.incompleteSlotRemindersEnabled,_that.planningChangesAlertsEnabled,_that.lastUpdatedInstant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'delivery_reminders_enabled')  bool deliveryRemindersEnabled, @JsonKey(name: 'volunteer_alerts_enabled')  bool volunteerAlertsEnabled, @JsonKey(name: 'urgent_need_alerts_enabled')  bool urgentNeedAlertsEnabled, @JsonKey(name: 'incomplete_slot_reminders_enabled')  bool incompleteSlotRemindersEnabled, @JsonKey(name: 'planning_changes_alerts_enabled')  bool planningChangesAlertsEnabled, @JsonKey(name: 'last_updated_instant')  String lastUpdatedInstant)?  $default,) {final _that = this;
switch (_that) {
case _MemberPreferences() when $default != null:
return $default(_that.deliveryRemindersEnabled,_that.volunteerAlertsEnabled,_that.urgentNeedAlertsEnabled,_that.incompleteSlotRemindersEnabled,_that.planningChangesAlertsEnabled,_that.lastUpdatedInstant);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberPreferences implements MemberPreferences {
  const _MemberPreferences({@JsonKey(name: 'delivery_reminders_enabled') this.deliveryRemindersEnabled = true, @JsonKey(name: 'volunteer_alerts_enabled') this.volunteerAlertsEnabled = true, @JsonKey(name: 'urgent_need_alerts_enabled') this.urgentNeedAlertsEnabled = true, @JsonKey(name: 'incomplete_slot_reminders_enabled') this.incompleteSlotRemindersEnabled = false, @JsonKey(name: 'planning_changes_alerts_enabled') this.planningChangesAlertsEnabled = true, @JsonKey(name: 'last_updated_instant') required this.lastUpdatedInstant});
  factory _MemberPreferences.fromJson(Map<String, dynamic> json) => _$MemberPreferencesFromJson(json);

@override@JsonKey(name: 'delivery_reminders_enabled') final  bool deliveryRemindersEnabled;
@override@JsonKey(name: 'volunteer_alerts_enabled') final  bool volunteerAlertsEnabled;
@override@JsonKey(name: 'urgent_need_alerts_enabled') final  bool urgentNeedAlertsEnabled;
@override@JsonKey(name: 'incomplete_slot_reminders_enabled') final  bool incompleteSlotRemindersEnabled;
@override@JsonKey(name: 'planning_changes_alerts_enabled') final  bool planningChangesAlertsEnabled;
@override@JsonKey(name: 'last_updated_instant') final  String lastUpdatedInstant;

/// Create a copy of MemberPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberPreferencesCopyWith<_MemberPreferences> get copyWith => __$MemberPreferencesCopyWithImpl<_MemberPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberPreferences&&(identical(other.deliveryRemindersEnabled, deliveryRemindersEnabled) || other.deliveryRemindersEnabled == deliveryRemindersEnabled)&&(identical(other.volunteerAlertsEnabled, volunteerAlertsEnabled) || other.volunteerAlertsEnabled == volunteerAlertsEnabled)&&(identical(other.urgentNeedAlertsEnabled, urgentNeedAlertsEnabled) || other.urgentNeedAlertsEnabled == urgentNeedAlertsEnabled)&&(identical(other.incompleteSlotRemindersEnabled, incompleteSlotRemindersEnabled) || other.incompleteSlotRemindersEnabled == incompleteSlotRemindersEnabled)&&(identical(other.planningChangesAlertsEnabled, planningChangesAlertsEnabled) || other.planningChangesAlertsEnabled == planningChangesAlertsEnabled)&&(identical(other.lastUpdatedInstant, lastUpdatedInstant) || other.lastUpdatedInstant == lastUpdatedInstant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,deliveryRemindersEnabled,volunteerAlertsEnabled,urgentNeedAlertsEnabled,incompleteSlotRemindersEnabled,planningChangesAlertsEnabled,lastUpdatedInstant);
}

@override
String toString() {
    return 'MemberPreferences(deliveryRemindersEnabled: $deliveryRemindersEnabled, volunteerAlertsEnabled: $volunteerAlertsEnabled, urgentNeedAlertsEnabled: $urgentNeedAlertsEnabled, incompleteSlotRemindersEnabled: $incompleteSlotRemindersEnabled, planningChangesAlertsEnabled: $planningChangesAlertsEnabled, lastUpdatedInstant: $lastUpdatedInstant)';
}


}

/// @nodoc
abstract mixin class _$MemberPreferencesCopyWith<$Res> implements $MemberPreferencesCopyWith<$Res> {
  factory _$MemberPreferencesCopyWith(_MemberPreferences value, $Res Function(_MemberPreferences) _then) = __$MemberPreferencesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'delivery_reminders_enabled') bool deliveryRemindersEnabled,@JsonKey(name: 'volunteer_alerts_enabled') bool volunteerAlertsEnabled,@JsonKey(name: 'urgent_need_alerts_enabled') bool urgentNeedAlertsEnabled,@JsonKey(name: 'incomplete_slot_reminders_enabled') bool incompleteSlotRemindersEnabled,@JsonKey(name: 'planning_changes_alerts_enabled') bool planningChangesAlertsEnabled,@JsonKey(name: 'last_updated_instant') String lastUpdatedInstant
});




}
/// @nodoc
class __$MemberPreferencesCopyWithImpl<$Res>
    implements _$MemberPreferencesCopyWith<$Res> {
  __$MemberPreferencesCopyWithImpl(this._self, this._then);

  final _MemberPreferences _self;
  final $Res Function(_MemberPreferences) _then;

/// Create a copy of MemberPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deliveryRemindersEnabled = null,Object? volunteerAlertsEnabled = null,Object? urgentNeedAlertsEnabled = null,Object? incompleteSlotRemindersEnabled = null,Object? planningChangesAlertsEnabled = null,Object? lastUpdatedInstant = null,}) {
  return _then(_MemberPreferences(
deliveryRemindersEnabled: null == deliveryRemindersEnabled ? _self.deliveryRemindersEnabled : deliveryRemindersEnabled // ignore: cast_nullable_to_non_nullable
as bool,volunteerAlertsEnabled: null == volunteerAlertsEnabled ? _self.volunteerAlertsEnabled : volunteerAlertsEnabled // ignore: cast_nullable_to_non_nullable
as bool,urgentNeedAlertsEnabled: null == urgentNeedAlertsEnabled ? _self.urgentNeedAlertsEnabled : urgentNeedAlertsEnabled // ignore: cast_nullable_to_non_nullable
as bool,incompleteSlotRemindersEnabled: null == incompleteSlotRemindersEnabled ? _self.incompleteSlotRemindersEnabled : incompleteSlotRemindersEnabled // ignore: cast_nullable_to_non_nullable
as bool,planningChangesAlertsEnabled: null == planningChangesAlertsEnabled ? _self.planningChangesAlertsEnabled : planningChangesAlertsEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastUpdatedInstant: null == lastUpdatedInstant ? _self.lastUpdatedInstant : lastUpdatedInstant // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
