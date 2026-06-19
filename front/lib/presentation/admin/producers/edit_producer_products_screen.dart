import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_management_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_ui_helpers.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditProducerProductsScreen extends StatelessWidget {
  const EditProducerProductsScreen({
    required this.organization,
    required this.producerAccount,
    super.key,
  });

  final Organization organization;
  final ProducerAccount producerAccount;

  @override
  Widget build(BuildContext context) {
    return _EditProducerProductsView(
      organization: organization,
      producerAccount: producerAccount,
    );
  }
}

class _EditProducerProductsView extends StatefulWidget {
  const _EditProducerProductsView({
    required this.organization,
    required this.producerAccount,
  });

  final Organization organization;
  final ProducerAccount producerAccount;

  @override
  State<_EditProducerProductsView> createState() =>
      _EditProducerProductsViewState();
}

class _EditProducerProductsViewState extends State<_EditProducerProductsView> {
  late final Set<String> _selectedProductTypeIds;
  late final Map<String, Set<String>> _selectedBasketSizes;
  late List<ProducerProduct> _managedProducts;
  var _saveRequested = false;

  bool get _isNoAccountProducer =>
      widget.producerAccount.managementMode == ProducerManagementMode.noAccount;

  @override
  void initState() {
    super.initState();
    final existingProducts = widget.organization.products
        .where(
          (product) =>
              product.producerAccountId ==
              widget.producerAccount.producerAccountId,
        )
        .toList();
    _selectedProductTypeIds = existingProducts
        .map((product) => product.productTypeId)
        .toSet();
    _selectedBasketSizes = {
      for (final product in existingProducts)
        product.productTypeId: product.supportedBasketSizes
            .map((basketSize) => basketSize.name)
            .toSet(),
    };
    // ProducerAccount.products is the single source of truth for both
    // NO_ACCOUNT and ACCOUNT_BACKED producers.
    _managedProducts = widget.producerAccount.products.toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProducerManagementBloc, ProducerManagementState>(
      listenWhen: (_, current) =>
          current is ProducerManagementDetailLoaded ||
          current is ProducerManagementListLoaded,
      listener: (context, state) {
        if (!_saveRequested) return;
        final actionInProgress = switch (state) {
          ProducerManagementDetailLoaded(:final actionInProgress) =>
            actionInProgress,
          ProducerManagementListLoaded(:final actionInProgress) =>
            actionInProgress,
          _ => false,
        };
        final actionError = switch (state) {
          ProducerManagementDetailLoaded(:final actionError) => actionError,
          ProducerManagementListLoaded(:final actionError) => actionError,
          _ => null,
        };
        if (actionInProgress) return;
        if (actionError != null) {
          _saveRequested = false;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(actionError)));
          return;
        }
        if (!context.mounted) return;
        _saveRequested = false;
        Navigator.of(context).pop();
      },
      builder: (context, state) {
        final actionInProgress = switch (state) {
          ProducerManagementDetailLoaded(:final actionInProgress) =>
            actionInProgress,
          ProducerManagementListLoaded(:final actionInProgress) =>
            actionInProgress,
          _ => false,
        };
        return ConnectedScaffold(
          title: 'Modifier les produits',
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.producerAccount.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (widget.producerAccount.contactEmail != null)
                      Text(widget.producerAccount.contactEmail!),
                    const SizedBox(height: 8),
                    Text(
                      _isNoAccountProducer
                          ? 'Gérez les produits de ce producteur :'
                          : 'Sélectionnez les produits à associer à cet AMAP :',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isNoAccountProducer
                    ? _ManagedProductsBody(
                        products: _managedProducts,
                        onEdit: (i) => _editManagedProductAt(context, i),
                        onDelete: _removeManagedProductAt,
                        onAdd: () => _addManagedProduct(context),
                      )
                    : _CatalogProductsBody(
                        producerProducts: widget.producerAccount.products,
                        selectedProductTypeIds: _selectedProductTypeIds,
                        selectedBasketSizes: _selectedBasketSizes,
                        onSelectionChanged: _toggleCatalogProduct,
                        onBasketSizeChanged: _toggleBasketSize,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: actionInProgress
                    ? const CircularProgressIndicator()
                    : Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              key: const Key('save_producer_products_button'),
                              onPressed: _canSave ? () => _save(context) : null,
                              child: const Text('Enregistrer'),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _canSave => _isNoAccountProducer
      ? _managedProducts.isNotEmpty
      : _selectedProductTypeIds.isNotEmpty;

  void _toggleCatalogProduct(ProducerProduct product, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedProductTypeIds.add(product.productTypeId);
      } else {
        _selectedProductTypeIds.remove(product.productTypeId);
        _selectedBasketSizes.remove(product.productTypeId);
      }
    });
  }

  void _toggleBasketSize(
    ProducerProduct product,
    BasketSize basketSize,
    bool selected,
  ) {
    setState(() {
      final sizes = _selectedBasketSizes.putIfAbsent(
        product.productTypeId,
        () => <String>{},
      );
      if (selected) {
        sizes.add(basketSize.name);
      } else {
        sizes.remove(basketSize.name);
      }
    });
  }

  Future<void> _addManagedProduct(BuildContext context) async {
    final product = await showManagedProducerProductDialog(context);
    if (product == null) return;
    setState(() => _managedProducts.add(product));
  }

  Future<void> _editManagedProductAt(BuildContext context, int index) async {
    final updated = await showManagedProducerProductDialog(
      context,
      initialProduct: _managedProducts[index],
    );
    if (updated == null) return;
    setState(() => _managedProducts[index] = updated);
  }

  void _removeManagedProductAt(int index) {
    setState(() => _managedProducts.removeAt(index));
  }

  void _save(BuildContext context) {
    _saveRequested = true;
    if (_isNoAccountProducer) {
      context.read<ProducerManagementBloc>().add(
        ProducerManagementEvent.updateNoAccountProductsRequested(
          producerAccount: widget.producerAccount,
          products: _managedProducts,
        ),
      );
      return;
    }
    context.read<ProducerManagementBloc>().add(
      ProducerManagementEvent.updateProductsRequested(
        producerAccount: widget.producerAccount,
        products: _selectedProductTypeIds
            .map((productTypeId) {
              final product = widget.producerAccount.products
                  .where(
                    (candidate) => candidate.productTypeId == productTypeId,
                  )
                  .firstOrNull;
              if (product == null) return null;
              final selectedSizes = _selectedBasketSizes[productTypeId];
              final basketSizes = selectedSizes != null
                  ? product.supportedBasketSizes
                        .where(
                          (basketSize) =>
                              selectedSizes.contains(basketSize.name),
                        )
                        .toList()
                  : product.supportedBasketSizes;
              return OrgProduct(
                name: product.name,
                productTypeId: product.productTypeId,
                producerAccountId: widget.producerAccount.producerAccountId,
                supportedBasketSizes: basketSizes,
                description: product.description,
              );
            })
            .whereType<OrgProduct>()
            .toList(),
      ),
    );
  }
}

class _CatalogProductsBody extends StatelessWidget {
  const _CatalogProductsBody({
    required this.producerProducts,
    required this.selectedProductTypeIds,
    required this.selectedBasketSizes,
    required this.onSelectionChanged,
    required this.onBasketSizeChanged,
  });

