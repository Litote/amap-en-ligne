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
import 'package:amap_en_ligne/presentation/common/error_feedback.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_card.dart';
import 'package:amap_en_ligne/presentation/delivery/registration_rejection.dart';
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
    } on Exception catch (e) {
      recordFallbackBreadcrumb('JWT sub decode failed', e);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                registrationRejectionMessage(state.rejectedMutations),
              ),
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

    // Same full month format everywhere; the chevron icons show the direction.
    // On a phone the neighbouring months drop the year so every label keeps a
    // readable size instead of being scaled down.
    final isNarrow = MediaQuery.sizeOf(context).width < _narrowWidth;
    String monthLabel(DateTime month, {bool withYear = true}) => _capitalise(
      DateFormat(withYear ? 'MMMM yyyy' : 'MMMM', 'fr').format(month),
    );
    final prevLabel = monthLabel(prevMonth, withYear: !isNarrow);
    final currentLabel = monthLabel(selectedMonth);
    final nextLabel = monthLabel(nextMonth, withYear: !isNarrow);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // Labels shrink (never wrap) so the three parts and both
            // chevrons always fit, even on a phone.
            children: [
              Flexible(
                child: TextButton.icon(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                  label: _OneLine(prevLabel),
                ),
              ),
              Flexible(
                child: _OneLine(
                  currentLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: TextButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                  label: _OneLine(nextLabel),
                  iconAlignment: IconAlignment.end,
                ),
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
    return templates.where((t) => t.deliveryTemplateId == id).firstOrNull;
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
    // On a phone the icon sits above a shorter label: three side-by-side
    // "icon + MON HISTORIQUE" buttons only fit by shrinking the text to an
    // unreadable size.
    final isNarrow = MediaQuery.sizeOf(context).width < _narrowWidth;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _FooterButton(
              onPressed: () => context.go('/'),
              icon: '🏠',
              label: 'ACCUEIL',
              stacked: isNarrow,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterButton(
              onPressed: () => context.go('/history'),
              icon: '📊',
              label: isNarrow ? 'HISTORIQUE' : 'MON HISTORIQUE',
              stacked: isNarrow,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterButton(
              onPressed: () => context.go('/help'),
              icon: 'ℹ️',
              label: 'AIDE',
              stacked: isNarrow,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.stacked,
  });

  final VoidCallback onPressed;
  final String icon;
  final String label;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    if (!stacked) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Text(icon),
        label: _OneLine(label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(icon), _OneLine(label)],
      ),
    );
  }
}

/// Below this width (a phone) the month navigation and the footer switch to
/// their compact layout.
const double _narrowWidth = 480;

/// Single-line label that scales down instead of wrapping (a narrow button
/// would otherwise break the word in the middle, e.g. "ACCUEI L").
class _OneLine extends StatelessWidget {
  const _OneLine(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, style: style, maxLines: 1, softWrap: false),
  );
}
