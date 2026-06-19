import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_management_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_ui_helpers.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Two-step wizard to enroll a producer into an organization.
///
/// Step 1: Search for an account-backed producer or create a no-account
/// producer managed directly by the AMAP.
/// Step 2: Either select products from the producer catalog, or define the
/// AMAP-managed products manually.
const _kEnrollProducerTitle = 'Inscrire un producteur';

class EnrollProducerScreen extends StatelessWidget {
  const EnrollProducerScreen({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProducerManagementBloc(
        organizationRepository: context.read<OrganizationRepository>(),
        adminApi: context.read<AdminApi>(),
        organizationId: organizationId,
      )..add(const ProducerManagementEvent.loadRequested()),
      child: const _EnrollView(),
    );
  }
}

class _EnrollView extends StatelessWidget {
  const _EnrollView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProducerManagementBloc, ProducerManagementState>(
          listenWhen: (previous, current) =>
              current is ProducerManagementListLoaded &&
              (previous is ProducerManagementInitial ||
                  previous is ProducerManagementLoading),
          listener: (context, state) {
            context.read<ProducerManagementBloc>().add(
              const ProducerManagementEvent.enrollSearchChanged(''),
            );
          },
        ),
        BlocListener<ProducerManagementBloc, ProducerManagementState>(
          listenWhen: (previous, current) =>
              current is ProducerManagementListLoaded &&
              (previous is ProducerManagementEnrollStep2 ||
                  previous is ProducerManagementEnrollNoAccountStep2),
          listener: (context, state) {
            context.pop();
          },
        ),
      ],
      child: BlocBuilder<ProducerManagementBloc, ProducerManagementState>(
        builder: (context, state) => switch (state) {
          ProducerManagementInitial() ||
          ProducerManagementLoading() => const ConnectedScaffold(
            title: _kEnrollProducerTitle,
            body: Center(child: CircularProgressIndicator()),
          ),
          ProducerManagementError(:final message) => ConnectedScaffold(
            title: _kEnrollProducerTitle,
            body: Center(child: Text(message)),
          ),
          ProducerManagementEnrollStep1(
            :final organization,
            :final searchQuery,
            :final searchResults,
            :final searching,
          ) =>
            _Step1(
              organization: organization,
              searchQuery: searchQuery,
              searchResults: searchResults,
              searching: searching,
            ),
          ProducerManagementEnrollStep2(
            :final organization,
            :final selectedProducer,
            :final actionInProgress,
            :final actionError,
          ) =>
            _AccountBackedStep2(
              organization: organization,
              selectedProducer: selectedProducer,
              actionInProgress: actionInProgress,
              actionError: actionError,
            ),
          ProducerManagementEnrollNoAccountStep2(
            :final organization,
            :final actionInProgress,
            :final actionError,
          ) =>
            _NoAccountStep2(
              organization: organization,
              actionInProgress: actionInProgress,
              actionError: actionError,
            ),
          ProducerManagementListLoaded() ||
          ProducerManagementDetailLoaded() => const ConnectedScaffold(
            title: _kEnrollProducerTitle,
            body: SizedBox.shrink(),
          ),
        },
      ),
    );
  }
}

class _Step1 extends StatefulWidget {
  const _Step1({
    required this.organization,
    required this.searchQuery,
    required this.searchResults,
    required this.searching,
  });

  final Organization organization;
  final String searchQuery;
  final List<ProducerAccount> searchResults;
  final bool searching;

  @override
  State<_Step1> createState() => _Step1State();
}

