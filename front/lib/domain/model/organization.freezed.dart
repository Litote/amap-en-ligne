// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberRegistration {

@JsonKey(name: 'member_id') String get memberId;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'member_email') String get memberEmail;// ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
@JsonKey(name: 'registration_instant') String get registrationInstant; RegistrationStatus get status;
/// Create a copy of MemberRegistration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberRegistrationCopyWith<MemberRegistration> get copyWith => _$MemberRegistrationCopyWithImpl<MemberRegistration>(this as MemberRegistration, _$identity);

  /// Serializes this MemberRegistration to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberRegistration&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.memberEmail, memberEmail) || other.memberEmail == memberEmail)&&(identical(other.registrationInstant, registrationInstant) || other.registrationInstant == registrationInstant)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,displayName,memberEmail,registrationInstant,status);

@override
String toString() {
  return 'MemberRegistration(memberId: $memberId, displayName: $displayName, memberEmail: $memberEmail, registrationInstant: $registrationInstant, status: $status)';
}


}

/// @nodoc
abstract mixin class $MemberRegistrationCopyWith<$Res>  {
  factory $MemberRegistrationCopyWith(MemberRegistration value, $Res Function(MemberRegistration) _then) = _$MemberRegistrationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'member_id') String memberId,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'member_email') String memberEmail,@JsonKey(name: 'registration_instant') String registrationInstant, RegistrationStatus status
});




}
/// @nodoc
class _$MemberRegistrationCopyWithImpl<$Res>
    implements $MemberRegistrationCopyWith<$Res> {
  _$MemberRegistrationCopyWithImpl(this._self, this._then);

  final MemberRegistration _self;
  final $Res Function(MemberRegistration) _then;

/// Create a copy of MemberRegistration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberId = null,Object? displayName = null,Object? memberEmail = null,Object? registrationInstant = null,Object? status = null,}) {
  return _then(_self.copyWith(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,memberEmail: null == memberEmail ? _self.memberEmail : memberEmail // ignore: cast_nullable_to_non_nullable
as String,registrationInstant: null == registrationInstant ? _self.registrationInstant : registrationInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegistrationStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberRegistration].
extension MemberRegistrationPatterns on MemberRegistration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberRegistration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberRegistration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberRegistration value)  $default,){
final _that = this;
switch (_that) {
case _MemberRegistration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberRegistration value)?  $default,){
final _that = this;
switch (_that) {
case _MemberRegistration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'member_email')  String memberEmail, @JsonKey(name: 'registration_instant')  String registrationInstant,  RegistrationStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberRegistration() when $default != null:
return $default(_that.memberId,_that.displayName,_that.memberEmail,_that.registrationInstant,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'member_email')  String memberEmail, @JsonKey(name: 'registration_instant')  String registrationInstant,  RegistrationStatus status)  $default,) {final _that = this;
switch (_that) {
case _MemberRegistration():
return $default(_that.memberId,_that.displayName,_that.memberEmail,_that.registrationInstant,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'member_email')  String memberEmail, @JsonKey(name: 'registration_instant')  String registrationInstant,  RegistrationStatus status)?  $default,) {final _that = this;
switch (_that) {
case _MemberRegistration() when $default != null:
return $default(_that.memberId,_that.displayName,_that.memberEmail,_that.registrationInstant,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberRegistration implements MemberRegistration {
  const _MemberRegistration({@JsonKey(name: 'member_id') required this.memberId, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'member_email') required this.memberEmail, @JsonKey(name: 'registration_instant') required this.registrationInstant, required this.status});
  factory _MemberRegistration.fromJson(Map<String, dynamic> json) => _$MemberRegistrationFromJson(json);

@override@JsonKey(name: 'member_id') final  String memberId;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'member_email') final  String memberEmail;
// ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
@override@JsonKey(name: 'registration_instant') final  String registrationInstant;
@override final  RegistrationStatus status;

/// Create a copy of MemberRegistration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberRegistrationCopyWith<_MemberRegistration> get copyWith => __$MemberRegistrationCopyWithImpl<_MemberRegistration>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberRegistrationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberRegistration&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.memberEmail, memberEmail) || other.memberEmail == memberEmail)&&(identical(other.registrationInstant, registrationInstant) || other.registrationInstant == registrationInstant)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,displayName,memberEmail,registrationInstant,status);

@override
String toString() {
  return 'MemberRegistration(memberId: $memberId, displayName: $displayName, memberEmail: $memberEmail, registrationInstant: $registrationInstant, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MemberRegistrationCopyWith<$Res> implements $MemberRegistrationCopyWith<$Res> {
  factory _$MemberRegistrationCopyWith(_MemberRegistration value, $Res Function(_MemberRegistration) _then) = __$MemberRegistrationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'member_id') String memberId,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'member_email') String memberEmail,@JsonKey(name: 'registration_instant') String registrationInstant, RegistrationStatus status
});




}
/// @nodoc
class __$MemberRegistrationCopyWithImpl<$Res>
    implements _$MemberRegistrationCopyWith<$Res> {
  __$MemberRegistrationCopyWithImpl(this._self, this._then);

  final _MemberRegistration _self;
  final $Res Function(_MemberRegistration) _then;

/// Create a copy of MemberRegistration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberId = null,Object? displayName = null,Object? memberEmail = null,Object? registrationInstant = null,Object? status = null,}) {
  return _then(_MemberRegistration(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,memberEmail: null == memberEmail ? _self.memberEmail : memberEmail // ignore: cast_nullable_to_non_nullable
as String,registrationInstant: null == registrationInstant ? _self.registrationInstant : registrationInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegistrationStatus,
  ));
}


}


/// @nodoc
mixin _$MemberSlot {

/// Server-allocated slot identity (nullable for legacy slots not yet
/// backfilled). Preserved as-is on edits — never generated client-side.
@JsonKey(name: 'slot_id') String? get slotId;// ISO-8601 string, e.g. "2025-06-14T09:00:00"
@JsonKey(name: 'start_time') String get startTime;@JsonKey(name: 'end_time') String get endTime;@JsonKey(name: 'activity_type') ActivityType get activityType;@JsonKey(name: 'required_volunteers') int get requiredVolunteers;@JsonKey(name: 'current_registrations') int get currentRegistrations; SlotStatus get status;/// Distinguishes standard slots from early-arrival slots.
/// Defaults to [SlotKind.standard] so legacy JSON without this field
/// deserializes correctly.
@JsonKey(name: 'slot_kind') SlotKind get slotKind; List<MemberRegistration> get registrations;
/// Create a copy of MemberSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberSlotCopyWith<MemberSlot> get copyWith => _$MemberSlotCopyWithImpl<MemberSlot>(this as MemberSlot, _$identity);

  /// Serializes this MemberSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberSlot&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.activityType, activityType) || other.activityType == activityType)&&(identical(other.requiredVolunteers, requiredVolunteers) || other.requiredVolunteers == requiredVolunteers)&&(identical(other.currentRegistrations, currentRegistrations) || other.currentRegistrations == currentRegistrations)&&(identical(other.status, status) || other.status == status)&&(identical(other.slotKind, slotKind) || other.slotKind == slotKind)&&const DeepCollectionEquality().equals(other.registrations, registrations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slotId,startTime,endTime,activityType,requiredVolunteers,currentRegistrations,status,slotKind,const DeepCollectionEquality().hash(registrations));

@override
String toString() {
  return 'MemberSlot(slotId: $slotId, startTime: $startTime, endTime: $endTime, activityType: $activityType, requiredVolunteers: $requiredVolunteers, currentRegistrations: $currentRegistrations, status: $status, slotKind: $slotKind, registrations: $registrations)';
}


}

