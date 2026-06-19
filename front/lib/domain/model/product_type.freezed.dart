// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductType {

@JsonKey(name: 'product_type_id') String get productTypeId;@JsonKey(name: 'producer_account_id') String get producerAccountId;@JsonKey(name: 'supported_basket_sizes') List<BasketSize> get supportedBasketSizes; String get name; String? get description;@JsonKey(name: 'item_types') List<ItemType> get itemTypes;
/// Create a copy of ProductType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductTypeCopyWith<ProductType> get copyWith => _$ProductTypeCopyWithImpl<ProductType>(this as ProductType, _$identity);

  /// Serializes this ProductType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductType&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&const DeepCollectionEquality().equals(other.supportedBasketSizes, supportedBasketSizes)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.itemTypes, itemTypes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productTypeId,producerAccountId,const DeepCollectionEquality().hash(supportedBasketSizes),name,description,const DeepCollectionEquality().hash(itemTypes));

@override
String toString() {
  return 'ProductType(productTypeId: $productTypeId, producerAccountId: $producerAccountId, supportedBasketSizes: $supportedBasketSizes, name: $name, description: $description, itemTypes: $itemTypes)';
}


}

/// @nodoc
abstract mixin class $ProductTypeCopyWith<$Res>  {
  factory $ProductTypeCopyWith(ProductType value, $Res Function(ProductType) _then) = _$ProductTypeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'supported_basket_sizes') List<BasketSize> supportedBasketSizes, String name, String? description,@JsonKey(name: 'item_types') List<ItemType> itemTypes
});




}
/// @nodoc
class _$ProductTypeCopyWithImpl<$Res>
    implements $ProductTypeCopyWith<$Res> {
  _$ProductTypeCopyWithImpl(this._self, this._then);

  final ProductType _self;
  final $Res Function(ProductType) _then;

/// Create a copy of ProductType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productTypeId = null,Object? producerAccountId = null,Object? supportedBasketSizes = null,Object? name = null,Object? description = freezed,Object? itemTypes = null,}) {
  return _then(_self.copyWith(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,supportedBasketSizes: null == supportedBasketSizes ? _self.supportedBasketSizes : supportedBasketSizes // ignore: cast_nullable_to_non_nullable
as List<BasketSize>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,itemTypes: null == itemTypes ? _self.itemTypes : itemTypes // ignore: cast_nullable_to_non_nullable
as List<ItemType>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductType].
extension ProductTypePatterns on ProductType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductType value)  $default,){
final _that = this;
switch (_that) {
case _ProductType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductType value)?  $default,){
final _that = this;
switch (_that) {
case _ProductType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String name,  String? description, @JsonKey(name: 'item_types')  List<ItemType> itemTypes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductType() when $default != null:
return $default(_that.productTypeId,_that.producerAccountId,_that.supportedBasketSizes,_that.name,_that.description,_that.itemTypes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String name,  String? description, @JsonKey(name: 'item_types')  List<ItemType> itemTypes)  $default,) {final _that = this;
switch (_that) {
case _ProductType():
return $default(_that.productTypeId,_that.producerAccountId,_that.supportedBasketSizes,_that.name,_that.description,_that.itemTypes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String name,  String? description, @JsonKey(name: 'item_types')  List<ItemType> itemTypes)?  $default,) {final _that = this;
switch (_that) {
case _ProductType() when $default != null:
return $default(_that.productTypeId,_that.producerAccountId,_that.supportedBasketSizes,_that.name,_that.description,_that.itemTypes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductType implements ProductType {
  const _ProductType({@JsonKey(name: 'product_type_id') required this.productTypeId, @JsonKey(name: 'producer_account_id') required this.producerAccountId, @JsonKey(name: 'supported_basket_sizes') final  List<BasketSize> supportedBasketSizes = const <BasketSize>[], required this.name, this.description, @JsonKey(name: 'item_types') final  List<ItemType> itemTypes = const <ItemType>[]}): _supportedBasketSizes = supportedBasketSizes,_itemTypes = itemTypes;
  factory _ProductType.fromJson(Map<String, dynamic> json) => _$ProductTypeFromJson(json);

@override@JsonKey(name: 'product_type_id') final  String productTypeId;
@override@JsonKey(name: 'producer_account_id') final  String producerAccountId;
 final  List<BasketSize> _supportedBasketSizes;
@override@JsonKey(name: 'supported_basket_sizes') List<BasketSize> get supportedBasketSizes {
  if (_supportedBasketSizes is EqualUnmodifiableListView) return _supportedBasketSizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedBasketSizes);
}

@override final  String name;
@override final  String? description;
 final  List<ItemType> _itemTypes;
@override@JsonKey(name: 'item_types') List<ItemType> get itemTypes {
  if (_itemTypes is EqualUnmodifiableListView) return _itemTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itemTypes);
}


/// Create a copy of ProductType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductTypeCopyWith<_ProductType> get copyWith => __$ProductTypeCopyWithImpl<_ProductType>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductTypeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductType&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&const DeepCollectionEquality().equals(other._supportedBasketSizes, _supportedBasketSizes)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._itemTypes, _itemTypes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productTypeId,producerAccountId,const DeepCollectionEquality().hash(_supportedBasketSizes),name,description,const DeepCollectionEquality().hash(_itemTypes));

@override
String toString() {
  return 'ProductType(productTypeId: $productTypeId, producerAccountId: $producerAccountId, supportedBasketSizes: $supportedBasketSizes, name: $name, description: $description, itemTypes: $itemTypes)';
}


}

/// @nodoc
abstract mixin class _$ProductTypeCopyWith<$Res> implements $ProductTypeCopyWith<$Res> {
  factory _$ProductTypeCopyWith(_ProductType value, $Res Function(_ProductType) _then) = __$ProductTypeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'supported_basket_sizes') List<BasketSize> supportedBasketSizes, String name, String? description,@JsonKey(name: 'item_types') List<ItemType> itemTypes
});




}
/// @nodoc
class __$ProductTypeCopyWithImpl<$Res>
    implements _$ProductTypeCopyWith<$Res> {
  __$ProductTypeCopyWithImpl(this._self, this._then);

  final _ProductType _self;
  final $Res Function(_ProductType) _then;

/// Create a copy of ProductType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productTypeId = null,Object? producerAccountId = null,Object? supportedBasketSizes = null,Object? name = null,Object? description = freezed,Object? itemTypes = null,}) {
  return _then(_ProductType(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,supportedBasketSizes: null == supportedBasketSizes ? _self._supportedBasketSizes : supportedBasketSizes // ignore: cast_nullable_to_non_nullable
as List<BasketSize>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,itemTypes: null == itemTypes ? _self._itemTypes : itemTypes // ignore: cast_nullable_to_non_nullable
as List<ItemType>,
  ));
}


}


