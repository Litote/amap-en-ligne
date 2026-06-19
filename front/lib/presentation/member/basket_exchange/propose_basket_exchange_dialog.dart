import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange_view.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/shared_basket_view.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Modal dialog for creating a new basket-exchange offer.
///
/// Filters the available deliveries to only those where:
/// - The delivery is upcoming (scheduled after now) and active (not cancelled/completed)
/// - The member's basket for that delivery is not already committed in another
///   exchange — offered (OPEN/ACCEPTED) or already exchanged / received through a
///   settled exchange (see [committedDeliveryIdsFor]).
///
/// When a delivery has multiple contracts, a second dropdown for contract
/// selection is shown so the user can pick which basket to offer.
class ProposeBasketExchangeDialog extends StatefulWidget {
  const ProposeBasketExchangeDialog({
    super.key,
    required this.org,
    required this.memberId,
    required this.allExchanges,
    required this.contracts,
    required this.onSubmit,
  });

  final Organization org;
  final String memberId;

  /// All exchanges in the org — used to filter out deliveries whose basket is
  /// already committed by this member (offered, exchanged or received).
  final List<BasketExchange> allExchanges;

  /// The org's contracts — used to hide deliveries/contracts where this member shares the basket
  /// in alternation and it is **not** their turn that week (see [memberHoldsBasketOn]).
  final List<Contract> contracts;

  /// Called when the user confirms the dialog.
  final void Function(BasketExchangeProposeSubmitted event) onSubmit;

  @override
  State<ProposeBasketExchangeDialog> createState() =>
      _ProposeBasketExchangeDialogState();
}

class _ProposeBasketExchangeDialogState
    extends State<ProposeBasketExchangeDialog> {
  Delivery? _selectedDelivery;
  DeliveryContract? _selectedContract;
  final _motiveController = TextEditingController();

  @override
  void dispose() {
    _motiveController.dispose();
    super.dispose();
  }

  /// Returns the deliveries eligible for a new offer.
  List<Delivery> get _eligibleDeliveries {
    final now = DateTime.now();

    // Ids of deliveries whose basket is already committed by this member —
    // offered (OPEN/ACCEPTED) or already exchanged / received.
    final committed = committedDeliveryIdsFor(
      widget.allExchanges,
      widget.memberId,
    );

    return widget.org.deliveries.where((d) {
      // Must be upcoming.
      final scheduled = DateTime.tryParse(d.scheduledDate);
      if (scheduled == null || scheduled.isBefore(now)) return false;
      // Must be active status.
      if (!d.status.isActive) return false;
      // Must not already be committed in another exchange.
      if (committed.contains(d.deliveryId)) return false;
      // At least one contract on the delivery must be the member's to give that week
      // (alternation: a shared-basket week that belongs to another family is excluded).
      if (!d.contracts.any((c) => _holdsBasket(c, d.deliveryId))) return false;
      return true;
    }).toList()..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  /// Contracts in the selected delivery the member may actually offer (alternation-aware).
  List<DeliveryContract> get _eligibleContracts {
    final delivery = _selectedDelivery;
    if (delivery == null) return const [];
    return delivery.contracts
        .where((c) => _holdsBasket(c, delivery.deliveryId))
        .toList();
  }

  Contract? _contractById(String id) {
    for (final c in widget.contracts) {
      if (c.contractId == id) return c;
    }
    return null;
  }

  /// Whether the member holds [dc]'s basket on [deliveryId] (true for non-shared contracts).
  bool _holdsBasket(DeliveryContract dc, String deliveryId) {
    final contract = _contractById(dc.contractId);
    if (contract == null) return true;
    final ordered = contractDeliveriesOrdered(widget.org, contract.contractId);
    return memberHoldsBasketOn(contract, ordered, deliveryId, widget.memberId);
  }

  bool get _canSubmit {
    final delivery = _selectedDelivery;
    if (delivery == null) return false;
    final contracts = _eligibleContracts;
    if (contracts.length > 1 && _selectedContract == null) return false;
    return true;
  }

  String _formatDeliveryLabel(Delivery d) {
    final date = DateTime.tryParse(d.scheduledDate);
    if (date == null) return d.deliveryId;
    final datePart = DateFormat('EEEE d MMM', 'fr').format(date);
    final capitalised = datePart[0].toUpperCase() + datePart.substring(1);
    // Show the delivery descriptions from contracts.
    final descriptions = d.contracts
        .map((c) => c.deliveryDescription)
        .where((desc) => desc.isNotEmpty)
        .toSet()
        .join(' + ');
    if (descriptions.isEmpty) return capitalised;
    return '$capitalised • $descriptions';
  }

  void _onDeliveryChanged(Delivery? delivery) {
    setState(() {
      _selectedDelivery = delivery;
      _selectedContract = null;
    });
  }

  void _submit() {
    final delivery = _selectedDelivery;
    if (delivery == null) return;

    final contracts = _eligibleContracts;
    final contract = contracts.length == 1
        ? contracts.first
        : _selectedContract;
    if (contract == null) return;

    final motive = _motiveController.text.trim();
    widget.onSubmit(
      BasketExchangeEvent.proposeSubmitted(
            deliveryId: delivery.deliveryId,
            contractId: contract.contractId,
            motive: motive.isEmpty ? null : motive,
          )
          as BasketExchangeProposeSubmitted,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final eligible = _eligibleDeliveries;
    final contracts = _eligibleContracts;
    final showContractPicker = contracts.length > 1;

    return AlertDialog(
      title: const Text('Proposer un échange'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Delivery picker ---
            const Text('📅 Sélectionner la livraison :'),
            const SizedBox(height: 8),
            if (eligible.isEmpty)
              const Text(
                "Aucune livraison disponible pour un échange.",
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else
              DropdownButtonFormField<Delivery>(
                initialValue: _selectedDelivery,
                hint: const Text('Choisir une livraison'),
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: eligible
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          _formatDeliveryLabel(d),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _onDeliveryChanged,
              ),

            // --- Contract picker (only when ambiguous) ---
            if (showContractPicker) ...[
              const SizedBox(height: 16),
              const Text('🛒 Sélectionner le contrat :'),
              const SizedBox(height: 8),
              DropdownButtonFormField<DeliveryContract>(
                initialValue: _selectedContract,
                hint: const Text('Choisir un contrat'),
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: contracts
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.deliveryDescription,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (c) => setState(() => _selectedContract = c),
              ),
            ],

            // --- Motive field ---
            const SizedBox(height: 16),
            const Text('📝 Motif de l\'échange (optionnel) :'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _motiveController,
              maxLines: 3,
              maxLength: 200,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: const InputDecoration(
                hintText: 'Ex: Déplacement professionnel…',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            // --- Exchange rules ---
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Règles d\'échange :',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Vous ne pouvez avoir qu\'une seule proposition ouverte par livraison.',
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Le membre intéressé vous proposera l\'une de ses livraisons en échange.',
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Précisez vos disponibilités dans le motif ci-dessus.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: const Text('PROPOSER'),
        ),
      ],
    );
  }
}
