// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EarlySlot {

@JsonKey(name: 'arrival_time') String get arrivalTime; String? get explanation;@JsonKey(name: 'max_volunteers') int get maxVolunteers;
/// Create a copy of EarlySlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarlySlotCopyWith<EarlySlot> get copyWith => _$EarlySlotCopyWithImpl<EarlySlot>(this as EarlySlot, _$identity);

  /// Serializes this EarlySlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarlySlot&&(identical(other.arrivalTime, arrivalTime) || other.arrivalTime == arrivalTime)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.maxVolunteers, maxVolunteers) || other.maxVolunteers == maxVolunteers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,arrivalTime,explanation,maxVolunteers);

@override
String toString() {
  return 'EarlySlot(arrivalTime: $arrivalTime, explanation: $explanation, maxVolunteers: $maxVolunteers)';
}


}

/// @nodoc
abstract mixin class $EarlySlotCopyWith<$Res>  {
  factory $EarlySlotCopyWith(EarlySlot value, $Res Function(EarlySlot) _then) = _$EarlySlotCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'arrival_time') String arrivalTime, String? explanation,@JsonKey(name: 'max_volunteers') int maxVolunteers
});




}
/// @nodoc
class _$EarlySlotCopyWithImpl<$Res>
    implements $EarlySlotCopyWith<$Res> {
  _$EarlySlotCopyWithImpl(this._self, this._then);

  final EarlySlot _self;
  final $Res Function(EarlySlot) _then;

/// Create a copy of EarlySlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? arrivalTime = null,Object? explanation = freezed,Object? maxVolunteers = null,}) {
  return _then(_self.copyWith(
arrivalTime: null == arrivalTime ? _self.arrivalTime : arrivalTime // ignore: cast_nullable_to_non_nullable
as String,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,maxVolunteers: null == maxVolunteers ? _self.maxVolunteers : maxVolunteers // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EarlySlot].
extension EarlySlotPatterns on EarlySlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarlySlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarlySlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarlySlot value)  $default,){
final _that = this;
switch (_that) {
case _EarlySlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarlySlot value)?  $default,){
final _that = this;
switch (_that) {
case _EarlySlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'arrival_time')  String arrivalTime,  String? explanation, @JsonKey(name: 'max_volunteers')  int maxVolunteers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarlySlot() when $default != null:
return $default(_that.arrivalTime,_that.explanation,_that.maxVolunteers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'arrival_time')  String arrivalTime,  String? explanation, @JsonKey(name: 'max_volunteers')  int maxVolunteers)  $default,) {final _that = this;
switch (_that) {
case _EarlySlot():
return $default(_that.arrivalTime,_that.explanation,_that.maxVolunteers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'arrival_time')  String arrivalTime,  String? explanation, @JsonKey(name: 'max_volunteers')  int maxVolunteers)?  $default,) {final _that = this;
switch (_that) {
case _EarlySlot() when $default != null:
return $default(_that.arrivalTime,_that.explanation,_that.maxVolunteers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EarlySlot implements EarlySlot {
  const _EarlySlot({@JsonKey(name: 'arrival_time') required this.arrivalTime, this.explanation, @JsonKey(name: 'max_volunteers') required this.maxVolunteers});
  factory _EarlySlot.fromJson(Map<String, dynamic> json) => _$EarlySlotFromJson(json);

@override@JsonKey(name: 'arrival_time') final  String arrivalTime;
@override final  String? explanation;
@override@JsonKey(name: 'max_volunteers') final  int maxVolunteers;

/// Create a copy of EarlySlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarlySlotCopyWith<_EarlySlot> get copyWith => __$EarlySlotCopyWithImpl<_EarlySlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarlySlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarlySlot&&(identical(other.arrivalTime, arrivalTime) || other.arrivalTime == arrivalTime)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.maxVolunteers, maxVolunteers) || other.maxVolunteers == maxVolunteers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,arrivalTime,explanation,maxVolunteers);

@override
String toString() {
  return 'EarlySlot(arrivalTime: $arrivalTime, explanation: $explanation, maxVolunteers: $maxVolunteers)';
}


}

/// @nodoc
abstract mixin class _$EarlySlotCopyWith<$Res> implements $EarlySlotCopyWith<$Res> {
  factory _$EarlySlotCopyWith(_EarlySlot value, $Res Function(_EarlySlot) _then) = __$EarlySlotCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'arrival_time') String arrivalTime, String? explanation,@JsonKey(name: 'max_volunteers') int maxVolunteers
});




}
/// @nodoc
class __$EarlySlotCopyWithImpl<$Res>
    implements _$EarlySlotCopyWith<$Res> {
  __$EarlySlotCopyWithImpl(this._self, this._then);

  final _EarlySlot _self;
  final $Res Function(_EarlySlot) _then;

/// Create a copy of EarlySlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? arrivalTime = null,Object? explanation = freezed,Object? maxVolunteers = null,}) {
  return _then(_EarlySlot(
arrivalTime: null == arrivalTime ? _self.arrivalTime : arrivalTime // ignore: cast_nullable_to_non_nullable
as String,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,maxVolunteers: null == maxVolunteers ? _self.maxVolunteers : maxVolunteers // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DeliveryTemplate {

@JsonKey(name: 'delivery_template_id') String get deliveryTemplateId;@JsonKey(name: 'organization_id') String get organizationId; String get name;@JsonKey(name: 'standard_start_time') String get standardStartTime;@JsonKey(name: 'standard_end_time') String get standardEndTime;@JsonKey(name: 'volunteer_arrival_time') String? get volunteerArrivalTime;@JsonKey(name: 'desired_volunteer_count') int get desiredVolunteerCount;@JsonKey(name: 'early_slot') EarlySlot? get earlySlot;
/// Create a copy of DeliveryTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryTemplateCopyWith<DeliveryTemplate> get copyWith => _$DeliveryTemplateCopyWithImpl<DeliveryTemplate>(this as DeliveryTemplate, _$identity);

  /// Serializes this DeliveryTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryTemplate&&(identical(other.deliveryTemplateId, deliveryTemplateId) || other.deliveryTemplateId == deliveryTemplateId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.standardStartTime, standardStartTime) || other.standardStartTime == standardStartTime)&&(identical(other.standardEndTime, standardEndTime) || other.standardEndTime == standardEndTime)&&(identical(other.volunteerArrivalTime, volunteerArrivalTime) || other.volunteerArrivalTime == volunteerArrivalTime)&&(identical(other.desiredVolunteerCount, desiredVolunteerCount) || other.desiredVolunteerCount == desiredVolunteerCount)&&(identical(other.earlySlot, earlySlot) || other.earlySlot == earlySlot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deliveryTemplateId,organizationId,name,standardStartTime,standardEndTime,volunteerArrivalTime,desiredVolunteerCount,earlySlot);

@override
String toString() {
  return 'DeliveryTemplate(deliveryTemplateId: $deliveryTemplateId, organizationId: $organizationId, name: $name, standardStartTime: $standardStartTime, standardEndTime: $standardEndTime, volunteerArrivalTime: $volunteerArrivalTime, desiredVolunteerCount: $desiredVolunteerCount, earlySlot: $earlySlot)';
}


}

/// @nodoc
abstract mixin class $DeliveryTemplateCopyWith<$Res>  {
  factory $DeliveryTemplateCopyWith(DeliveryTemplate value, $Res Function(DeliveryTemplate) _then) = _$DeliveryTemplateCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'delivery_template_id') String deliveryTemplateId,@JsonKey(name: 'organization_id') String organizationId, String name,@JsonKey(name: 'standard_start_time') String standardStartTime,@JsonKey(name: 'standard_end_time') String standardEndTime,@JsonKey(name: 'volunteer_arrival_time') String? volunteerArrivalTime,@JsonKey(name: 'desired_volunteer_count') int desiredVolunteerCount,@JsonKey(name: 'early_slot') EarlySlot? earlySlot
});


