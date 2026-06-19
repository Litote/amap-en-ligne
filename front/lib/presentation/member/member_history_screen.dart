import 'dart:async';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Personal participation history screen for volunteer (Amapien) members.
///
/// Mirrors `documentation/feature/fr/ui/member/screen-member-03-history.md`.
///
/// Shows:
///   1. Season header — "Saison YEAR" derived from active contracts.
///   2. Stats card — total participations (season-scoped), rank, last
///      participation, activity status.
///   3. Upcoming commitments — future deliveries where the member is registered.
///   4. Completed participations — past COMPLETED registrations, desc order.
///   5. Monthly histogram — months in the current season.
///   6. Footer — PLANNING (active), Participations globales -> /history/ranking.
const _kHistoryTitle = 'Mon historique bénévole';

class MemberHistoryScreen extends StatefulWidget {
  const MemberHistoryScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  State<MemberHistoryScreen> createState() => _MemberHistoryScreenState();
}

class _MemberHistoryScreenState extends State<MemberHistoryScreen> {
  StreamSubscription<Organization?>? _orgSub;
  StreamSubscription<Member?>? _memberSub;
  StreamSubscription<List<Member>>? _allMembersSub;
  StreamSubscription<List<Contract>>? _contractsSub;

  Organization? _org;
  Member? _me;
  List<Member> _allMembers = const [];
  List<Contract> _contracts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  @override
  void didUpdateWidget(MemberHistoryScreen oldWidget) {
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
        _me = null;
        _allMembers = const [];
        _contracts = const [];
      });
      return;
    }

    final sub = _resolveSub();
    final orgRepo = context.read<OrganizationRepository>();
    final memberRepo = context.read<MemberRepository>();
    final contractRepo = context.read<ContractRepository>();

    _orgSub = orgRepo.watch(widget.tenantId).listen((org) {
      if (mounted) {
        setState(() {
          _org = org;
          _loading = false;
        });
      }
    });

    _memberSub = memberRepo.watchMyMember(sub).listen((member) {
      if (mounted) setState(() => _me = member);
    });

    _allMembersSub = memberRepo.watch(widget.tenantId).listen((members) {
      if (mounted) setState(() => _allMembers = members);
    });

    _contractsSub = contractRepo.watch(widget.tenantId).listen((contracts) {
      if (mounted) setState(() => _contracts = contracts);
    });
  }

  void _cancelStreams() {
    _orgSub?.cancel();
    _memberSub?.cancel();
    _allMembersSub?.cancel();
    _contractsSub?.cancel();
    _orgSub = null;
    _memberSub = null;
    _allMembersSub = null;
    _contractsSub = null;
    _loading = true;
    _org = null;
    _me = null;
    _allMembers = const [];
    _contracts = const [];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty || _loading) {
      return const ConnectedScaffold(
        title: _kHistoryTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final org = _org;
    final me = _me;

    if (org == null || me == null) {
      return const ConnectedScaffold(
        title: _kHistoryTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ConnectedScaffold(
      title: _kHistoryTitle,
      body: _HistoryBody(
        org: org,
        me: me,
        allMembers: _allMembers,
        contracts: _contracts,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.org,
    required this.me,
    required this.allMembers,
    required this.contracts,
  });

  final Organization org;
  final Member me;
  final List<Member> allMembers;
  final List<Contract> contracts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final memberId = me.memberId;

    final seasonYear = currentSeasonYear(contracts, now);
    final contractIds = seasonContractIds(contracts, seasonYear);

    final upcoming = personalUpcomingRegistrations(org, memberId, now);
    final completed = personalCompletedRegistrations(org, memberId);

    // Empty state: no registrations at all (past or future).
    if (upcoming.isEmpty && completed.isEmpty) {
      return _EmptyHistoryView();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SeasonHeader(contracts: contracts, seasonYear: seasonYear, now: now),
        const SizedBox(height: 16),
        _StatsCard(
          org: org,
          memberId: memberId,
          allMembers: allMembers,
          seasonContractIds: contractIds,
        ),
        const SizedBox(height: 16),
        Text(
          '📋 Historique détaillé',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          '⭕ Engagements à venir',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Aucun engagement à venir.'),
          )
        else
          for (final entry in upcoming)
            _UpcomingCard(delivery: entry.delivery, selfMemberId: memberId),
        const SizedBox(height: 8),
        Text(
          '✅ Participations réalisées',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (completed.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Aucune participation réalisée.'),
          )
        else
          for (final entry in completed)
            _CompletedCard(delivery: entry.delivery),
        const SizedBox(height: 8),
        _MonthlyBarChart(
          org: org,
          memberId: memberId,
          contracts: contracts,
          seasonContractIds: contractIds,
        ),
        const SizedBox(height: 8),
        _HistoryFooter(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Season header
// ---------------------------------------------------------------------------

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader({
    required this.contracts,
    required this.seasonYear,
    required this.now,
  });

  final List<Contract> contracts;
  final int seasonYear;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final label = seasonLabel(contracts, seasonYear, now);
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Retour Accueil'),
        ),
        const Spacer(),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats card
// ---------------------------------------------------------------------------

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.org,
    required this.memberId,
    required this.allMembers,
    required this.seasonContractIds,
  });

  final Organization org;
  final String memberId;
  final List<Member> allMembers;
  final Set<String> seasonContractIds;

  @override
  Widget build(BuildContext context) {
    final totalCount = completedRegistrationsInSeason(
      org,
      memberId,
      seasonContractIds,
    );

    final registrationsCount = seasonRegistrationsCount(
      org,
      memberId,
      seasonContractIds,
    );

    // Rank denominator: only ACTIVE members (ACTIVE account status or legacy
    // activeStatus=true). Terminated/suspended members are excluded.
    final activeMembers = allMembers.where((m) {
      final status = m.accountStatus;
      if (status != null) return status == MemberAccountStatus.active;
      return m.activeStatus;
    });
    final rankResult = memberRankIn(
      org,
      activeMembers,
      memberId,
      seasonContractIds,
    );

    final lastDelivery = lastCompletedDeliveryInSeason(
      org,
      memberId,
      seasonContractIds,
    );
    final lastDateLabel = lastDelivery != null
        ? _formatLastDate(lastDelivery.scheduledDate)
        : '—';

    final activity = memberActivityStatus(org, memberId, seasonContractIds);
    final activityLabel = switch (activity) {
      MemberActivityStatus.active => 'Membre actif',
      MemberActivityStatus.occasional => 'Occasionnel',
      MemberActivityStatus.inactive => 'Inactif',
    };

    // Rank label with ex-aequo support.
    // null → member not in activeMembers (e.g. suspended) → display '—'.
    final String rankLabel;
    if (rankResult == null) {
      rankLabel = '—';
    } else if (rankResult.tied) {
      rankLabel =
          '${_ordinal(rankResult.rank)} ex-aequo / ${rankResult.total} membres';
    } else {
      rankLabel = '${_ordinal(rankResult.rank)} / ${rankResult.total} membres';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Mes statistiques',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Text('📈 Total participations : $totalCount'),
            const SizedBox(height: 4),
            Text('📝 Inscriptions cette saison : $registrationsCount'),
            const SizedBox(height: 4),
            Text('🏆 Rang dans l\'Amap : $rankLabel'),
            const SizedBox(height: 4),
            Text('📅 Dernière participation : $lastDateLabel'),
            const SizedBox(height: 4),
            Text('⭐ Statut : $activityLabel'),
          ],
        ),
      ),
    );
  }

  /// French ordinal suffix: 1 → "1er", 2 → "2ème", 3 → "3ème", etc.
  String _ordinal(int n) {
    if (n == 1) return '1er';
    // ignore: unnecessary_brace_in_string_interps
    return '${n}ème';
  }

  /// Format the last participation date as "d MMMM yyyy" in French.
  String _formatLastDate(String scheduledDate) {
    try {
      final date = DateTime.parse(scheduledDate);
      return DateFormat('d MMMM yyyy', 'fr').format(date);
    } catch (_) {
      return scheduledDate;
    }
  }
}

