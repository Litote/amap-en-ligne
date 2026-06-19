import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_bloc.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_event.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_state.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/propose_basket_exchange_dialog.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/submit_request_dialog.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Main basket-exchange screen.
///
/// Route: `/basket-exchange`
///
/// Implements the wireframe in
/// `documentation/feature/fr/ui/coordinator/screen-coordinator-06-basket-exchange.md`.
/// Three sections: "💝 Mes propositions en cours", "🛍️ Échanges disponibles",
/// "📊 Mon historique".
class BasketExchangeScreen extends StatelessWidget {
  const BasketExchangeScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final sub = _resolveSub(context);
    return BlocProvider(
      create: (_) => BasketExchangeBloc(
        organizationRepository: context.read<OrganizationRepository>(),
        memberRepository: context.read<MemberRepository>(),
        basketExchangeRepository: context.read<BasketExchangeRepository>(),
        contractRepository: context.read<ContractRepository>(),
        syncBloc: context.read<SyncBloc>(),
        orgId: tenantId,
        sub: sub,
      ),
      child: const _BasketExchangeView(),
    );
  }
}

/// Resolves the current user's `sub` claim from the active auth session.
String _resolveSub(BuildContext context) {
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

// ---------------------------------------------------------------------------
// Inner view — consumes the BLoC
// ---------------------------------------------------------------------------

class _BasketExchangeView extends StatelessWidget {
  const _BasketExchangeView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BasketExchangeBloc, BasketExchangeState>(
      // Only fire the listener when the dialog state transitions or a new
      // failure appears. Without this guard, every stream-driven state update
      // (e.g. an org change from a background sync) would re-invoke showDialog
      // while a dialog is already open, stacking one dialog per sync cycle.
      listenWhen: (previous, current) {
        if (current is! BasketExchangeReady) return false;
        if (current.saveStatus == BasketExchangeSaveStatus.failure &&
            (previous is! BasketExchangeReady ||
                previous.saveStatus != BasketExchangeSaveStatus.failure)) {
          return true;
        }
        final prevDialog = previous is BasketExchangeReady
            ? previous.dialogState
            : null;
        return prevDialog != current.dialogState;
      },
      listener: _onStateChanged,
      builder: (context, state) {
        return ConnectedScaffold(
          title: 'Échanges de paniers',
          actions: const [SyncButton()],
          body: switch (state) {
            BasketExchangeLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            BasketExchangeUnauthorized() => _UnauthorizedBody(),
            BasketExchangeReady() => _ReadyBody(state: state),
          },
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, BasketExchangeState state) {
    if (state is! BasketExchangeReady) return;

    // Show failure snackbar.
    if (state.saveStatus == BasketExchangeSaveStatus.failure) {
      final message = state.errorMessage ?? 'Une erreur est survenue.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    // Open / close dialogs in reaction to dialogState changes.
    state.dialogState.maybeWhen(
      propose: () {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ProposeBasketExchangeDialog(
            org: state.org,
            memberId: state.me.memberId,
            allExchanges: state.allExchanges,
            contracts: state.contracts,
            onSubmit: (event) {
              context.read<BasketExchangeBloc>().add(event);
            },
          ),
        ).then((_) {
          if (context.mounted) {
            context.read<BasketExchangeBloc>().add(
              const BasketExchangeEvent.dialogDismissed(),
            );
          }
        });
      },
      submitRequest: (offer) {
        final org = state.org;
        final offererDisplayName = _resolveMemberName(
          offer.offeringMemberId,
          state.membersById,
        );
        final contractDescription = _resolveContractDescription(offer, org);
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => SubmitRequestDialog(
            offer: offer,
            offererDisplayName: offererDisplayName,
            contractDescription: contractDescription,
            org: org,
            memberId: state.me.memberId,
            allExchanges: state.allExchanges,
            contracts: state.contracts,
            onConfirm: ({required proposedDeliveryId, proposedContractId}) {
              context.read<BasketExchangeBloc>().add(
                BasketExchangeEvent.requestSubmitted(
                  offer: offer,
                  proposedDeliveryId: proposedDeliveryId,
                  proposedContractId: proposedContractId,
                ),
              );
            },
          ),
        ).then((_) {
          if (context.mounted) {
            context.read<BasketExchangeBloc>().add(
              const BasketExchangeEvent.dialogDismissed(),
            );
          }
        });
      },
      orElse: () {},
    );
  }
}

// ---------------------------------------------------------------------------
// Unauthorized body — member row not yet available or user is not a member
// ---------------------------------------------------------------------------

class _UnauthorizedBody extends StatelessWidget {
  const _UnauthorizedBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Votre profil de membre n\'est pas encore disponible.\n'
              'Si ce message persiste après une actualisation, '
              'vous n\'êtes peut-être pas inscrit comme amapien.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.read<BasketExchangeBloc>().add(
                const BasketExchangeEvent.refreshRequested(),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('ACTUALISER'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ready body
// ---------------------------------------------------------------------------

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state});

  final BasketExchangeReady state;

  @override
  Widget build(BuildContext context) {
    final openOffers = state.myOffers
        .where((e) => e.status == BasketExchangeStatus.open)
        .toList();
    final available = state.availableOffers;
    final history = [...state.historyItems]
      ..sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
    final recentHistory = history.take(3).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Header ---
        Text(
          '✨ Échange de paniers',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Proposez votre panier si vous êtes absent · Récupérez celui d\'un autre membre',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // --- Section: Mes propositions en cours ---
        Text(
          '💝 Mes propositions en cours',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (openOffers.isEmpty)
          const _EmptyCard(message: 'Aucune proposition en cours.')
        else
          for (final offer in openOffers)
            _MyOfferCard(offer: offer, org: state.org),
        const SizedBox(height: 12),

        // --- Propose button ---
        FilledButton.icon(
          onPressed: () {
            context.read<BasketExchangeBloc>().add(
              const BasketExchangeEvent.proposeRequested(),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('PROPOSER UN ÉCHANGE'),
        ),
        const SizedBox(height: 24),

        // --- Section: Échanges disponibles ---
        Text(
          '🛍️ Échanges disponibles',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (available.isEmpty)
          const _EmptyCard(message: 'Aucun échange disponible.')
        else
          for (final offer in available)
            _AvailableOfferCard(
              offer: offer,
              org: state.org,
              membersById: state.membersById,
              myPendingRequest: state.myPendingRequestOn(offer),
            ),
        const SizedBox(height: 24),

        // --- Section: Mon historique ---
        Text(
          '📊 Mon historique',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Échanges réussis cette année : ${state.successfulExchangesThisYear}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (recentHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final e in recentHistory)
                    _HistoryRow(
                      exchange: e,
                      me: state.me,
                      org: state.org,
                      membersById: state.membersById,
                    ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/basket-exchange/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('VOIR HISTORIQUE COMPLET'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- Footer actions ---
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<BasketExchangeBloc>().add(
                    const BasketExchangeEvent.refreshRequested(),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('ACTUALISER'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/basket-exchange/overview'),
                icon: const Icon(Icons.table_chart),
                label: const Text("VUE D'ENSEMBLE"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.go('/basket-exchange/history'),
          icon: const Icon(Icons.list_alt),
          label: const Text('HISTORIQUE DÉTAILLÉ'),
        ),
      ],
    );
  }

  String _sortKey(BasketExchange e) => e.decidedAt ?? e.createdAt;
}

// ---------------------------------------------------------------------------
// My offer card
// ---------------------------------------------------------------------------

class _MyOfferCard extends StatelessWidget {
  const _MyOfferCard({required this.offer, required this.org});

  final BasketExchange offer;
  final Organization org;

  @override
  Widget build(BuildContext context) {
    final pendingCount = offer.requests
        .where((r) => r.status == BasketExchangeRequestStatus.pending)
        .length;
    final dateLabel = _resolveDateLabel(offer, org);
    final contractDesc = _resolveContractDescription(offer, org);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 $dateLabel • $contractDesc',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (offer.motive != null) ...[
              const SizedBox(height: 4),
              Text('💬 "${offer.motive}"'),
            ],
            const SizedBox(height: 4),
            Text(
              '🟡 En attente • $pendingCount demande${pendingCount > 1 ? 's' : ''} reçue${pendingCount > 1 ? 's' : ''}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(
                      '/basket-exchange/${offer.basketExchangeId}/requests',
                    ),
                    child: const Text('VOIR LES DEMANDES'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<BasketExchangeBloc>().add(
                        BasketExchangeEvent.offerCancelled(offer: offer),
                      );
                    },
                    child: const Text('ANNULER'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Available offer card
// ---------------------------------------------------------------------------

class _AvailableOfferCard extends StatelessWidget {
  const _AvailableOfferCard({
    required this.offer,
    required this.org,
    required this.membersById,
    required this.myPendingRequest,
  });

  final BasketExchange offer;
  final Organization org;
  final Map<String, Member> membersById;
  final BasketExchangeRequest? myPendingRequest;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _resolveDateLabel(offer, org);
    final contractDesc = _resolveContractDescription(offer, org);
    final offererName = _resolveMemberName(offer.offeringMemberId, membersById);
    final pending = myPendingRequest;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 $dateLabel • $contractDesc',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('👤 $offererName • Propose son panier'),
            if (offer.motive != null) ...[
              const SizedBox(height: 4),
              Text('💬 "${offer.motive}"'),
            ],
            const SizedBox(height: 8),
            if (pending != null) ...[
              const Text(
                'Votre demande est en attente.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<BasketExchangeBloc>().add(
                      BasketExchangeEvent.requestWithdrawn(
                        offer: offer,
                        requestId: pending.requestId,
                      ),
                    );
                  },
                  child: const Text('RETIRER MA DEMANDE'),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<BasketExchangeBloc>().add(
                      BasketExchangeEvent.requestRequested(offer: offer),
                    );
                  },
                  child: const Text('DEMANDER ÉCHANGE'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History row (compact, inside the summary card)
// ---------------------------------------------------------------------------

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.exchange,
    required this.me,
    required this.org,
    required this.membersById,
  });

  final BasketExchange exchange;
  final Member me;
  final Organization org;
  final Map<String, Member> membersById;

  @override
  Widget build(BuildContext context) {
    final statusEmoji = switch (exchange.status) {
      BasketExchangeStatus.accepted => '✅',
      BasketExchangeStatus.cancelled => '⏸️',
      BasketExchangeStatus.open => '🟡',
    };

    final isOfferer = exchange.offeringMemberId == me.memberId;
    final counterpartId = isOfferer
        ? _acceptedRequesterId(exchange)
        : exchange.offeringMemberId;
    final counterpart = counterpartId == null
        ? null
        : _resolveMemberName(counterpartId, membersById);

    // D1 = offered delivery; D2 = the accepted counter-delivery (if any).
    final offeredDate = _deliveryDateLabel(exchange.deliveryId, org);
    final counterDeliveryId = _acceptedRequest(exchange)?.proposedDeliveryId;
    final swap =
        exchange.status == BasketExchangeStatus.accepted &&
            counterDeliveryId != null
        ? '$offeredDate ↔ ${_deliveryDateLabel(counterDeliveryId, org)}'
        : offeredDate;

    final who = counterpart != null ? ' · $counterpart' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$statusEmoji $swap$who'),
    );
  }

  BasketExchangeRequest? _acceptedRequest(BasketExchange e) {
    final id = e.acceptedRequestId;
    if (id == null) return null;
    return e.requests.where((r) => r.requestId == id).firstOrNull;
  }

  String? _acceptedRequesterId(BasketExchange e) =>
      _acceptedRequest(e)?.requesterMemberId;
}

// ---------------------------------------------------------------------------
// Empty state card
// ---------------------------------------------------------------------------

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers — resolve display data from the org model
// ---------------------------------------------------------------------------

/// Returns a formatted date label for the delivery linked to [offer].
String _resolveDateLabel(BasketExchange offer, Organization org) {
  final delivery = org.deliveries
      .where((d) => d.deliveryId == offer.deliveryId)
      .firstOrNull;
  if (delivery == null) return offer.deliveryId;
  final dt = DateTime.tryParse(delivery.scheduledDate);
  if (dt == null) return offer.deliveryId;
  final part = DateFormat('EEEE d MMM', 'fr').format(dt);
  return part[0].toUpperCase() + part.substring(1);
}

/// Returns the contract description for the basket in [offer].
String _resolveContractDescription(BasketExchange offer, Organization org) {
  final delivery = org.deliveries
      .where((d) => d.deliveryId == offer.deliveryId)
      .firstOrNull;
  if (delivery == null) return offer.contractId;
  final contract = delivery.contracts
      .where((c) => c.contractId == offer.contractId)
      .firstOrNull;
  if (contract == null) return offer.contractId;
  return contract.deliveryDescription.isNotEmpty
      ? contract.deliveryDescription
      : offer.contractId;
}

/// Resolves a member's display name from the synced member list, falling back to
/// the id when the member row is not (yet) available.
String _resolveMemberName(String memberId, Map<String, Member> membersById) {
  final member = membersById[memberId];
  if (member == null) return memberId;
  final name = [
    member.firstName,
    member.lastName,
  ].where((p) => p != null && p.isNotEmpty).join(' ');
  return name.isNotEmpty ? name : memberId;
}

/// Formats the delivery date for [deliveryId] within [org], or '?' if unknown.
String _deliveryDateLabel(String? deliveryId, Organization org) {
  if (deliveryId == null) return '?';
  final delivery = org.deliveries
      .where((d) => d.deliveryId == deliveryId)
      .firstOrNull;
  if (delivery == null) return '?';
  final dt = DateTime.tryParse(delivery.scheduledDate);
  if (dt == null) return '?';
  return DateFormat('d MMM yyyy', 'fr').format(dt);
}
