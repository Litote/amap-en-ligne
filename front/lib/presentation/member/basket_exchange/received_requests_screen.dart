import 'dart:async';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Screen showing all PENDING requests received on one of the user's offers.
///
/// Route: `/basket-exchange/:offerId/requests`
///
/// Mirrors the "Demandes pour mon échange" wireframe in
/// `documentation/feature/fr/ui/coordinator/screen-coordinator-06-basket-exchange.md`.
///
/// When the offer transitions to ACCEPTED or CANCELLED while this screen is
/// visible, the screen navigates back automatically with a SnackBar notification.
class ReceivedRequestsScreen extends StatefulWidget {
  const ReceivedRequestsScreen({
    super.key,
    required this.orgId,
    required this.offerId,
  });

  final String orgId;
  final String offerId;

  @override
  State<ReceivedRequestsScreen> createState() => _ReceivedRequestsScreenState();
}

class _ReceivedRequestsScreenState extends State<ReceivedRequestsScreen> {
  StreamSubscription<List<BasketExchange>>? _exchangeSub;
  StreamSubscription<List<Member>>? _membersSub;
  StreamSubscription<Organization?>? _orgSub;

  BasketExchange? _offer;
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

    _exchangeSub = exchangeRepo.watch(widget.orgId).listen(_onExchangesUpdated);

    _membersSub = memberRepo.watch(widget.orgId).listen((members) {
      if (!mounted) return;
      setState(() => _members = members);
    });
  }

  void _onExchangesUpdated(List<BasketExchange> exchanges) {
    if (!mounted) return;
    final offer = exchanges
        .where((e) => e.basketExchangeId == widget.offerId)
        .firstOrNull;
    setState(() {
      _offer = offer;
      _loading = false;
    });

    // Auto-navigate back when offer is no longer OPEN.
    if (offer != null && offer.status != BasketExchangeStatus.open) {
      _scheduleOfferClosedNavigation(offer);
    }
  }

  void _scheduleOfferClosedNavigation(BasketExchange offer) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = offer.status == BasketExchangeStatus.accepted
          ? 'Échange accepté.'
          : 'Proposition annulée.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      // Use go_router for safer navigation instead of Navigator.pop()
      try {
        context.go('/basket-exchange');
      } catch (_) {
        // If navigation fails (unmounted or other state issues), safely ignore
      }
    });
  }

  String _memberName(String memberId) {
    final member = _members.where((m) => m.memberId == memberId).firstOrNull;
    // Fallback to the raw id when the member is not yet in the local cache.
    if (member == null) return memberId;
    final first = member.firstName ?? '';
    final last = member.lastName ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? memberId : name;
  }

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

  String _relativeTime(String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return createdAt;
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }

  Future<void> _accept(BasketExchangeRequest request) async {
    final offer = _offer;
    if (offer == null) return;
    final offeredDate = _deliveryDateLabel(offer.deliveryId);
    final counterDate = _deliveryDateLabel(request.proposedDeliveryId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer l\'échange'),
        content: Text(
          'Vous cédez votre panier du $offeredDate et récupérez celui du '
          '$counterDate. Les autres demandes seront automatiquement refusées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ANNULER'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final repo = context.read<BasketExchangeRepository>();
    final syncBloc = context.read<SyncBloc>();
    final decidedAt = DateTime.now().toUtc().toIso8601String();
    await repo.acceptRequest(
      basketExchange: offer,
      requestId: request.requestId,
      decidedAt: decidedAt,
    );
    syncBloc.add(const SyncEvent.mutationApplied());
  }

  Future<void> _refuse(BasketExchangeRequest request) async {
    final offer = _offer;
    if (offer == null) return;
    final repo = context.read<BasketExchangeRepository>();
    final syncBloc = context.read<SyncBloc>();
    final decidedAt = DateTime.now().toUtc().toIso8601String();
    // Individual refusal keeps the offer OPEN for other requesters (offerer-only,
    // supported by the back's BasketExchangeService).
    await repo.refuseRequest(
      basketExchange: offer,
      requestId: request.requestId,
      decidedAt: decidedAt,
    );
    syncBloc.add(const SyncEvent.mutationApplied());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes pour mon échange')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final offer = _offer;
    if (offer == null) {
      return const Center(child: Text('Proposition introuvable.'));
    }

    final pendingRequests =
        offer.requests
            .where((r) => r.status == BasketExchangeRequestStatus.pending)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Offer summary ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Demandes reçues (${pendingRequests.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 Votre panier du ${_deliveryDateLabel(offer.deliveryId)}',
                ),
                if (offer.motive != null) ...[
                  const SizedBox(height: 4),
                  Text('💬 Motif : "${offer.motive}"'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- Request cards ---
        if (pendingRequests.isEmpty)
          const Center(
            child: Text(
              'Aucune demande reçue pour le moment.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          for (final request in pendingRequests)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👤 ${_memberName(request.requesterMemberId)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🔄 Propose son panier du '
                      '${_deliveryDateLabel(request.proposedDeliveryId)}',
                    ),
                    const SizedBox(height: 4),
                    Text('⏰ Demande reçue ${_relativeTime(request.createdAt)}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _accept(request),
                            child: const Text('VALIDER'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _refuse(request),
                            child: const Text('REFUSER'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.go('/basket-exchange'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('RETOUR'),
        ),
      ],
    );
  }
}
