import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_contract_name.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:flutter/material.dart';

/// Display names of [delivery]'s contracts that have no coordinator yet, in
/// link order (live contract name, else the link snapshot).
List<String> missingCoordinatorContractNames(
  Delivery delivery,
  Iterable<Contract> contracts,
) => delivery.contracts
    .where((link) => link.coordinators.isEmpty)
    .map((link) => deliveryContractName(link, contracts))
    .toList();

/// « ⚠️ Coordinateur manquant : `<contrats>` » alert line of a delivery card
/// (coordinator dashboard and delivery list). Renders nothing when every
/// contract has a coordinator.
class MissingCoordinatorWarning extends StatelessWidget {
  const MissingCoordinatorWarning({super.key, required this.contractNames});

  final List<String> contractNames;

  @override
  Widget build(BuildContext context) {
    if (contractNames.isEmpty) return const SizedBox.shrink();
    return Text(
      '⚠️ Coordinateur manquant : ${contractNames.join(', ')}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
