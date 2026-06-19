import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_event.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_state.dart';
import 'package:bloc/bloc.dart';

class DeliveryDescriptionBloc
    extends Bloc<DeliveryDescriptionEvent, DeliveryDescriptionState> {
  DeliveryDescriptionBloc({
    required OrganizationRepository organizationRepository,
    required ProductTypeRepository productTypeRepository,
  }) : _orgRepository = organizationRepository,
       _productTypeRepository = productTypeRepository,
       super(const DeliveryDescriptionState.initial()) {
    on<DeliveryDescriptionRequested>(_onRequested);
    on<ItemToggled>(_onItemToggled);
    on<WeightChanged>(_onWeightChanged);
    on<DeliveryDescriptionSaveRequested>(_onSaveRequested);
  }

  final OrganizationRepository _orgRepository;
  final ProductTypeRepository _productTypeRepository;

  Future<void> _onRequested(
    DeliveryDescriptionRequested event,
    Emitter<DeliveryDescriptionState> emit,
  ) async {
    try {
      final delivery = event.org.deliveries.firstWhere(
        (d) => d.deliveryId == event.deliveryId,
      );

      // Derive tenant id from the organization's products (first available
      // producerAccountId), falling back to empty string when no products exist.
      final tenantId = event.org.products.isNotEmpty
          ? event.org.products.first.producerAccountId
          : '';

      final productTypes = await _productTypeRepository.watch(tenantId).first;

      emit(
        DeliveryDescriptionState.loaded(
          org: event.org,
          delivery: delivery,
          productTypes: productTypes,
          localDescriptions: delivery.basketDescriptions,
        ),
      );
    } catch (e) {
      emit(DeliveryDescriptionState.error(message: e.toString()));
    }
  }

  void _onItemToggled(
    ItemToggled event,
    Emitter<DeliveryDescriptionState> emit,
  ) {
    final current = state;
    if (current is! DeliveryDescriptionLoaded) return;

    final descriptions = List<BasketDeliveryDescription>.from(
      current.localDescriptions,
    );

    final descIndex = descriptions.indexWhere(
      (d) =>
          d.productTypeId == event.productTypeId &&
          d.basketSizeName == event.basketSizeName,
    );

    if (descIndex == -1) {
      // No entry yet for this product+basket — create one with this item.
      descriptions.add(
        BasketDeliveryDescription(
          productTypeId: event.productTypeId,
          basketSizeName: event.basketSizeName,
          items: [
            _buildDeliveryItem(current, event.productTypeId, event.itemTypeId),
          ],
        ),
      );
    } else {
      final desc = descriptions[descIndex];
      final itemExists = desc.items.any(
        (i) => i.itemTypeId == event.itemTypeId,
      );
      if (itemExists) {
        // Toggle off — remove the item.
        final newItems = desc.items
            .where((i) => i.itemTypeId != event.itemTypeId)
            .toList();
        if (newItems.isEmpty) {
          descriptions.removeAt(descIndex);
        } else {
          descriptions[descIndex] = desc.copyWith(items: newItems);
        }
      } else {
        // Toggle on — add the item.
        descriptions[descIndex] = desc.copyWith(
          items: [
            ...desc.items,
            _buildDeliveryItem(current, event.productTypeId, event.itemTypeId),
          ],
        );
      }
    }

    emit(current.copyWith(localDescriptions: descriptions));
  }

  /// Builds a [DeliveryItem] referencing the chosen component, with a tiny
  /// label snapshot from the producer's [ItemType] catalog. The heavy SVG is
  /// not stored here — it lives once in [Organization.itemTypes] (see
  /// [_mergedCatalog]).
  DeliveryItem _buildDeliveryItem(
    DeliveryDescriptionLoaded current,
    String productTypeId,
    String itemTypeId,
  ) {
    for (final pt in current.productTypes) {
      if (pt.productTypeId != productTypeId) continue;
      for (final it in pt.itemTypes) {
        if (it.id == itemTypeId) {
          return DeliveryItem(itemTypeId: itemTypeId, name: it.name);
        }
      }
    }
    return DeliveryItem(itemTypeId: itemTypeId);
  }

  /// Merges the org's existing component catalog with the (latest) producer
  /// [ItemType] definitions of every component referenced by the current
  /// composition — keyed by id so each SVG is stored exactly once and existing
  /// entries (referenced by other deliveries) are preserved. Members resolve a
  /// [DeliveryItem]'s icon from this list by `item_type_id`.
  List<ItemType> _mergedCatalog(DeliveryDescriptionLoaded current) {
    final usedIds = <String>{
      for (final desc in current.localDescriptions)
        for (final item in desc.items) item.itemTypeId,
    };
    final byId = <String, ItemType>{
      for (final it in current.org.itemTypes) it.id: it,
    };
    for (final pt in current.productTypes) {
      for (final it in pt.itemTypes) {
        if (usedIds.contains(it.id)) byId[it.id] = it;
      }
    }
    return byId.values.toList();
  }

  void _onWeightChanged(
    WeightChanged event,
    Emitter<DeliveryDescriptionState> emit,
  ) {
    final current = state;
    if (current is! DeliveryDescriptionLoaded) return;

    final descriptions = current.localDescriptions.map((desc) {
      if (desc.productTypeId != event.productTypeId ||
          desc.basketSizeName != event.basketSizeName) {
        return desc;
      }
      final newItems = desc.items.map((item) {
        if (item.itemTypeId != event.itemTypeId) return item;
        return item.copyWith(weight: event.weight);
      }).toList();
      return desc.copyWith(items: newItems);
    }).toList();

    emit(current.copyWith(localDescriptions: descriptions));
  }

  Future<void> _onSaveRequested(
    DeliveryDescriptionSaveRequested event,
    Emitter<DeliveryDescriptionState> emit,
  ) async {
    final current = state;
    if (current is! DeliveryDescriptionLoaded) return;
    emit(const DeliveryDescriptionState.saving());
    try {
      await _orgRepository.updateDeliveryDescription(
        currentOrg: current.org,
        deliveryId: current.delivery.deliveryId,
        basketDescriptions: current.localDescriptions,
        itemTypes: _mergedCatalog(current),
      );
      emit(const DeliveryDescriptionState.saved());
    } catch (e) {
      emit(DeliveryDescriptionState.error(message: e.toString()));
    }
  }
}
