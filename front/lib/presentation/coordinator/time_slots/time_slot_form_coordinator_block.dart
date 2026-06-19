import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Block showing one row per [DeliveryContract] with coordinator chips and
/// self-assign / admin-assign actions.
///
/// Spec: screen-coordinator-02-time-slots.md § "Coordinateurs par contrat".
class CoordinatorBlock extends StatelessWidget {
  const CoordinatorBlock({
    super.key,
    required this.delivery,
    required this.previewContractNames,
    required this.org,
    required this.me,
    required this.allMembers,
    required this.contracts,
  });

  /// The delivery whose contracts are displayed. Null in creation mode
  /// (before contracts exist).
  final Delivery? delivery;

  /// Contracts that will be linked on save (creation mode preview) — shown
  /// without coordinator actions, which require an existing delivery.
  final List<String> previewContractNames;
  final Organization org;
  final Member? me;
  final List<Member> allMembers;

  /// Season contract definitions — used to resolve each delivery-contract's
  /// [Contract.coordinators] pool, which constrains who can be assigned.
  final List<Contract> contracts;

  bool get _isAdmin => me?.roles.contains(Role.admin) ?? false;

  /// The coordinator pool of the [Contract] matching [contractId], or empty
  /// when the contract is not cached locally.
  List<String> _poolFor(String contractId) {
    for (final c in contracts) {
      if (c.contractId == contractId) return c.coordinators;
    }
    return const [];
  }

  /// Resolves the displayable contract name from the live [contracts] catalog
  /// by id, falling back to the link's denormalised
  /// [DeliveryContract.deliveryDescription] (which is blank on imported data).
  String _nameFor(DeliveryContract link) {
    for (final c in contracts) {
      if (c.contractId == link.contractId && c.name.trim().isNotEmpty) {
        return c.name;
      }
    }
    return link.deliveryDescription;
  }

  @override
  Widget build(BuildContext context) {
    final deliveryContracts = delivery?.contracts ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '👥 Coordinateurs par contrat',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (deliveryContracts.isNotEmpty)
          for (final contract in deliveryContracts)
            _ContractCoordinatorRow(
              contract: contract,
              contractName: _nameFor(contract),
              delivery: delivery!,
              org: org,
              me: me,
              allMembers: allMembers,
              isAdmin: _isAdmin,
              coordinatorPool: _poolFor(contract.contractId),
            )
        else if (previewContractNames.isNotEmpty)
          for (final name in previewContractNames)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aucun coordinateur',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
        else
          const Text('Aucun contrat encore défini.'),
      ],
    );
  }
}

/// One row in the coordinator block for a single [DeliveryContract].
class _ContractCoordinatorRow extends StatelessWidget {
  const _ContractCoordinatorRow({
    required this.contract,
    required this.contractName,
    required this.delivery,
    required this.org,
    required this.me,
    required this.allMembers,
    required this.isAdmin,
    required this.coordinatorPool,
  });

  final DeliveryContract contract;

  /// Resolved contract name (from the contracts catalog), used as the row
  /// header so the coordinator knows which contract each entry belongs to.
  final String contractName;
  final Delivery delivery;
  final Organization org;
  final Member? me;
  final List<Member> allMembers;
  final bool isAdmin;

  /// The linked [Contract.coordinators] pool — the effective coordinator(s)
  /// assigned for this delivery must be chosen among these members.
  final List<String> coordinatorPool;

  bool get _isActive => delivery.status.isActive;

  /// Whether the ✕ button should be enabled for [coordinatorId].
  ///
  /// ADMIN: active on any coordinator while the delivery is active.
  /// COORDINATOR non-ADMIN: only own entry, only while not IN_PROGRESS.
  bool _canRemove(String coordinatorId) {
    if (!_isActive) return false;
    if (isAdmin) return true;
    // Non-admin coordinator: own entry only, not IN_PROGRESS or beyond.
    if (me == null) return false;
    if (coordinatorId != me!.memberId) return false;
    return delivery.status != DeliveryStatus.inProgress &&
        delivery.status != DeliveryStatus.completed &&
        delivery.status != DeliveryStatus.cancelled;
  }

  bool get _canSelfAssign {
    if (!_isActive) return false;
    if (me == null) return false;
    // A coordinator may only stand for a contract they belong to (the pool).
    return coordinatorPool.contains(me!.memberId) &&
        !contract.coordinators.contains(me!.memberId);
  }

  /// Pool members not yet assigned on this delivery-contract — the candidates
  /// the ADMIN picker may add.
  List<String> get _assignablePoolMemberIds => coordinatorPool
      .where((id) => !contract.coordinators.contains(id))
      .toList();