$EarlySlotCopyWith<$Res>? get earlySlot;

}
/// @nodoc
class _$DeliveryTemplateCopyWithImpl<$Res>
    implements $DeliveryTemplateCopyWith<$Res> {
  _$DeliveryTemplateCopyWithImpl(this._self, this._then);

  final DeliveryTemplate _self;
  final $Res Function(DeliveryTemplate) _then;

/// Create a copy of DeliveryTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deliveryTemplateId = null,Object? organizationId = null,Object? name = null,Object? standardStartTime = null,Object? standardEndTime = null,Object? volunteerArrivalTime = freezed,Object? desiredVolunteerCount = null,Object? earlySlot = freezed,}) {
  return _then(_self.copyWith(
deliveryTemplateId: null == deliveryTemplateId ? _self.deliveryTemplateId : deliveryTemplateId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,standardStartTime: null == standardStartTime ? _self.standardStartTime : standardStartTime // ignore: cast_nullable_to_non_nullable
as String,standardEndTime: null == standardEndTime ? _self.standardEndTime : standardEndTime // ignore: cast_nullable_to_non_nullable
as String,volunteerArrivalTime: freezed == volunteerArrivalTime ? _self.volunteerArrivalTime : volunteerArrivalTime // ignore: cast_nullable_to_non_nullable
as String?,desiredVolunteerCount: null == desiredVolunteerCount ? _self.desiredVolunteerCount : desiredVolunteerCount // ignore: cast_nullable_to_non_nullable
as int,earlySlot: freezed == earlySlot ? _self.earlySlot : earlySlot // ignore: cast_nullable_to_non_nullable
as EarlySlot?,
  ));
}
/// Create a copy of DeliveryTemplate
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


