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

/// Anonymised global participations screen for Amapien members.
///
/// Mirrors `documentation/feature/fr/ui/member/screen-member-05-participations-globales.md`.
///
/// Shows the current user's position in the AMAP participation ranking and
/// the distribution of all active members across activity tiers. Other
/// members' names are never displayed.
const _kRankingTitle = '🏆 Participations globales';

class MemberRankingScreen extends StatefulWidget {
  const MemberRankingScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  State<MemberRankingScreen> createState() => _MemberRankingScreenState();
}

class _MemberRankingScreenState extends State<MemberRankingScreen> {
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
  void didUpdateWidget(MemberRankingScreen oldWidget) {
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
        title: _kRankingTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final org = _org;
    final me = _me;

    if (org == null || me == null) {
      return const ConnectedScaffold(
        title: _kRankingTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final seasonYear = currentSeasonYear(_contracts, now);
    final contractIds = seasonContractIds(_contracts, seasonYear);

    // Denominator: ACTIVE members only.
    final activeMembers = _allMembers.where((m) {
      final status = m.accountStatus;
      if (status != null) return status == MemberAccountStatus.active;
      return m.activeStatus;
    }).toList();

    final memberId = me.memberId;
    final myCount = completedRegistrationsInSeason(org, memberId, contractIds);
    final rankResult = memberRankIn(org, activeMembers, memberId, contractIds);
    final distribution = participationDistribution(
      org,
      activeMembers,
      contractIds,
    );

    final myActivity = memberActivityStatus(org, memberId, contractIds);

    return ConnectedScaffold(
      title: _kRankingTitle,
      body: _RankingBody(
        seasonYear: seasonYear,
        myCount: myCount,
        rankResult: rankResult,
        distribution: distribution,
        myActivity: myActivity,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _RankingBody extends StatelessWidget {
  const _RankingBody({
    required this.seasonYear,
    required this.myCount,
    required this.rankResult,
    required this.distribution,
    required this.myActivity,
  });

  final int seasonYear;
  final int myCount;
  final MemberRankResult? rankResult;
  final ({int active, int occasional, int inactive}) distribution;
  final MemberActivityStatus myActivity;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RankingHeader(seasonYear: seasonYear),
        const SizedBox(height: 16),
        _MyPositionCard(myCount: myCount, rankResult: rankResult),
        const SizedBox(height: 16),
        _DistributionSection(
          distribution: distribution,
          myActivity: myActivity,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header: [← Retour] + Saison <année>
// ---------------------------------------------------------------------------

class _RankingHeader extends StatelessWidget {
  const _RankingHeader({required this.seasonYear});

  final int seasonYear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => context.go('/history'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Retour'),
        ),
        const Spacer(),
        Text(
          'Saison $seasonYear',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "📍 Ma position" card
// ---------------------------------------------------------------------------

class _MyPositionCard extends StatelessWidget {
  const _MyPositionCard({required this.myCount, required this.rankResult});

  final int myCount;
  final MemberRankResult? rankResult;

  @override
  Widget build(BuildContext context) {
    // Build position label.
    final String positionLabel;
    if (rankResult == null) {
      positionLabel = '—';
    } else if (rankResult!.tied) {
      positionLabel =
          'Vous êtes ${_ordinal(rankResult!.rank)} ex-aequo / ${rankResult!.total} membres actifs';
    } else {
      positionLabel =
          'Vous êtes ${_ordinal(rankResult!.rank)} / ${rankResult!.total} membres actifs';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 Ma position',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Text(positionLabel),
            const SizedBox(height: 4),
            Text('📈 Mes participations cette saison : $myCount'),
          ],
        ),
      ),
    );
  }

  /// French ordinal suffix: 1 -> "1er", 2 -> "2ème", 3 -> "3ème", etc.
  String _ordinal(int n) {
    if (n == 1) return '1er';
    // ignore: unnecessary_brace_in_string_interps
    return '${n}ème';
  }
}

// ---------------------------------------------------------------------------
// "📊 Répartition des membres actifs" section
// ---------------------------------------------------------------------------

class _DistributionSection extends StatelessWidget {
  const _DistributionSection({
    required this.distribution,
    required this.myActivity,
  });

  final ({int active, int occasional, int inactive}) distribution;
  final MemberActivityStatus myActivity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Répartition des membres actifs',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _TierRow(
          label: 'Actifs (≥5)',
          count: distribution.active,
          isMe: myActivity == MemberActivityStatus.active,
        ),
        _TierRow(
          label: 'Occasionnels (1-4)',
          count: distribution.occasional,
          isMe: myActivity == MemberActivityStatus.occasional,
        ),
        _TierRow(
          label: 'Inactifs (0)',
          count: distribution.inactive,
          isMe: myActivity == MemberActivityStatus.inactive,
        ),
      ],
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.label,
    required this.count,
    required this.isMe,
  });

  final String label;
  final int count;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bars = '■' * count;
    final meMarker = isMe ? '  ← vous' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label : $bars ($count membres)$meMarker'),
    );
  }
}
