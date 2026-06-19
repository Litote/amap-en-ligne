import 'dart:async';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Detailed history screen — all non-OPEN exchanges involving the current member.
///
/// Route: `/basket-exchange/history`
///
/// Shows exchanges in descending order by createdAt (or decidedAt when available).
/// Read-only — no actions.
class BasketExchangeHistoryScreen extends StatefulWidget {
  const BasketExchangeHistoryScreen({
    super.key,
    required this.orgId,
    required this.memberId,
  });

  final String orgId;
  final String memberId;

  @override
  State<BasketExchangeHistoryScreen> createState() =>
      _BasketExchangeHistoryScreenState();
}

class _BasketExchangeHistoryScreenState
    extends State<BasketExchangeHistoryScreen> {
  StreamSubscription<List<BasketExchange>>? _exchangeSub;
  StreamSubscription<List<Member>>? _membersSub;
  StreamSubscription<Organization?>? _orgSub;

  List<BasketExchange> _history = const [];
  List<Member> _members = const [];
  Organization? _org;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  @override
  void dispose() {
    _exchangeSub?.cancel();
    _membersSub?.cancel();
    _orgSub?.cancel();
    super.dispose();
  }

  void _startStreams() {
    final exchangeRepo = context.read<BasketExchangeRepository>();
    final memberRepo = context.read<MemberRepository>();
    final orgRepo = context.read<OrganizationRepository>();

    _orgSub = orgRepo.watch(widget.orgId).listen((org) {
      if (!mounted) return;
      setState(() => _org = org);
    });

    _exchangeSub = exchangeRepo
        .watchHistory(widget.orgId, widget.memberId)
        .listen((history) {
          if (!mounted) return;
          setState(() {
            _history = history;
            _loading = false;
          });
        });

    _membersSub = memberRepo.watch(widget.orgId).listen((members) {
      if (!mounted) return;
      setState(() => _members = members);
    });
  }

  String _memberName(String memberId) {
    if (memberId == widget.memberId) return 'Vous';
    final member = _members.where((m) => m.memberId == memberId).firstOrNull;
    // Fallback to the raw id when the member is not yet in the local cache.
    if (member == null) return memberId;
    final first = member.firstName ?? '';
    final last = member.lastName ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? memberId : name;
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    final part = DateFormat('EEEE d MMMM yyyy', 'fr').format(dt);
    return part[0].toUpperCase() + part.substring(1);
  }

  /// Sorting key — uses decidedAt when available, else createdAt.
  String _sortKey(BasketExchange e) => e.decidedAt ?? e.createdAt;

  String _deliveryDateLabel(String? deliveryId) {
    final org = _org;
    if (deliveryId == null || org == null) return '?';
    final delivery = org.deliveries
        .where((d) => d.deliveryId == deliveryId)
        .firstOrNull;
    if (delivery == null) return '?';
    final dt = DateTime.tryParse(delivery.scheduledDate);
    if (dt == null) return '?';
    return DateFormat('d MMM yyyy', 'fr').format(dt);
  }

  /// "{offered date} ↔ {counter date}" for a confirmed swap, else the offered date.
  String _swapLabel(BasketExchange e) {
    final offered = _deliveryDateLabel(e.deliveryId);
    final acceptedId = e.acceptedRequestId;
    if (e.status == BasketExchangeStatus.accepted && acceptedId != null) {
      final req = e.requests
          .where((r) => r.requestId == acceptedId)
          .firstOrNull;
      if (req?.proposedDeliveryId != null) {
        return '$offered ↔ ${_deliveryDateLabel(req!.proposedDeliveryId)}';
      }
    }
    return offered;
  }

  String _directionLabel(BasketExchange e) {
    if (e.offeringMemberId == widget.memberId) return 'J\'ai proposé';
    return 'J\'ai demandé';
  }

  String _counterpartName(BasketExchange e) {
    if (e.offeringMemberId == widget.memberId) {
      // I am the offerer — find the accepted requester.
      final acceptedId = e.acceptedRequestId;
      if (acceptedId != null) {
        final req = e.requests
            .where((r) => r.requestId == acceptedId)
            .firstOrNull;
        if (req != null) return _memberName(req.requesterMemberId);
      }
      return 'Inconnu';
    }
    // I am a requester — the offerer is the counterpart.
    return _memberName(e.offeringMemberId);
  }

  String _statusLabel(BasketExchange e) {
    return switch (e.status) {
      BasketExchangeStatus.accepted => 'Échangé',
      BasketExchangeStatus.cancelled =>
        e.offeringMemberId == widget.memberId ? 'Annulé par moi' : 'Annulé',
      BasketExchangeStatus.open => 'Ouvert',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique détaillé des échanges')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sorted = [..._history]
      ..sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));

    if (sorted.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Aucun échange dans votre historique.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/basket-exchange'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('RETOUR'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final exchange in sorted)
          _HistoryCard(
            exchange: exchange,
            directionLabel: _directionLabel(exchange),
            counterpartName: _counterpartName(exchange),
            statusLabel: _statusLabel(exchange),
            dateLabel: _formatDate(_sortKey(exchange)),
            swapLabel: _swapLabel(exchange),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.go('/basket-exchange'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('RETOUR'),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.exchange,
    required this.directionLabel,
    required this.counterpartName,
    required this.statusLabel,
    required this.dateLabel,
    required this.swapLabel,
  });

  final BasketExchange exchange;
  final String directionLabel;
  final String counterpartName;
  final String statusLabel;
  final String dateLabel;
  final String swapLabel;

  String get _statusEmoji => switch (exchange.status) {
    BasketExchangeStatus.accepted => '✅',
    BasketExchangeStatus.cancelled => '⏸️',
    BasketExchangeStatus.open => '🟡',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 $dateLabel',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('🔄 Paniers : $swapLabel'),
            const SizedBox(height: 4),
            Text('↔ $directionLabel avec $counterpartName'),
            const SizedBox(height: 4),
            Text('$_statusEmoji $statusLabel'),
          ],
        ),
      ),
    );
  }
}
