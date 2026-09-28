import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the basket-composition editor of one of the producer's deliveries.
class ProducerCompositionButton extends StatelessWidget {
  const ProducerCompositionButton({
    super.key,
    required this.organizationId,
    required this.deliveryId,
  });

  final String organizationId;
  final String deliveryId;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.go(
      '/producer-deliveries/$organizationId/$deliveryId/composition',
    ),
    icon: const Icon(Icons.shopping_basket_outlined),
    label: const Text('COMPOSITION DU PANIER'),
  );
}
