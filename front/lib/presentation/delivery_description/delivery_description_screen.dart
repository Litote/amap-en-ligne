import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/validation/input_rules.dart';
import 'package:amap_en_ligne/presentation/common/french_date_formatting.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_bloc.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_event.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_state.dart';
import 'package:amap_en_ligne/presentation/nav/back_navigation.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen to edit the [BasketDeliveryDescription] list for a given delivery.
///
/// Requires [OrganizationRepository] and [ProductTypeRepository] provided
/// above in the widget tree.
/// Below this window width the AppBar title wraps on two lines.
const double _kNarrowWidth = 600;

/// Route entry of `/coordinator/deliveries/:deliveryId/description`: uses the
/// organization handed over by the delivery form ([org]) or, when opened by
/// its URL (page reload, shared link), reads it back from the local cache.
/// Back leads to the delivery form when there is no page to pop.
class DeliveryDescriptionRouteScreen extends StatelessWidget {
  const DeliveryDescriptionRouteScreen({
    super.key,
    required this.tenantId,
    required this.deliveryId,
    this.org,
  });

  final String tenantId;
  final String deliveryId;
  final Organization? org;

  @override
  Widget build(BuildContext context) {
    final backRoute = '/coordinator/time-slots/$deliveryId';
    final handedOver = org;
    if (handedOver != null) {
      return DeliveryDescriptionScreen(
        org: handedOver,
        deliveryId: deliveryId,
        backRoute: backRoute,
      );
    }
    return StreamBuilder<Organization?>(
      stream: context.read<OrganizationRepository>().watch(tenantId),
      builder: (context, snapshot) {
        final cached = snapshot.data;
        if (cached == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return DeliveryDescriptionScreen(
          org: cached,
          deliveryId: deliveryId,
          backRoute: backRoute,
        );
      },
    );
  }
}

class DeliveryDescriptionScreen extends StatelessWidget {
  const DeliveryDescriptionScreen({
    super.key,
    required this.org,
    required this.deliveryId,
    this.save,
    this.backRoute,
  });

  final Organization org;
  final String deliveryId;

  /// Screen to return to when this one was opened by its URL (nothing to
  /// pop); null ⇒ always pops (the coordinator opens it on top of the
  /// delivery form).
  final String? backRoute;

  /// How the composition is saved; null ⇒ the coordinator path (the
  /// organization). The producer passes its own (see
  /// `ProducerDeliveryCompositionScreen`).
  final DeliveryCompositionSave? save;

  @override
  Widget build(BuildContext context) => BlocProvider<DeliveryDescriptionBloc>(
    create: (context) =>
        DeliveryDescriptionBloc(
          organizationRepository: context.read<OrganizationRepository>(),
          productTypeRepository: context.read<ProductTypeRepository>(),
          save: save,
        )..add(
          DeliveryDescriptionEvent.requested(org: org, deliveryId: deliveryId),
        ),
    child: _DeliveryDescriptionView(backRoute: backRoute),
  );
}

class _DeliveryDescriptionView extends StatelessWidget {
  const _DeliveryDescriptionView({required this.backRoute});

  final String? backRoute;

  void _close(BuildContext context) {
    final route = backRoute;
    if (route == null) {
      Navigator.of(context).pop();
    } else {
      popOrGo(context, route);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DeliveryDescriptionBloc, DeliveryDescriptionState>(
        listener: (context, state) {
          if (state is DeliveryDescriptionSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Description enregistrée')),
            );
            _close(context);
          }
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            leading: backRoute == null
                ? null
                : BackButton(onPressed: () => _close(context)),
            // On a phone the full date does not fit on one line: wrap it on
            // two smaller lines rather than truncating the date away.
            title: MediaQuery.sizeOf(context).width < _kNarrowWidth
                ? Text(
                    _appBarTitle(state),
                    maxLines: 2,
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                : Text(_appBarTitle(state)),
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
              :final delivery,
              :final productTypes,
              :final localDescriptions,
            ) =>
              _DeliveryDescriptionBody(
                products: _deliveryProducts(org, delivery),
                productTypes: productTypes,
                localDescriptions: localDescriptions,
              ),
          },
        ),
      );

