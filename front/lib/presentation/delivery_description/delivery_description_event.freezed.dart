// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_description_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliveryDescriptionEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryDescriptionEvent()';
}


}

/// @nodoc
class $DeliveryDescriptionEventCopyWith<$Res>  {
$DeliveryDescriptionEventCopyWith(DeliveryDescriptionEvent _, $Res Function(DeliveryDescriptionEvent) __);
}


/// Adds pattern-matching-related methods to [DeliveryDescriptionEvent].
extension DeliveryDescriptionEventPatterns on DeliveryDescriptionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeliveryDescriptionRequested value)?  requested,TResult Function( ItemToggled value)?  itemToggled,TResult Function( WeightChanged value)?  weightChanged,TResult Function( DeliveryDescriptionSaveRequested value)?  saveRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeliveryDescriptionRequested() when requested != null:
return requested(_that);case ItemToggled() when itemToggled != null:
return itemToggled(_that);case WeightChanged() when weightChanged != null:
return weightChanged(_that);case DeliveryDescriptionSaveRequested() when saveRequested != null:
return saveRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeliveryDescriptionRequested value)  requested,required TResult Function( ItemToggled value)  itemToggled,required TResult Function( WeightChanged value)  weightChanged,required TResult Function( DeliveryDescriptionSaveRequested value)  saveRequested,}){
final _that = this;
switch (_that) {
case DeliveryDescriptionRequested():
return requested(_that);case ItemToggled():
return itemToggled(_that);case WeightChanged():
return weightChanged(_that);case DeliveryDescriptionSaveRequested():
return saveRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeliveryDescriptionRequested value)?  requested,TResult? Function( ItemToggled value)?  itemToggled,TResult? Function( WeightChanged value)?  weightChanged,TResult? Function( DeliveryDescriptionSaveRequested value)?  saveRequested,}){
final _that = this;
switch (_that) {
case DeliveryDescriptionRequested() when requested != null:
return requested(_that);case ItemToggled() when itemToggled != null:
return itemToggled(_that);case WeightChanged() when weightChanged != null:
return weightChanged(_that);case DeliveryDescriptionSaveRequested() when saveRequested != null:
return saveRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Organization org,  String deliveryId)?  requested,TResult Function( String productTypeId,  String basketSizeName,  String itemTypeId)?  itemToggled,TResult Function( String productTypeId,  String basketSizeName,  String itemTypeId,  String? weight)?  weightChanged,TResult Function()?  saveRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeliveryDescriptionRequested() when requested != null:
return requested(_that.org,_that.deliveryId);case ItemToggled() when itemToggled != null:
return itemToggled(_that.productTypeId,_that.basketSizeName,_that.itemTypeId);case WeightChanged() when weightChanged != null:
return weightChanged(_that.productTypeId,_that.basketSizeName,_that.itemTypeId,_that.weight);case DeliveryDescriptionSaveRequested() when saveRequested != null:
return saveRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Organization org,  String deliveryId)  requested,required TResult Function( String productTypeId,  String basketSizeName,  String itemTypeId)  itemToggled,required TResult Function( String productTypeId,  String basketSizeName,  String itemTypeId,  String? weight)  weightChanged,required TResult Function()  saveRequested,}) {final _that = this;
switch (_that) {
case DeliveryDescriptionRequested():
return requested(_that.org,_that.deliveryId);case ItemToggled():
return itemToggled(_that.productTypeId,_that.basketSizeName,_that.itemTypeId);case WeightChanged():
return weightChanged(_that.productTypeId,_that.basketSizeName,_that.itemTypeId,_that.weight);case DeliveryDescriptionSaveRequested():
return saveRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Organization org,  String deliveryId)?  requested,TResult? Function( String productTypeId,  String basketSizeName,  String itemTypeId)?  itemToggled,TResult? Function( String productTypeId,  String basketSizeName,  String itemTypeId,  String? weight)?  weightChanged,TResult? Function()?  saveRequested,}) {final _that = this;
switch (_that) {
case DeliveryDescriptionRequested() when requested != null:
return requested(_that.org,_that.deliveryId);case ItemToggled() when itemToggled != null:
return itemToggled(_that.productTypeId,_that.basketSizeName,_that.itemTypeId);case WeightChanged() when weightChanged != null:
return weightChanged(_that.productTypeId,_that.basketSizeName,_that.itemTypeId,_that.weight);case DeliveryDescriptionSaveRequested() when saveRequested != null:
return saveRequested();case _:
  return null;

}
}

}

/// @nodoc


class DeliveryDescriptionRequested implements DeliveryDescriptionEvent {
  const DeliveryDescriptionRequested({required this.org, required this.deliveryId});
  

 final  Organization org;
 final  String deliveryId;

/// Create a copy of DeliveryDescriptionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryDescriptionRequestedCopyWith<DeliveryDescriptionRequested> get copyWith => _$DeliveryDescriptionRequestedCopyWithImpl<DeliveryDescriptionRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionRequested&&(identical(other.org, org) || other.org == org)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId));
}


@override
int get hashCode => Object.hash(runtimeType,org,deliveryId);

@override
String toString() {
  return 'DeliveryDescriptionEvent.requested(org: $org, deliveryId: $deliveryId)';
}


}