// ---------------------------------------------------------------------------
// Upcoming commitment card
// ---------------------------------------------------------------------------

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.delivery, required this.selfMemberId});

  final Delivery delivery;
  final String selfMemberId;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatCardDate(delivery.scheduledDate);
    final teammates = teammatesOn(delivery, selfMemberId);

    // Show up to 4 names; add "… et N autres" suffix when more.
    final String teammateLabel;
    if (teammates.isEmpty) {
      teammateLabel = 'Seul(e) sur cette livraison';
    } else {
      const maxShown = 4;
      final shown = teammates.take(maxShown).map((r) => r.displayName).toList();
      final extra = teammates.length - maxShown;
      if (extra > 0) {
        teammateLabel = 'Avec: ${shown.join(', ')} … et $extra autres';
      } else {
        teammateLabel = 'Avec: ${shown.join(', ')}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 $dateLabel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text('✅ Confirmé - Préparation paniers'),
            const SizedBox(height: 4),
            Text('👤 $teammateLabel'),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completed participation card
// ---------------------------------------------------------------------------

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatCardDate(delivery.scheduledDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 $dateLabel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            // V1: Only COMPLETED status is supported. Absences signalées /
            // absences non signalées require a separate domain field not yet
            // available on MemberRegistration.
            const Text('✅ Participation confirmée'),
            // V1 limitation: MemberRegistration has no 'note' field — notes
            // shown in the wireframe are not rendered here until the domain
            // model is extended.
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly bar chart
// ---------------------------------------------------------------------------

/// French month abbreviations matching the UI spec exactly.
const _kMonthAbbreviations = [
  'Janv',
  'Févr',
  'Mars',
  'Avr',
  'Mai',
  'Juin',
  'Juil',
  'Août',
  'Sep',
  'Oct',
  'Nov',
  'Déc',
];

/// Bar chart covering every month of the season range.
///
/// Built entirely from Material 3 widgets (Column/Row of Container bars) —
/// no third-party charting library is used.
///
/// - Bar height is proportional to count relative to the season maximum.
/// - Zero-count months render as empty bars (height 0) with a "(0)" label.
/// - When the range spans two calendar years, the year is shown below the
///   axis at the first month of each new year (matching the wireframe).
/// - A horizontal scroll view prevents overflow when many months are present.
class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({
    required this.org,
    required this.memberId,
    required this.contracts,
    required this.seasonContractIds,
  });

  final Organization org;
  final String memberId;
  final List<Contract> contracts;
  final Set<String> seasonContractIds;

  /// Max rendered bar height in logical pixels.
  static const double _maxBarHeight = 80;

  /// Width of each bar column (bar + label).
  static const double _colWidth = 40;

  @override
  Widget build(BuildContext context) {
    final data = seasonMonthlyParticipationCounts(
      org,
      memberId,
      contracts,
      seasonContractIds,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📊 Répartition par mois', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        if (data.isEmpty)
          Text('Aucune donnée pour cette saison.', style: textTheme.bodySmall)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildChart(context, data, colorScheme, textTheme),
          ),
      ],
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<({int year, int month, int count})> data,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final maxCount = data.fold<int>(
      0,
      (acc, e) => e.count > acc ? e.count : acc,
    );

    // Track which years have already had their label rendered.
    final renderedYears = <int>{};
    // First year seen — used to decide if year labels are needed at all.
    final firstYear = data.first.year;
    final multiYear = data.any((e) => e.year != firstYear);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((entry) {
        final barHeight = (maxCount == 0)
            ? 0.0
            : (entry.count / maxCount) * _maxBarHeight;

        // Show year label at the first occurrence of each year (only when
        // the season spans multiple calendar years).
        final showYear = multiYear && renderedYears.add(entry.year);

        return SizedBox(
          width: _colWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Count label above bar (shown for zero bars too).
              Text(
                '(${entry.count})',
                style: textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              // Bar (or empty space when count == 0).
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: _colWidth * 0.55,
                  height: barHeight.clamp(0, _maxBarHeight),
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              // Month label.
              Text(
                _kMonthAbbreviations[entry.month - 1],
                style: textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              // Year label — shown at first month of each new year when range
              // spans multiple calendar years.
              if (showYear)
                Text(
                  '${entry.year}',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                const SizedBox(height: 14),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyHistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aucune participation pour le moment.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Inscrivez-vous depuis le planning.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/planning'),
              child: const Text('📅 PLANNING'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _HistoryFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/planning'),
              icon: const Text('📅'),
              label: const Text('PLANNING'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/history/ranking'),
              icon: const Text('🏆'),
              label: const Text('Participations globales'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Formats a scheduled-date ISO-8601 string to the card format:
/// "d MMM yyyy • HHh-HHh" (e.g. "10 Jan 2025 • 18h-20h").
String _formatCardDate(String scheduledDate) {
  try {
    final date = DateTime.parse(scheduledDate);
    final datePart = DateFormat('d MMM yyyy', 'fr').format(date);
    final startH = date.hour.toString().padLeft(2, '0');
    final endH = (date.hour + 2).toString().padLeft(2, '0');
    return '$datePart • ${startH}h-${endH}h';
  } catch (_) {
    return scheduledDate;
  }
}
