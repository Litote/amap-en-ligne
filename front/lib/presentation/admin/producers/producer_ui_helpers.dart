import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:flutter/material.dart';

class ProducerManagementModeBadge extends StatelessWidget {
  const ProducerManagementModeBadge({required this.mode, super.key});

  final ProducerManagementMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = switch (mode) {
      ProducerManagementMode.accountBacked => (
        background: colorScheme.tertiaryContainer,
        text: colorScheme.onTertiaryContainer,
      ),
      ProducerManagementMode.noAccount => (
        background: colorScheme.surfaceContainerHighest,
        text: colorScheme.onSurfaceVariant,
      ),
    };
    return Chip(
      label: Text(
        producerManagementModeLabel(mode),
        style: TextStyle(color: colors.text, fontSize: 12),
      ),
      backgroundColor: colors.background,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

String producerManagementModeLabel(ProducerManagementMode mode) =>
    switch (mode) {
      ProducerManagementMode.accountBacked => 'Avec compte',
      ProducerManagementMode.noAccount => 'Sans compte',
    };

Future<ProducerProduct?> showManagedProducerProductDialog(
  BuildContext context, {
  ProducerProduct? initialProduct,
}) {
  return showDialog<ProducerProduct>(
    context: context,
    builder: (dialogContext) =>
        _ManagedProducerProductDialog(initialProduct: initialProduct),
  );
}

class _ManagedProducerProductDialog extends StatefulWidget {
  const _ManagedProducerProductDialog({this.initialProduct});

  final ProducerProduct? initialProduct;

  @override
  State<_ManagedProducerProductDialog> createState() =>
      _ManagedProducerProductDialogState();
}

class _ManagedProducerProductDialogState
    extends State<_ManagedProducerProductDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialProduct?.name ?? '',
  );
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.initialProduct?.description ?? '');
  late final TextEditingController _newBasketSizeController =
      TextEditingController();
  late final List<String> _basketSizes =
      widget.initialProduct?.supportedBasketSizes
          .map((basketSize) => basketSize.name)
          .toList() ??
      [];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _newBasketSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialProduct == null
            ? 'Ajouter un produit'
            : 'Modifier le produit',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit',
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Text(
                'Tailles de panier',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (_basketSizes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aucune taille pour le moment',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _basketSizes
                        .map(
                          (size) => Chip(
                            label: Text(size),
                            onDeleted: () =>
                                setState(() => _basketSizes.remove(size)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newBasketSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Ajouter une taille',
                        hintText: 'Ex: Petit',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: _addBasketSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addBasketSize,
                    icon: const Icon(Icons.add),
                    tooltip: 'Ajouter',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }

  void _addBasketSize([String? _]) {
    final newSize = _newBasketSizeController.text.trim();
    if (newSize.isEmpty) return;
    if (_basketSizes.contains(newSize)) return;
    setState(() {
      _basketSizes.add(newSize);
      _newBasketSizeController.clear();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final product = ProducerProduct(
      name: _nameController.text.trim(),
      productTypeId:
          widget.initialProduct?.productTypeId ?? _nextTemporaryProductTypeId(),
      supportedBasketSizes: _basketSizes
          .map((name) => BasketSize(name: name))
          .toList(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
    Navigator.of(context).pop(product);
  }

  String _nextTemporaryProductTypeId() =>
      '${ClientMutation.tmpIdPrefix}${DateTime.now().microsecondsSinceEpoch}';
}