  @override
  Widget build(BuildContext context) {
    final membersById = {for (final m in allMembers) m.memberId: m};

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contractName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (contract.coordinators.isEmpty)
            Text(
              'Aucun coordinateur',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            )
          else
            for (final id in contract.coordinators)
              _CoordinatorChip(
                coordinatorId: id,
                displayName: _resolveName(id, membersById),
                canRemove: _canRemove(id),
                onRemove: () => _removeCoordinator(context, id),
              ),
          const SizedBox(height: 4),
          // Self-assign button
          if (_canSelfAssign)
            OutlinedButton(
              onPressed: () => _selfAssign(context),
              child: const Text('ME PORTER COORDINATEUR'),
            )
          else if (me == null)
            const Tooltip(
              message: 'Chargement du compte…',
              child: OutlinedButton(
                onPressed: null,
                child: Text('ME PORTER COORDINATEUR'),
              ),
            ),
          // Admin add button — only when the contract pool has an
          // assignable (not-yet-assigned) coordinator.
          if (isAdmin && _isActive && _assignablePoolMemberIds.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _showAdminPicker(context, membersById),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un coordinateur'),
            ),
        ],
      ),
    );
  }

  String _resolveName(String memberId, Map<String, Member> membersById) {
    final member = membersById[memberId];
    if (member == null) return memberId;
    final first = member.firstName?.trim() ?? '';
    final last = member.lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return memberId;
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  void _selfAssign(BuildContext context) {
    if (me == null) return;
    final orgRepo = context.read<OrganizationRepository>();
    final syncBloc = context.read<SyncBloc>();
    orgRepo
        .assignCoordinatorById(
          organizationId: org.organizationId,
          deliveryId: delivery.deliveryId,
          contractId: contract.contractId,
          memberId: me!.memberId,
        )
        .then((_) => syncBloc.add(const SyncEvent.mutationApplied()));
  }

  void _removeCoordinator(BuildContext context, String coordinatorId) {
    final orgRepo = context.read<OrganizationRepository>();
    final syncBloc = context.read<SyncBloc>();
    orgRepo
        .unassignCoordinatorById(
          organizationId: org.organizationId,
          deliveryId: delivery.deliveryId,
          contractId: contract.contractId,
          memberId: coordinatorId,
        )
        .then((_) => syncBloc.add(const SyncEvent.mutationApplied()));
  }

  void _showAdminPicker(BuildContext context, Map<String, Member> membersById) {
    // Restrict to the contract's coordinator pool, excluding members already
    // assigned on this delivery-contract.
    final coordinators = _assignablePoolMemberIds
        .map((id) => membersById[id])
        .whereType<Member>()
        .toList();

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _AdminCoordinatorPickerSheet(
        coordinators: coordinators,
        onSelected: (memberId) {
          Navigator.of(sheetContext).pop();
          final orgRepo = context.read<OrganizationRepository>();
          final syncBloc = context.read<SyncBloc>();
          orgRepo
              .assignCoordinatorById(
                organizationId: org.organizationId,
                deliveryId: delivery.deliveryId,
                contractId: contract.contractId,
                memberId: memberId,
              )
              .then((_) => syncBloc.add(const SyncEvent.mutationApplied()));
        },
      ),
    );
  }
}

/// A chip displaying one coordinator's name with an optional ✕ button.
class _CoordinatorChip extends StatelessWidget {
  const _CoordinatorChip({
    required this.coordinatorId,
    required this.displayName,
    required this.canRemove,
    required this.onRemove,
  });

  final String coordinatorId;
  final String displayName;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(displayName),
        IconButton(
          icon: const Icon(Icons.close),
          iconSize: 16,
          splashRadius: 16,
          // null onPressed disables the button visually.
          onPressed: canRemove ? onRemove : null,
          tooltip: canRemove ? 'Retirer' : null,
        ),
      ],
    );
}

/// Bottom sheet for ADMIN to pick a coordinator from the AMAP roster.
class _AdminCoordinatorPickerSheet extends StatelessWidget {
  const _AdminCoordinatorPickerSheet({
    required this.coordinators,
    required this.onSelected,
  });

  final List<Member> coordinators;
  final ValueChanged<String> onSelected;

  String _name(Member m) {
    final first = m.firstName?.trim() ?? '';
    final last = m.lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return m.memberId;
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Ajouter un coordinateur',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (coordinators.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun coordinateur dans cette AMAP.'),
            )
          else
            for (final coordinator in coordinators)
              ListTile(
                title: Text(_name(coordinator)),
                onTap: () => onSelected(coordinator.memberId),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
}
