import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_types_event.freezed.dart';

@freezed
sealed class ItemTypesEvent with _$ItemTypesEvent {
  const factory ItemTypesEvent.requested({required ProductType productType}) =
      ItemTypesRequested;

  const factory ItemTypesEvent.added({required String name, String? imageSvg}) =
      ItemTypeAdded;

  const factory ItemTypesEvent.removed({required String itemTypeId}) =
      ItemTypeRemoved;

  const factory ItemTypesEvent.updated({required ItemType itemType}) =
      ItemTypeUpdated;
}
