import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:flutter/material.dart';

/// Side-panel listing all season contracts with a button to create a new one.
class ContractList extends StatelessWidget {
  const ContractList({
    super.key,
    required this.contracts,
    required this.organization,
    required this.producerAccounts,
    required this.selectedContractId,
    required this.onCreateRequested,
    required this.onSelected,
    this.shrinkWrap = false,
  });

  final List<Contract> contracts;
  final Organization organization;
  final List<ProducerAccount> producerAccounts;
  final String? selectedContractId;
  final VoidCallback onCreateRequested;
  final ValueChanged<Contract> onSelected;

  /// Phone layout: the list takes the height of its contracts and scrolls
  /// with the page, instead of filling (and scrolling inside) its parent.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Contrats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.tonal(
                onPressed: onCreateRequested,
                child: const Text('➕ NOUVEAU CONTRAT'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fill(
            contracts.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun contrat de saison n\'est encore défini. Créez votre premier contrat.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: shrinkWrap,
                    physics: shrinkWrap
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: contracts.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final contract = contracts[index];
                      final selected =
                          contract.contractId == selectedContractId;
                      final producerName = contractProductLabel(
                        contract,
                        organization,
                        producerAccounts,
                      );
                      return ListTile(
                        selected: selected,
                        title: Text(contract.name),
                        subtitle: Text(
                          '$producerName • ${contract.seasonYear} • '
                          '${contract.members.length} amapiens'
                          // Its status may still say ACTIVE after the last
                          // delivery: flag it so it is not mistaken for open.
                          '${isContractEffectivelyEnded(contract) ? ' • Terminé' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onSelected(contract),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _fill(Widget child) => shrinkWrap ? child : Expanded(child: child);
}