/// @nodoc
abstract mixin class $MemberSlotCopyWith<$Res>  {
  factory $MemberSlotCopyWith(MemberSlot value, $Res Function(MemberSlot) _then) = _$MemberSlotCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'slot_id') String? slotId,@JsonKey(name: 'start_time') String startTime,@JsonKey(name: 'end_time') String endTime,@JsonKey(name: 'activity_type') ActivityType activityType,@JsonKey(name: 'required_volunteers') int requiredVolunteers,@JsonKey(name: 'current_registrations') int currentRegistrations, SlotStatus status,@JsonKey(name: 'slot_kind') SlotKind slotKind, List<MemberRegistration> registrations
});




}
/// @nodoc
class _$MemberSlotCopyWithImpl<$Res>
    implements $MemberSlotCopyWith<$Res> {
  _$MemberSlotCopyWithImpl(this._self, this._then);

  final MemberSlot _self;
  final $Res Function(MemberSlot) _then;

/// Create a copy of MemberSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slotId = freezed,Object? startTime = null,Object? endTime = null,Object? activityType = null,Object? requiredVolunteers = null,Object? currentRegistrations = null,Object? status = null,Object? slotKind = null,Object? registrations = null,}) {
  return _then(_self.copyWith(
slotId: freezed == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,activityType: null == activityType ? _self.activityType : activityType // ignore: cast_nullable_to_non_nullable
as ActivityType,requiredVolunteers: null == requiredVolunteers ? _self.requiredVolunteers : requiredVolunteers // ignore: cast_nullable_to_non_nullable
as int,currentRegistrations: null == currentRegistrations ? _self.currentRegistrations : currentRegistrations // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SlotStatus,slotKind: null == slotKind ? _self.slotKind : slotKind // ignore: cast_nullable_to_non_nullable
as SlotKind,registrations: null == registrations ? _self.registrations : registrations // ignore: cast_nullable_to_non_nullable
as List<MemberRegistration>,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberSlot].
extension MemberSlotPatterns on MemberSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberSlot value)  $default,){
final _that = this;
switch (_that) {
case _MemberSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberSlot value)?  $default,){
final _that = this;
switch (_that) {
case _MemberSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'slot_id')  String? slotId, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(name: 'activity_type')  ActivityType activityType, @JsonKey(name: 'required_volunteers')  int requiredVolunteers, @JsonKey(name: 'current_registrations')  int currentRegistrations,  SlotStatus status, @JsonKey(name: 'slot_kind')  SlotKind slotKind,  List<MemberRegistration> registrations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberSlot() when $default != null:
return $default(_that.slotId,_that.startTime,_that.endTime,_that.activityType,_that.requiredVolunteers,_that.currentRegistrations,_that.status,_that.slotKind,_that.registrations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'slot_id')  String? slotId, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(name: 'activity_type')  ActivityType activityType, @JsonKey(name: 'required_volunteers')  int requiredVolunteers, @JsonKey(name: 'current_registrations')  int currentRegistrations,  SlotStatus status, @JsonKey(name: 'slot_kind')  SlotKind slotKind,  List<MemberRegistration> registrations)  $default,) {final _that = this;
switch (_that) {
case _MemberSlot():
return $default(_that.slotId,_that.startTime,_that.endTime,_that.activityType,_that.requiredVolunteers,_that.currentRegistrations,_that.status,_that.slotKind,_that.registrations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'slot_id')  String? slotId, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(name: 'activity_type')  ActivityType activityType, @JsonKey(name: 'required_volunteers')  int requiredVolunteers, @JsonKey(name: 'current_registrations')  int currentRegistrations,  SlotStatus status, @JsonKey(name: 'slot_kind')  SlotKind slotKind,  List<MemberRegistration> registrations)?  $default,) {final _that = this;
switch (_that) {
case _MemberSlot() when $default != null:
return $default(_that.slotId,_that.startTime,_that.endTime,_that.activityType,_that.requiredVolunteers,_that.currentRegistrations,_that.status,_that.slotKind,_that.registrations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberSlot implements MemberSlot {
  const _MemberSlot({@JsonKey(name: 'slot_id') this.slotId, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') required this.endTime, @JsonKey(name: 'activity_type') required this.activityType, @JsonKey(name: 'required_volunteers') required this.requiredVolunteers, @JsonKey(name: 'current_registrations') required this.currentRegistrations, required this.status, @JsonKey(name: 'slot_kind') this.slotKind = SlotKind.standard, final  List<MemberRegistration> registrations = const []}): _registrations = registrations;
  factory _MemberSlot.fromJson(Map<String, dynamic> json) => _$MemberSlotFromJson(json);

/// Server-allocated slot identity (nullable for legacy slots not yet
/// backfilled). Preserved as-is on edits — never generated client-side.
@override@JsonKey(name: 'slot_id') final  String? slotId;
// ISO-8601 string, e.g. "2025-06-14T09:00:00"
@override@JsonKey(name: 'start_time') final  String startTime;
@override@JsonKey(name: 'end_time') final  String endTime;
@override@JsonKey(name: 'activity_type') final  ActivityType activityType;
@override@JsonKey(name: 'required_volunteers') final  int requiredVolunteers;
@override@JsonKey(name: 'current_registrations') final  int currentRegistrations;
@override final  SlotStatus status;
/// Distinguishes standard slots from early-arrival slots.
/// Defaults to [SlotKind.standard] so legacy JSON without this field
/// deserializes correctly.
@override@JsonKey(name: 'slot_kind') final  SlotKind slotKind;
 final  List<MemberRegistration> _registrations;
@override@JsonKey() List<MemberRegistration> get registrations {
  if (_registrations is EqualUnmodifiableListView) return _registrations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_registrations);
}


/// Create a copy of MemberSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberSlotCopyWith<_MemberSlot> get copyWith => __$MemberSlotCopyWithImpl<_MemberSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberSlot&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.activityType, activityType) || other.activityType == activityType)&&(identical(other.requiredVolunteers, requiredVolunteers) || other.requiredVolunteers == requiredVolunteers)&&(identical(other.currentRegistrations, currentRegistrations) || other.currentRegistrations == currentRegistrations)&&(identical(other.status, status) || other.status == status)&&(identical(other.slotKind, slotKind) || other.slotKind == slotKind)&&const DeepCollectionEquality().equals(other._registrations, _registrations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slotId,startTime,endTime,activityType,requiredVolunteers,currentRegistrations,status,slotKind,const DeepCollectionEquality().hash(_registrations));

@override
String toString() {
  return 'MemberSlot(slotId: $slotId, startTime: $startTime, endTime: $endTime, activityType: $activityType, requiredVolunteers: $requiredVolunteers, currentRegistrations: $currentRegistrations, status: $status, slotKind: $slotKind, registrations: $registrations)';
}


}

/// @nodoc
abstract mixin class _$MemberSlotCopyWith<$Res> implements $MemberSlotCopyWith<$Res> {
  factory _$MemberSlotCopyWith(_MemberSlot value, $Res Function(_MemberSlot) _then) = __$MemberSlotCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'slot_id') String? slotId,@JsonKey(name: 'start_time') String startTime,@JsonKey(name: 'end_time') String endTime,@JsonKey(name: 'activity_type') ActivityType activityType,@JsonKey(name: 'required_volunteers') int requiredVolunteers,@JsonKey(name: 'current_registrations') int currentRegistrations, SlotStatus status,@JsonKey(name: 'slot_kind') SlotKind slotKind, List<MemberRegistration> registrations
});




}
/// @nodoc
class __$MemberSlotCopyWithImpl<$Res>
    implements _$MemberSlotCopyWith<$Res> {
  __$MemberSlotCopyWithImpl(this._self, this._then);

  final _MemberSlot _self;
  final $Res Function(_MemberSlot) _then;

/// Create a copy of MemberSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slotId = freezed,Object? startTime = null,Object? endTime = null,Object? activityType = null,Object? requiredVolunteers = null,Object? currentRegistrations = null,Object? status = null,Object? slotKind = null,Object? registrations = null,}) {
  return _then(_MemberSlot(
slotId: freezed == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,activityType: null == activityType ? _self.activityType : activityType // ignore: cast_nullable_to_non_nullable
as ActivityType,requiredVolunteers: null == requiredVolunteers ? _self.requiredVolunteers : requiredVolunteers // ignore: cast_nullable_to_non_nullable
as int,currentRegistrations: null == currentRegistrations ? _self.currentRegistrations : currentRegistrations // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SlotStatus,slotKind: null == slotKind ? _self.slotKind : slotKind // ignore: cast_nullable_to_non_nullable
as SlotKind,registrations: null == registrations ? _self._registrations : registrations // ignore: cast_nullable_to_non_nullable
as List<MemberRegistration>,
  ));
}


}


/// @nodoc
mixin _$DeliveryContract {

@JsonKey(name: 'contract_id') String get contractId;@JsonKey(name: 'coordinators') List<String> get coordinators;@JsonKey(name: 'basket_quantity') int get basketQuantity;@JsonKey(name: 'delivery_description') String get deliveryDescription;@JsonKey(name: 'preparation_notes') String? get preparationNotes; DeliveryContractStatus get status; List<MemberSlot> get slots;
/// Create a copy of DeliveryContract
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryContractCopyWith<DeliveryContract> get copyWith => _$DeliveryContractCopyWithImpl<DeliveryContract>(this as DeliveryContract, _$identity);

  /// Serializes this DeliveryContract to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryContract&&(identical(other.contractId, contractId) || other.contractId == contractId)&&const DeepCollectionEquality().equals(other.coordinators, coordinators)&&(identical(other.basketQuantity, basketQuantity) || other.basketQuantity == basketQuantity)&&(identical(other.deliveryDescription, deliveryDescription) || other.deliveryDescription == deliveryDescription)&&(identical(other.preparationNotes, preparationNotes) || other.preparationNotes == preparationNotes)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.slots, slots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractId,const DeepCollectionEquality().hash(coordinators),basketQuantity,deliveryDescription,preparationNotes,status,const DeepCollectionEquality().hash(slots));

@override
String toString() {
  return 'DeliveryContract(contractId: $contractId, coordinators: $coordinators, basketQuantity: $basketQuantity, deliveryDescription: $deliveryDescription, preparationNotes: $preparationNotes, status: $status, slots: $slots)';
}


}

