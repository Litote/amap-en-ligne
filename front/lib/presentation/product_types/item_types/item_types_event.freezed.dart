// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_types_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItemTypesEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ItemTypesEvent()';
}


}

/// @nodoc
class $ItemTypesEventCopyWith<$Res>  {
$ItemTypesEventCopyWith(ItemTypesEvent _, $Res Function(ItemTypesEvent) __);
}


/// Adds pattern-matching-related methods to [ItemTypesEvent].
extension ItemTypesEventPatterns on ItemTypesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ItemTypesRequested value)?  requested,TResult Function( ItemTypeAdded value)?  added,TResult Function( ItemTypeRemoved value)?  removed,TResult Function( ItemTypeUpdated value)?  updated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ItemTypesRequested() when requested != null:
return requested(_that);case ItemTypeAdded() when added != null:
return added(_that);case ItemTypeRemoved() when removed != null:
return removed(_that);case ItemTypeUpdated() when updated != null:
return updated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ItemTypesRequested value)  requested,required TResult Function( ItemTypeAdded value)  added,required TResult Function( ItemTypeRemoved value)  removed,required TResult Function( ItemTypeUpdated value)  updated,}){
final _that = this;
switch (_that) {
case ItemTypesRequested():
return requested(_that);case ItemTypeAdded():
return added(_that);case ItemTypeRemoved():
return removed(_that);case ItemTypeUpdated():
return updated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ItemTypesRequested value)?  requested,TResult? Function( ItemTypeAdded value)?  added,TResult? Function( ItemTypeRemoved value)?  removed,TResult? Function( ItemTypeUpdated value)?  updated,}){
final _that = this;
switch (_that) {
case ItemTypesRequested() when requested != null:
return requested(_that);case ItemTypeAdded() when added != null:
return added(_that);case ItemTypeRemoved() when removed != null:
return removed(_that);case ItemTypeUpdated() when updated != null:
return updated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ProductType productType)?  requested,TResult Function( String name,  String? imageSvg)?  added,TResult Function( String itemTypeId)?  removed,TResult Function( ItemType itemType)?  updated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ItemTypesRequested() when requested != null:
return requested(_that.productType);case ItemTypeAdded() when added != null:
return added(_that.name,_that.imageSvg);case ItemTypeRemoved() when removed != null:
return removed(_that.itemTypeId);case ItemTypeUpdated() when updated != null:
return updated(_that.itemType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ProductType productType)  requested,required TResult Function( String name,  String? imageSvg)  added,required TResult Function( String itemTypeId)  removed,required TResult Function( ItemType itemType)  updated,}) {final _that = this;
switch (_that) {
case ItemTypesRequested():
return requested(_that.productType);case ItemTypeAdded():
return added(_that.name,_that.imageSvg);case ItemTypeRemoved():
return removed(_that.itemTypeId);case ItemTypeUpdated():
return updated(_that.itemType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ProductType productType)?  requested,TResult? Function( String name,  String? imageSvg)?  added,TResult? Function( String itemTypeId)?  removed,TResult? Function( ItemType itemType)?  updated,}) {final _that = this;
switch (_that) {
case ItemTypesRequested() when requested != null:
return requested(_that.productType);case ItemTypeAdded() when added != null:
return added(_that.name,_that.imageSvg);case ItemTypeRemoved() when removed != null:
return removed(_that.itemTypeId);case ItemTypeUpdated() when updated != null:
return updated(_that.itemType);case _:
  return null;

}
}

}

/// @nodoc


class ItemTypesRequested implements ItemTypesEvent {
  const ItemTypesRequested({required this.productType});
  

 final  ProductType productType;

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypesRequestedCopyWith<ItemTypesRequested> get copyWith => _$ItemTypesRequestedCopyWithImpl<ItemTypesRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypesRequested&&(identical(other.productType, productType) || other.productType == productType));
}


@override
int get hashCode => Object.hash(runtimeType,productType);

@override
String toString() {
  return 'ItemTypesEvent.requested(productType: $productType)';
}


}

/// @nodoc
abstract mixin class $ItemTypesRequestedCopyWith<$Res> implements $ItemTypesEventCopyWith<$Res> {
  factory $ItemTypesRequestedCopyWith(ItemTypesRequested value, $Res Function(ItemTypesRequested) _then) = _$ItemTypesRequestedCopyWithImpl;
@useResult
$Res call({
 ProductType productType
});


$ProductTypeCopyWith<$Res> get productType;

}
/// @nodoc
class _$ItemTypesRequestedCopyWithImpl<$Res>
    implements $ItemTypesRequestedCopyWith<$Res> {
  _$ItemTypesRequestedCopyWithImpl(this._self, this._then);

  final ItemTypesRequested _self;
  final $Res Function(ItemTypesRequested) _then;

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productType = null,}) {
  return _then(ItemTypesRequested(
productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductTypeCopyWith<$Res> get productType {
  
  return $ProductTypeCopyWith<$Res>(_self.productType, (value) {
    return _then(_self.copyWith(productType: value));
  });
}
}

/// @nodoc


class ItemTypeAdded implements ItemTypesEvent {
  const ItemTypeAdded({required this.name, this.imageSvg});
  

 final  String name;
 final  String? imageSvg;

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypeAddedCopyWith<ItemTypeAdded> get copyWith => _$ItemTypeAddedCopyWithImpl<ItemTypeAdded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypeAdded&&(identical(other.name, name) || other.name == name)&&(identical(other.imageSvg, imageSvg) || other.imageSvg == imageSvg));
}


@override
int get hashCode => Object.hash(runtimeType,name,imageSvg);

@override
String toString() {
  return 'ItemTypesEvent.added(name: $name, imageSvg: $imageSvg)';
}


}