/// @nodoc
abstract mixin class $DeliveryDescriptionRequestedCopyWith<$Res> implements $DeliveryDescriptionEventCopyWith<$Res> {
  factory $DeliveryDescriptionRequestedCopyWith(DeliveryDescriptionRequested value, $Res Function(DeliveryDescriptionRequested) _then) = _$DeliveryDescriptionRequestedCopyWithImpl;
@useResult
$Res call({
 Organization org, String deliveryId
});


$OrganizationCopyWith<$Res> get org;

}
/// @nodoc
class _$DeliveryDescriptionRequestedCopyWithImpl<$Res>
    implements $DeliveryDescriptionRequestedCopyWith<$Res> {
  _$DeliveryDescriptionRequestedCopyWithImpl(this._self, this._then);

  final DeliveryDescriptionRequested _self;
  final $Res Function(DeliveryDescriptionRequested) _then;

/// Create a copy of DeliveryDescriptionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? org = null,Object? deliveryId = null,}) {
  return _then(DeliveryDescriptionRequested(
org: null == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as Organization,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of DeliveryDescriptionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get org {
  
  return $OrganizationCopyWith<$Res>(_self.org, (value) {
    return _then(_self.copyWith(org: value));
  });
}
}

/// @nodoc


class ItemToggled implements DeliveryDescriptionEvent {
  const ItemToggled({required this.productTypeId, required this.basketSizeName, required this.itemTypeId});
  

 final  String productTypeId;
 final  String basketSizeName;
 final  String itemTypeId;

/// Create a copy of DeliveryDescriptionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemToggledCopyWith<ItemToggled> get copyWith => _$ItemToggledCopyWithImpl<ItemToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemToggled&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.basketSizeName, basketSizeName) || other.basketSizeName == basketSizeName)&&(identical(other.itemTypeId, itemTypeId) || other.itemTypeId == itemTypeId));
}


@override
int get hashCode => Object.hash(runtimeType,productTypeId,basketSizeName,itemTypeId);

@override
String toString() {
  return 'DeliveryDescriptionEvent.itemToggled(productTypeId: $productTypeId, basketSizeName: $basketSizeName, itemTypeId: $itemTypeId)';
}


}

/// @nodoc
abstract mixin class $ItemToggledCopyWith<$Res> implements $DeliveryDescriptionEventCopyWith<$Res> {
  factory $ItemToggledCopyWith(ItemToggled value, $Res Function(ItemToggled) _then) = _$ItemToggledCopyWithImpl;
@useResult
$Res call({
 String productTypeId, String basketSizeName, String itemTypeId
});




}
/// @nodoc
class _$ItemToggledCopyWithImpl<$Res>
    implements $ItemToggledCopyWith<$Res> {
  _$ItemToggledCopyWithImpl(this._self, this._then);

  final ItemToggled _self;
  final $Res Function(ItemToggled) _then;

/// Create a copy of DeliveryDescriptionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productTypeId = null,Object? basketSizeName = null,Object? itemTypeId = null,}) {
  return _then(ItemToggled(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,basketSizeName: null == basketSizeName ? _self.basketSizeName : basketSizeName // ignore: cast_nullable_to_non_nullable
as String,itemTypeId: null == itemTypeId ? _self.itemTypeId : itemTypeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class WeightChanged implements DeliveryDescriptionEvent {
  const WeightChanged({required this.productTypeId, required this.basketSizeName, required this.itemTypeId, this.weight});
  

 final  String productTypeId;
 final  String basketSizeName;
 final  String itemTypeId;
 final  String? weight;

/// Create a copy of DeliveryDescriptionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeightChangedCopyWith<WeightChanged> get copyWith => _$WeightChangedCopyWithImpl<WeightChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeightChanged&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.basketSizeName, basketSizeName) || other.basketSizeName == basketSizeName)&&(identical(other.itemTypeId, itemTypeId) || other.itemTypeId == itemTypeId)&&(identical(other.weight, weight) || other.weight == weight));
}


@override
int get hashCode => Object.hash(runtimeType,productTypeId,basketSizeName,itemTypeId,weight);

@override
String toString() {
  return 'DeliveryDescriptionEvent.weightChanged(productTypeId: $productTypeId, basketSizeName: $basketSizeName, itemTypeId: $itemTypeId, weight: $weight)';
}


}

/// @nodoc
abstract mixin class $WeightChangedCopyWith<$Res> implements $DeliveryDescriptionEventCopyWith<$Res> {
  factory $WeightChangedCopyWith(WeightChanged value, $Res Function(WeightChanged) _then) = _$WeightChangedCopyWithImpl;
@useResult
$Res call({
 String productTypeId, String basketSizeName, String itemTypeId, String? weight
});




}
/// @nodoc
class _$WeightChangedCopyWithImpl<$Res>
    implements $WeightChangedCopyWith<$Res> {
  _$WeightChangedCopyWithImpl(this._self, this._then);

  final WeightChanged _self;
  final $Res Function(WeightChanged) _then;

/// Create a copy of DeliveryDescriptionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productTypeId = null,Object? basketSizeName = null,Object? itemTypeId = null,Object? weight = freezed,}) {
  return _then(WeightChanged(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,basketSizeName: null == basketSizeName ? _self.basketSizeName : basketSizeName // ignore: cast_nullable_to_non_nullable
as String,itemTypeId: null == itemTypeId ? _self.itemTypeId : itemTypeId // ignore: cast_nullable_to_non_nullable
as String,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class DeliveryDescriptionSaveRequested implements DeliveryDescriptionEvent {
  const DeliveryDescriptionSaveRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionSaveRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryDescriptionEvent.saveRequested()';
}


}




// dart format on
