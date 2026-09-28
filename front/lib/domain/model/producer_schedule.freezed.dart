// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProducerSchedule {

@JsonKey(name: 'organization_id') String get organizationId;@JsonKey(name: 'producer_account_id') String get producerAccountId;@JsonKey(name: 'organization_name') String get organizationName; List<ProducerScheduleDelivery> get deliveries;
/// Create a copy of ProducerSchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerScheduleCopyWith<ProducerSchedule> get copyWith => _$ProducerScheduleCopyWithImpl<ProducerSchedule>(this as ProducerSchedule, _$identity);

  /// Serializes this ProducerSchedule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProducerSchedule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerSchedule&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.producerAccountId, _this.producerAccountId) || other.producerAccountId == _this.producerAccountId)&&(identical(other.organizationName, _this.organizationName) || other.organizationName == _this.organizationName)&&const DeepCollectionEquality().equals(other.deliveries, _this.deliveries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProducerSchedule;
  return Object.hash(runtimeType,_this.organizationId,_this.producerAccountId,_this.organizationName,const DeepCollectionEquality().hash(_this.deliveries));
}

@override
String toString() {
  final _this = this as ProducerSchedule;
  return 'ProducerSchedule(organizationId: ${_this.organizationId}, producerAccountId: ${_this.producerAccountId}, organizationName: ${_this.organizationName}, deliveries: ${_this.deliveries})';
}


}

/// @nodoc
abstract mixin class $ProducerScheduleCopyWith<$Res>  {
  factory $ProducerScheduleCopyWith(ProducerSchedule value, $Res Function(ProducerSchedule) _then) = _$ProducerScheduleCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'organization_name') String organizationName, List<ProducerScheduleDelivery> deliveries
});




}
/// @nodoc
class _$ProducerScheduleCopyWithImpl<$Res>
    implements $ProducerScheduleCopyWith<$Res> {
  _$ProducerScheduleCopyWithImpl(this._self, this._then);

  final ProducerSchedule _self;
  final $Res Function(ProducerSchedule) _then;

/// Create a copy of ProducerSchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? producerAccountId = null,Object? organizationName = null,Object? deliveries = null,}) {
  return _then(ProducerSchedule(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,deliveries: null == deliveries ? _self.deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as List<ProducerScheduleDelivery>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProducerSchedule].
extension ProducerSchedulePatterns on ProducerSchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerSchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerSchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerSchedule value)  $default,){
final _that = this;
switch (_that) {
case _ProducerSchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerSchedule value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerSchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'organization_name')  String organizationName,  List<ProducerScheduleDelivery> deliveries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerSchedule() when $default != null:
return $default(_that.organizationId,_that.producerAccountId,_that.organizationName,_that.deliveries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'organization_name')  String organizationName,  List<ProducerScheduleDelivery> deliveries)  $default,) {final _that = this;
switch (_that) {
case _ProducerSchedule():
return $default(_that.organizationId,_that.producerAccountId,_that.organizationName,_that.deliveries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'organization_name')  String organizationName,  List<ProducerScheduleDelivery> deliveries)?  $default,) {final _that = this;
switch (_that) {
case _ProducerSchedule() when $default != null:
return $default(_that.organizationId,_that.producerAccountId,_that.organizationName,_that.deliveries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProducerSchedule implements ProducerSchedule {
  const _ProducerSchedule({@JsonKey(name: 'organization_id') required this.organizationId, @JsonKey(name: 'producer_account_id') required this.producerAccountId, @JsonKey(name: 'organization_name') required this.organizationName,  List<ProducerScheduleDelivery> deliveries = const <ProducerScheduleDelivery>[]}): _deliveries = deliveries;
  factory _ProducerSchedule.fromJson(Map<String, dynamic> json) => _$ProducerScheduleFromJson(json);

@override@JsonKey(name: 'organization_id') final  String organizationId;
@override@JsonKey(name: 'producer_account_id') final  String producerAccountId;
@override@JsonKey(name: 'organization_name') final  String organizationName;
 final  List<ProducerScheduleDelivery> _deliveries;
@override@JsonKey() List<ProducerScheduleDelivery> get deliveries {
  if (_deliveries is EqualUnmodifiableListView) return _deliveries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveries);
}


/// Create a copy of ProducerSchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerScheduleCopyWith<_ProducerSchedule> get copyWith => __$ProducerScheduleCopyWithImpl<_ProducerSchedule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProducerScheduleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerSchedule&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&const DeepCollectionEquality().equals(other.deliveries, _deliveries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,producerAccountId,organizationName,const DeepCollectionEquality().hash(_deliveries));
}

@override
String toString() {
    return 'ProducerSchedule(organizationId: $organizationId, producerAccountId: $producerAccountId, organizationName: $organizationName, deliveries: $deliveries)';
}


}

/// @nodoc
abstract mixin class _$ProducerScheduleCopyWith<$Res> implements $ProducerScheduleCopyWith<$Res> {
  factory _$ProducerScheduleCopyWith(_ProducerSchedule value, $Res Function(_ProducerSchedule) _then) = __$ProducerScheduleCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'organization_name') String organizationName, List<ProducerScheduleDelivery> deliveries
});




}
/// @nodoc
class __$ProducerScheduleCopyWithImpl<$Res>
    implements _$ProducerScheduleCopyWith<$Res> {
  __$ProducerScheduleCopyWithImpl(this._self, this._then);

  final _ProducerSchedule _self;
  final $Res Function(_ProducerSchedule) _then;

/// Create a copy of ProducerSchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? producerAccountId = null,Object? organizationName = null,Object? deliveries = null,}) {
  return _then(_ProducerSchedule(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,deliveries: null == deliveries ? _self._deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as List<ProducerScheduleDelivery>,
  ));
}


}


