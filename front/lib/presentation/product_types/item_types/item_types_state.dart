import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_types_state.freezed.dart';

@freezed
sealed class ItemTypesState with _$ItemTypesState {
  const factory ItemTypesState.initial() = ItemTypesInitial;

  const factory ItemTypesState.loaded({required ProductType productType}) =
      ItemTypesLoaded;

  const factory ItemTypesState.saving({required ProductType productType}) =
      ItemTypesSaving;

  const factory ItemTypesState.saved({required ProductType productType}) =
      ItemTypesSaved;

  const factory ItemTypesState.error({required String message}) =
      ItemTypesError;
}
