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
  });

  final List<Contract> contracts;
  final Organization organization;
  final List<ProducerAccount> producerAccounts;
  final String? selectedContractId;
  final VoidCallback onCreateRequested;
  final ValueChanged<Contract> onSelected;

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            Expanded(
              child: contracts.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun contrat de saison n\'est encore défini. Créez votre premier contrat.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
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
                            '$producerName • ${contract.seasonYear} • ${contract.members.length} amapiens',
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
}