/// @nodoc
mixin _$ProducerScheduleDelivery {

@JsonKey(name: 'delivery_id') String get deliveryId;@JsonKey(name: 'scheduled_date') String get scheduledDate; DeliveryStatus get status; List<ProducerScheduleContract> get contracts;@JsonKey(name: 'basket_descriptions') List<BasketDeliveryDescription> get basketDescriptions;
/// Create a copy of ProducerScheduleDelivery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerScheduleDeliveryCopyWith<ProducerScheduleDelivery> get copyWith => _$ProducerScheduleDeliveryCopyWithImpl<ProducerScheduleDelivery>(this as ProducerScheduleDelivery, _$identity);

  /// Serializes this ProducerScheduleDelivery to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProducerScheduleDelivery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerScheduleDelivery&&(identical(other.deliveryId, _this.deliveryId) || other.deliveryId == _this.deliveryId)&&(identical(other.scheduledDate, _this.scheduledDate) || other.scheduledDate == _this.scheduledDate)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.contracts, _this.contracts)&&const DeepCollectionEquality().equals(other.basketDescriptions, _this.basketDescriptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProducerScheduleDelivery;
  return Object.hash(runtimeType,_this.deliveryId,_this.scheduledDate,_this.status,const DeepCollectionEquality().hash(_this.contracts),const DeepCollectionEquality().hash(_this.basketDescriptions));
}

@override
String toString() {
  final _this = this as ProducerScheduleDelivery;
  return 'ProducerScheduleDelivery(deliveryId: ${_this.deliveryId}, scheduledDate: ${_this.scheduledDate}, status: ${_this.status}, contracts: ${_this.contracts}, basketDescriptions: ${_this.basketDescriptions})';
}


}

