import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Resolves the contract id whose slot of [kind] should receive a registration.
///
/// Only main contracts mobilise volunteers, so the search is restricted to the
/// delivery's main-contract links ([mainContractIds]); when none is flagged main
/// (legacy data), every contract is searched. Prefers a contract whose [kind]
/// slot still has free capacity (by counting non-coordinator active registrations
/// against [MemberSlot.requiredVolunteers], matching the capacity math used by the
/// cards); falls back to the first searched contract.
String? _findContractIdForKind(
  Delivery delivery,
  SlotKind kind,
  Set<String> mainContractIds,
) {
  final mains = delivery.contracts
      .where((c) => mainContractIds.contains(c.contractId))
      .toList();
  final searchContracts = mains.isEmpty ? delivery.contracts : mains;
  for (final contract in searchContracts) {
    for (final slot in contract.slots) {
      if (slot.slotKind == kind &&
          nonCoordinatorActiveRegistrations(slot, contract) <
              slot.requiredVolunteers) {
        return contract.contractId;
      }
    }
  }
  return searchContracts.firstOrNull?.contractId;
}

/// Registers [member] to a slot of [slotKind] on [delivery] and flushes sync.
void registerToSlotAction(
  BuildContext context, {
  required Delivery delivery,
  required SlotKind slotKind,
  required Member member,
  required Organization org,
  Set<String> mainContractIds = const {},
}) {
  final contractId = _findContractIdForKind(
    delivery,
    slotKind,
    mainContractIds,
  );
  if (contractId == null) return;

  context.read<OrganizationRepository>().registerToSlot(
    currentOrg: org,
    deliveryId: delivery.deliveryId,
    contractId: contractId,
    slotKind: slotKind,
    me: member,
  );
  context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
}

/// Removes [memberId]'s first active registration on [delivery] and flushes
/// sync. Locates the slot dynamically.
void unregisterFromDeliveryAction(
  BuildContext context, {
  required Delivery delivery,
  required String memberId,
  required Organization org,
}) {
  for (final contract in delivery.contracts) {
    for (final slot in contract.slots) {
      for (final reg in slot.registrations) {
        if (reg.memberId == memberId &&
            reg.status != RegistrationStatus.cancelled) {
          context.read<OrganizationRepository>().unregisterFromSlot(
            currentOrg: org,
            deliveryId: delivery.deliveryId,
            contractId: contract.contractId,
            slotKind: slot.slotKind,
            memberId: memberId,
          );
          context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
          return;
        }
      }
    }
  }
}

/// Registration button. The [label] is supplied by the caller (the copy differs
/// between the planning screen and the dashboard, per spec); the registration
/// action is shared via [registerToSlotAction].
class RegisterButton extends StatelessWidget {
  const RegisterButton({
    required this.delivery,
    required this.slotKind,
    required this.member,
    required this.org,
    required this.label,
    this.mainContractIds = const {},
    super.key,
  });

  final Delivery delivery;
  final SlotKind slotKind;
  final Member member;
  final Organization org;
  final String label;

  /// Ids of the org's main contracts — registration is targeted at a main
  /// contract's slot (volunteers are never mobilised on secondary contracts).
  final Set<String> mainContractIds;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => registerToSlotAction(
        context,
        delivery: delivery,
        slotKind: slotKind,
        member: member,
        org: org,
        mainContractIds: mainContractIds,
      ),
      child: Text(label),
    );
  }
}

/// Unregister button — "SE DÉSINSCRIRE" — shared by the planning screen, the
/// dashboard upcoming list and the "Ma prochaine participation" card.
class UnregisterButton extends StatelessWidget {
  const UnregisterButton({
    required this.delivery,
    required this.memberId,
    required this.org,
    super.key,
  });

  final Delivery delivery;
  final String memberId;
  final Organization org;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => unregisterFromDeliveryAction(
        context,
        delivery: delivery,
        memberId: memberId,
        org: org,
      ),
      icon: const Text('❌'),
      label: const Text('SE DÉSINSCRIRE'),
    );
  }
}