/// @nodoc
abstract mixin class $DeliveryContractCopyWith<$Res>  {
  factory $DeliveryContractCopyWith(DeliveryContract value, $Res Function(DeliveryContract) _then) = _$DeliveryContractCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'coordinators') List<String> coordinators,@JsonKey(name: 'basket_quantity') int basketQuantity,@JsonKey(name: 'delivery_description') String deliveryDescription,@JsonKey(name: 'preparation_notes') String? preparationNotes, DeliveryContractStatus status, List<MemberSlot> slots
});




}
/// @nodoc
class _$DeliveryContractCopyWithImpl<$Res>
    implements $DeliveryContractCopyWith<$Res> {
  _$DeliveryContractCopyWithImpl(this._self, this._then);

  final DeliveryContract _self;
  final $Res Function(DeliveryContract) _then;

/// Create a copy of DeliveryContract
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractId = null,Object? coordinators = null,Object? basketQuantity = null,Object? deliveryDescription = null,Object? preparationNotes = freezed,Object? status = null,Object? slots = null,}) {
  return _then(_self.copyWith(
contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,coordinators: null == coordinators ? _self.coordinators : coordinators // ignore: cast_nullable_to_non_nullable
as List<String>,basketQuantity: null == basketQuantity ? _self.basketQuantity : basketQuantity // ignore: cast_nullable_to_non_nullable
as int,deliveryDescription: null == deliveryDescription ? _self.deliveryDescription : deliveryDescription // ignore: cast_nullable_to_non_nullable
as String,preparationNotes: freezed == preparationNotes ? _self.preparationNotes : preparationNotes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeliveryContractStatus,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<MemberSlot>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryContract].
extension DeliveryContractPatterns on DeliveryContract {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryContract value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryContract() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryContract value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryContract():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryContract value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryContract() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'coordinators')  List<String> coordinators, @JsonKey(name: 'basket_quantity')  int basketQuantity, @JsonKey(name: 'delivery_description')  String deliveryDescription, @JsonKey(name: 'preparation_notes')  String? preparationNotes,  DeliveryContractStatus status,  List<MemberSlot> slots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryContract() when $default != null:
return $default(_that.contractId,_that.coordinators,_that.basketQuantity,_that.deliveryDescription,_that.preparationNotes,_that.status,_that.slots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'coordinators')  List<String> coordinators, @JsonKey(name: 'basket_quantity')  int basketQuantity, @JsonKey(name: 'delivery_description')  String deliveryDescription, @JsonKey(name: 'preparation_notes')  String? preparationNotes,  DeliveryContractStatus status,  List<MemberSlot> slots)  $default,) {final _that = this;
switch (_that) {
case _DeliveryContract():
return $default(_that.contractId,_that.coordinators,_that.basketQuantity,_that.deliveryDescription,_that.preparationNotes,_that.status,_that.slots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'coordinators')  List<String> coordinators, @JsonKey(name: 'basket_quantity')  int basketQuantity, @JsonKey(name: 'delivery_description')  String deliveryDescription, @JsonKey(name: 'preparation_notes')  String? preparationNotes,  DeliveryContractStatus status,  List<MemberSlot> slots)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryContract() when $default != null:
return $default(_that.contractId,_that.coordinators,_that.basketQuantity,_that.deliveryDescription,_that.preparationNotes,_that.status,_that.slots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryContract implements DeliveryContract {
  const _DeliveryContract({@JsonKey(name: 'contract_id') required this.contractId, @JsonKey(name: 'coordinators') final  List<String> coordinators = const <String>[], @JsonKey(name: 'basket_quantity') required this.basketQuantity, @JsonKey(name: 'delivery_description') required this.deliveryDescription, @JsonKey(name: 'preparation_notes') this.preparationNotes, required this.status, final  List<MemberSlot> slots = const []}): _coordinators = coordinators,_slots = slots;
  factory _DeliveryContract.fromJson(Map<String, dynamic> json) => _$DeliveryContractFromJson(json);

@override@JsonKey(name: 'contract_id') final  String contractId;
 final  List<String> _coordinators;
@override@JsonKey(name: 'coordinators') List<String> get coordinators {
  if (_coordinators is EqualUnmodifiableListView) return _coordinators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coordinators);
}

@override@JsonKey(name: 'basket_quantity') final  int basketQuantity;
@override@JsonKey(name: 'delivery_description') final  String deliveryDescription;
@override@JsonKey(name: 'preparation_notes') final  String? preparationNotes;
@override final  DeliveryContractStatus status;
 final  List<MemberSlot> _slots;
@override@JsonKey() List<MemberSlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}


/// Create a copy of DeliveryContract
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryContractCopyWith<_DeliveryContract> get copyWith => __$DeliveryContractCopyWithImpl<_DeliveryContract>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryContractToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryContract&&(identical(other.contractId, contractId) || other.contractId == contractId)&&const DeepCollectionEquality().equals(other._coordinators, _coordinators)&&(identical(other.basketQuantity, basketQuantity) || other.basketQuantity == basketQuantity)&&(identical(other.deliveryDescription, deliveryDescription) || other.deliveryDescription == deliveryDescription)&&(identical(other.preparationNotes, preparationNotes) || other.preparationNotes == preparationNotes)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._slots, _slots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractId,const DeepCollectionEquality().hash(_coordinators),basketQuantity,deliveryDescription,preparationNotes,status,const DeepCollectionEquality().hash(_slots));

@override
String toString() {
  return 'DeliveryContract(contractId: $contractId, coordinators: $coordinators, basketQuantity: $basketQuantity, deliveryDescription: $deliveryDescription, preparationNotes: $preparationNotes, status: $status, slots: $slots)';
}


}

/// @nodoc
abstract mixin class _$DeliveryContractCopyWith<$Res> implements $DeliveryContractCopyWith<$Res> {
  factory _$DeliveryContractCopyWith(_DeliveryContract value, $Res Function(_DeliveryContract) _then) = __$DeliveryContractCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'coordinators') List<String> coordinators,@JsonKey(name: 'basket_quantity') int basketQuantity,@JsonKey(name: 'delivery_description') String deliveryDescription,@JsonKey(name: 'preparation_notes') String? preparationNotes, DeliveryContractStatus status, List<MemberSlot> slots
});




}
/// @nodoc
class __$DeliveryContractCopyWithImpl<$Res>
    implements _$DeliveryContractCopyWith<$Res> {
  __$DeliveryContractCopyWithImpl(this._self, this._then);

  final _DeliveryContract _self;
  final $Res Function(_DeliveryContract) _then;

/// Create a copy of DeliveryContract
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractId = null,Object? coordinators = null,Object? basketQuantity = null,Object? deliveryDescription = null,Object? preparationNotes = freezed,Object? status = null,Object? slots = null,}) {
  return _then(_DeliveryContract(
contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,coordinators: null == coordinators ? _self._coordinators : coordinators // ignore: cast_nullable_to_non_nullable
as List<String>,basketQuantity: null == basketQuantity ? _self.basketQuantity : basketQuantity // ignore: cast_nullable_to_non_nullable
as int,deliveryDescription: null == deliveryDescription ? _self.deliveryDescription : deliveryDescription // ignore: cast_nullable_to_non_nullable
as String,preparationNotes: freezed == preparationNotes ? _self.preparationNotes : preparationNotes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeliveryContractStatus,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<MemberSlot>,
  ));
}


}


/// @nodoc
mixin _$DeliveryItem {

@JsonKey(name: 'item_type_id') String get itemTypeId;// Tiny denormalised label snapshot (historical accuracy / resilience); the heavy SVG icon is
// resolved by itemTypeId from the org-level Organization.itemTypes catalog, never duplicated here.
 String get name; String? get weight;
/// Create a copy of DeliveryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryItemCopyWith<DeliveryItem> get copyWith => _$DeliveryItemCopyWithImpl<DeliveryItem>(this as DeliveryItem, _$identity);

  /// Serializes this DeliveryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryItem&&(identical(other.itemTypeId, itemTypeId) || other.itemTypeId == itemTypeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemTypeId,name,weight);

@override
String toString() {
  return 'DeliveryItem(itemTypeId: $itemTypeId, name: $name, weight: $weight)';
}


}