/// @nodoc
abstract mixin class $ProducerScheduleDeliveryCopyWith<$Res>  {
  factory $ProducerScheduleDeliveryCopyWith(ProducerScheduleDelivery value, $Res Function(ProducerScheduleDelivery) _then) = _$ProducerScheduleDeliveryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'scheduled_date') String scheduledDate, DeliveryStatus status, List<ProducerScheduleContract> contracts,@JsonKey(name: 'basket_descriptions') List<BasketDeliveryDescription> basketDescriptions
});




}
/// @nodoc
class _$ProducerScheduleDeliveryCopyWithImpl<$Res>
    implements $ProducerScheduleDeliveryCopyWith<$Res> {
  _$ProducerScheduleDeliveryCopyWithImpl(this._self, this._then);

  final ProducerScheduleDelivery _self;
  final $Res Function(ProducerScheduleDelivery) _then;

/// Create a copy of ProducerScheduleDelivery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deliveryId = null,Object? scheduledDate = null,Object? status = null,Object? contracts = null,Object? basketDescriptions = null,}) {
  return _then(ProducerScheduleDelivery(
deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeliveryStatus,contracts: null == contracts ? _self.contracts : contracts // ignore: cast_nullable_to_non_nullable
as List<ProducerScheduleContract>,basketDescriptions: null == basketDescriptions ? _self.basketDescriptions : basketDescriptions // ignore: cast_nullable_to_non_nullable
as List<BasketDeliveryDescription>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProducerScheduleDelivery].
extension ProducerScheduleDeliveryPatterns on ProducerScheduleDelivery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerScheduleDelivery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerScheduleDelivery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerScheduleDelivery value)  $default,){
final _that = this;
switch (_that) {
case _ProducerScheduleDelivery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerScheduleDelivery value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerScheduleDelivery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'scheduled_date')  String scheduledDate,  DeliveryStatus status,  List<ProducerScheduleContract> contracts, @JsonKey(name: 'basket_descriptions')  List<BasketDeliveryDescription> basketDescriptions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerScheduleDelivery() when $default != null:
return $default(_that.deliveryId,_that.scheduledDate,_that.status,_that.contracts,_that.basketDescriptions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'scheduled_date')  String scheduledDate,  DeliveryStatus status,  List<ProducerScheduleContract> contracts, @JsonKey(name: 'basket_descriptions')  List<BasketDeliveryDescription> basketDescriptions)  $default,) {final _that = this;
switch (_that) {
case _ProducerScheduleDelivery():
return $default(_that.deliveryId,_that.scheduledDate,_that.status,_that.contracts,_that.basketDescriptions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'scheduled_date')  String scheduledDate,  DeliveryStatus status,  List<ProducerScheduleContract> contracts, @JsonKey(name: 'basket_descriptions')  List<BasketDeliveryDescription> basketDescriptions)?  $default,) {final _that = this;
switch (_that) {
case _ProducerScheduleDelivery() when $default != null:
return $default(_that.deliveryId,_that.scheduledDate,_that.status,_that.contracts,_that.basketDescriptions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProducerScheduleDelivery implements ProducerScheduleDelivery {
  const _ProducerScheduleDelivery({@JsonKey(name: 'delivery_id') required this.deliveryId, @JsonKey(name: 'scheduled_date') required this.scheduledDate, required this.status,  List<ProducerScheduleContract> contracts = const <ProducerScheduleContract>[], @JsonKey(name: 'basket_descriptions')  List<BasketDeliveryDescription> basketDescriptions = const <BasketDeliveryDescription>[]}): _contracts = contracts,_basketDescriptions = basketDescriptions;
  factory _ProducerScheduleDelivery.fromJson(Map<String, dynamic> json) => _$ProducerScheduleDeliveryFromJson(json);

@override@JsonKey(name: 'delivery_id') final  String deliveryId;
@override@JsonKey(name: 'scheduled_date') final  String scheduledDate;
@override final  DeliveryStatus status;
 final  List<ProducerScheduleContract> _contracts;
@override@JsonKey() List<ProducerScheduleContract> get contracts {
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


/// Create a copy of ProducerScheduleDelivery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerScheduleDeliveryCopyWith<_ProducerScheduleDelivery> get copyWith => __$ProducerScheduleDeliveryCopyWithImpl<_ProducerScheduleDelivery>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProducerScheduleDeliveryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerScheduleDelivery&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.contracts, _contracts)&&const DeepCollectionEquality().equals(other.basketDescriptions, _basketDescriptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,deliveryId,scheduledDate,status,const DeepCollectionEquality().hash(_contracts),const DeepCollectionEquality().hash(_basketDescriptions));
}

@override
String toString() {
    return 'ProducerScheduleDelivery(deliveryId: $deliveryId, scheduledDate: $scheduledDate, status: $status, contracts: $contracts, basketDescriptions: $basketDescriptions)';
}


}

/// @nodoc
abstract mixin class _$ProducerScheduleDeliveryCopyWith<$Res> implements $ProducerScheduleDeliveryCopyWith<$Res> {
  factory _$ProducerScheduleDeliveryCopyWith(_ProducerScheduleDelivery value, $Res Function(_ProducerScheduleDelivery) _then) = __$ProducerScheduleDeliveryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'scheduled_date') String scheduledDate, DeliveryStatus status, List<ProducerScheduleContract> contracts,@JsonKey(name: 'basket_descriptions') List<BasketDeliveryDescription> basketDescriptions
});




}
/// @nodoc
class __$ProducerScheduleDeliveryCopyWithImpl<$Res>
    implements _$ProducerScheduleDeliveryCopyWith<$Res> {
  __$ProducerScheduleDeliveryCopyWithImpl(this._self, this._then);

  final _ProducerScheduleDelivery _self;
  final $Res Function(_ProducerScheduleDelivery) _then;

/// Create a copy of ProducerScheduleDelivery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deliveryId = null,Object? scheduledDate = null,Object? status = null,Object? contracts = null,Object? basketDescriptions = null,}) {
  return _then(_ProducerScheduleDelivery(
deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeliveryStatus,contracts: null == contracts ? _self._contracts : contracts // ignore: cast_nullable_to_non_nullable
as List<ProducerScheduleContract>,basketDescriptions: null == basketDescriptions ? _self._basketDescriptions : basketDescriptions // ignore: cast_nullable_to_non_nullable
as List<BasketDeliveryDescription>,
  ));
}


}


