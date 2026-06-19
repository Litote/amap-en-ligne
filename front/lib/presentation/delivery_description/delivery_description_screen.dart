import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_bloc.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_event.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_state.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen to edit the [BasketDeliveryDescription] list for a given delivery.
///
/// Requires [OrganizationRepository] and [ProductTypeRepository] provided
/// above in the widget tree.
class DeliveryDescriptionScreen extends StatelessWidget {
  const DeliveryDescriptionScreen({
    super.key,
    required this.org,
    required this.deliveryId,
  });

  final Organization org;
  final String deliveryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeliveryDescriptionBloc>(
      create: (context) =>
          DeliveryDescriptionBloc(
            organizationRepository: context.read<OrganizationRepository>(),
            productTypeRepository: context.read<ProductTypeRepository>(),
          )..add(
            DeliveryDescriptionEvent.requested(
              org: org,
              deliveryId: deliveryId,
            ),
          ),
      child: const _DeliveryDescriptionView(),
    );
  }
}

class _DeliveryDescriptionView extends StatelessWidget {
  const _DeliveryDescriptionView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryDescriptionBloc, DeliveryDescriptionState>(
      listener: (context, state) {
        if (state is DeliveryDescriptionSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Description enregistrée')),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_appBarTitle(state)),
            actions: [
              if (state is DeliveryDescriptionLoaded)
                TextButton(
                  onPressed: () => context.read<DeliveryDescriptionBloc>().add(
                    const DeliveryDescriptionEvent.saveRequested(),
                  ),
                  child: const Text('Enregistrer'),
                ),
            ],
          ),
          body: switch (state) {
            DeliveryDescriptionInitial() ||
            DeliveryDescriptionSaving() ||
            DeliveryDescriptionSaved() => const Center(
              child: CircularProgressIndicator(),
            ),
            DeliveryDescriptionError(:final message) => Center(
              child: Text(message),
            ),
            DeliveryDescriptionLoaded(
              :final org,
              :final productTypes,
              :final localDescriptions,
            ) =>
              _DeliveryDescriptionBody(
                org: org,
                productTypes: productTypes,
                localDescriptions: localDescriptions,
              ),
          },
        );
      },
    );
  }

  String _appBarTitle(DeliveryDescriptionState state) {
    if (state is DeliveryDescriptionLoaded) {
      return 'Description du ${state.delivery.scheduledDate}';
    }
    return 'Description de livraison';
  }
}

class _DeliveryDescriptionBody extends StatelessWidget {
  const _DeliveryDescriptionBody({
    required this.org,
    required this.productTypes,
    required this.localDescriptions,
  });

  final Organization org;
  final List<ProductType> productTypes;
  final List<BasketDeliveryDescription> localDescriptions;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: org.products.length,
      itemBuilder: (context, i) {
        final product = org.products[i];
        final productType = productTypes
            .where((pt) => pt.productTypeId == product.productTypeId)
            .firstOrNull;
        return ExpansionTile(
          title: Text(product.name),
          children: product.supportedBasketSizes.map((basketSize) {
            return _BasketSizeSection(
              productTypeId: product.productTypeId,
              basketSizeName: basketSize.name,
              productType: productType,
              localDescriptions: localDescriptions,
            );
          }).toList(),
        );
      },
    );
  }
}

class _BasketSizeSection extends StatelessWidget {
  const _BasketSizeSection({
    required this.productTypeId,
    required this.basketSizeName,
    required this.productType,
    required this.localDescriptions,
  });

  final String productTypeId;
  final String basketSizeName;
  final ProductType? productType;
  final List<BasketDeliveryDescription> localDescriptions;

  @override
  Widget build(BuildContext context) {
    final desc = localDescriptions
        .where(
          (d) =>
              d.productTypeId == productTypeId &&
              d.basketSizeName == basketSizeName,
        )
        .firstOrNull;
    final selectedItems = desc?.items ?? const [];
    final availableItemTypes = productType?.itemTypes ?? const [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(basketSizeName, style: Theme.of(context).textTheme.titleSmall),
          ...selectedItems.map(
            (deliveryItem) => _SelectedItemTile(
              deliveryItem: deliveryItem,
              availableItemTypes: availableItemTypes,
              productTypeId: productTypeId,
              basketSizeName: basketSizeName,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            onPressed: availableItemTypes.isEmpty
                ? null
                : () => _showItemPicker(
                    context,
                    selectedItems,
                    availableItemTypes,
                  ),
          ),
        ],
      ),
    );
  }

  void _showItemPicker(
    BuildContext context,
    List<DeliveryItem> selectedItems,
    List<ItemType> availableItemTypes,
  ) {
    final bloc = context.read<DeliveryDescriptionBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ListView(
        children: availableItemTypes.map((itemType) {
          final isSelected = selectedItems.any(
            (i) => i.itemTypeId == itemType.id,
          );
          return CheckboxListTile(
            title: Text(itemType.name),
            secondary: ItemTypeSvgIcon(svg: itemType.imageSvg, size: 32),
            value: isSelected,
            onChanged: (_) {
              bloc.add(
                DeliveryDescriptionEvent.itemToggled(
                  productTypeId: productTypeId,
                  basketSizeName: basketSizeName,
                  itemTypeId: itemType.id,
                ),
              );
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SelectedItemTile extends StatelessWidget {
  const _SelectedItemTile({
    required this.deliveryItem,
    required this.availableItemTypes,
    required this.productTypeId,
    required this.basketSizeName,
  });

  final DeliveryItem deliveryItem;
  final List<ItemType> availableItemTypes;
  final String productTypeId;
  final String basketSizeName;

  @override
  Widget build(BuildContext context) {
    final itemType = availableItemTypes
        .where((it) => it.id == deliveryItem.itemTypeId)
        .firstOrNull;
    return Row(
      children: [
        ItemTypeSvgIcon(svg: itemType?.imageSvg, size: 24),
        const SizedBox(width: 8),
        Expanded(child: Text(itemType?.name ?? deliveryItem.itemTypeId)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: deliveryItem.weight,
            decoration: const InputDecoration(
              labelText: 'Poids',
              isDense: true,
            ),
            onChanged: (value) => context.read<DeliveryDescriptionBloc>().add(
              DeliveryDescriptionEvent.weightChanged(
                productTypeId: productTypeId,
                basketSizeName: basketSizeName,
                itemTypeId: deliveryItem.itemTypeId,
                weight: value.isEmpty ? null : value,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => context.read<DeliveryDescriptionBloc>().add(
            DeliveryDescriptionEvent.itemToggled(
              productTypeId: productTypeId,
              basketSizeName: basketSizeName,
              itemTypeId: deliveryItem.itemTypeId,
            ),
          ),
        ),
      ],
    );
  }
}