  String _appBarTitle(DeliveryDescriptionState state) {
    if (state is DeliveryDescriptionLoaded) {
      final date = DateTime.tryParse(state.delivery.scheduledDate);
      if (date != null) {
        return "Composition du ${frenchDateFormat('EEEE d MMMM').format(date)}";
      }
    }
    return 'Description de livraison';
  }
}

/// Products the delivery carries: the delivery form writes one description per
/// product present ("Produits présents"), so only those are composed — a
/// component of another product would be dropped at the next delivery save
/// (and is rejected by the back). Legacy deliveries without any description
/// fall back to every product of the organization.
List<OrgProduct> _deliveryProducts(Organization org, Delivery delivery) {
  final present = {
    for (final description in delivery.basketDescriptions)
      description.productTypeId,
  };
  if (present.isEmpty) return org.products;
  return org.products
      .where((product) => present.contains(product.productTypeId))
      .toList();
}

class _DeliveryDescriptionBody extends StatelessWidget {
  const _DeliveryDescriptionBody({
    required this.products,
    required this.productTypes,
    required this.localDescriptions,
  });

  final List<OrgProduct> products;
  final List<ProductType> productTypes;
  final List<BasketDeliveryDescription> localDescriptions;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: products.length,
    itemBuilder: (context, i) {
      final product = products[i];
      final productType = productTypes
          .where((pt) => pt.productTypeId == product.productTypeId)
          .firstOrNull;
      return ExpansionTile(
        title: Text(product.name),
        // Left-align every basket size section, empty or not.
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: product.supportedBasketSizes
            .map(
              (basketSize) => _BasketSizeSection(
                productTypeId: product.productTypeId,
                basketSizeName: basketSize.name,
                productType: productType,
                localDescriptions: localDescriptions,
              ),
            )
            .toList(),
      );
    },
  );
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

  String _sizeLabel() {
    final productName = productType?.name;
    return productName == null
        ? basketSizeName
        : '$productName — $basketSizeName';
  }

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
          // Every size has its own "Ajouter": the tooltip (also read by
          // screen readers) says which one.
          Tooltip(
            message: 'Ajouter un composant (${_sizeLabel()})',
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              // Producer catalog when there is one, otherwise free entry (e.g. a
              // producer without an account has no component catalog).
              onPressed: availableItemTypes.isEmpty
                  ? () => _showFreeItemForm(context)
                  : () => _showItemPicker(
                      context,
                      selectedItems,
                      availableItemTypes,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFreeItemForm(BuildContext context) async {
    final bloc = context.read<DeliveryDescriptionBloc>();
    final entry = await showDialog<({String name, String weight})>(
      context: context,
      builder: (_) => const _FreeItemDialog(),
    );
    if (entry == null) return;
    bloc.add(
      DeliveryDescriptionEvent.freeItemAdded(
        productTypeId: productTypeId,
        basketSizeName: basketSizeName,
        name: entry.name,
        weight: entry.weight,
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

  /// Catalog name, else the item's own name snapshot (free component), else
  /// its id as a last resort for legacy data.
  String _itemLabel(ItemType? itemType) {
    if (itemType != null) return itemType.name;
    if (deliveryItem.name.isNotEmpty) return deliveryItem.name;
    return deliveryItem.itemTypeId;
  }

  @override
  Widget build(BuildContext context) {
    final itemType = availableItemTypes
        .where((it) => it.id == deliveryItem.itemTypeId)
        .firstOrNull;
    return Row(
      children: [
        ItemTypeSvgIcon(svg: itemType?.imageSvg, size: 24),
        const SizedBox(width: 8),
        Expanded(child: Text(_itemLabel(itemType))),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: deliveryItem.weight,
            maxLength: kMaxNameLength,
            decoration: const InputDecoration(
              labelText: 'Poids',
              isDense: true,
              counterText: '',
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
          tooltip: 'Retirer ${_itemLabel(itemType)}',
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

/// Free entry of a basket component (name + optional weight), for products
/// whose producer has no component catalog. Rules mirror the back
/// (`OrganizationValidation.basketItemsError`).
class _FreeItemDialog extends StatefulWidget {
  const _FreeItemDialog();

  @override
  State<_FreeItemDialog> createState() => _FreeItemDialogState();
}

class _FreeItemDialogState extends State<_FreeItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop((name: _nameController.text.trim(), weight: _weightController.text));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ajouter un composant'),
    semanticLabel: 'Ajouter un composant',
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            autofocus: true,
            maxLength: kMaxNameLength,
            decoration: const InputDecoration(
              labelText: 'Composant *',
              hintText: 'Ex. : Courge butternut',
            ),
            validator: requiredName,
          ),
          TextFormField(
            controller: _weightController,
            maxLength: kMaxNameLength,
            decoration: const InputDecoration(
              labelText: 'Poids (facultatif)',
              hintText: 'Ex. : 500 g, 1 pièce',
            ),
            onFieldSubmitted: (_) => _submit(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('ANNULER'),
      ),
      FilledButton(onPressed: _submit, child: const Text('AJOUTER')),
    ],
  );
}