/// @nodoc
mixin _$ProducerScheduleContract {

@JsonKey(name: 'contract_id') String get contractId;@JsonKey(name: 'contract_name') String get contractName;@JsonKey(name: 'basket_quantity') int get basketQuantity; DeliveryContractStatus get status;/// Lifecycle of the contract itself (null only for schedules synced
/// before the back sent it).
@JsonKey(name: 'contract_status') ContractStatus? get contractStatus;
/// Create a copy of ProducerScheduleContract
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerScheduleContractCopyWith<ProducerScheduleContract> get copyWith => _$ProducerScheduleContractCopyWithImpl<ProducerScheduleContract>(this as ProducerScheduleContract, _$identity);

  /// Serializes this ProducerScheduleContract to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProducerScheduleContract;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerScheduleContract&&(identical(other.contractId, _this.contractId) || other.contractId == _this.contractId)&&(identical(other.contractName, _this.contractName) || other.contractName == _this.contractName)&&(identical(other.basketQuantity, _this.basketQuantity) || other.basketQuantity == _this.basketQuantity)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.contractStatus, _this.contractStatus) || other.contractStatus == _this.contractStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProducerScheduleContract;
  return Object.hash(runtimeType,_this.contractId,_this.contractName,_this.basketQuantity,_this.status,_this.contractStatus);
}

@override
String toString() {
  final _this = this as ProducerScheduleContract;
  return 'ProducerScheduleContract(contractId: ${_this.contractId}, contractName: ${_this.contractName}, basketQuantity: ${_this.basketQuantity}, status: ${_this.status}, contractStatus: ${_this.contractStatus})';
}


}