/// Adds pattern-matching-related methods to [DeliveryTemplate].
extension DeliveryTemplatePatterns on DeliveryTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryTemplate value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'delivery_template_id')  String deliveryTemplateId, @JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'standard_start_time')  String standardStartTime, @JsonKey(name: 'standard_end_time')  String standardEndTime, @JsonKey(name: 'volunteer_arrival_time')  String? volunteerArrivalTime, @JsonKey(name: 'desired_volunteer_count')  int desiredVolunteerCount, @JsonKey(name: 'early_slot')  EarlySlot? earlySlot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryTemplate() when $default != null:
return $default(_that.deliveryTemplateId,_that.organizationId,_that.name,_that.standardStartTime,_that.standardEndTime,_that.volunteerArrivalTime,_that.desiredVolunteerCount,_that.earlySlot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'delivery_template_id')  String deliveryTemplateId, @JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'standard_start_time')  String standardStartTime, @JsonKey(name: 'standard_end_time')  String standardEndTime, @JsonKey(name: 'volunteer_arrival_time')  String? volunteerArrivalTime, @JsonKey(name: 'desired_volunteer_count')  int desiredVolunteerCount, @JsonKey(name: 'early_slot')  EarlySlot? earlySlot)  $default,) {final _that = this;
switch (_that) {
case _DeliveryTemplate():
return $default(_that.deliveryTemplateId,_that.organizationId,_that.name,_that.standardStartTime,_that.standardEndTime,_that.volunteerArrivalTime,_that.desiredVolunteerCount,_that.earlySlot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'delivery_template_id')  String deliveryTemplateId, @JsonKey(name: 'organization_id')  String organizationId,  String name, @JsonKey(name: 'standard_start_time')  String standardStartTime, @JsonKey(name: 'standard_end_time')  String standardEndTime, @JsonKey(name: 'volunteer_arrival_time')  String? volunteerArrivalTime, @JsonKey(name: 'desired_volunteer_count')  int desiredVolunteerCount, @JsonKey(name: 'early_slot')  EarlySlot? earlySlot)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryTemplate() when $default != null:
return $default(_that.deliveryTemplateId,_that.organizationId,_that.name,_that.standardStartTime,_that.standardEndTime,_that.volunteerArrivalTime,_that.desiredVolunteerCount,_that.earlySlot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryTemplate implements DeliveryTemplate {
  const _DeliveryTemplate({@JsonKey(name: 'delivery_template_id') required this.deliveryTemplateId, @JsonKey(name: 'organization_id') required this.organizationId, required this.name, @JsonKey(name: 'standard_start_time') required this.standardStartTime, @JsonKey(name: 'standard_end_time') required this.standardEndTime, @JsonKey(name: 'volunteer_arrival_time') this.volunteerArrivalTime, @JsonKey(name: 'desired_volunteer_count') this.desiredVolunteerCount = 1, @JsonKey(name: 'early_slot') this.earlySlot});
  factory _DeliveryTemplate.fromJson(Map<String, dynamic> json) => _$DeliveryTemplateFromJson(json);

@override@JsonKey(name: 'delivery_template_id') final  String deliveryTemplateId;
@override@JsonKey(name: 'organization_id') final  String organizationId;
@override final  String name;
@override@JsonKey(name: 'standard_start_time') final  String standardStartTime;
@override@JsonKey(name: 'standard_end_time') final  String standardEndTime;
@override@JsonKey(name: 'volunteer_arrival_time') final  String? volunteerArrivalTime;
@override@JsonKey(name: 'desired_volunteer_count') final  int desiredVolunteerCount;
@override@JsonKey(name: 'early_slot') final  EarlySlot? earlySlot;

/// Create a copy of DeliveryTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryTemplateCopyWith<_DeliveryTemplate> get copyWith => __$DeliveryTemplateCopyWithImpl<_DeliveryTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryTemplate&&(identical(other.deliveryTemplateId, deliveryTemplateId) || other.deliveryTemplateId == deliveryTemplateId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.standardStartTime, standardStartTime) || other.standardStartTime == standardStartTime)&&(identical(other.standardEndTime, standardEndTime) || other.standardEndTime == standardEndTime)&&(identical(other.volunteerArrivalTime, volunteerArrivalTime) || other.volunteerArrivalTime == volunteerArrivalTime)&&(identical(other.desiredVolunteerCount, desiredVolunteerCount) || other.desiredVolunteerCount == desiredVolunteerCount)&&(identical(other.earlySlot, earlySlot) || other.earlySlot == earlySlot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deliveryTemplateId,organizationId,name,standardStartTime,standardEndTime,volunteerArrivalTime,desiredVolunteerCount,earlySlot);

@override
String toString() {
  return 'DeliveryTemplate(deliveryTemplateId: $deliveryTemplateId, organizationId: $organizationId, name: $name, standardStartTime: $standardStartTime, standardEndTime: $standardEndTime, volunteerArrivalTime: $volunteerArrivalTime, desiredVolunteerCount: $desiredVolunteerCount, earlySlot: $earlySlot)';
}


}

/// @nodoc
abstract mixin class _$DeliveryTemplateCopyWith<$Res> implements $DeliveryTemplateCopyWith<$Res> {
  factory _$DeliveryTemplateCopyWith(_DeliveryTemplate value, $Res Function(_DeliveryTemplate) _then) = __$DeliveryTemplateCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'delivery_template_id') String deliveryTemplateId,@JsonKey(name: 'organization_id') String organizationId, String name,@JsonKey(name: 'standard_start_time') String standardStartTime,@JsonKey(name: 'standard_end_time') String standardEndTime,@JsonKey(name: 'volunteer_arrival_time') String? volunteerArrivalTime,@JsonKey(name: 'desired_volunteer_count') int desiredVolunteerCount,@JsonKey(name: 'early_slot') EarlySlot? earlySlot
});


