import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:flutter/material.dart';

/// Status chip for a [DeliveryStatus] — shared by the coordinator dashboard and
/// the coordinator tracking entry screens.
class DeliveryStatusChip extends StatelessWidget {
  const DeliveryStatusChip({required this.status, super.key});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DeliveryStatus.inProgress => ('🔴 En cours', Colors.red),
      DeliveryStatus.confirmed => ('Confirmée', Colors.green),
      DeliveryStatus.planned => ('Planifiée', Colors.blue),
      _ => (status.name, Colors.grey),
    };
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      side: BorderSide(color: color),
    );
  }
}

/// Status chip for a [SlotStatus] — shared by the time-slots management screen.
///
/// The summarising [SlotStatus] of a delivery is computed by
/// `deliverySlotStatus` in `organization_member_view.dart`.
class SlotStatusChip extends StatelessWidget {
  const SlotStatusChip({required this.slotStatus, super.key});

  final SlotStatus slotStatus;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (slotStatus) {
      SlotStatus.open => ('Ouvert', Colors.green),
      SlotStatus.critical => ('Critique', Colors.orange),
      SlotStatus.full => ('Complet', Colors.blue),
      SlotStatus.closed => ('Fermé', Colors.grey),
      SlotStatus.cancelled => ('Annulé', Colors.red),
    };
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      side: BorderSide(color: color),
    );
  }
}