/// @nodoc
abstract mixin class $DeliveryItemCopyWith<$Res>  {
  factory $DeliveryItemCopyWith(DeliveryItem value, $Res Function(DeliveryItem) _then) = _$DeliveryItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'item_type_id') String itemTypeId, String name, String? weight
});




}
/// @nodoc
class _$DeliveryItemCopyWithImpl<$Res>
    implements $DeliveryItemCopyWith<$Res> {
  _$DeliveryItemCopyWithImpl(this._self, this._then);

  final DeliveryItem _self;
  final $Res Function(DeliveryItem) _then;

/// Create a copy of DeliveryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemTypeId = null,Object? name = null,Object? weight = freezed,}) {
  return _then(_self.copyWith(
itemTypeId: null == itemTypeId ? _self.itemTypeId : itemTypeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryItem].
extension DeliveryItemPatterns on DeliveryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryItem value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryItem value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'item_type_id')  String itemTypeId,  String name,  String? weight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryItem() when $default != null:
return $default(_that.itemTypeId,_that.name,_that.weight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'item_type_id')  String itemTypeId,  String name,  String? weight)  $default,) {final _that = this;
switch (_that) {
case _DeliveryItem():
return $default(_that.itemTypeId,_that.name,_that.weight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'item_type_id')  String itemTypeId,  String name,  String? weight)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryItem() when $default != null:
return $default(_that.itemTypeId,_that.name,_that.weight);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryItem implements DeliveryItem {
  const _DeliveryItem({@JsonKey(name: 'item_type_id') required this.itemTypeId, this.name = '', this.weight});
  factory _DeliveryItem.fromJson(Map<String, dynamic> json) => _$DeliveryItemFromJson(json);

@override@JsonKey(name: 'item_type_id') final  String itemTypeId;
// Tiny denormalised label snapshot (historical accuracy / resilience); the heavy SVG icon is
// resolved by itemTypeId from the org-level Organization.itemTypes catalog, never duplicated here.
@override@JsonKey() final  String name;
@override final  String? weight;

/// Create a copy of DeliveryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryItemCopyWith<_DeliveryItem> get copyWith => __$DeliveryItemCopyWithImpl<_DeliveryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryItem&&(identical(other.itemTypeId, itemTypeId) || other.itemTypeId == itemTypeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemTypeId,name,weight);

@override
String toString() {
  return 'DeliveryItem(itemTypeId: $itemTypeId, name: $name, weight: $weight)';
}


}

/// @nodoc
abstract mixin class _$DeliveryItemCopyWith<$Res> implements $DeliveryItemCopyWith<$Res> {
  factory _$DeliveryItemCopyWith(_DeliveryItem value, $Res Function(_DeliveryItem) _then) = __$DeliveryItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'item_type_id') String itemTypeId, String name, String? weight
});




}
/// @nodoc
class __$DeliveryItemCopyWithImpl<$Res>
    implements _$DeliveryItemCopyWith<$Res> {
  __$DeliveryItemCopyWithImpl(this._self, this._then);

  final _DeliveryItem _self;
  final $Res Function(_DeliveryItem) _then;

/// Create a copy of DeliveryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemTypeId = null,Object? name = null,Object? weight = freezed,}) {
  return _then(_DeliveryItem(
itemTypeId: null == itemTypeId ? _self.itemTypeId : itemTypeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BasketDeliveryDescription {

@JsonKey(name: 'product_type_id') String get productTypeId;@JsonKey(name: 'basket_size_name') String get basketSizeName; List<DeliveryItem> get items;
/// Create a copy of BasketDeliveryDescription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketDeliveryDescriptionCopyWith<BasketDeliveryDescription> get copyWith => _$BasketDeliveryDescriptionCopyWithImpl<BasketDeliveryDescription>(this as BasketDeliveryDescription, _$identity);

  /// Serializes this BasketDeliveryDescription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketDeliveryDescription&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.basketSizeName, basketSizeName) || other.basketSizeName == basketSizeName)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productTypeId,basketSizeName,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'BasketDeliveryDescription(productTypeId: $productTypeId, basketSizeName: $basketSizeName, items: $items)';
}


}

/// @nodoc
abstract mixin class $BasketDeliveryDescriptionCopyWith<$Res>  {
  factory $BasketDeliveryDescriptionCopyWith(BasketDeliveryDescription value, $Res Function(BasketDeliveryDescription) _then) = _$BasketDeliveryDescriptionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'basket_size_name') String basketSizeName, List<DeliveryItem> items
});




}
/// @nodoc
class _$BasketDeliveryDescriptionCopyWithImpl<$Res>
    implements $BasketDeliveryDescriptionCopyWith<$Res> {
  _$BasketDeliveryDescriptionCopyWithImpl(this._self, this._then);

  final BasketDeliveryDescription _self;
  final $Res Function(BasketDeliveryDescription) _then;

/// Create a copy of BasketDeliveryDescription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productTypeId = null,Object? basketSizeName = null,Object? items = null,}) {
  return _then(_self.copyWith(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,basketSizeName: null == basketSizeName ? _self.basketSizeName : basketSizeName // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<DeliveryItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [BasketDeliveryDescription].
extension BasketDeliveryDescriptionPatterns on BasketDeliveryDescription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketDeliveryDescription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketDeliveryDescription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketDeliveryDescription value)  $default,){
final _that = this;
switch (_that) {
case _BasketDeliveryDescription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketDeliveryDescription value)?  $default,){
final _that = this;
switch (_that) {
case _BasketDeliveryDescription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size_name')  String basketSizeName,  List<DeliveryItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketDeliveryDescription() when $default != null:
return $default(_that.productTypeId,_that.basketSizeName,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size_name')  String basketSizeName,  List<DeliveryItem> items)  $default,) {final _that = this;
switch (_that) {
case _BasketDeliveryDescription():
return $default(_that.productTypeId,_that.basketSizeName,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size_name')  String basketSizeName,  List<DeliveryItem> items)?  $default,) {final _that = this;
switch (_that) {
case _BasketDeliveryDescription() when $default != null:
return $default(_that.productTypeId,_that.basketSizeName,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BasketDeliveryDescription implements BasketDeliveryDescription {
  const _BasketDeliveryDescription({@JsonKey(name: 'product_type_id') required this.productTypeId, @JsonKey(name: 'basket_size_name') required this.basketSizeName, final  List<DeliveryItem> items = const <DeliveryItem>[]}): _items = items;
  factory _BasketDeliveryDescription.fromJson(Map<String, dynamic> json) => _$BasketDeliveryDescriptionFromJson(json);

@override@JsonKey(name: 'product_type_id') final  String productTypeId;
@override@JsonKey(name: 'basket_size_name') final  String basketSizeName;
 final  List<DeliveryItem> _items;
@override@JsonKey() List<DeliveryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BasketDeliveryDescription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketDeliveryDescriptionCopyWith<_BasketDeliveryDescription> get copyWith => __$BasketDeliveryDescriptionCopyWithImpl<_BasketDeliveryDescription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BasketDeliveryDescriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketDeliveryDescription&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.basketSizeName, basketSizeName) || other.basketSizeName == basketSizeName)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productTypeId,basketSizeName,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'BasketDeliveryDescription(productTypeId: $productTypeId, basketSizeName: $basketSizeName, items: $items)';
}


}

/// @nodoc
abstract mixin class _$BasketDeliveryDescriptionCopyWith<$Res> implements $BasketDeliveryDescriptionCopyWith<$Res> {
  factory _$BasketDeliveryDescriptionCopyWith(_BasketDeliveryDescription value, $Res Function(_BasketDeliveryDescription) _then) = __$BasketDeliveryDescriptionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'basket_size_name') String basketSizeName, List<DeliveryItem> items
});




}
/// @nodoc
class __$BasketDeliveryDescriptionCopyWithImpl<$Res>
    implements _$BasketDeliveryDescriptionCopyWith<$Res> {
  __$BasketDeliveryDescriptionCopyWithImpl(this._self, this._then);

  final _BasketDeliveryDescription _self;
  final $Res Function(_BasketDeliveryDescription) _then;

/// Create a copy of BasketDeliveryDescription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productTypeId = null,Object? basketSizeName = null,Object? items = null,}) {
  return _then(_BasketDeliveryDescription(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,basketSizeName: null == basketSizeName ? _self.basketSizeName : basketSizeName // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DeliveryItem>,
  ));
}


}


/// @nodoc
mixin _$Delivery {

@JsonKey(name: 'delivery_id') String get deliveryId;@JsonKey(name: 'organization_id') String get organizationId;// ISO-8601 string, e.g. "2025-06-14T09:00:00"
@JsonKey(name: 'scheduled_date') String get scheduledDate; DeliveryStatus get status;@JsonKey(name: 'min_volunteers_required') int get minVolunteersRequired;@JsonKey(name: 'delivery_template_id') String? get deliveryTemplateId;// Per-delivery overrides of the template's slot times ("HH:MM"); null falls back
// to the linked template, then to the hard-coded defaults. An early slot may be
// defined here even without a template.
@JsonKey(name: 'standard_end_time') String? get standardEndTime;@JsonKey(name: 'volunteer_arrival_time') String? get volunteerArrivalTime;@JsonKey(name: 'early_slot') EarlySlot? get earlySlot; List<DeliveryContract> get contracts;@JsonKey(name: 'basket_descriptions') List<BasketDeliveryDescription> get basketDescriptions;
/// Create a copy of Delivery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryCopyWith<Delivery> get copyWith => _$DeliveryCopyWithImpl<Delivery>(this as Delivery, _$identity);

  /// Serializes this Delivery to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Delivery&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.minVolunteersRequired, minVolunteersRequired) || other.minVolunteersRequired == minVolunteersRequired)&&(identical(other.deliveryTemplateId, deliveryTemplateId) || other.deliveryTemplateId == deliveryTemplateId)&&(identical(other.standardEndTime, standardEndTime) || other.standardEndTime == standardEndTime)&&(identical(other.volunteerArrivalTime, volunteerArrivalTime) || other.volunteerArrivalTime == volunteerArrivalTime)&&(identical(other.earlySlot, earlySlot) || other.earlySlot == earlySlot)&&const DeepCollectionEquality().equals(other.contracts, contracts)&&const DeepCollectionEquality().equals(other.basketDescriptions, basketDescriptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deliveryId,organizationId,scheduledDate,status,minVolunteersRequired,deliveryTemplateId,standardEndTime,volunteerArrivalTime,earlySlot,const DeepCollectionEquality().hash(contracts),const DeepCollectionEquality().hash(basketDescriptions));

@override
String toString() {
  return 'Delivery(deliveryId: $deliveryId, organizationId: $organizationId, scheduledDate: $scheduledDate, status: $status, minVolunteersRequired: $minVolunteersRequired, deliveryTemplateId: $deliveryTemplateId, standardEndTime: $standardEndTime, volunteerArrivalTime: $volunteerArrivalTime, earlySlot: $earlySlot, contracts: $contracts, basketDescriptions: $basketDescriptions)';
}


}

/// @nodoc
abstract mixin class $DeliveryCopyWith<$Res>  {
  factory $DeliveryCopyWith(Delivery value, $Res Function(Delivery) _then) = _$DeliveryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'scheduled_date') String scheduledDate, DeliveryStatus status,@JsonKey(name: 'min_volunteers_required') int minVolunteersRequired,@JsonKey(name: 'delivery_template_id') String? deliveryTemplateId,@JsonKey(name: 'standard_end_time') String? standardEndTime,@JsonKey(name: 'volunteer_arrival_time') String? volunteerArrivalTime,@JsonKey(name: 'early_slot') EarlySlot? earlySlot, List<DeliveryContract> contracts,@JsonKey(name: 'basket_descriptions') List<BasketDeliveryDescription> basketDescriptions
});