/// @nodoc
mixin _$ItemType {

 String get id; String get name;// Inline SVG markup of the component icon (SVG only); null when unset.
@JsonKey(name: 'image_svg') String? get imageSvg;
/// Create a copy of ItemType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypeCopyWith<ItemType> get copyWith => _$ItemTypeCopyWithImpl<ItemType>(this as ItemType, _$identity);

  /// Serializes this ItemType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemType&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.imageSvg, imageSvg) || other.imageSvg == imageSvg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,imageSvg);

@override
String toString() {
  return 'ItemType(id: $id, name: $name, imageSvg: $imageSvg)';
}


}

/// @nodoc
abstract mixin class $ItemTypeCopyWith<$Res>  {
  factory $ItemTypeCopyWith(ItemType value, $Res Function(ItemType) _then) = _$ItemTypeCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'image_svg') String? imageSvg
});




}
/// @nodoc
class _$ItemTypeCopyWithImpl<$Res>
    implements $ItemTypeCopyWith<$Res> {
  _$ItemTypeCopyWithImpl(this._self, this._then);

  final ItemType _self;
  final $Res Function(ItemType) _then;

/// Create a copy of ItemType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? imageSvg = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,imageSvg: freezed == imageSvg ? _self.imageSvg : imageSvg // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemType].
extension ItemTypePatterns on ItemType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemType value)  $default,){
final _that = this;
switch (_that) {
case _ItemType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemType value)?  $default,){
final _that = this;
switch (_that) {
case _ItemType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'image_svg')  String? imageSvg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemType() when $default != null:
return $default(_that.id,_that.name,_that.imageSvg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'image_svg')  String? imageSvg)  $default,) {final _that = this;
switch (_that) {
case _ItemType():
return $default(_that.id,_that.name,_that.imageSvg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'image_svg')  String? imageSvg)?  $default,) {final _that = this;
switch (_that) {
case _ItemType() when $default != null:
return $default(_that.id,_that.name,_that.imageSvg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemType implements ItemType {
  const _ItemType({required this.id, required this.name, @JsonKey(name: 'image_svg') this.imageSvg});
  factory _ItemType.fromJson(Map<String, dynamic> json) => _$ItemTypeFromJson(json);

@override final  String id;
@override final  String name;
// Inline SVG markup of the component icon (SVG only); null when unset.
@override@JsonKey(name: 'image_svg') final  String? imageSvg;

/// Create a copy of ItemType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemTypeCopyWith<_ItemType> get copyWith => __$ItemTypeCopyWithImpl<_ItemType>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemTypeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemType&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.imageSvg, imageSvg) || other.imageSvg == imageSvg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,imageSvg);

@override
String toString() {
  return 'ItemType(id: $id, name: $name, imageSvg: $imageSvg)';
}


}

/// @nodoc
abstract mixin class _$ItemTypeCopyWith<$Res> implements $ItemTypeCopyWith<$Res> {
  factory _$ItemTypeCopyWith(_ItemType value, $Res Function(_ItemType) _then) = __$ItemTypeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'image_svg') String? imageSvg
});




}
/// @nodoc
class __$ItemTypeCopyWithImpl<$Res>
    implements _$ItemTypeCopyWith<$Res> {
  __$ItemTypeCopyWithImpl(this._self, this._then);

  final _ItemType _self;
  final $Res Function(_ItemType) _then;

/// Create a copy of ItemType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? imageSvg = freezed,}) {
  return _then(_ItemType(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,imageSvg: freezed == imageSvg ? _self.imageSvg : imageSvg // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BasketSize {

 String get name;
/// Create a copy of BasketSize
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketSizeCopyWith<BasketSize> get copyWith => _$BasketSizeCopyWithImpl<BasketSize>(this as BasketSize, _$identity);

  /// Serializes this BasketSize to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketSize&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'BasketSize(name: $name)';
}


}

/// @nodoc
abstract mixin class $BasketSizeCopyWith<$Res>  {
  factory $BasketSizeCopyWith(BasketSize value, $Res Function(BasketSize) _then) = _$BasketSizeCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$BasketSizeCopyWithImpl<$Res>
    implements $BasketSizeCopyWith<$Res> {
  _$BasketSizeCopyWithImpl(this._self, this._then);

  final BasketSize _self;
  final $Res Function(BasketSize) _then;

/// Create a copy of BasketSize
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BasketSize].
extension BasketSizePatterns on BasketSize {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketSize value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketSize() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketSize value)  $default,){
final _that = this;
switch (_that) {
case _BasketSize():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketSize value)?  $default,){
final _that = this;
switch (_that) {
case _BasketSize() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketSize() when $default != null:
return $default(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name)  $default,) {final _that = this;
switch (_that) {
case _BasketSize():
return $default(_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name)?  $default,) {final _that = this;
switch (_that) {
case _BasketSize() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BasketSize implements BasketSize {
  const _BasketSize({required this.name});
  factory _BasketSize.fromJson(Map<String, dynamic> json) => _$BasketSizeFromJson(json);

@override final  String name;

/// Create a copy of BasketSize
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketSizeCopyWith<_BasketSize> get copyWith => __$BasketSizeCopyWithImpl<_BasketSize>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BasketSizeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketSize&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'BasketSize(name: $name)';
}


}

/// @nodoc
abstract mixin class _$BasketSizeCopyWith<$Res> implements $BasketSizeCopyWith<$Res> {
  factory _$BasketSizeCopyWith(_BasketSize value, $Res Function(_BasketSize) _then) = __$BasketSizeCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$BasketSizeCopyWithImpl<$Res>
    implements _$BasketSizeCopyWith<$Res> {
  __$BasketSizeCopyWithImpl(this._self, this._then);

  final _BasketSize _self;
  final $Res Function(_BasketSize) _then;

/// Create a copy of BasketSize
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_BasketSize(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
