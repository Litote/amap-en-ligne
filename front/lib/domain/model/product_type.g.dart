// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductType _$ProductTypeFromJson(Map<String, dynamic> json) => _ProductType(
  productTypeId: json['product_type_id'] as String,
  producerAccountId: json['producer_account_id'] as String,
  supportedBasketSizes:
      (json['supported_basket_sizes'] as List<dynamic>?)
          ?.map((e) => BasketSize.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BasketSize>[],
  name: json['name'] as String,
  description: json['description'] as String?,
  itemTypes:
      (json['item_types'] as List<dynamic>?)
          ?.map((e) => ItemType.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ItemType>[],
);

Map<String, dynamic> _$ProductTypeToJson(_ProductType instance) =>
    <String, dynamic>{
      'product_type_id': instance.productTypeId,
      'producer_account_id': instance.producerAccountId,
      'supported_basket_sizes': instance.supportedBasketSizes,
      'name': instance.name,
      'description': ?instance.description,
      'item_types': instance.itemTypes,
    };

_ItemType _$ItemTypeFromJson(Map<String, dynamic> json) => _ItemType(
  id: json['id'] as String,
  name: json['name'] as String,
  imageSvg: json['image_svg'] as String?,
);

Map<String, dynamic> _$ItemTypeToJson(_ItemType instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'image_svg': ?instance.imageSvg,
};

_BasketSize _$BasketSizeFromJson(Map<String, dynamic> json) =>
    _BasketSize(name: json['name'] as String);

Map<String, dynamic> _$BasketSizeToJson(_BasketSize instance) =>
    <String, dynamic>{'name': instance.name};
