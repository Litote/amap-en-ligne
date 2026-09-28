import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_format.dart';
import 'package:flutter/material.dart';

/// Asks the coordinator to confirm the irreversible deletion of [delivery],
/// warning about the volunteers who would lose their registration. Shared by
/// the delivery list (swipe) and the delivery form (« Supprimer la livraison »).
Future<bool> confirmDeliveryDeletion(
  BuildContext context,
  Delivery delivery,
) async {
  final registered = [
    for (final link in delivery.contracts)
      for (final slot in link.slots) activeRegistrationsCount(slot),
  ].fold(0, (a, b) => a + b);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Supprimer la livraison ?'),
      semanticLabel: 'Supprimer la livraison ?',
      content: Text(
        'La livraison du ${formatDeliveryDateTime(delivery.scheduledDate)} '
        'sera supprimée. Cette action est irréversible.'
        '${registered == 0 ? '' : '\n\n${_registeredWarning(registered)}'}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('SUPPRIMER'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

String _registeredWarning(int count) => count == 1
    ? '1 bénévole inscrit perdra son inscription.'
    : '$count bénévoles inscrits perdront leur inscription.';