$EarlySlotCopyWith<$Res>? get earlySlot;

}
/// @nodoc
class _$DeliveryCopyWithImpl<$Res>
    implements $DeliveryCopyWith<$Res> {
  _$DeliveryCopyWithImpl(this._self, this._then);

  final Delivery _self;
  final $Res Function(Delivery) _then;

/// Create a copy of Delivery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deliveryId = null,Object? organizationId = null,Object? scheduledDate = null,Object? status = null,Object? minVolunteersRequired = null,Object? deliveryTemplateId = freezed,Object? standardEndTime = freezed,Object? volunteerArrivalTime = freezed,Object? earlySlot = freezed,Object? contracts = null,Object? basketDescriptions = null,}) {
  return _then(_self.copyWith(
deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeliveryStatus,minVolunteersRequired: null == minVolunteersRequired ? _self.minVolunteersRequired : minVolunteersRequired // ignore: cast_nullable_to_non_nullable
as int,deliveryTemplateId: freezed == deliveryTemplateId ? _self.deliveryTemplateId : deliveryTemplateId // ignore: cast_nullable_to_non_nullable
as String?,standardEndTime: freezed == standardEndTime ? _self.standardEndTime : standardEndTime // ignore: cast_nullable_to_non_nullable
as String?,volunteerArrivalTime: freezed == volunteerArrivalTime ? _self.volunteerArrivalTime : volunteerArrivalTime // ignore: cast_nullable_to_non_nullable
as String?,earlySlot: freezed == earlySlot ? _self.earlySlot : earlySlot // ignore: cast_nullable_to_non_nullable
as EarlySlot?,contracts: null == contracts ? _self.contracts : contracts // ignore: cast_nullable_to_non_nullable
as List<DeliveryContract>,basketDescriptions: null == basketDescriptions ? _self.basketDescriptions : basketDescriptions // ignore: cast_nullable_to_non_nullable
as List<BasketDeliveryDescription>,
  ));
}
/// Create a copy of Delivery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EarlySlotCopyWith<$Res>? get earlySlot {
    if (_self.earlySlot == null) {
    return null;
  }

  return $EarlySlotCopyWith<$Res>(_self.earlySlot!, (value) {
    return _then(_self.copyWith(earlySlot: value));
  });
}
}


/// Adds pattern-matching-related methods to [Delivery].
extension DeliveryPatterns on Delivery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Delivery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Delivery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Delivery value)  $default,){
final _that = this;
switch (_that) {
case _Delivery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Delivery value)?  $default,){
final _that = this;
switch (_that) {
case _Delivery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'scheduled_date')  String scheduledDate,  DeliveryStatus status, @JsonKey(name: 'min_volunteers_required')  int minVolunteersRequired, @JsonKey(name: 'delivery_template_id')  String? deliveryTemplateId, @JsonKey(name: 'standard_end_time')  String? standardEndTime, @JsonKey(name: 'volunteer_arrival_time')  String? volunteerArrivalTime, @JsonKey(name: 'early_slot')  EarlySlot? earlySlot,  List<DeliveryContract> contracts, @JsonKey(name: 'basket_descriptions')  List<BasketDeliveryDescription> basketDescriptions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Delivery() when $default != null:
return $default(_that.deliveryId,_that.organizationId,_that.scheduledDate,_that.status,_that.minVolunteersRequired,_that.deliveryTemplateId,_that.standardEndTime,_that.volunteerArrivalTime,_that.earlySlot,_that.contracts,_that.basketDescriptions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'scheduled_date')  String scheduledDate,  DeliveryStatus status, @JsonKey(name: 'min_volunteers_required')  int minVolunteersRequired, @JsonKey(name: 'delivery_template_id')  String? deliveryTemplateId, @JsonKey(name: 'standard_end_time')  String? standardEndTime, @JsonKey(name: 'volunteer_arrival_time')  String? volunteerArrivalTime, @JsonKey(name: 'early_slot')  EarlySlot? earlySlot,  List<DeliveryContract> contracts, @JsonKey(name: 'basket_descriptions')  List<BasketDeliveryDescription> basketDescriptions)  $default,) {final _that = this;
switch (_that) {
case _Delivery():
return $default(_that.deliveryId,_that.organizationId,_that.scheduledDate,_that.status,_that.minVolunteersRequired,_that.deliveryTemplateId,_that.standardEndTime,_that.volunteerArrivalTime,_that.earlySlot,_that.contracts,_that.basketDescriptions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'scheduled_date')  String scheduledDate,  DeliveryStatus status, @JsonKey(name: 'min_volunteers_required')  int minVolunteersRequired, @JsonKey(name: 'delivery_template_id')  String? deliveryTemplateId, @JsonKey(name: 'standard_end_time')  String? standardEndTime, @JsonKey(name: 'volunteer_arrival_time')  String? volunteerArrivalTime, @JsonKey(name: 'early_slot')  EarlySlot? earlySlot,  List<DeliveryContract> contracts, @JsonKey(name: 'basket_descriptions')  List<BasketDeliveryDescription> basketDescriptions)?  $default,) {final _that = this;
switch (_that) {
case _Delivery() when $default != null:
return $default(_that.deliveryId,_that.organizationId,_that.scheduledDate,_that.status,_that.minVolunteersRequired,_that.deliveryTemplateId,_that.standardEndTime,_that.volunteerArrivalTime,_that.earlySlot,_that.contracts,_that.basketDescriptions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Delivery implements Delivery {
  const _Delivery({@JsonKey(name: 'delivery_id') required this.deliveryId, @JsonKey(name: 'organization_id') required this.organizationId, @JsonKey(name: 'scheduled_date') required this.scheduledDate, required this.status, @JsonKey(name: 'min_volunteers_required') required this.minVolunteersRequired, @JsonKey(name: 'delivery_template_id') this.deliveryTemplateId, @JsonKey(name: 'standard_end_time') this.standardEndTime, @JsonKey(name: 'volunteer_arrival_time') this.volunteerArrivalTime, @JsonKey(name: 'early_slot') this.earlySlot, final  List<DeliveryContract> contracts = const [], @JsonKey(name: 'basket_descriptions') final  List<BasketDeliveryDescription> basketDescriptions = const <BasketDeliveryDescription>[]}): _contracts = contracts,_basketDescriptions = basketDescriptions;
  factory _Delivery.fromJson(Map<String, dynamic> json) => _$DeliveryFromJson(json);

@override@JsonKey(name: 'delivery_id') final  String deliveryId;
@override@JsonKey(name: 'organization_id') final  String organizationId;
// ISO-8601 string, e.g. "2025-06-14T09:00:00"
@override@JsonKey(name: 'scheduled_date') final  String scheduledDate;
@override final  DeliveryStatus status;
@override@JsonKey(name: 'min_volunteers_required') final  int minVolunteersRequired;
@override@JsonKey(name: 'delivery_template_id') final  String? deliveryTemplateId;
// Per-delivery overrides of the template's slot times ("HH:MM"); null falls back
// to the linked template, then to the hard-coded defaults. An early slot may be
// defined here even without a template.
@override@JsonKey(name: 'standard_end_time') final  String? standardEndTime;
@override@JsonKey(name: 'volunteer_arrival_time') final  String? volunteerArrivalTime;
@override@JsonKey(name: 'early_slot') final  EarlySlot? earlySlot;
 final  List<DeliveryContract> _contracts;
@override@JsonKey() List<DeliveryContract> get contracts {
  if (_contracts is EqualUnmodifiableListView) return _contracts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contracts);
}

 final  List<BasketDeliveryDescription> _basketDescriptions;
@override@JsonKey(name: 'basket_descriptions') List<BasketDeliveryDescription> get basketDescriptions {
  if (_basketDescriptions is EqualUnmodifiableListView) return _basketDescriptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_basketDescriptions);
}


/// Create a copy of Delivery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryCopyWith<_Delivery> get copyWith => __$DeliveryCopyWithImpl<_Delivery>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Delivery&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.minVolunteersRequired, minVolunteersRequired) || other.minVolunteersRequired == minVolunteersRequired)&&(identical(other.deliveryTemplateId, deliveryTemplateId) || other.deliveryTemplateId == deliveryTemplateId)&&(identical(other.standardEndTime, standardEndTime) || other.standardEndTime == standardEndTime)&&(identical(other.volunteerArrivalTime, volunteerArrivalTime) || other.volunteerArrivalTime == volunteerArrivalTime)&&(identical(other.earlySlot, earlySlot) || other.earlySlot == earlySlot)&&const DeepCollectionEquality().equals(other._contracts, _contracts)&&const DeepCollectionEquality().equals(other._basketDescriptions, _basketDescriptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deliveryId,organizationId,scheduledDate,status,minVolunteersRequired,deliveryTemplateId,standardEndTime,volunteerArrivalTime,earlySlot,const DeepCollectionEquality().hash(_contracts),const DeepCollectionEquality().hash(_basketDescriptions));

@override
String toString() {
  return 'Delivery(deliveryId: $deliveryId, organizationId: $organizationId, scheduledDate: $scheduledDate, status: $status, minVolunteersRequired: $minVolunteersRequired, deliveryTemplateId: $deliveryTemplateId, standardEndTime: $standardEndTime, volunteerArrivalTime: $volunteerArrivalTime, earlySlot: $earlySlot, contracts: $contracts, basketDescriptions: $basketDescriptions)';
}


}

/// @nodoc
abstract mixin class _$DeliveryCopyWith<$Res> implements $DeliveryCopyWith<$Res> {
  factory _$DeliveryCopyWith(_Delivery value, $Res Function(_Delivery) _then) = __$DeliveryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'scheduled_date') String scheduledDate, DeliveryStatus status,@JsonKey(name: 'min_volunteers_required') int minVolunteersRequired,@JsonKey(name: 'delivery_template_id') String? deliveryTemplateId,@JsonKey(name: 'standard_end_time') String? standardEndTime,@JsonKey(name: 'volunteer_arrival_time') String? volunteerArrivalTime,@JsonKey(name: 'early_slot') EarlySlot? earlySlot, List<DeliveryContract> contracts,@JsonKey(name: 'basket_descriptions') List<BasketDeliveryDescription> basketDescriptions
});