@override $EarlySlotCopyWith<$Res>? get earlySlot;

}
/// @nodoc
class __$DeliveryTemplateCopyWithImpl<$Res>
    implements _$DeliveryTemplateCopyWith<$Res> {
  __$DeliveryTemplateCopyWithImpl(this._self, this._then);

  final _DeliveryTemplate _self;
  final $Res Function(_DeliveryTemplate) _then;

/// Create a copy of DeliveryTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deliveryTemplateId = null,Object? organizationId = null,Object? name = null,Object? standardStartTime = null,Object? standardEndTime = null,Object? volunteerArrivalTime = freezed,Object? desiredVolunteerCount = null,Object? earlySlot = freezed,}) {
  return _then(_DeliveryTemplate(
deliveryTemplateId: null == deliveryTemplateId ? _self.deliveryTemplateId : deliveryTemplateId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,standardStartTime: null == standardStartTime ? _self.standardStartTime : standardStartTime // ignore: cast_nullable_to_non_nullable
as String,standardEndTime: null == standardEndTime ? _self.standardEndTime : standardEndTime // ignore: cast_nullable_to_non_nullable
as String,volunteerArrivalTime: freezed == volunteerArrivalTime ? _self.volunteerArrivalTime : volunteerArrivalTime // ignore: cast_nullable_to_non_nullable
as String?,desiredVolunteerCount: null == desiredVolunteerCount ? _self.desiredVolunteerCount : desiredVolunteerCount // ignore: cast_nullable_to_non_nullable
as int,earlySlot: freezed == earlySlot ? _self.earlySlot : earlySlot // ignore: cast_nullable_to_non_nullable
as EarlySlot?,
  ));
}

/// Create a copy of DeliveryTemplate
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

// dart format on
