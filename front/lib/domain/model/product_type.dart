import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_type.freezed.dart';
part 'product_type.g.dart';

@freezed
abstract class ProductType with _$ProductType {
  const factory ProductType({
    @JsonKey(name: 'product_type_id') required String productTypeId,
    @JsonKey(name: 'producer_account_id') required String producerAccountId,
    @JsonKey(name: 'supported_basket_sizes')
    @Default(<BasketSize>[])
    List<BasketSize> supportedBasketSizes,
    required String name,
    String? description,
    @JsonKey(name: 'item_types')
    @Default(<ItemType>[])
    List<ItemType> itemTypes,
  }) = _ProductType;

  factory ProductType.fromJson(Map<String, Object?> json) =>
      _$ProductTypeFromJson(json);
}

@freezed
abstract class ItemType with _$ItemType {
  const factory ItemType({
    required String id,
    required String name,
    // Inline SVG markup of the component icon (SVG only); null when unset.
    @JsonKey(name: 'image_svg') String? imageSvg,
  }) = _ItemType;

  factory ItemType.fromJson(Map<String, Object?> json) =>
      _$ItemTypeFromJson(json);
}

@freezed
abstract class BasketSize with _$BasketSize {
  const factory BasketSize({required String name}) = _BasketSize;

  factory BasketSize.fromJson(Map<String, Object?> json) =>
      _$BasketSizeFromJson(json);
}
