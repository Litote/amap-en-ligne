import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_event.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_state.dart';
import 'package:bloc/bloc.dart';

class ItemTypesBloc extends Bloc<ItemTypesEvent, ItemTypesState> {
  ItemTypesBloc({
    required ProductTypeRepository productTypeRepository,
    required IdGenerator idGenerator,
  }) : _productTypeRepository = productTypeRepository,
       _idGen = idGenerator,
       super(const ItemTypesState.initial()) {
    on<ItemTypesRequested>(_onRequested);
    on<ItemTypeAdded>(_onAdded);
    on<ItemTypeRemoved>(_onRemoved);
    on<ItemTypeUpdated>(_onUpdated);
  }

  final ProductTypeRepository _productTypeRepository;
  final IdGenerator _idGen;

  void _onRequested(ItemTypesRequested event, Emitter<ItemTypesState> emit) {
    emit(ItemTypesState.loaded(productType: event.productType));
  }

  Future<void> _onAdded(
    ItemTypeAdded event,
    Emitter<ItemTypesState> emit,
  ) async {
    final current = state;
    if (current is! ItemTypesLoaded && current is! ItemTypesSaved) return;
    final pt = current is ItemTypesLoaded
        ? current.productType
        : (current as ItemTypesSaved).productType;
    emit(ItemTypesState.saving(productType: pt));
    try {
      final newItem = ItemType(
        id: _idGen.next(),
        name: event.name,
        imageSvg: event.imageSvg,
      );
      final newList = [...pt.itemTypes, newItem];
      await _productTypeRepository.updateItemTypes(pt, newList);
      final updated = pt.copyWith(itemTypes: newList);
      emit(ItemTypesState.saved(productType: updated));
    } catch (e) {
      emit(ItemTypesState.error(message: e.toString()));
    }
  }

  Future<void> _onRemoved(
    ItemTypeRemoved event,
    Emitter<ItemTypesState> emit,
  ) async {
    final current = state;
    if (current is! ItemTypesLoaded && current is! ItemTypesSaved) return;
    final pt = current is ItemTypesLoaded
        ? current.productType
        : (current as ItemTypesSaved).productType;
    emit(ItemTypesState.saving(productType: pt));
    try {
      final newList = pt.itemTypes
          .where((it) => it.id != event.itemTypeId)
          .toList();
      await _productTypeRepository.updateItemTypes(pt, newList);
      final updated = pt.copyWith(itemTypes: newList);
      emit(ItemTypesState.saved(productType: updated));
    } catch (e) {
      emit(ItemTypesState.error(message: e.toString()));
    }
  }

  Future<void> _onUpdated(
    ItemTypeUpdated event,
    Emitter<ItemTypesState> emit,
  ) async {
    final current = state;
    if (current is! ItemTypesLoaded && current is! ItemTypesSaved) return;
    final pt = current is ItemTypesLoaded
        ? current.productType
        : (current as ItemTypesSaved).productType;
    emit(ItemTypesState.saving(productType: pt));
    try {
      final newList = pt.itemTypes
          .map((it) => it.id == event.itemType.id ? event.itemType : it)
          .toList();
      await _productTypeRepository.updateItemTypes(pt, newList);
      final updated = pt.copyWith(itemTypes: newList);
      emit(ItemTypesState.saved(productType: updated));
    } catch (e) {
      emit(ItemTypesState.error(message: e.toString()));
    }
  }
}
