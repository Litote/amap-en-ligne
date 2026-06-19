import 'dart:async';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange_view.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Compact home-dashboard card summarising the member's ongoing basket exchanges
/// (requests to validate, proposals awaiting validation, confirmed exchanges).
///
/// Renders nothing until the member is known and there is activity to surface, so
/// it stays invisible for members with no exchanges in flight.
class BasketExchangeDashboardCard extends StatefulWidget {
  const BasketExchangeDashboardCard({required this.tenantId, super.key});

  final String tenantId;

  @override
  State<BasketExchangeDashboardCard> createState() =>
      _BasketExchangeDashboardCardState();
}

class _BasketExchangeDashboardCardState
    extends State<BasketExchangeDashboardCard> {
  StreamSubscription<Member?>? _memberSub;
  StreamSubscription<List<BasketExchange>>? _exchangeSub;

  Member? _member;
  List<BasketExchange> _exchanges = const [];

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  @override
  void didUpdateWidget(BasketExchangeDashboardCard oldWidget) {
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
    final state = context.read<AuthService>().currentState;
    if (state is! Authenticated) return '';
    try {
      return JwtClaims.decode(state.accessToken).string('sub') ?? '';
    } catch (_) {
      return '';
    }
  }

  void _startStreams() {
    if (widget.tenantId.isEmpty) return;
    final memberRepo = context.read<MemberRepository>();
    final exchangeRepo = context.read<BasketExchangeRepository>();
    _memberSub = memberRepo.watchMyMember(_resolveSub()).listen((m) {
      if (mounted) setState(() => _member = m);
    });
    _exchangeSub = exchangeRepo.watch(widget.tenantId).listen((list) {
      if (mounted) setState(() => _exchanges = list);
    });
  }

  void _cancelStreams() {
    _memberSub?.cancel();
    _exchangeSub?.cancel();
    _memberSub = null;
    _exchangeSub = null;
    _member = null;
    _exchanges = const [];
  }

  @override
  Widget build(BuildContext context) {
    final member = _member;
    if (member == null) return const SizedBox.shrink();
    final summary = basketExchangeSummaryFor(_exchanges, member.memberId);
    if (!summary.hasActivity) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go('/basket-exchange'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔄 Échanges de paniers',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (summary.requestsToValidate > 0)
                _line(
                  '• ${summary.requestsToValidate} '
                  'proposition${summary.requestsToValidate > 1 ? 's' : ''} '
                  'à valider',
                  emphasise: true,
                ),
              if (summary.proposalsAwaitingValidation > 0)
                _line(
                  '• ${summary.proposalsAwaitingValidation} '
                  'demande${summary.proposalsAwaitingValidation > 1 ? 's' : ''} '
                  'en attente de validation',
                ),
              if (summary.confirmedExchanges > 0)
                _line(
                  '• ${summary.confirmedExchanges} '
                  'échange${summary.confirmedExchanges > 1 ? 's' : ''} '
                  'confirmé${summary.confirmedExchanges > 1 ? 's' : ''}',
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/basket-exchange'),
                  child: const Text('VOIR LES ÉCHANGES'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String text, {bool emphasise = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: emphasise
            ? theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              )
            : theme.textTheme.bodyMedium,
      ),
    );
  }
}