/// @nodoc
abstract mixin class $ItemTypeAddedCopyWith<$Res> implements $ItemTypesEventCopyWith<$Res> {
  factory $ItemTypeAddedCopyWith(ItemTypeAdded value, $Res Function(ItemTypeAdded) _then) = _$ItemTypeAddedCopyWithImpl;
@useResult
$Res call({
 String name, String? imageSvg
});




}
/// @nodoc
class _$ItemTypeAddedCopyWithImpl<$Res>
    implements $ItemTypeAddedCopyWith<$Res> {
  _$ItemTypeAddedCopyWithImpl(this._self, this._then);

  final ItemTypeAdded _self;
  final $Res Function(ItemTypeAdded) _then;

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? imageSvg = freezed,}) {
  return _then(ItemTypeAdded(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,imageSvg: freezed == imageSvg ? _self.imageSvg : imageSvg // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ItemTypeRemoved implements ItemTypesEvent {
  const ItemTypeRemoved({required this.itemTypeId});
  

 final  String itemTypeId;

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypeRemovedCopyWith<ItemTypeRemoved> get copyWith => _$ItemTypeRemovedCopyWithImpl<ItemTypeRemoved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypeRemoved&&(identical(other.itemTypeId, itemTypeId) || other.itemTypeId == itemTypeId));
}


@override
int get hashCode => Object.hash(runtimeType,itemTypeId);

@override
String toString() {
  return 'ItemTypesEvent.removed(itemTypeId: $itemTypeId)';
}


}

/// @nodoc
abstract mixin class $ItemTypeRemovedCopyWith<$Res> implements $ItemTypesEventCopyWith<$Res> {
  factory $ItemTypeRemovedCopyWith(ItemTypeRemoved value, $Res Function(ItemTypeRemoved) _then) = _$ItemTypeRemovedCopyWithImpl;
@useResult
$Res call({
 String itemTypeId
});




}
/// @nodoc
class _$ItemTypeRemovedCopyWithImpl<$Res>
    implements $ItemTypeRemovedCopyWith<$Res> {
  _$ItemTypeRemovedCopyWithImpl(this._self, this._then);

  final ItemTypeRemoved _self;
  final $Res Function(ItemTypeRemoved) _then;

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itemTypeId = null,}) {
  return _then(ItemTypeRemoved(
itemTypeId: null == itemTypeId ? _self.itemTypeId : itemTypeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ItemTypeUpdated implements ItemTypesEvent {
  const ItemTypeUpdated({required this.itemType});
  

 final  ItemType itemType;

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypeUpdatedCopyWith<ItemTypeUpdated> get copyWith => _$ItemTypeUpdatedCopyWithImpl<ItemTypeUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypeUpdated&&(identical(other.itemType, itemType) || other.itemType == itemType));
}


@override
int get hashCode => Object.hash(runtimeType,itemType);

@override
String toString() {
  return 'ItemTypesEvent.updated(itemType: $itemType)';
}


}

/// @nodoc
abstract mixin class $ItemTypeUpdatedCopyWith<$Res> implements $ItemTypesEventCopyWith<$Res> {
  factory $ItemTypeUpdatedCopyWith(ItemTypeUpdated value, $Res Function(ItemTypeUpdated) _then) = _$ItemTypeUpdatedCopyWithImpl;
@useResult
$Res call({
 ItemType itemType
});


$ItemTypeCopyWith<$Res> get itemType;

}
/// @nodoc
class _$ItemTypeUpdatedCopyWithImpl<$Res>
    implements $ItemTypeUpdatedCopyWith<$Res> {
  _$ItemTypeUpdatedCopyWithImpl(this._self, this._then);

  final ItemTypeUpdated _self;
  final $Res Function(ItemTypeUpdated) _then;

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itemType = null,}) {
  return _then(ItemTypeUpdated(
itemType: null == itemType ? _self.itemType : itemType // ignore: cast_nullable_to_non_nullable
as ItemType,
  ));
}

/// Create a copy of ItemTypesEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ItemTypeCopyWith<$Res> get itemType {
  
  return $ItemTypeCopyWith<$Res>(_self.itemType, (value) {
    return _then(_self.copyWith(itemType: value));
  });
}
}

// dart format on