@override $EarlySlotCopyWith<$Res>? get earlySlot;

}
/// @nodoc
class __$DeliveryCopyWithImpl<$Res>
    implements _$DeliveryCopyWith<$Res> {
  __$DeliveryCopyWithImpl(this._self, this._then);

  final _Delivery _self;
  final $Res Function(_Delivery) _then;

/// Create a copy of Delivery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deliveryId = null,Object? organizationId = null,Object? scheduledDate = null,Object? status = null,Object? minVolunteersRequired = null,Object? deliveryTemplateId = freezed,Object? standardEndTime = freezed,Object? volunteerArrivalTime = freezed,Object? earlySlot = freezed,Object? contracts = null,Object? basketDescriptions = null,}) {
  return _then(_Delivery(
deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeliveryStatus,minVolunteersRequired: null == minVolunteersRequired ? _self.minVolunteersRequired : minVolunteersRequired // ignore: cast_nullable_to_non_nullable
as int,deliveryTemplateId: freezed == deliveryTemplateId ? _self.deliveryTemplateId : deliveryTemplateId // ignore: cast_nullable_to_non_nullable
as String?,standardEndTime: freezed == standardEndTime ? _self.standardEndTime : standardEndTime // ignore: cast_nullable_to_non_nullable
as String?,volunteerArrivalTime: freezed == volunteerArrivalTime ? _self.volunteerArrivalTime : volunteerArrivalTime // ignore: cast_nullable_to_non_nullable
as String?,earlySlot: freezed == earlySlot ? _self.earlySlot : earlySlot // ignore: cast_nullable_to_non_nullable
as EarlySlot?,contracts: null == contracts ? _self._contracts : contracts // ignore: cast_nullable_to_non_nullable
as List<DeliveryContract>,basketDescriptions: null == basketDescriptions ? _self._basketDescriptions : basketDescriptions // ignore: cast_nullable_to_non_nullable
as List<BasketDeliveryDescription>,
  ));
}

/// Create a copy of Delivery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EarlySlotCopyWith<$Res>? get earlySlot {
    if (_self.earlySlot == null) {
    return null;
  }

  return $EarlySlotCopyWith<$Res>(_self.earlySlot!, (value) {
    return _then(_self.copyWith(earlySlot: value));
  });
}
}


/// @nodoc
mixin _$OrganizationProducer {

@JsonKey(name: 'producer_account_id') String get producerAccountId;// ISO-8601 instant string, e.g. "2026-05-18T22:23:25.095Z".
@JsonKey(name: 'association_instant') String get associationInstant; OrganizationProducerStatus get status;
/// Create a copy of OrganizationProducer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationProducerCopyWith<OrganizationProducer> get copyWith => _$OrganizationProducerCopyWithImpl<OrganizationProducer>(this as OrganizationProducer, _$identity);

  /// Serializes this OrganizationProducer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationProducer&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.associationInstant, associationInstant) || other.associationInstant == associationInstant)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,producerAccountId,associationInstant,status);

@override
String toString() {
  return 'OrganizationProducer(producerAccountId: $producerAccountId, associationInstant: $associationInstant, status: $status)';
}


}

/// @nodoc
abstract mixin class $OrganizationProducerCopyWith<$Res>  {
  factory $OrganizationProducerCopyWith(OrganizationProducer value, $Res Function(OrganizationProducer) _then) = _$OrganizationProducerCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'association_instant') String associationInstant, OrganizationProducerStatus status
});




}
/// @nodoc
class _$OrganizationProducerCopyWithImpl<$Res>
    implements $OrganizationProducerCopyWith<$Res> {
  _$OrganizationProducerCopyWithImpl(this._self, this._then);

  final OrganizationProducer _self;
  final $Res Function(OrganizationProducer) _then;

/// Create a copy of OrganizationProducer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? producerAccountId = null,Object? associationInstant = null,Object? status = null,}) {
  return _then(_self.copyWith(
producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,associationInstant: null == associationInstant ? _self.associationInstant : associationInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrganizationProducerStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationProducer].
extension OrganizationProducerPatterns on OrganizationProducer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationProducer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationProducer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationProducer value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationProducer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationProducer value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationProducer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'association_instant')  String associationInstant,  OrganizationProducerStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationProducer() when $default != null:
return $default(_that.producerAccountId,_that.associationInstant,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'association_instant')  String associationInstant,  OrganizationProducerStatus status)  $default,) {final _that = this;
switch (_that) {
case _OrganizationProducer():
return $default(_that.producerAccountId,_that.associationInstant,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'association_instant')  String associationInstant,  OrganizationProducerStatus status)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationProducer() when $default != null:
return $default(_that.producerAccountId,_that.associationInstant,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrganizationProducer implements OrganizationProducer {
  const _OrganizationProducer({@JsonKey(name: 'producer_account_id') required this.producerAccountId, @JsonKey(name: 'association_instant') required this.associationInstant, required this.status});
  factory _OrganizationProducer.fromJson(Map<String, dynamic> json) => _$OrganizationProducerFromJson(json);

@override@JsonKey(name: 'producer_account_id') final  String producerAccountId;
// ISO-8601 instant string, e.g. "2026-05-18T22:23:25.095Z".
@override@JsonKey(name: 'association_instant') final  String associationInstant;
@override final  OrganizationProducerStatus status;

/// Create a copy of OrganizationProducer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationProducerCopyWith<_OrganizationProducer> get copyWith => __$OrganizationProducerCopyWithImpl<_OrganizationProducer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrganizationProducerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationProducer&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.associationInstant, associationInstant) || other.associationInstant == associationInstant)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,producerAccountId,associationInstant,status);

@override
String toString() {
  return 'OrganizationProducer(producerAccountId: $producerAccountId, associationInstant: $associationInstant, status: $status)';
}


}

/// @nodoc
abstract mixin class _$OrganizationProducerCopyWith<$Res> implements $OrganizationProducerCopyWith<$Res> {
  factory _$OrganizationProducerCopyWith(_OrganizationProducer value, $Res Function(_OrganizationProducer) _then) = __$OrganizationProducerCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'association_instant') String associationInstant, OrganizationProducerStatus status
});




}
/// @nodoc
class __$OrganizationProducerCopyWithImpl<$Res>
    implements _$OrganizationProducerCopyWith<$Res> {
  __$OrganizationProducerCopyWithImpl(this._self, this._then);

  final _OrganizationProducer _self;
  final $Res Function(_OrganizationProducer) _then;

/// Create a copy of OrganizationProducer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? producerAccountId = null,Object? associationInstant = null,Object? status = null,}) {
  return _then(_OrganizationProducer(
producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,associationInstant: null == associationInstant ? _self.associationInstant : associationInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrganizationProducerStatus,
  ));
}


}


/// @nodoc
mixin _$OrgProduct {

 String get name;@JsonKey(name: 'product_type_id') String get productTypeId;@JsonKey(name: 'producer_account_id') String get producerAccountId;@JsonKey(name: 'supported_basket_sizes') List<BasketSize> get supportedBasketSizes; String? get description;
/// Create a copy of OrgProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrgProductCopyWith<OrgProduct> get copyWith => _$OrgProductCopyWithImpl<OrgProduct>(this as OrgProduct, _$identity);

  /// Serializes this OrgProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrgProduct&&(identical(other.name, name) || other.name == name)&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&const DeepCollectionEquality().equals(other.supportedBasketSizes, supportedBasketSizes)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,productTypeId,producerAccountId,const DeepCollectionEquality().hash(supportedBasketSizes),description);

@override
String toString() {
  return 'OrgProduct(name: $name, productTypeId: $productTypeId, producerAccountId: $producerAccountId, supportedBasketSizes: $supportedBasketSizes, description: $description)';
}


}

