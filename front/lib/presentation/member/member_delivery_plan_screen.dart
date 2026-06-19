import 'dart:async';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_card.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Monthly delivery planning screen for volunteer (Amapien) members.
///
/// Mirrors `documentation/feature/fr/ui/member/screen-member-02-delivery-plan.md`.
///
/// Shows all deliveries for the selected month, chronologically sorted, with
/// per-delivery registration/unregistration actions. Supports EARLY+STANDARD
/// two-button layout when both slots have capacity.
const _kPlanningTitle = 'Planning des livraisons';

class MemberDeliveryPlanScreen extends StatefulWidget {
  const MemberDeliveryPlanScreen({
    super.key,
    required this.tenantId,
    @visibleForTesting this.initialMonth,
  });

  final String tenantId;

  /// Overrides the initial selected month. Used by widget tests only so that
  /// deliveries at a specific future date are shown without navigating.
  @visibleForTesting
  final DateTime? initialMonth;

  @override
  State<MemberDeliveryPlanScreen> createState() =>
      _MemberDeliveryPlanScreenState();
}

class _MemberDeliveryPlanScreenState extends State<MemberDeliveryPlanScreen> {
  late DateTime _selectedMonth;
  bool _autoMonthAdjusted = false;

  StreamSubscription<Organization?>? _orgSub;
  StreamSubscription<Member?>? _memberSub;
  StreamSubscription<List<DeliveryTemplate>>? _templatesSub;
  StreamSubscription<List<Member>>? _allMembersSub;
  StreamSubscription<List<Contract>>? _contractsSub;

