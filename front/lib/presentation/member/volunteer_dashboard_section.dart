import 'dart:async';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_card.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Volunteer / member section of the unified dashboard.
///
/// Mirrors `documentation/feature/fr/ui/member/screen-member-01-home.md`.
/// Sections (in spec order):
///   1. 🎯 Ma prochaine participation — only when the member has an upcoming
///      registered delivery.
///   2. 📋 Prochaines livraisons — up to 5 upcoming active deliveries.
///   3. 📊 Mon historique — participation count + last participation date.
///   4. Footer buttons — [VOIR PLANNING COMPLET] / [MON HISTORIQUE].
class VolunteerDashboardSection extends StatefulWidget {
  const VolunteerDashboardSection({required this.tenantId, super.key});

  final String tenantId;

  @override
  State<VolunteerDashboardSection> createState() =>
      _VolunteerDashboardSectionState();
}

class _VolunteerDashboardSectionState extends State<VolunteerDashboardSection> {
  StreamSubscription<Organization?>? _orgSub;
  StreamSubscription<Member?>? _memberSub;
  StreamSubscription<List<Member>>? _allMembersSub;
  StreamSubscription<List<DeliveryTemplate>>? _templatesSub;

  Organization? _org;
  Member? _member;
  List<Member> _allMembers = const [];
  List<DeliveryTemplate> _templates = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  @override
  void didUpdateWidget(VolunteerDashboardSection oldWidget) {
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
      setState(() {
        _loading = true;
        _org = null;
        _member = null;
        _allMembers = const [];
        _templates = const [];
      });
      return;
    }

    final sub = _resolveSub();
    final orgRepo = context.read<OrganizationRepository>();
    final memberRepo = context.read<MemberRepository>();
    final templateRepo = context.read<DeliveryTemplateRepository>();

    _orgSub = orgRepo.watch(widget.tenantId).listen((org) {
      if (mounted) {
        setState(() {
          _org = org;
          _loading = false;
        });
      }
    });

    _memberSub = memberRepo.watchMyMember(sub).listen((member) {
      if (mounted) {
        setState(() {
          _member = member;
        });
      }
    });

    _allMembersSub = memberRepo.watch(widget.tenantId).listen((members) {
      if (mounted) {
        setState(() {
          _allMembers = members;
        });
      }
    });

    _templatesSub = templateRepo.watch(widget.tenantId).listen((templates) {
      if (mounted) setState(() => _templates = templates);
    });
  }

  void _cancelStreams() {
    _orgSub?.cancel();
    _memberSub?.cancel();
    _allMembersSub?.cancel();
    _templatesSub?.cancel();
    _orgSub = null;
    _memberSub = null;
    _allMembersSub = null;
    _templatesSub = null;
    _loading = true;
    _org = null;
    _member = null;
    _allMembers = const [];
    _templates = const [];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty || _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final org = _org;
    if (org == null) {
      return const Center(child: Text('Synchronisation en cours...'));
    }

    final member = _member;
    if (member == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (_, curr) =>
          curr is SyncSucceeded && curr.rejectedMutations.isNotEmpty,
      listener: (context, state) {
        if (state is! SyncSucceeded) return;
        final rejected = state.rejectedMutations;
        if (rejected.isEmpty) return;
        // V1 limitation: surface a generic rejection message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "L'inscription n'a pas pu être enregistrée. Réessayez.",
            ),
          ),
        );
      },
      child: _SectionBody(
        org: org,
        member: member,
        membersById: {for (final m in _allMembers) m.memberId: m},
        templates: _templates,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.org,
    required this.member,
    required this.membersById,
    required this.templates,
  });

  final Organization org;
  final Member member;
  final Map<String, Member> membersById;
  final List<DeliveryTemplate> templates;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final memberId = member.memberId;

    final nextRegistered = nextRegistrationFor(org, memberId, now: now);
    final upcoming = upcomingActiveDeliveries(org, now, limit: 5);

    // Dashboard uses calendar-year scope for a quick participation count.
    // The detailed history screen uses contract-season scoping instead.
    final thisYear = now.year;
    final completedCount = _completedInYear(org, memberId, thisYear);
    final lastCompleted = lastCompletedDelivery(org, memberId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Section 1: Ma prochaine participation ---
        if (nextRegistered != null) ...[
          const _SectionHeader(title: '🎯 Ma prochaine participation'),
          DeliveryCard(
            delivery: nextRegistered,
            member: member,
            org: org,
            membersById: membersById,
            variant: DeliveryCardVariant.dashboard,
            template: _templateForDelivery(nextRegistered),
            highlightAsNextParticipation: true,
          ),
          const SizedBox(height: 16),
        ],

        // --- Section 2: Prochaines livraisons ---
        const _SectionHeader(title: '📋 Prochaines livraisons'),
        if (upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Aucune livraison à venir.'),
          )
        else
          for (final delivery in upcoming)
            DeliveryCard(
              delivery: delivery,
              member: member,
              org: org,
              membersById: membersById,
              variant: DeliveryCardVariant.dashboard,
              template: _templateForDelivery(delivery),
            ),
        const SizedBox(height: 16),

        // --- Section 3: Mon historique ---
        if (completedCount > 0 || lastCompleted != null) ...[
          const _SectionHeader(title: '📊 Mon historique'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '• $completedCount '
              'participation${completedCount > 1 ? 's' : ''} cette saison',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (lastCompleted != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• Dernière participation : '
                '${_formatHistoryDate(lastCompleted.scheduledDate)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 16),
        ],

        // --- Footer buttons ---
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/planning'),
                icon: const Text('📅'),
                label: const Text('VOIR PLANNING COMPLET'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/history'),
                icon: const Text('📋'),
                label: const Text('MON HISTORIQUE'),
              ),
            ),
          ],
        ),
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

  String _formatHistoryDate(String scheduledDate) {
    final date = DateTime.parse(scheduledDate);
    return DateFormat('d MMM yyyy', 'fr').format(date);
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Counts completed registrations for [memberId] in [org] filtered by
/// calendar [year]. Used only by the dashboard quick-count; the history
/// screen uses contract-season scoping via [completedRegistrationsInSeason].
int _completedInYear(Organization org, String memberId, int year) {
  var count = 0;
  for (final delivery in org.deliveries) {
    final deliveryYear = DateTime.parse(delivery.scheduledDate).year;
    if (deliveryYear != year) continue;
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (reg.memberId == memberId &&
              reg.status == RegistrationStatus.completed) {
            count++;
          }
        }
      }
    }
  }
  return count;
}