/// @nodoc
abstract mixin class $OrgProductCopyWith<$Res>  {
  factory $OrgProductCopyWith(OrgProduct value, $Res Function(OrgProduct) _then) = _$OrgProductCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'supported_basket_sizes') List<BasketSize> supportedBasketSizes, String? description
});




}
/// @nodoc
class _$OrgProductCopyWithImpl<$Res>
    implements $OrgProductCopyWith<$Res> {
  _$OrgProductCopyWithImpl(this._self, this._then);

  final OrgProduct _self;
  final $Res Function(OrgProduct) _then;

/// Create a copy of OrgProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? productTypeId = null,Object? producerAccountId = null,Object? supportedBasketSizes = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,supportedBasketSizes: null == supportedBasketSizes ? _self.supportedBasketSizes : supportedBasketSizes // ignore: cast_nullable_to_non_nullable
as List<BasketSize>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrgProduct].
extension OrgProductPatterns on OrgProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrgProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrgProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrgProduct value)  $default,){
final _that = this;
switch (_that) {
case _OrgProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrgProduct value)?  $default,){
final _that = this;
switch (_that) {
case _OrgProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrgProduct() when $default != null:
return $default(_that.name,_that.productTypeId,_that.producerAccountId,_that.supportedBasketSizes,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String? description)  $default,) {final _that = this;
switch (_that) {
case _OrgProduct():
return $default(_that.name,_that.productTypeId,_that.producerAccountId,_that.supportedBasketSizes,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _OrgProduct() when $default != null:
return $default(_that.name,_that.productTypeId,_that.producerAccountId,_that.supportedBasketSizes,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrgProduct implements OrgProduct {
  const _OrgProduct({required this.name, @JsonKey(name: 'product_type_id') required this.productTypeId, @JsonKey(name: 'producer_account_id') required this.producerAccountId, @JsonKey(name: 'supported_basket_sizes') final  List<BasketSize> supportedBasketSizes = const [], this.description}): _supportedBasketSizes = supportedBasketSizes;
  factory _OrgProduct.fromJson(Map<String, dynamic> json) => _$OrgProductFromJson(json);

@override final  String name;
@override@JsonKey(name: 'product_type_id') final  String productTypeId;
@override@JsonKey(name: 'producer_account_id') final  String producerAccountId;
 final  List<BasketSize> _supportedBasketSizes;
@override@JsonKey(name: 'supported_basket_sizes') List<BasketSize> get supportedBasketSizes {
  if (_supportedBasketSizes is EqualUnmodifiableListView) return _supportedBasketSizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedBasketSizes);
}

@override final  String? description;

/// Create a copy of OrgProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrgProductCopyWith<_OrgProduct> get copyWith => __$OrgProductCopyWithImpl<_OrgProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrgProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrgProduct&&(identical(other.name, name) || other.name == name)&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&const DeepCollectionEquality().equals(other._supportedBasketSizes, _supportedBasketSizes)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,productTypeId,producerAccountId,const DeepCollectionEquality().hash(_supportedBasketSizes),description);

@override
String toString() {
  return 'OrgProduct(name: $name, productTypeId: $productTypeId, producerAccountId: $producerAccountId, supportedBasketSizes: $supportedBasketSizes, description: $description)';
}


}

/// @nodoc
abstract mixin class _$OrgProductCopyWith<$Res> implements $OrgProductCopyWith<$Res> {
  factory _$OrgProductCopyWith(_OrgProduct value, $Res Function(_OrgProduct) _then) = __$OrgProductCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'supported_basket_sizes') List<BasketSize> supportedBasketSizes, String? description
});




}
/// @nodoc
class __$OrgProductCopyWithImpl<$Res>
    implements _$OrgProductCopyWith<$Res> {
  __$OrgProductCopyWithImpl(this._self, this._then);

  final _OrgProduct _self;
  final $Res Function(_OrgProduct) _then;

/// Create a copy of OrgProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? productTypeId = null,Object? producerAccountId = null,Object? supportedBasketSizes = null,Object? description = freezed,}) {
  return _then(_OrgProduct(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,supportedBasketSizes: null == supportedBasketSizes ? _self._supportedBasketSizes : supportedBasketSizes // ignore: cast_nullable_to_non_nullable
as List<BasketSize>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Organization {

@JsonKey(name: 'organization_id') String get organizationId; String get name;@JsonKey(name: 'contact_email') String get contactEmail;@JsonKey(name: 'active_status') bool get activeStatus; String? get timezone;@JsonKey(name: 'default_language') String? get defaultLanguage;@JsonKey(name: 'default_delivery_template_id', includeIfNull: false) String? get defaultDeliveryTemplateId; String? get website;// ISO-8601 instant strings, e.g. "2026-05-18T22:23:25.095Z".
@JsonKey(name: 'created_instant') String? get createdInstant;@JsonKey(name: 'last_updated_instant') String? get lastUpdatedInstant; List<OrganizationProducer> get producers; List<OrgProduct> get products; List<Delivery> get deliveries;// Flat, deduplicated catalog of basket components (with their inline SVG icons) referenced by
// deliveries' basketDescriptions. Stored once per component (not per delivery) and member-synced.
@JsonKey(name: 'item_types') List<ItemType> get itemTypes;@JsonKey(name: 'notification_overrides') Map<NotificationCategory, NotificationCopyOverride> get notificationOverrides;
/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationCopyWith<Organization> get copyWith => _$OrganizationCopyWithImpl<Organization>(this as Organization, _$identity);

  /// Serializes this Organization to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Organization&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.activeStatus, activeStatus) || other.activeStatus == activeStatus)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.defaultDeliveryTemplateId, defaultDeliveryTemplateId) || other.defaultDeliveryTemplateId == defaultDeliveryTemplateId)&&(identical(other.website, website) || other.website == website)&&(identical(other.createdInstant, createdInstant) || other.createdInstant == createdInstant)&&(identical(other.lastUpdatedInstant, lastUpdatedInstant) || other.lastUpdatedInstant == lastUpdatedInstant)&&const DeepCollectionEquality().equals(other.producers, producers)&&const DeepCollectionEquality().equals(other.products, products)&&const DeepCollectionEquality().equals(other.deliveries, deliveries)&&const DeepCollectionEquality().equals(other.itemTypes, itemTypes)&&const DeepCollectionEquality().equals(other.notificationOverrides, notificationOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organizationId,name,contactEmail,activeStatus,timezone,defaultLanguage,defaultDeliveryTemplateId,website,createdInstant,lastUpdatedInstant,const DeepCollectionEquality().hash(producers),const DeepCollectionEquality().hash(products),const DeepCollectionEquality().hash(deliveries),const DeepCollectionEquality().hash(itemTypes),const DeepCollectionEquality().hash(notificationOverrides));

@override
String toString() {
  return 'Organization(organizationId: $organizationId, name: $name, contactEmail: $contactEmail, activeStatus: $activeStatus, timezone: $timezone, defaultLanguage: $defaultLanguage, defaultDeliveryTemplateId: $defaultDeliveryTemplateId, website: $website, createdInstant: $createdInstant, lastUpdatedInstant: $lastUpdatedInstant, producers: $producers, products: $products, deliveries: $deliveries, itemTypes: $itemTypes, notificationOverrides: $notificationOverrides)';
}


}

/// @nodoc
abstract mixin class $OrganizationCopyWith<$Res>  {
  factory $OrganizationCopyWith(Organization value, $Res Function(Organization) _then) = _$OrganizationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId, String name,@JsonKey(name: 'contact_email') String contactEmail,@JsonKey(name: 'active_status') bool activeStatus, String? timezone,@JsonKey(name: 'default_language') String? defaultLanguage,@JsonKey(name: 'default_delivery_template_id', includeIfNull: false) String? defaultDeliveryTemplateId, String? website,@JsonKey(name: 'created_instant') String? createdInstant,@JsonKey(name: 'last_updated_instant') String? lastUpdatedInstant, List<OrganizationProducer> producers, List<OrgProduct> products, List<Delivery> deliveries,@JsonKey(name: 'item_types') List<ItemType> itemTypes,@JsonKey(name: 'notification_overrides') Map<NotificationCategory, NotificationCopyOverride> notificationOverrides
});




}
/// @nodoc
class _$OrganizationCopyWithImpl<$Res>
    implements $OrganizationCopyWith<$Res> {
  _$OrganizationCopyWithImpl(this._self, this._then);

  final Organization _self;
  final $Res Function(Organization) _then;

/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? name = null,Object? contactEmail = null,Object? activeStatus = null,Object? timezone = freezed,Object? defaultLanguage = freezed,Object? defaultDeliveryTemplateId = freezed,Object? website = freezed,Object? createdInstant = freezed,Object? lastUpdatedInstant = freezed,Object? producers = null,Object? products = null,Object? deliveries = null,Object? itemTypes = null,Object? notificationOverrides = null,}) {
  return _then(_self.copyWith(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,activeStatus: null == activeStatus ? _self.activeStatus : activeStatus // ignore: cast_nullable_to_non_nullable
as bool,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,defaultLanguage: freezed == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String?,defaultDeliveryTemplateId: freezed == defaultDeliveryTemplateId ? _self.defaultDeliveryTemplateId : defaultDeliveryTemplateId // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,createdInstant: freezed == createdInstant ? _self.createdInstant : createdInstant // ignore: cast_nullable_to_non_nullable
as String?,lastUpdatedInstant: freezed == lastUpdatedInstant ? _self.lastUpdatedInstant : lastUpdatedInstant // ignore: cast_nullable_to_non_nullable
as String?,producers: null == producers ? _self.producers : producers // ignore: cast_nullable_to_non_nullable
as List<OrganizationProducer>,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<OrgProduct>,deliveries: null == deliveries ? _self.deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as List<Delivery>,itemTypes: null == itemTypes ? _self.itemTypes : itemTypes // ignore: cast_nullable_to_non_nullable
as List<ItemType>,notificationOverrides: null == notificationOverrides ? _self.notificationOverrides : notificationOverrides // ignore: cast_nullable_to_non_nullable
as Map<NotificationCategory, NotificationCopyOverride>,
  ));
}

}