  final List<ProducerProduct> producerProducts;
  final Set<String> selectedProductTypeIds;
  final Map<String, Set<String>> selectedBasketSizes;
  final void Function(ProducerProduct product, bool? checked)
  onSelectionChanged;
  final void Function(
    ProducerProduct product,
    BasketSize basketSize,
    bool selected,
  )
  onBasketSizeChanged;

  @override
  Widget build(BuildContext context) {
    if (producerProducts.isEmpty) {
      return const Center(child: Text('Ce producteur n\'a aucun produit.'));
    }
    return ListView.builder(
      itemCount: producerProducts.length,
      itemBuilder: (context, index) {
        final product = producerProducts[index];
        final isSelected = selectedProductTypeIds.contains(
          product.productTypeId,
        );
        return Column(
          children: [
            CheckboxListTile(
              value: isSelected,
              title: Text(product.name),
              subtitle: product.description != null
                  ? Text(product.description!)
                  : null,
              onChanged: (checked) => onSelectionChanged(product, checked),
            ),
            if (isSelected && product.supportedBasketSizes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
                child: Wrap(
                  spacing: 8,
                  children: product.supportedBasketSizes
                      .map(
                        (basketSize) => FilterChip(
                          label: Text(basketSize.name),
                          selected:
                              selectedBasketSizes[product.productTypeId]
                                  ?.contains(basketSize.name) ??
                              false,
                          onSelected: (selected) => onBasketSizeChanged(
                            product,
                            basketSize,
                            selected,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ManagedProductsBody extends StatelessWidget {
  const _ManagedProductsBody({
    required this.products,
    this.onEdit,
    this.onDelete,
    this.onAdd,
  });

  final List<ProducerProduct> products;
  final void Function(int index)? onEdit;
  final void Function(int index)? onDelete;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && onAdd == null) {
      return const Center(
        child: Text('Aucun produit assigné à ce producteur.'),
      );
    }
    return ListView.builder(
      itemCount: products.length + (onAdd != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (onAdd != null && index == products.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              key: const Key('add_managed_product_button'),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un produit'),
            ),
          );
        }
        final product = products[index];
        final basketSizes = product.supportedBasketSizes
            .map((basketSize) => basketSize.name)
            .join(', ');
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.description != null) Text(product.description!),
                if (basketSizes.isNotEmpty) Text(basketSizes),
              ],
            ),
            trailing: (onEdit != null || onDelete != null)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit!(index),
                          tooltip: 'Modifier',
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onDelete!(index),
                          tooltip: 'Supprimer',
                        ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
}
