import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart'
    show activeRegistrationsExcluding, deliveryCoordinatorIds;
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slots_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Block listing every volunteer slot of the edited delivery with per-slot
/// lifecycle actions (cancel / delete).
///
/// States per slot:
///  - active registrations → [ANNULER] enabled, [SUPPRIMER] disabled;
///  - no active registration → both enabled;
///  - CANCELLED → "ANNULÉ" badge, all actions disabled.
class SlotsBlock extends StatelessWidget {
  const SlotsBlock({
    super.key,
    required this.delivery,
    required this.org,
    required this.mainContractIds,
  });

  final Delivery delivery;
  final Organization org;

  /// Ids of the org's main contracts: only those mobilise volunteers, so only
  /// their slots are listed here (legacy fallback: when none of the delivery's
  /// links is main, every contract is shown).
  final Set<String> mainContractIds;

  @override
  Widget build(BuildContext context) {
    final mains = delivery.contracts
        .where((c) => mainContractIds.contains(c.contractId))
        .toList();
    final shownContracts = mains.isEmpty ? delivery.contracts : mains;
    final rows = <Widget>[];
    for (final contract in shownContracts) {
      for (final slot in contract.slots) {
        rows.add(
          _SlotRow(
            org: org,
            delivery: delivery,
            contract: contract,
            slot: slot,
          ),
        );
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '🕐 Créneaux bénévoles',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}

/// One row of [SlotsBlock]: time range, active registration count, status
/// badge and the [ANNULER] / [SUPPRIMER] actions.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.org,
    required this.delivery,
    required this.contract,
    required this.slot,
  });

  final Organization org;
  final Delivery delivery;
  final DeliveryContract contract;
  final MemberSlot slot;

  bool get _isCancelled => slot.status == SlotStatus.cancelled;

  int get _activeRegistrations =>
      activeRegistrationsExcluding(slot, deliveryCoordinatorIds(delivery));

  String get _timeLabel {
    String hhmm(String iso) {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return '${hhmm(slot.startTime)} – ${hhmm(slot.endTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeRegistrations;
    final kindLabel = slot.slotKind == SlotKind.early
        ? 'Créneau anticipé'
        : 'Créneau standard';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$kindLabel • $_timeLabel • '
                  '$active inscrit${active > 1 ? 's' : ''}',
                  style: _isCancelled
                      ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                        )
                      : Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (_isCancelled)
                Chip(
                  label: const Text('ANNULÉ'),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          if (!_isCancelled)
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _confirmCancel(context, active),
                  child: const Text('ANNULER'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  // Local guard: deletion requires no active registration.
                  // The server re-validates and returns CONFLICT on a race.
                  onPressed: active == 0 ? () => _confirmDelete(context) : null,
                  child: const Text('SUPPRIMER'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, int activeCount) {
    final bloc = context.read<TimeSlotsBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Annuler ce créneau ?',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                activeCount > 0
                    ? '$activeCount inscrit${activeCount > 1 ? 's' : ''} '
                          'seront notifiés et leurs inscriptions annulées.'
                    : 'Ce créneau ne compte aucun inscrit.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  bloc.add(
                    TimeSlotsEvent.slotCancelRequested(
                      currentOrg: org,
                      deliveryId: delivery.deliveryId,
                      contractId: contract.contractId,
                      slot: slot,
                    ),
                  );
                },
                child: const Text("CONFIRMER L'ANNULATION"),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('RETOUR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final bloc = context.read<TimeSlotsBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce créneau ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ANNULER'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(
                TimeSlotsEvent.slotDeleteRequested(
                  currentOrg: org,
                  deliveryId: delivery.deliveryId,
                  contractId: contract.contractId,
                  slot: slot,
                ),
              );
            },
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }
}
