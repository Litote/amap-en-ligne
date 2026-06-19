import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amap_en_ligne/presentation/common/open_url_stub.dart'
    if (dart.library.js_interop) 'package:amap_en_ligne/presentation/common/open_url_web.dart'
    if (dart.library.io) 'package:amap_en_ligne/presentation/common/open_url_native.dart';

/// Live-tracking screen for a single delivery.
///
/// Displays simplified coordinator tracking:
/// - volunteers can only be marked present or absent,
/// - contracts can only be marked collected or not collected,
/// - member contact uses the existing phone/email profile data.
const _kDeliveryTrackingTitle = 'Suivi livraison';

class CoordinatorDeliveryTrackingScreen extends StatelessWidget {
  const CoordinatorDeliveryTrackingScreen({
    super.key,
    required this.tenantId,
    required this.deliveryId,
  });

  final String tenantId;
  final String deliveryId;

  static String _statusLabel(DeliveryStatus status) => switch (status) {
    DeliveryStatus.inProgress => '🔴 LIVE',
    DeliveryStatus.confirmed => 'Confirmée',
    DeliveryStatus.planned => 'Planifiée',
    DeliveryStatus.completed => 'Terminée',
    DeliveryStatus.cancelled => 'Annulée',
  };

  static Widget _statusBadge(DeliveryStatus status) {
    final isLive = status == DeliveryStatus.inProgress;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: Text(
          _statusLabel(status),
          style: TextStyle(
            color: isLive ? Colors.red : null,
            fontWeight: isLive ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  static bool _syncListenWhen(SyncState _, SyncState current) =>
      current is SyncFailed ||
      current is SyncSucceeded && current.rejectedMutations.isNotEmpty;

  static void _onSyncState(BuildContext context, SyncState state) {
    final messenger = ScaffoldMessenger.of(context);
    if (state is SyncFailed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('La synchronisation a échoué. Réessayez.'),
        ),
      );
      return;
    }
    if (state is SyncSucceeded && state.rejectedMutations.isNotEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("La modification n'a pas pu être synchronisée."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: _kDeliveryTrackingTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<Organization?>(
      stream: context.read<OrganizationRepository>().watch(tenantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ConnectedScaffold(
            title: _kDeliveryTrackingTitle,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final org = snapshot.data;
        if (org == null) {
          return const ConnectedScaffold(
            title: _kDeliveryTrackingTitle,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final delivery = org.deliveries
            .where((candidate) => candidate.deliveryId == deliveryId)
            .firstOrNull;
        if (delivery == null) {
          return const ConnectedScaffold(
            title: _kDeliveryTrackingTitle,
            body: Center(child: Text('Livraison introuvable.')),
          );
        }

        return StreamBuilder<List<Member>>(
          stream: context.read<MemberRepository>().watch(tenantId),
          initialData: const [],
          builder: (context, membersSnapshot) {
            final membersById = {
              for (final member in membersSnapshot.data ?? const <Member>[])
                member.memberId: member,
            };

            return ConnectedScaffold(
              title: _kDeliveryTrackingTitle,
              actions: [_statusBadge(delivery.status), const SyncButton()],
              body: BlocListener<SyncBloc, SyncState>(
                listenWhen: _syncListenWhen,
                listener: _onSyncState,
                child: _TrackingBody(
                  org: org,
                  delivery: delivery,
                  membersById: membersById,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({
    required this.org,
    required this.delivery,
    required this.membersById,
  });

  final Organization org;
  final Delivery delivery;
  final Map<String, Member> membersById;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Contract>>(
      stream: context.read<ContractRepository>().watch(org.organizationId),
      initialData: const [],
      builder: (context, contractsSnapshot) {
        final contracts = contractsSnapshot.data ?? const [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoordinatorsSectionTracking(
                delivery: delivery,
                membersById: membersById,
                org: org,
                contracts: contracts,
              ),
              const SizedBox(height: 16),
              _VolunteerSection(
                org: org,
                delivery: delivery,
                membersById: membersById,
              ),
              const SizedBox(height: 16),
              _BasketPickupSection(
                org: org,
                delivery: delivery,
                contracts: contracts,
              ),
              const SizedBox(height: 16),
              _ProgressionSection(
                delivery: delivery,
                mainContractIds: mainContractIdsOf(contracts),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Coordinators section — detailed vertical layout for the tracking screen
// ---------------------------------------------------------------------------

/// Displays "👥 Coordinateurs de cette livraison" grouped by [DeliveryContract].
///
/// For each contract:
///   - Each coordinator is shown as "name • 📞 phone" (tel: link) or
///     "name • (téléphone non communiqué)" when no phone is available.
///   - When no coordinator is assigned: "Coordinateur à confirmer".
///
// V1: no per-contract emoji yet; spec uses 🥕/🍞 as illustrations.
class _CoordinatorsSectionTracking extends StatelessWidget {
  const _CoordinatorsSectionTracking({
    required this.delivery,
    required this.membersById,
    this.org,
    this.contracts = const [],
  });

  final Delivery delivery;
  final Map<String, Member> membersById;
  final Organization? org;
  final List<Contract> contracts;

  @override
  Widget build(BuildContext context) {
    final activeContracts =
        org?.activeContractsForDelivery(delivery, contracts: contracts) ??
        delivery.contracts;

    if (activeContracts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👥 Coordinateurs de cette livraison',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final contract in activeContracts)
                  _ContractCoordinatorBlock(
                    contract: contract,
                    membersById: membersById,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContractCoordinatorBlock extends StatelessWidget {
  const _ContractCoordinatorBlock({
    required this.contract,
    required this.membersById,
  });

  final DeliveryContract contract;
  final Map<String, Member> membersById;

  @override
  Widget build(BuildContext context) {
    final description = contract.deliveryDescription;
    final resolvedCoordinators = contract.coordinators
        .map((id) => membersById[id])
        .whereType<Member>()
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (resolvedCoordinators.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Coordinateur à confirmer',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            for (final coordinator in resolvedCoordinators)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: _CoordinatorPhoneRow(coordinator: coordinator),
              ),
        ],
      ),
    );
  }
}

class _CoordinatorPhoneRow extends StatelessWidget {
  const _CoordinatorPhoneRow({required this.coordinator});

  final Member coordinator;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(coordinator);
    final phone = coordinator.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;

    return Row(
      children: [
        Text(name, style: Theme.of(context).textTheme.bodySmall),
        Text(' • ', style: Theme.of(context).textTheme.bodySmall),
        if (hasPhone)
          InkWell(
            onTap: () => openUrl('tel:$phone'),
            child: Text(
              '📞 $phone',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        else
          Text(
            '(téléphone non communiqué)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  String _displayName(Member member) {
    final first = member.firstName?.trim() ?? '';
    final last = member.lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return member.memberId;
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }
}

class _VolunteerSection extends StatelessWidget {
  const _VolunteerSection({
    required this.org,
    required this.delivery,
    required this.membersById,
  });

  final Organization org;
  final Delivery delivery;
  final Map<String, Member> membersById;

  @override
  Widget build(BuildContext context) {
    // The delivery's coordinators are not volunteers: a coordinator registered
    // on a slot must not appear in the volunteer-presence list (consistent with
    // the staffing counter, which excludes the coordinator union).
    final coordinatorIds = deliveryCoordinatorIds(delivery);
    final items = <_RegistrationEntry>[];
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        for (final registration in slot.registrations) {
          if (coordinatorIds.contains(registration.memberId)) continue;
          items.add(
            _RegistrationEntry(
              contractId: contract.contractId,
              registration: registration,
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👥 Présence des bénévoles',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucun bénévole inscrit.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _RegistrationTile(
                    org: org,
                    deliveryId: delivery.deliveryId,
                    entry: items[index],
                    member: membersById[items[index].registration.memberId],
                  ),
                ),
        ),
      ],
    );
  }
}

class _RegistrationEntry {
  const _RegistrationEntry({
    required this.contractId,
    required this.registration,
  });

  final String contractId;
  final MemberRegistration registration;
}

class _RegistrationTile extends StatefulWidget {
  const _RegistrationTile({
    required this.org,
    required this.deliveryId,
    required this.entry,
    required this.member,
  });

  final Organization org;
  final String deliveryId;
  final _RegistrationEntry entry;
  final Member? member;

  @override
  State<_RegistrationTile> createState() => _RegistrationTileState();
}

class _RegistrationTileState extends State<_RegistrationTile> {
  bool _saving = false;

  Future<void> _updateStatus(RegistrationStatus newStatus) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<OrganizationRepository>().updateRegistrationStatus(
        currentOrg: widget.org,
        deliveryId: widget.deliveryId,
        contractId: widget.entry.contractId,
        memberId: widget.entry.registration.memberId,
        newStatus: newStatus,
      );
      if (!mounted) return;
      context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Uri? _resolveContactUri() {
    final contact = _resolveMemberContact(
      member: widget.member,
      registration: widget.entry.registration,
    );
    if (contact == null) return null;
    final preferPhone =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (preferPhone && contact.phone != null) {
      return Uri(scheme: 'tel', path: contact.phone);
    }
    if (contact.email != null) {
      return Uri(scheme: 'mailto', path: contact.email);
    }
    if (contact.phone != null) {
      return Uri(scheme: 'tel', path: contact.phone);
    }
    return null;
  }

  Widget _buildContactButton(BuildContext context, String displayName) {
    final uri = _resolveContactUri();
    return IconButton(
      icon: const Icon(Icons.contact_phone),
      tooltip: 'Contacter $displayName',
      onPressed: uri == null
          ? () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aucun contact disponible.')),
            )
          : () => openUrl(uri.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registration = widget.entry.registration;
    final isPresent = _isPresentStatus(registration.status);
    final isAbsent = registration.status == RegistrationStatus.cancelled;
    final icon = switch (registration.status) {
      RegistrationStatus.cancelled => Icons.cancel,
      RegistrationStatus.confirmed ||
      RegistrationStatus.completed => Icons.check_circle,
      RegistrationStatus.registered => Icons.help_outline,
    };
    final iconColor = switch (registration.status) {
      RegistrationStatus.cancelled => Colors.red,
      RegistrationStatus.confirmed ||
      RegistrationStatus.completed => Colors.green,
      RegistrationStatus.registered => Colors.orange,
    };
    final subtitle = switch (registration.status) {
      RegistrationStatus.cancelled => 'Absent',
      RegistrationStatus.confirmed || RegistrationStatus.completed => 'Présent',
      RegistrationStatus.registered => 'À confirmer',
    };

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(registration.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subtitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusToggleButton(
                label: 'PRÉSENT',
                selected: isPresent,
                enabled: !_saving,
                onPressed: () => _updateStatus(RegistrationStatus.confirmed),
              ),
              _StatusToggleButton(
                label: 'ABSENT',
                selected: isAbsent,
                enabled: !_saving,
                onPressed: () => _updateStatus(RegistrationStatus.cancelled),
              ),
            ],
          ),
          if (_saving) ...[
            const SizedBox(height: 8),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      trailing: _buildContactButton(context, registration.displayName),
    );
  }
}

class _StatusToggleButton extends StatelessWidget {
  const _StatusToggleButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      child: Text(label),
    );
  }
}

class _MemberContact {
  const _MemberContact({required this.phone, required this.email});

  final String? phone;
  final String? email;
}

_MemberContact? _resolveMemberContact({
  required Member? member,
  required MemberRegistration registration,
}) {
  final phone = _normalizedContactValue(member?.phone);
  final email =
      _normalizedContactValue(member?.email) ??
      _normalizedContactValue(registration.memberEmail);
  if (phone == null && email == null) {
    return null;
  }
  return _MemberContact(phone: phone, email: email);
}

String? _normalizedContactValue(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

class _BasketPickupSection extends StatelessWidget {
  const _BasketPickupSection({
    required this.org,
    required this.delivery,
    required this.contracts,
  });

  final Organization org;
  final Delivery delivery;
  final List<Contract> contracts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📦 Récupération des paniers',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final contract in delivery.contracts)
          _ContractBasketCard(
            org: org,
            deliveryId: delivery.deliveryId,
            contract: contract,
            productNames: org.productNamesForDeliveryContract(
              contract,
              contracts: contracts,
            ),
          ),
      ],
    );
  }
}

class _ContractBasketCard extends StatefulWidget {
  const _ContractBasketCard({
    required this.org,
    required this.deliveryId,
    required this.contract,
    required this.productNames,
  });

  final Organization org;
  final String deliveryId;
  final DeliveryContract contract;

  /// Product names attached to this contract, shown under the title so the
  /// coordinator sees which product each basket block concerns.
  final List<String> productNames;

  @override
  State<_ContractBasketCard> createState() => _ContractBasketCardState();
}

class _ContractBasketCardState extends State<_ContractBasketCard> {
  bool _saving = false;

  Future<void> _toggleCollected() async {
    if (_saving) return;
    setState(() => _saving = true);
    final newStatus =
        widget.contract.status == DeliveryContractStatus.distributed
        ? DeliveryContractStatus.pending
        : DeliveryContractStatus.distributed;
    try {
      await context.read<OrganizationRepository>().updateDeliveryContractStatus(
        currentOrg: widget.org,
        deliveryId: widget.deliveryId,
        contractId: widget.contract.contractId,
        newStatus: newStatus,
      );
      if (!mounted) return;
      context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.contract.basketQuantity;
    final isCollected =
        widget.contract.status == DeliveryContractStatus.distributed;
    final progress = total > 0 && isCollected ? 1.0 : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📦 ${widget.contract.deliveryDescription}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (widget.productNames.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Produits : ${widget.productNames.join(' + ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text('$total panier${total > 1 ? 's' : ''}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isCollected ? 'Collecté' : 'Non collecté'),
                if (_saving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _StatusToggleButton(
                    label: isCollected ? 'NON COLLECTÉ' : 'COLLECTÉ',
                    selected: isCollected,
                    enabled: true,
                    onPressed: _toggleCollected,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressionSection extends StatelessWidget {
  const _ProgressionSection({
    required this.delivery,
    this.mainContractIds = const {},
  });

  final Delivery delivery;

  /// Ids of the delivery's main contracts; only those drive the volunteer need
  /// (empty ⇒ legacy fallback that counts every contract).
  final Set<String> mainContractIds;

  /// Counts present registrations on a single slot, excluding coordinators.
  int _countPresentInSlot(MemberSlot slot, Set<String> coordinatorIds) {
    var count = 0;
    for (final reg in slot.registrations) {
      if (coordinatorIds.contains(reg.memberId)) continue;
      if (_isPresentStatus(reg.status)) count++;
    }
    return count;
  }

  /// Counts all present volunteers across the counting contracts, excluding
  /// coordinator registrations and cancelled slots.
  int _countPresentVolunteers(Set<String> coordinatorIds) {
    final mains = delivery.contracts
        .where((c) => mainContractIds.contains(c.contractId))
        .toList();
    final countingContracts = mains.isEmpty ? delivery.contracts : mains;
    var count = 0;
    for (final contract in countingContracts) {
      for (final slot in contract.slots) {
        if (slot.status == SlotStatus.cancelled) continue;
        count += _countPresentInSlot(slot, coordinatorIds);
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final requiredVolunteers = deliveryVolunteerStaffing(
      delivery,
      mainContractIds: mainContractIds,
    ).required;
    final coordinatorIds = deliveryCoordinatorIds(delivery);
    final presentVolunteers = _countPresentVolunteers(coordinatorIds);
    final volunteerProgress = requiredVolunteers > 0
        ? presentVolunteers / requiredVolunteers
        : 0.0;

    final totalContracts = delivery.contracts.length;
    final collectedContracts = delivery.contracts
        .where(
          (contract) => contract.status == DeliveryContractStatus.distributed,
        )
        .length;
    final contractProgress = totalContracts > 0
        ? collectedContracts / totalContracts
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📊 Progression', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bénévoles présents',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: volunteerProgress),
                const SizedBox(height: 4),
                Text('$presentVolunteers/$requiredVolunteers bénévoles'),
                const SizedBox(height: 16),
                Text(
                  'Contrats collectés',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: contractProgress),
                const SizedBox(height: 4),
                Text('$collectedContracts/$totalContracts contrats'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

bool _isPresentStatus(RegistrationStatus status) =>
    status == RegistrationStatus.confirmed ||
    status == RegistrationStatus.completed;