class _Step1State extends State<_Step1> {
  late final _controller = TextEditingController(text: widget.searchQuery);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Inscrire un producteur — Étape 1',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher un producteur',
                    hintText: 'Nom ou email',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) => context
                      .read<ProducerManagementBloc>()
                      .add(ProducerManagementEvent.enrollSearchChanged(query)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('create_no_account_producer_button'),
                    onPressed: () => context.read<ProducerManagementBloc>().add(
                      const ProducerManagementEvent.enrollNoAccountStarted(),
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Créer un producteur sans compte'),
                  ),
                ),
              ],
            ),
          ),
          if (widget.searching)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (widget.searchResults.isEmpty &&
              widget.searchQuery.isNotEmpty)
            const Expanded(
              child: Center(child: Text('Aucun producteur trouvé.')),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: widget.searchResults.length,
                separatorBuilder: (_, idx) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final producer = widget.searchResults[index];
                  return ListTile(
                    title: Text(producer.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProducerManagementModeBadge(
                          mode: producer.managementMode,
                        ),
                        if (producer.contactEmail != null)
                          Text(producer.contactEmail!),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.read<ProducerManagementBloc>().add(
                      ProducerManagementEvent.enrollProducerSelected(producer),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountBackedStep2 extends StatefulWidget {
  const _AccountBackedStep2({
    required this.organization,
    required this.selectedProducer,
    required this.actionInProgress,
    required this.actionError,
  });

  final Organization organization;
  final ProducerAccount selectedProducer;
  final bool actionInProgress;
  final String? actionError;

  @override
  State<_AccountBackedStep2> createState() => _AccountBackedStep2State();
}

class _AccountBackedStep2State extends State<_AccountBackedStep2> {
  final Set<String> _selectedProductTypeIds = {};
  final Map<String, Set<String>> _selectedBasketSizes = {};

  @override
  Widget build(BuildContext context) {
    final producerProducts = widget.selectedProducer.products;

    return ConnectedScaffold(
      title: 'Inscrire un producteur — Étape 2',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedProducer.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                ProducerManagementModeBadge(
                  mode: widget.selectedProducer.managementMode,
                ),
                if (widget.selectedProducer.contactEmail != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.selectedProducer.contactEmail!),
                ],
                const SizedBox(height: 8),
                const Text('Sélectionnez les produits à associer à cet AMAP :'),
              ],
            ),
          ),
          Expanded(
            child: producerProducts.isEmpty
                ? const Center(child: Text('Ce producteur n\'a aucun produit.'))
                : ListView.builder(
                    itemCount: producerProducts.length,
                    itemBuilder: (context, index) =>
                        _productTile(producerProducts[index]),
                  ),
          ),
          if (widget.actionError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.actionError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: widget.actionInProgress
                ? const CircularProgressIndicator()
                : Row(
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            context.read<ProducerManagementBloc>().add(
                              const ProducerManagementEvent.backToListRequested(),
                            ),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _selectedProductTypeIds.isEmpty
                              ? null
                              : () => _confirm(context),
                          child: const Text('Confirmer l\'inscription'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _onProductChecked(ProducerProduct product, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedProductTypeIds.add(product.productTypeId);
      } else {
        _selectedProductTypeIds.remove(product.productTypeId);
        _selectedBasketSizes.remove(product.productTypeId);
      }
    });
  }

  void _onBasketSizeSelected(
    ProducerProduct product,
    String basketSizeName,
    bool selected,
  ) {
    setState(() {
      final sizes = _selectedBasketSizes.putIfAbsent(
        product.productTypeId,
        () => {},
      );
      if (selected) {
        sizes.add(basketSizeName);
      } else {
        sizes.remove(basketSizeName);
      }
    });
  }

  Widget _productTile(ProducerProduct product) {
    final isSelected = _selectedProductTypeIds.contains(product.productTypeId);
    return Column(
      children: [
        CheckboxListTile(
          title: Text(product.name),
          subtitle: product.description != null
              ? Text(product.description!)
              : null,
          value: isSelected,
          onChanged: (checked) => _onProductChecked(product, checked),
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
                          _selectedBasketSizes[product.productTypeId]?.contains(
                            basketSize.name,
                          ) ??
                          false,
                      onSelected: (selected) => _onBasketSizeSelected(
                        product,
                        basketSize.name,
                        selected,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _confirm(BuildContext context) {
    final products = _selectedProductTypeIds
        .map((ptId) {
          final product = widget.selectedProducer.products
              .where((p) => p.productTypeId == ptId)
              .firstOrNull;
          if (product == null) return null;
          final selectedSizes = _selectedBasketSizes[ptId];
          final basketSizes = selectedSizes != null
              ? product.supportedBasketSizes
                    .where((bs) => selectedSizes.contains(bs.name))
                    .toList()
              : product.supportedBasketSizes;
          return OrgProduct(
            name: product.name,
            productTypeId: ptId,
            producerAccountId: widget.selectedProducer.producerAccountId,
            supportedBasketSizes: basketSizes,
            description: product.description,
          );
        })
        .whereType<OrgProduct>()
        .toList();

    context.read<ProducerManagementBloc>().add(
      ProducerManagementEvent.enrollConfirmed(products),
    );
  }
}

class _NoAccountStep2 extends StatefulWidget {
  const _NoAccountStep2({
    required this.organization,
    required this.actionInProgress,
    required this.actionError,
  });

  final Organization organization;
  final bool actionInProgress;
  final String? actionError;

  @override
  State<_NoAccountStep2> createState() => _NoAccountStep2State();
}

class _NoAccountStep2State extends State<_NoAccountStep2> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  List<ProducerProduct> _products = [];

  @override
  void dispose() {
    _nameController.dispose();
    _contactEmailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Créer un producteur sans compte — Étape 2',
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ProducerManagementModeBadge(
                      mode: ProducerManagementMode.noAccount,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du producteur *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Renseignez un nom.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email de contact',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Site web',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Produits AMAP (${_products.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const Key('add_no_account_product_button'),
                          onPressed: _addProduct,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_products.isEmpty)
                      const Text(
                        'Ajoutez au moins un produit pour ce producteur sans compte.',
                      )
                    else
                      ..._products.map(_buildProductCard),
                  ],
                ),
              ),
            ),
          ),
          if (widget.actionError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.actionError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: widget.actionInProgress
                ? const CircularProgressIndicator()
                : Row(
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            context.read<ProducerManagementBloc>().add(
                              const ProducerManagementEvent.backToListRequested(),
                            ),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _products.isEmpty ? null : _confirm,
                          child: const Text('Créer le producteur'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProducerProduct product) {
    final basketSizes = product.supportedBasketSizes
        .map((basketSize) => basketSize.name)
        .join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Modifier',
              onPressed: () => _editProduct(product),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Supprimer',
              onPressed: () => _deleteProduct(product),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProduct() async {
    final created = await showManagedProducerProductDialog(context);
    if (created == null) return;
    setState(() => _products = [..._products, created]);
  }

  Future<void> _editProduct(ProducerProduct product) async {
    final updated = await showManagedProducerProductDialog(
      context,
      initialProduct: product,
    );
    if (updated == null) return;
    setState(() {
      _products = _products
          .map(
            (candidate) => candidate.productTypeId == product.productTypeId
                ? updated
                : candidate,
          )
          .toList();
    });
  }

  void _deleteProduct(ProducerProduct product) {
    setState(() {
      _products = _products
          .where(
            (candidate) => candidate.productTypeId != product.productTypeId,
          )
          .toList();
    });
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProducerManagementBloc>().add(
      ProducerManagementEvent.enrollNoAccountConfirmed(
        name: _nameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
        products: _products,
      ),
    );
  }
}
