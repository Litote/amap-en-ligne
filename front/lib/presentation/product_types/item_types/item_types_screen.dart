import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/validation/input_rules.dart';
import 'package:amap_en_ligne/presentation/nav/back_navigation.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_bloc.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_event.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Route entry of the component catalog: uses the product type handed over by
/// the product type form, or — opened by its URL (reload, shared link) —
/// reads it from the local cache.
class ItemTypesRouteScreen extends StatelessWidget {
  const ItemTypesRouteScreen({
    super.key,
    required this.tenantId,
    required this.productTypeId,
    this.productType,
  });

  final String tenantId;
  final String productTypeId;
  final ProductType? productType;

  @override
  Widget build(BuildContext context) {
    final handedOver = productType;
    if (handedOver != null) return ItemTypesScreen(productType: handedOver);
    return StreamBuilder<List<ProductType>>(
      stream: context.read<ProductTypeRepository>().watch(tenantId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final cached = data
            ?.where((p) => p.productTypeId == productTypeId)
            .firstOrNull;
        if (cached != null) return ItemTypesScreen(productType: cached);
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => popOrGo(context, '/product-types'),
            ),
            title: const Text('Catalogue de composants'),
          ),
          body: Center(
            child: data == null
                ? const CircularProgressIndicator()
                : const Text('Type de produit introuvable.'),
          ),
        );
      },
    );
  }
}

class ItemTypesScreen extends StatelessWidget {
  const ItemTypesScreen({super.key, required this.productType});

  final ProductType productType;

  @override
  Widget build(BuildContext context) => BlocProvider<ItemTypesBloc>(
    create: (context) => ItemTypesBloc(
      productTypeRepository: context.read<ProductTypeRepository>(),
      idGenerator: IdGenerator(),
    )..add(ItemTypesEvent.requested(productType: productType)),
    child: _ItemTypesView(productType: productType),
  );
}

class _ItemTypesView extends StatelessWidget {
  const _ItemTypesView({required this.productType});

  final ProductType productType;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(
        onPressed: () =>
            popOrGo(context, '/product-types/${productType.productTypeId}'),
      ),
      title: Text('Catalogue de composants — ${productType.name}'),
    ),
    body: BlocBuilder<ItemTypesBloc, ItemTypesState>(
      builder: (context, state) => switch (state) {
        ItemTypesInitial() => const Center(child: CircularProgressIndicator()),
        ItemTypesSaving() => const Center(child: CircularProgressIndicator()),
        ItemTypesError(:final message) => Center(child: Text(message)),
        ItemTypesLoaded(:final productType) ||
        ItemTypesSaved(
          :final productType,
        ) => _ItemTypesList(productType: productType),
      },
    ),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Ajouter un composant',
      onPressed: () => _showAddItemSheet(context),
      child: const Icon(Icons.add),
    ),
  );

  void _showAddItemSheet(BuildContext context) {
    final bloc = context.read<ItemTypesBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddItemSheet(bloc: bloc),
    );
  }
}

class _ItemTypesList extends StatelessWidget {
  const _ItemTypesList({required this.productType});

  final ProductType productType;

  @override
  Widget build(BuildContext context) {
    final items = productType.itemTypes;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Aucun composant défini. Ajoutez des composants pour décrire vos '
          'livraisons.',
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return ListTile(
          leading: ItemTypeSvgIcon(svg: item.imageSvg, size: 40),
          title: Text(item.name),
          trailing: IconButton(
            tooltip: 'Supprimer ${item.name}',
            icon: const Icon(Icons.delete),
            onPressed: () => context.read<ItemTypesBloc>().add(
              ItemTypesEvent.removed(itemTypeId: item.id),
            ),
          ),
        );
      },
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.bloc});

  final ItemTypesBloc bloc;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameController = TextEditingController();
  final _svgController = TextEditingController();

  /// Set once "Ajouter" was tapped, so the missing-name error shows only then.
  bool _submitAttempted = false;

  @override
  void initState() {
    super.initState();
    // Rebuild the live preview as the producer pastes SVG markup.
    _svgController.addListener(_onSvgChanged);
  }

  void _onSvgChanged() => setState(() {});

  @override
  void dispose() {
    _svgController.removeListener(_onSvgChanged);
    _nameController.dispose();
    _svgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svgController.text.trim();
    // Same rule as the back (ProductType item_types.image_svg).
    final svgError = optionalSvgImageError(svg);
    final hasValidSvg = svg.isNotEmpty && svgError == null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ajouter un composant',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Nom',
              // Same rule as the back (ProductType item_types.name).
              errorText: _submitAttempted
                  ? requiredName(_nameController.text)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _svgController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Image SVG (optionnel)',
              hintText: 'Collez le code SVG (<svg …>)',
              alignLabelWithHint: true,
            ),
          ),
          if (svgError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                svgError,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          if (hasValidSvg) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ItemTypeSvgIcon(svg: svg, size: 56),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _submit(svg),
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit(String svg) {
    final name = _nameController.text.trim();
    if (requiredName(name) != null) {
      setState(() => _submitAttempted = true);
      return;
    }
    // The error is already shown under the field: the back would refuse it.
    if (optionalSvgImageError(svg) != null) return;
    final imageSvg = svg.isNotEmpty ? svg : null;
    widget.bloc.add(ItemTypesEvent.added(name: name, imageSvg: imageSvg));
    Navigator.of(context).pop();
  }
}

/// Renders an [ItemType]'s inline SVG icon, falling back to a placeholder when
/// no SVG is defined.
class ItemTypeSvgIcon extends StatelessWidget {
  const ItemTypeSvgIcon({required this.svg, required this.size, super.key});

  final String? svg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = svg;
    if (value == null || value.trim().isEmpty) {
      // No icon (e.g. a free-entry component): a neutral produce glyph rather
      // than a "broken image" one.
      return Icon(
        Icons.eco_outlined,
        size: size,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return SvgPicture.string(
      value,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => Icon(Icons.image_not_supported, size: size),
    );
  }
}