/// Adds pattern-matching-related methods to [Organization].
extension OrganizationPatterns on Organization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Organization value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Organization() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Organization value)  $default,){
final _that = this;
switch (_that) {
case _Organization():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Organization value)?  $default,){
final _that = this;
switch (_that) {
case _Organization() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'contact_email')  String contactEmail, @JsonKey(name: 'active_status')  bool activeStatus,  String? timezone, @JsonKey(name: 'default_language')  String? defaultLanguage, @JsonKey(name: 'default_delivery_template_id', includeIfNull: false)  String? defaultDeliveryTemplateId,  String? website, @JsonKey(name: 'created_instant')  String? createdInstant, @JsonKey(name: 'last_updated_instant')  String? lastUpdatedInstant,  List<OrganizationProducer> producers,  List<OrgProduct> products,  List<Delivery> deliveries, @JsonKey(name: 'item_types')  List<ItemType> itemTypes, @JsonKey(name: 'notification_overrides')  Map<NotificationCategory, NotificationCopyOverride> notificationOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Organization() when $default != null:
return $default(_that.organizationId,_that.name,_that.contactEmail,_that.activeStatus,_that.timezone,_that.defaultLanguage,_that.defaultDeliveryTemplateId,_that.website,_that.createdInstant,_that.lastUpdatedInstant,_that.producers,_that.products,_that.deliveries,_that.itemTypes,_that.notificationOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'contact_email')  String contactEmail, @JsonKey(name: 'active_status')  bool activeStatus,  String? timezone, @JsonKey(name: 'default_language')  String? defaultLanguage, @JsonKey(name: 'default_delivery_template_id', includeIfNull: false)  String? defaultDeliveryTemplateId,  String? website, @JsonKey(name: 'created_instant')  String? createdInstant, @JsonKey(name: 'last_updated_instant')  String? lastUpdatedInstant,  List<OrganizationProducer> producers,  List<OrgProduct> products,  List<Delivery> deliveries, @JsonKey(name: 'item_types')  List<ItemType> itemTypes, @JsonKey(name: 'notification_overrides')  Map<NotificationCategory, NotificationCopyOverride> notificationOverrides)  $default,) {final _that = this;
switch (_that) {
case _Organization():
return $default(_that.organizationId,_that.name,_that.contactEmail,_that.activeStatus,_that.timezone,_that.defaultLanguage,_that.defaultDeliveryTemplateId,_that.website,_that.createdInstant,_that.lastUpdatedInstant,_that.producers,_that.products,_that.deliveries,_that.itemTypes,_that.notificationOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'contact_email')  String contactEmail, @JsonKey(name: 'active_status')  bool activeStatus,  String? timezone, @JsonKey(name: 'default_language')  String? defaultLanguage, @JsonKey(name: 'default_delivery_template_id', includeIfNull: false)  String? defaultDeliveryTemplateId,  String? website, @JsonKey(name: 'created_instant')  String? createdInstant, @JsonKey(name: 'last_updated_instant')  String? lastUpdatedInstant,  List<OrganizationProducer> producers,  List<OrgProduct> products,  List<Delivery> deliveries, @JsonKey(name: 'item_types')  List<ItemType> itemTypes, @JsonKey(name: 'notification_overrides')  Map<NotificationCategory, NotificationCopyOverride> notificationOverrides)?  $default,) {final _that = this;
switch (_that) {
case _Organization() when $default != null:
return $default(_that.organizationId,_that.name,_that.contactEmail,_that.activeStatus,_that.timezone,_that.defaultLanguage,_that.defaultDeliveryTemplateId,_that.website,_that.createdInstant,_that.lastUpdatedInstant,_that.producers,_that.products,_that.deliveries,_that.itemTypes,_that.notificationOverrides);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Organization implements Organization {
  const _Organization({@JsonKey(name: 'organization_id') required this.organizationId, required this.name, @JsonKey(name: 'contact_email') required this.contactEmail, @JsonKey(name: 'active_status') this.activeStatus = true, this.timezone, @JsonKey(name: 'default_language') this.defaultLanguage, @JsonKey(name: 'default_delivery_template_id', includeIfNull: false) this.defaultDeliveryTemplateId, this.website, @JsonKey(name: 'created_instant') this.createdInstant, @JsonKey(name: 'last_updated_instant') this.lastUpdatedInstant, final  List<OrganizationProducer> producers = const [], final  List<OrgProduct> products = const [], final  List<Delivery> deliveries = const [], @JsonKey(name: 'item_types') final  List<ItemType> itemTypes = const <ItemType>[], @JsonKey(name: 'notification_overrides') final  Map<NotificationCategory, NotificationCopyOverride> notificationOverrides = const <NotificationCategory, NotificationCopyOverride>{}}): _producers = producers,_products = products,_deliveries = deliveries,_itemTypes = itemTypes,_notificationOverrides = notificationOverrides;
  factory _Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);

@override@JsonKey(name: 'organization_id') final  String organizationId;
@override final  String name;
@override@JsonKey(name: 'contact_email') final  String contactEmail;
@override@JsonKey(name: 'active_status') final  bool activeStatus;
@override final  String? timezone;
@override@JsonKey(name: 'default_language') final  String? defaultLanguage;
@override@JsonKey(name: 'default_delivery_template_id', includeIfNull: false) final  String? defaultDeliveryTemplateId;
@override final  String? website;
// ISO-8601 instant strings, e.g. "2026-05-18T22:23:25.095Z".
@override@JsonKey(name: 'created_instant') final  String? createdInstant;
@override@JsonKey(name: 'last_updated_instant') final  String? lastUpdatedInstant;
 final  List<OrganizationProducer> _producers;
@override@JsonKey() List<OrganizationProducer> get producers {
  if (_producers is EqualUnmodifiableListView) return _producers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_producers);
}

 final  List<OrgProduct> _products;
@override@JsonKey() List<OrgProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}

 final  List<Delivery> _deliveries;
@override@JsonKey() List<Delivery> get deliveries {
  if (_deliveries is EqualUnmodifiableListView) return _deliveries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveries);
}

// Flat, deduplicated catalog of basket components (with their inline SVG icons) referenced by
// deliveries' basketDescriptions. Stored once per component (not per delivery) and member-synced.
 final  List<ItemType> _itemTypes;
// Flat, deduplicated catalog of basket components (with their inline SVG icons) referenced by
// deliveries' basketDescriptions. Stored once per component (not per delivery) and member-synced.
@override@JsonKey(name: 'item_types') List<ItemType> get itemTypes {
  if (_itemTypes is EqualUnmodifiableListView) return _itemTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itemTypes);
}

 final  Map<NotificationCategory, NotificationCopyOverride> _notificationOverrides;
@override@JsonKey(name: 'notification_overrides') Map<NotificationCategory, NotificationCopyOverride> get notificationOverrides {
  if (_notificationOverrides is EqualUnmodifiableMapView) return _notificationOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_notificationOverrides);
}


/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationCopyWith<_Organization> get copyWith => __$OrganizationCopyWithImpl<_Organization>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrganizationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Organization&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.activeStatus, activeStatus) || other.activeStatus == activeStatus)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.defaultDeliveryTemplateId, defaultDeliveryTemplateId) || other.defaultDeliveryTemplateId == defaultDeliveryTemplateId)&&(identical(other.website, website) || other.website == website)&&(identical(other.createdInstant, createdInstant) || other.createdInstant == createdInstant)&&(identical(other.lastUpdatedInstant, lastUpdatedInstant) || other.lastUpdatedInstant == lastUpdatedInstant)&&const DeepCollectionEquality().equals(other._producers, _producers)&&const DeepCollectionEquality().equals(other._products, _products)&&const DeepCollectionEquality().equals(other._deliveries, _deliveries)&&const DeepCollectionEquality().equals(other._itemTypes, _itemTypes)&&const DeepCollectionEquality().equals(other._notificationOverrides, _notificationOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organizationId,name,contactEmail,activeStatus,timezone,defaultLanguage,defaultDeliveryTemplateId,website,createdInstant,lastUpdatedInstant,const DeepCollectionEquality().hash(_producers),const DeepCollectionEquality().hash(_products),const DeepCollectionEquality().hash(_deliveries),const DeepCollectionEquality().hash(_itemTypes),const DeepCollectionEquality().hash(_notificationOverrides));

@override
String toString() {
  return 'Organization(organizationId: $organizationId, name: $name, contactEmail: $contactEmail, activeStatus: $activeStatus, timezone: $timezone, defaultLanguage: $defaultLanguage, defaultDeliveryTemplateId: $defaultDeliveryTemplateId, website: $website, createdInstant: $createdInstant, lastUpdatedInstant: $lastUpdatedInstant, producers: $producers, products: $products, deliveries: $deliveries, itemTypes: $itemTypes, notificationOverrides: $notificationOverrides)';
}


}

/// @nodoc
abstract mixin class _$OrganizationCopyWith<$Res> implements $OrganizationCopyWith<$Res> {
  factory _$OrganizationCopyWith(_Organization value, $Res Function(_Organization) _then) = __$OrganizationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId, String name,@JsonKey(name: 'contact_email') String contactEmail,@JsonKey(name: 'active_status') bool activeStatus, String? timezone,@JsonKey(name: 'default_language') String? defaultLanguage,@JsonKey(name: 'default_delivery_template_id', includeIfNull: false) String? defaultDeliveryTemplateId, String? website,@JsonKey(name: 'created_instant') String? createdInstant,@JsonKey(name: 'last_updated_instant') String? lastUpdatedInstant, List<OrganizationProducer> producers, List<OrgProduct> products, List<Delivery> deliveries,@JsonKey(name: 'item_types') List<ItemType> itemTypes,@JsonKey(name: 'notification_overrides') Map<NotificationCategory, NotificationCopyOverride> notificationOverrides
});




}
/// @nodoc
class __$OrganizationCopyWithImpl<$Res>
    implements _$OrganizationCopyWith<$Res> {
  __$OrganizationCopyWithImpl(this._self, this._then);

  final _Organization _self;
  final $Res Function(_Organization) _then;

/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? name = null,Object? contactEmail = null,Object? activeStatus = null,Object? timezone = freezed,Object? defaultLanguage = freezed,Object? defaultDeliveryTemplateId = freezed,Object? website = freezed,Object? createdInstant = freezed,Object? lastUpdatedInstant = freezed,Object? producers = null,Object? products = null,Object? deliveries = null,Object? itemTypes = null,Object? notificationOverrides = null,}) {
  return _then(_Organization(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contactEmail: null == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String,activeStatus: null == activeStatus ? _self.activeStatus : activeStatus // ignore: cast_nullable_to_non_nullable
as bool,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,defaultLanguage: freezed == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String?,defaultDeliveryTemplateId: freezed == defaultDeliveryTemplateId ? _self.defaultDeliveryTemplateId : defaultDeliveryTemplateId // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,createdInstant: freezed == createdInstant ? _self.createdInstant : createdInstant // ignore: cast_nullable_to_non_nullable
as String?,lastUpdatedInstant: freezed == lastUpdatedInstant ? _self.lastUpdatedInstant : lastUpdatedInstant // ignore: cast_nullable_to_non_nullable
as String?,producers: null == producers ? _self._producers : producers // ignore: cast_nullable_to_non_nullable
as List<OrganizationProducer>,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<OrgProduct>,deliveries: null == deliveries ? _self._deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as List<Delivery>,itemTypes: null == itemTypes ? _self._itemTypes : itemTypes // ignore: cast_nullable_to_non_nullable
as List<ItemType>,notificationOverrides: null == notificationOverrides ? _self._notificationOverrides : notificationOverrides // ignore: cast_nullable_to_non_nullable
as Map<NotificationCategory, NotificationCopyOverride>,
  ));
}


}

// dart format on