  Organization? _org;
  Member? _member;
  List<DeliveryTemplate> _templates = const [];
  List<Member> _allMembers = const [];
  List<Contract> _contracts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth;
    if (initial != null) {
      _selectedMonth = DateTime(initial.year, initial.month);
    } else {
      final now = DateTime.now();
      _selectedMonth = DateTime(now.year, now.month);
    }
    _startStreams();
  }

  @override
  void didUpdateWidget(MemberDeliveryPlanScreen oldWidget) {
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
    if (widget.tenantId.isEmpty) {
      _resetState();
      return;
    }

    final sub = _resolveSub();
    final orgRepo = context.read<OrganizationRepository>();
    final memberRepo = context.read<MemberRepository>();
    final templateRepo = context.read<DeliveryTemplateRepository>();
    final contractRepo = context.read<ContractRepository>();

    _orgSub = orgRepo.watch(widget.tenantId).listen((org) {
      _updateState(() {
        _org = org;
        _loading = false;
        if (org != null && !_autoMonthAdjusted && widget.initialMonth == null) {
          _selectedMonth = defaultPlanningMonth(org, DateTime.now());
          _autoMonthAdjusted = true;
        }
      });
    });

    _memberSub = memberRepo.watchMyMember(sub).listen((member) {
      _updateState(() {
        _member = member;
      });
    });

    _templatesSub = templateRepo.watch(widget.tenantId).listen((templates) {
      _updateState(() {
        _templates = templates;
      });
    });

    _allMembersSub = memberRepo.watch(widget.tenantId).listen((members) {
      _updateState(() {
        _allMembers = members;
      });
    });

    _contractsSub = contractRepo.watch(widget.tenantId).listen((contracts) {
      _updateState(() {
        _contracts = contracts;
      });
    });
  }

  void _resetState() {
    setState(() {
      _loading = true;
      _org = null;
      _member = null;
      _templates = const [];
      _allMembers = const [];
      _contracts = const [];
    });
  }

  void _updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _cancelStreams() {
    _orgSub?.cancel();
    _memberSub?.cancel();
    _templatesSub?.cancel();
    _allMembersSub?.cancel();
    _contractsSub?.cancel();
    _orgSub = null;
    _memberSub = null;
    _templatesSub = null;
    _allMembersSub = null;
    _contractsSub = null;
    _loading = true;
    _autoMonthAdjusted = false;
    _org = null;
    _member = null;
    _templates = const [];
    _allMembers = const [];
    _contracts = const [];
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: _kPlanningTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loading) {
      return const ConnectedScaffold(
        title: _kPlanningTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final org = _org;
    if (org == null) {
      return const ConnectedScaffold(
        title: _kPlanningTitle,
        body: Center(child: Text('Synchronisation en cours...')),
      );
    }

    final member = _member;
    if (member == null) {
      return const ConnectedScaffold(
        title: _kPlanningTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ConnectedScaffold(
      title: _kPlanningTitle,
      body: BlocListener<SyncBloc, SyncState>(
        listenWhen: (_, curr) =>
            curr is SyncSucceeded && curr.rejectedMutations.isNotEmpty,
        listener: (context, state) {
          if (state is! SyncSucceeded) return;
          if (state.rejectedMutations.isEmpty) return;
          // V1 limitation: surface a generic rejection SnackBar.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("L'inscription n'a pas pu être enregistrée."),
            ),
          );
        },
        child: _PlanBody(
          org: org,
          member: member,
          templates: _templates,
          membersById: {for (final m in _allMembers) m.memberId: m},
          contractsById: {for (final c in _contracts) c.contractId: c},
          selectedMonth: _selectedMonth,
          onPrev: _prevMonth,
          onNext: _nextMonth,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.org,
    required this.member,
    required this.templates,
    required this.membersById,
    required this.contractsById,
    required this.selectedMonth,
    required this.onPrev,
    required this.onNext,
  });

  final Organization org;
  final Member member;
  final List<DeliveryTemplate> templates;
  final Map<String, Member> membersById;

  /// Season contracts of the AMAP — used to hide/flag deliveries whose
  /// contracts are not yet active.
  final Map<String, Contract> contractsById;
  final DateTime selectedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final canManage =
        member.roles.contains(Role.coordinator) ||
        member.roles.contains(Role.admin);
    final isCoordinator = member.roles.contains(Role.coordinator);
    final deliveries =
        org.deliveries.where((d) {
          final date = DateTime.parse(d.scheduledDate);
          if (date.year != selectedMonth.year ||
              date.month != selectedMonth.month) {
            return false;
          }
          // Deliveries of not-yet-active contracts are hidden from plain
          // members; coordinators/admins see them flagged "Contrat inactif".
          return canManage ||
              !isDeliveryPendingContractActivation(d, contractsById);
        }).toList()..sort(
          (a, b) => DateTime.parse(
            a.scheduledDate,
          ).compareTo(DateTime.parse(b.scheduledDate)),
        );

    // Build the month navigation labels including prev/next month names.
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);

    final prevLabel =
        '← ${_capitalise(DateFormat('MMM yyyy', 'fr').format(prevMonth))}';
    final currentLabel = _capitalise(
      DateFormat('MMMM yyyy', 'fr').format(selectedMonth),
    );
    final nextLabel =
        '${_capitalise(DateFormat('MMM yyyy', 'fr').format(nextMonth))} →';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                label: Text(prevLabel),
              ),
              Text(
                currentLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                label: Text(nextLabel),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '📋 Livraisons ce mois',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: deliveries.isEmpty
              ? const Center(child: Text('Aucune livraison ce mois-ci.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = deliveries[index];
                    final template = _templateForDelivery(delivery);
                    return DeliveryCard(
                      delivery: delivery,
                      member: member,
                      org: org,
                      membersById: membersById,
                      variant: DeliveryCardVariant.planning,
                      template: template,
                      showFollowButton: isCoordinator,
                      contracts: contractsById.values.toList(),
                      pendingContractActivation:
                          isDeliveryPendingContractActivation(
                            delivery,
                            contractsById,
                          ),
                    );
                  },
                ),
        ),
        const _PlanFooter(),
      ],
    );
  }

  DeliveryTemplate? _templateForDelivery(Delivery delivery) {
    final id = delivery.deliveryTemplateId;
    if (id == null) return null;
    try {
      return templates.firstWhere((t) => t.deliveryTemplateId == id);
    } catch (_) {
      return null;
    }
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _PlanFooter extends StatelessWidget {
  const _PlanFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Text('🏠'),
              label: const Text('ACCUEIL'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/history'),
              icon: const Text('📊'),
              label: const Text('MON HISTORIQUE'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            // V1: AIDE not yet implemented.
            child: Tooltip(
              message: 'À venir',
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Text('ℹ️'),
                label: const Text('AIDE'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
