import 'dart:async';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_display.dart';
import 'package:amap_en_ligne/presentation/coordinator/delivery_volunteer_summary.dart';
import 'package:amap_en_ligne/presentation/coordinator/missing_coordinator_listener.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_format.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_status_chip.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Coordinator section of the unified dashboard.
///
/// Renders the "Nouveau créneau" action, in-progress deliveries, and the
/// next five upcoming deliveries with self-assign capability when a contract
/// has no coordinator yet.
class CoordinatorDashboardSection extends StatefulWidget {
  const CoordinatorDashboardSection({required this.tenantId, super.key});

  final String tenantId;

  @override
  State<CoordinatorDashboardSection> createState() =>
      _CoordinatorDashboardSectionState();
}

class _CoordinatorDashboardSectionState
    extends State<CoordinatorDashboardSection> {
  StreamSubscription<Organization?>? _orgSub;
  StreamSubscription<List<Member>>? _allMembersSub;
  StreamSubscription<Member?>? _meSub;

  Organization? _org;
  Map<String, Member> _membersById = const {};
  Member? _me;

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  @override
  void didUpdateWidget(CoordinatorDashboardSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenantId != widget.tenantId) {
      _cancelStreams();
      _startStreams();
    }
  }

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }

  void _cancelStreams() {
    _orgSub?.cancel();
    _allMembersSub?.cancel();
    _meSub?.cancel();
  }

  String _resolveSub() {
    final authService = context.read<AuthService>();
    final state = authService.currentState;
    if (state is! Authenticated) return '';
    try {
      final claims = JwtClaims.decode(state.accessToken);
      return claims.string('sub') ?? '';
    } catch (_) {
      return '';
    }
  }

  void _startStreams() {
    if (widget.tenantId.isEmpty) return;
    final orgRepo = context.read<OrganizationRepository>();
    final memberRepo = context.read<MemberRepository>();

    _orgSub = orgRepo.watch(widget.tenantId).listen((org) {
      if (mounted) setState(() => _org = org);
    });

    _allMembersSub = memberRepo.watch(widget.tenantId).listen((members) {
      if (mounted) {
        setState(() {
          _membersById = {for (final m in members) m.memberId: m};
        });
      }
    });

    final sub = _resolveSub();
    if (sub.isNotEmpty) {
      _meSub = memberRepo.watchMyMember(sub).listen((me) {
        if (mounted) setState(() => _me = me);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_org == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MissingCoordinatorListener(
      org: _org,
      child: _SectionBody(org: _org!, membersById: _membersById, me: _me),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.org,
    required this.membersById,
    required this.me,
  });

  final Organization org;
  final Map<String, Member> membersById;
  final Member? me;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final inProgress =
        org.deliveries
            .where((d) => d.status == DeliveryStatus.inProgress)
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              a.scheduledDate,
            ).compareTo(DateTime.parse(b.scheduledDate)),
          );

    final upcoming =
        org.deliveries
            .where(
              (d) =>
                  d.status.isActive &&
                  d.status != DeliveryStatus.inProgress &&
                  DateTime.parse(d.scheduledDate).isAfter(now),
            )
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              a.scheduledDate,
            ).compareTo(DateTime.parse(b.scheduledDate)),
          );
    final nextFive = upcoming.take(5).toList();

    final isEmpty = inProgress.isEmpty && nextFive.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () => context.push('/coordinator/time-slots/new'),
            child: const Text('➕ NOUVEAU CRÉNEAU'),
          ),
        ),
        const SizedBox(height: 16),
        if (isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Aucune livraison active.')),
          )
        else ...[
          if (inProgress.isNotEmpty) ...[
            const _SectionHeader(title: 'Livraisons en cours'),
            for (final delivery in inProgress)
              _DeliveryCard(
                delivery: delivery,
                membersById: membersById,
                org: org,
                me: me,
              ),
            const SizedBox(height: 16),
          ],
          if (nextFive.isNotEmpty) ...[
            const _SectionHeader(title: 'Prochaines livraisons'),
            for (final delivery in nextFive)
              _DeliveryCard(
                delivery: delivery,
                membersById: membersById,
                org: org,
                me: me,
              ),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.delivery,
    required this.membersById,
    required this.org,
    required this.me,
  });

  final Delivery delivery;

  /// Map of all AMAP members — used for compact coordinator display.
  final Map<String, Member> membersById;

  final Organization org;
  final Member? me;

  @override
  Widget build(BuildContext context) {
    final title = formatDeliveryDateTime(delivery.scheduledDate);
    final summary = deliveryVolunteerSummary(delivery);

    // Compact coordinator line: "J. Morel · —"
    // V1: no per-contract emoji yet; spec uses 🥕/🍞 as illustrations.
    final coordinatorParts = delivery.contracts
        .map((c) => formatCoordinatorsCompact(c, membersById))
        .join(' · ');

    // Contracts missing a coordinator — shown in warning banner.
    final missingContracts = delivery.contracts
        .where((c) => c.coordinators.isEmpty)
        .map((c) => c.deliveryDescription)
        .toList();

    // Whether [ME PORTER COORDINATEUR] should be shown:
    //   - delivery is active
    //   - at least one contract is empty
    //   - the connected member is not already coordinator on ALL empty contracts
    final showSelfAssign =
        delivery.status.isActive && missingContracts.isNotEmpty && me != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/coordinator/tracking/${delivery.deliveryId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              DeliveryStatusChip(status: delivery.status),
              const SizedBox(height: 4),
              Text('${summary.current}/${summary.required} bénévoles'),
              if (delivery.contracts.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '👥 Coord. : $coordinatorParts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              if (missingContracts.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '⚠️ Coordinateur manquant : ${missingContracts.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (showSelfAssign ||
                  (me == null && missingContracts.isNotEmpty)) ...[
                const SizedBox(height: 8),
                _SelfAssignButton(delivery: delivery, org: org, me: me),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Button shown on a delivery card when the connected coordinator is not yet
/// assigned on at least one contract.
class _SelfAssignButton extends StatelessWidget {
  const _SelfAssignButton({
    required this.delivery,
    required this.org,
    required this.me,
  });

  final Delivery delivery;
  final Organization org;
  final Member? me;

  @override
  Widget build(BuildContext context) {
    // me == null: still loading — disable with tooltip.
    if (me == null) {
      return const Tooltip(
        message: 'Chargement du compte…',
        child: OutlinedButton(
          onPressed: null,
          child: Text('ME PORTER COORDINATEUR'),
        ),
      );
    }

    final emptyContracts = delivery.contracts
        .where((c) => c.coordinators.isEmpty)
        .toList();

    if (emptyContracts.isEmpty) return const SizedBox.shrink();

    return OutlinedButton(
      onPressed: () => _onTap(context, emptyContracts),
      child: const Text('ME PORTER COORDINATEUR'),
    );
  }

  void _onTap(BuildContext context, List<DeliveryContract> emptyContracts) {
    if (emptyContracts.length == 1) {
      _assign(context, emptyContracts.first.contractId);
      return;
    }
    // Multiple empty contracts — let the coordinator choose.
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _ContractPickerSheet(
        contracts: emptyContracts,
        onSelected: (contractId) {
          Navigator.of(sheetContext).pop();
          _assign(context, contractId);
        },
      ),
    );
  }

  void _assign(BuildContext context, String contractId) {
    final orgRepo = context.read<OrganizationRepository>();
    final syncBloc = context.read<SyncBloc>();
    orgRepo
        .assignCoordinator(
          currentOrg: org,
          deliveryId: delivery.deliveryId,
          contractId: contractId,
          memberId: me!.memberId,
        )
        .then((_) => syncBloc.add(const SyncEvent.mutationApplied()));
  }
}

/// Bottom sheet listing delivery contracts that still need a coordinator.
class _ContractPickerSheet extends StatelessWidget {
  const _ContractPickerSheet({
    required this.contracts,
    required this.onSelected,
  });

  final List<DeliveryContract> contracts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Choisir le contrat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final contract in contracts)
            ListTile(
              title: Text(contract.deliveryDescription),
              onTap: () => onSelected(contract.contractId),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
