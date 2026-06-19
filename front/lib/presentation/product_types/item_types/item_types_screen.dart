import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_bloc.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_event.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemTypesScreen extends StatelessWidget {
  const ItemTypesScreen({super.key, required this.productType});

  final ProductType productType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItemTypesBloc>(
      create: (context) => ItemTypesBloc(
        productTypeRepository: context.read<ProductTypeRepository>(),
        idGenerator: IdGenerator(),
      )..add(ItemTypesEvent.requested(productType: productType)),
      child: _ItemTypesView(productType: productType),
    );
  }
}

class _ItemTypesView extends StatelessWidget {
  const _ItemTypesView({required this.productType});

  final ProductType productType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Catalogue d'items — ${productType.name}")),
      body: BlocBuilder<ItemTypesBloc, ItemTypesState>(
        builder: (context, state) {
          return switch (state) {
            ItemTypesInitial() => const Center(
              child: CircularProgressIndicator(),
            ),
            ItemTypesSaving() => const Center(
              child: CircularProgressIndicator(),
            ),
            ItemTypesError(:final message) => Center(
              child: Text('Erreur : $message'),
            ),
            ItemTypesLoaded(:final productType) ||
            ItemTypesSaved(
              :final productType,
            ) => _ItemTypesList(productType: productType),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

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
          "Aucun item défini. Ajoutez des items pour décrire vos livraisons.",
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

  /// Accepts only inline SVG markup (no raster, no URL).
  bool _looksLikeSvg(String value) {
    final trimmed = value.trimLeft();
    return trimmed.startsWith('<svg') || trimmed.startsWith('<?xml');
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svgController.text.trim();
    final hasValidSvg = svg.isNotEmpty && _looksLikeSvg(svg);
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
            'Ajouter un item',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _svgController,
            minLines: 3,
            maxLines: 6,
            maxLength: 50000,
            decoration: const InputDecoration(
              labelText: 'Image SVG (optionnel)',
              hintText: 'Collez le code SVG (<svg …>)',
              alignLabelWithHint: true,
            ),
          ),
          if (svg.isNotEmpty && !hasValidSvg)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Seules les images au format SVG sont acceptées.',
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
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              // Reject anything that is not inline SVG markup.
              final imageSvg = (svg.isNotEmpty && _looksLikeSvg(svg))
                  ? svg
                  : null;
              widget.bloc.add(
                ItemTypesEvent.added(name: name, imageSvg: imageSvg),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
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
      return Icon(Icons.image_not_supported, size: size);
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