/// @nodoc
abstract mixin class $ProducerScheduleContractCopyWith<$Res>  {
  factory $ProducerScheduleContractCopyWith(ProducerScheduleContract value, $Res Function(ProducerScheduleContract) _then) = _$ProducerScheduleContractCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'contract_name') String contractName,@JsonKey(name: 'basket_quantity') int basketQuantity, DeliveryContractStatus status,@JsonKey(name: 'contract_status') ContractStatus? contractStatus
});




}
/// @nodoc
class _$ProducerScheduleContractCopyWithImpl<$Res>
    implements $ProducerScheduleContractCopyWith<$Res> {
  _$ProducerScheduleContractCopyWithImpl(this._self, this._then);

  final ProducerScheduleContract _self;
  final $Res Function(ProducerScheduleContract) _then;

/// Create a copy of ProducerScheduleContract
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractId = null,Object? contractName = null,Object? basketQuantity = null,Object? status = null,Object? contractStatus = freezed,}) {
  return _then(ProducerScheduleContract(
contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,contractName: null == contractName ? _self.contractName : contractName // ignore: cast_nullable_to_non_nullable
as String,basketQuantity: null == basketQuantity ? _self.basketQuantity : basketQuantity // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeliveryContractStatus,contractStatus: freezed == contractStatus ? _self.contractStatus : contractStatus // ignore: cast_nullable_to_non_nullable
as ContractStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProducerScheduleContract].
extension ProducerScheduleContractPatterns on ProducerScheduleContract {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerScheduleContract value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerScheduleContract() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerScheduleContract value)  $default,){
final _that = this;
switch (_that) {
case _ProducerScheduleContract():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerScheduleContract value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerScheduleContract() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'contract_name')  String contractName, @JsonKey(name: 'basket_quantity')  int basketQuantity,  DeliveryContractStatus status, @JsonKey(name: 'contract_status')  ContractStatus? contractStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerScheduleContract() when $default != null:
return $default(_that.contractId,_that.contractName,_that.basketQuantity,_that.status,_that.contractStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'contract_name')  String contractName, @JsonKey(name: 'basket_quantity')  int basketQuantity,  DeliveryContractStatus status, @JsonKey(name: 'contract_status')  ContractStatus? contractStatus)  $default,) {final _that = this;
switch (_that) {
case _ProducerScheduleContract():
return $default(_that.contractId,_that.contractName,_that.basketQuantity,_that.status,_that.contractStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'contract_name')  String contractName, @JsonKey(name: 'basket_quantity')  int basketQuantity,  DeliveryContractStatus status, @JsonKey(name: 'contract_status')  ContractStatus? contractStatus)?  $default,) {final _that = this;
switch (_that) {
case _ProducerScheduleContract() when $default != null:
return $default(_that.contractId,_that.contractName,_that.basketQuantity,_that.status,_that.contractStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProducerScheduleContract implements ProducerScheduleContract {
  const _ProducerScheduleContract({@JsonKey(name: 'contract_id') required this.contractId, @JsonKey(name: 'contract_name') required this.contractName, @JsonKey(name: 'basket_quantity') required this.basketQuantity, required this.status, @JsonKey(name: 'contract_status') this.contractStatus});
  factory _ProducerScheduleContract.fromJson(Map<String, dynamic> json) => _$ProducerScheduleContractFromJson(json);

@override@JsonKey(name: 'contract_id') final  String contractId;
@override@JsonKey(name: 'contract_name') final  String contractName;
@override@JsonKey(name: 'basket_quantity') final  int basketQuantity;
@override final  DeliveryContractStatus status;
/// Lifecycle of the contract itself (null only for schedules synced
/// before the back sent it).
@override@JsonKey(name: 'contract_status') final  ContractStatus? contractStatus;

/// Create a copy of ProducerScheduleContract
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerScheduleContractCopyWith<_ProducerScheduleContract> get copyWith => __$ProducerScheduleContractCopyWithImpl<_ProducerScheduleContract>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProducerScheduleContractToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerScheduleContract&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.contractName, contractName) || other.contractName == contractName)&&(identical(other.basketQuantity, basketQuantity) || other.basketQuantity == basketQuantity)&&(identical(other.status, status) || other.status == status)&&(identical(other.contractStatus, contractStatus) || other.contractStatus == contractStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,contractId,contractName,basketQuantity,status,contractStatus);
}

@override
String toString() {
    return 'ProducerScheduleContract(contractId: $contractId, contractName: $contractName, basketQuantity: $basketQuantity, status: $status, contractStatus: $contractStatus)';
}


}

/// @nodoc
abstract mixin class _$ProducerScheduleContractCopyWith<$Res> implements $ProducerScheduleContractCopyWith<$Res> {
  factory _$ProducerScheduleContractCopyWith(_ProducerScheduleContract value, $Res Function(_ProducerScheduleContract) _then) = __$ProducerScheduleContractCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'contract_name') String contractName,@JsonKey(name: 'basket_quantity') int basketQuantity, DeliveryContractStatus status,@JsonKey(name: 'contract_status') ContractStatus? contractStatus
});




}
/// @nodoc
class __$ProducerScheduleContractCopyWithImpl<$Res>
    implements _$ProducerScheduleContractCopyWith<$Res> {
  __$ProducerScheduleContractCopyWithImpl(this._self, this._then);

  final _ProducerScheduleContract _self;
  final $Res Function(_ProducerScheduleContract) _then;

/// Create a copy of ProducerScheduleContract
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractId = null,Object? contractName = null,Object? basketQuantity = null,Object? status = null,Object? contractStatus = freezed,}) {
  return _then(_ProducerScheduleContract(
contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,contractName: null == contractName ? _self.contractName : contractName // ignore: cast_nullable_to_non_nullable
as String,basketQuantity: null == basketQuantity ? _self.basketQuantity : basketQuantity // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeliveryContractStatus,contractStatus: freezed == contractStatus ? _self.contractStatus : contractStatus // ignore: cast_nullable_to_non_nullable
as ContractStatus?,
  ));
}


}

// dart format on
