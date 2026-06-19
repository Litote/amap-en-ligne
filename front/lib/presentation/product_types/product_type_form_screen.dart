import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Create-or-edit form. When [productTypeId] is null, the form creates a new
/// row with a `tmp_*` id; otherwise it loads the existing row from the local
/// cache and updates it on submit.
class ProductTypeFormScreen extends StatefulWidget {
  const ProductTypeFormScreen({
    super.key,
    required this.tenantId,
    this.productTypeId,
  });

  final String tenantId;
  final String? productTypeId;

  @override
  State<ProductTypeFormScreen> createState() => _ProductTypeFormScreenState();
}

class _ProductTypeFormScreenState extends State<ProductTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basketSizesController = TextEditingController();
  ProductType? _existing;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.productTypeId == null) {
      setState(() => _loading = false);
      return;
    }
    final repo = context.read<ProductTypeRepository>();
    final list = await repo.watch(widget.tenantId).first;
    final pt = list.firstWhere(
      (e) => e.productTypeId == widget.productTypeId,
      orElse: () => throw StateError(
        'ProductType ${widget.productTypeId} not found in local cache',
      ),
    );
    setState(() {
      _existing = pt;
      _nameController.text = pt.name;
      _descriptionController.text = pt.description ?? '';
      _basketSizesController.text = pt.supportedBasketSizes
          .map((s) => s.name)
          .join(', ');
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basketSizesController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce type de produit ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            key: const Key('product_type_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = context.read<ProductTypeRepository>();
    await repo.delete(
      tenantId: widget.tenantId,
      productTypeId: _existing!.productTypeId,
    );
    if (!mounted) return;
    context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
    context.pop();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = context.read<ProductTypeRepository>();
    final List<BasketSize> basketSizes = _basketSizesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => BasketSize(name: s))
        .toList();
    final description = _descriptionController.text.trim();

    if (_existing == null) {
      await repo.create(
        tenantId: widget.tenantId,
        name: _nameController.text.trim(),
        description: description.isEmpty ? null : description,
        supportedBasketSizes: basketSizes,
      );
    } else {
      await repo.update(
        _existing!.copyWith(
          name: _nameController.text.trim(),
          description: description.isEmpty ? null : description,
          supportedBasketSizes: basketSizes,
        ),
      );
    }
    if (!mounted) return;
    context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existing == null
              ? 'Nouveau type de produit'
              : 'Modifier le type de produit',
        ),
        actions: [
          if (_existing != null)
            IconButton(
              key: const Key('product_type_delete'),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _basketSizesController,
                decoration: const InputDecoration(
                  labelText: 'Tailles de panier (séparées par des virgules)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_existing != null) ...[
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Catalogue de composants'),
                    subtitle: Text(
                      '${_existing!.itemTypes.length} composant'
                      '${_existing!.itemTypes.length > 1 ? 's' : ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/product-types/${_existing!.productTypeId}/items',
                      extra: _existing,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
