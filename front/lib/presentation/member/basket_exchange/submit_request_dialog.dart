import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange_view.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/shared_basket_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal dialog for sending a request on an available basket-exchange offer.
///
/// Reciprocal swap: the requester must pick one of their own upcoming deliveries
/// to offer in return (the counter-delivery). The offerer will receive that
/// basket when validating the request.
class SubmitRequestDialog extends StatefulWidget {
  const SubmitRequestDialog({
    super.key,
    required this.offer,
    required this.offererDisplayName,
    required this.contractDescription,
    required this.org,
    required this.memberId,
    required this.allExchanges,
    required this.contracts,
    required this.onConfirm,
  });

  final BasketExchange offer;

  /// Resolved display name of the offerer (first+last name, or id as fallback).
  final String offererDisplayName;

  /// Human-readable description of the contract being exchanged.
  final String contractDescription;

  /// The organization, used to list the requester's eligible counter-deliveries.
  final Organization org;

  /// The requester's member id.
  final String memberId;

  /// All exchanges in the org, used to hide deliveries already committed.
  final List<BasketExchange> allExchanges;

  /// The org's contracts — used to hide counter-deliveries the requester does not hold that week
  /// when the basket is shared in alternation (see [memberHoldsBasketOn]).
  final List<Contract> contracts;

  /// Called with the chosen counter-delivery when the user taps [ENVOYER].
  final void Function({
    required String proposedDeliveryId,
    String? proposedContractId,
  })
  onConfirm;

  @override
  State<SubmitRequestDialog> createState() => _SubmitRequestDialogState();
}

class _SubmitRequestDialogState extends State<SubmitRequestDialog> {
  Delivery? _selectedDelivery;
  DeliveryContract? _selectedContract;

  /// Deliveries the requester can offer in return: upcoming, active, distinct
  /// from the offered one, and not already committed in another exchange.
  List<Delivery> get _eligibleDeliveries {
    final now = DateTime.now();
    final committed = committedDeliveryIdsFor(
      widget.allExchanges,
      widget.memberId,
    );
    return widget.org.deliveries.where((d) {
      if (d.deliveryId == widget.offer.deliveryId) return false;
      final scheduled = DateTime.tryParse(d.scheduledDate);
      if (scheduled == null || scheduled.isBefore(now)) return false;
      if (!d.status.isActive) return false;
      if (committed.contains(d.deliveryId)) return false;
      // Alternation: a shared-basket week that belongs to another family is not the requester's to give.
      if (!d.contracts.any((c) => _holdsBasket(c, d.deliveryId))) return false;
      return true;
    }).toList()..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  List<DeliveryContract> get _eligibleContracts =>
      _selectedDelivery?.contracts
          .where((c) => _holdsBasket(c, _selectedDelivery!.deliveryId))
          .toList() ??
      const [];

  Contract? _contractById(String id) {
    for (final c in widget.contracts) {
      if (c.contractId == id) return c;
    }
    return null;
  }

  /// Whether the requester holds [dc]'s basket on [deliveryId] (true for non-shared contracts).
  bool _holdsBasket(DeliveryContract dc, String deliveryId) {
    final contract = _contractById(dc.contractId);
    if (contract == null) return true;
    final ordered = contractDeliveriesOrdered(widget.org, contract.contractId);
    return memberHoldsBasketOn(contract, ordered, deliveryId, widget.memberId);
  }

  bool get _canSubmit {
    if (_selectedDelivery == null) return false;
    final contracts = _eligibleContracts;
    if (contracts.length > 1 && _selectedContract == null) return false;
    return true;
  }

  String _formatDeliveryLabel(Delivery d) {
    final date = DateTime.tryParse(d.scheduledDate);
    if (date == null) return d.deliveryId;
    final datePart = DateFormat('EEEE d MMM', 'fr').format(date);
    final capitalised = datePart[0].toUpperCase() + datePart.substring(1);
    final descriptions = d.contracts
        .map((c) => c.deliveryDescription)
        .where((desc) => desc.isNotEmpty)
        .toSet()
        .join(' + ');
    if (descriptions.isEmpty) return capitalised;
    return '$capitalised • $descriptions';
  }

  void _submit() {
    final delivery = _selectedDelivery;
    if (delivery == null) return;
    final contracts = _eligibleContracts;
    final contract = contracts.length == 1
        ? contracts.first
        : _selectedContract;
    Navigator.of(context).pop();
    widget.onConfirm(
      proposedDeliveryId: delivery.deliveryId,
      proposedContractId: contract?.contractId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eligible = _eligibleDeliveries;
    final showContractPicker = _eligibleContracts.length > 1;

    return AlertDialog(
      title: const Text('Demander cet échange'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Offer recap ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 ${widget.contractDescription}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('👤 Proposé par : ${widget.offererDisplayName}'),
                    if (widget.offer.motive != null) ...[
                      const SizedBox(height: 4),
                      Text('💬 "${widget.offer.motive}"'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- Counter-delivery picker ---
            const Text('🔄 Votre panier proposé en échange :'),
            const SizedBox(height: 8),
            if (eligible.isEmpty)
              const Text(
                "Aucune de vos livraisons à venir n'est disponible pour "
                'un échange en retour.',
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else
              DropdownButtonFormField<Delivery>(
                initialValue: _selectedDelivery,
                hint: const Text('Choisir la livraison à céder'),
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
                onChanged: (d) => setState(() {
                  _selectedDelivery = d;
                  _selectedContract = null;
                }),
              ),

            // --- Contract picker (only when ambiguous) ---
            if (showContractPicker) ...[
              const SizedBox(height: 16),
              const Text('🛒 Sélectionner le contrat à céder :'),
              const SizedBox(height: 8),
              DropdownButtonFormField<DeliveryContract>(
                initialValue: _selectedContract,
                hint: const Text('Choisir un contrat'),
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _eligibleContracts
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

            // --- Explanation ---
            const SizedBox(height: 16),
            Text(
              '${widget.offererDisplayName} recevra votre proposition et '
              'choisira de la valider ou non. Si une autre proposition est '
              'validée, la vôtre sera automatiquement refusée.',
              style: Theme.of(context).textTheme.bodySmall,
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
          child: const Text('ENVOYER'),
        ),
      ],
    );
  }
}
