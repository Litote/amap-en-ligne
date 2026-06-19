import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point to the per-delivery basket composition editor. Only an
/// already-saved delivery can be composed (the editor loads the delivery from
/// the org cache), so in creation mode this shows a hint to save first.
class BasketCompositionBlock extends StatelessWidget {
  const BasketCompositionBlock({
    super.key,
    required this.existingDelivery,
    required this.org,
  });

  final Delivery? existingDelivery;
  final Organization org;

  @override
  Widget build(BuildContext context) {
    final delivery = existingDelivery;
    if (delivery == null) {
      return const Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.shopping_basket_outlined),
          title: Text('Composition du panier'),
          subtitle: Text(
            'Enregistrez la livraison pour définir la composition.',
          ),
          enabled: false,
        ),
      );
    }
    final itemCount = delivery.basketDescriptions.fold<int>(
      0,
      (sum, d) => sum + d.items.length,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.shopping_basket_outlined),
        title: const Text('Composition du panier'),
        subtitle: Text(
          itemCount == 0
              ? 'Aucun composant'
              : '$itemCount composant${itemCount > 1 ? 's' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          '/coordinator/deliveries/${delivery.deliveryId}/description',
          extra: org,
        ),
      ),
    );
  }
}
