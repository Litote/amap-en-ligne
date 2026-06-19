import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_format.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_status_chip.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// MVP screen listing deliveries relevant to the current producer.
///
/// A delivery is "relevant" when at least one of its linked delivery-contracts
/// maps to a [Contract] whose [Contract.producerAccountId] equals
/// [producerAccountId]. Deliveries are sorted newest-first.
///
/// Read-only: no mutations are performed, no dedicated BLoC is needed. The
/// screen uses nested [StreamBuilder]s: the outer one resolves the
/// [Organization] from [tenantId] (which equals the producer's sub), and the
/// inner one resolves the [Contract] list from the org's real [Organization.organizationId].
class ProducerDeliveriesScreen extends StatelessWidget {
  const ProducerDeliveriesScreen({
    super.key,
    required this.tenantId,
    required this.producerAccountId,
  });

  final String tenantId;
  final String producerAccountId;

  @override
  Widget build(BuildContext context) => ConnectedScaffold(
      title: 'Mes livraisons',
      actions: const [SyncButton()],
      body: StreamBuilder<Organization?>(
        stream: context.read<OrganizationRepository>().watch(tenantId),
        builder: (context, orgSnapshot) {
          final org = orgSnapshot.data;
          if (org == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<Contract>>(
            stream: context.read<ContractRepository>().watch(
              org.organizationId,
            ),
            initialData: const <Contract>[],
            builder: (context, contractsSnapshot) {
              final contracts = contractsSnapshot.data ?? const <Contract>[];
              final deliveries = org.deliveriesForProducer(
                producerAccountId,
                contracts: contracts,
              );
              if (deliveries.isEmpty) {
                return const Center(
                  child: Text('Aucune livraison pour vos produits.'),
                );
              }
              return ListView.builder(
                itemCount: deliveries.length,
                itemBuilder: (context, i) =>
                    _DeliveryTile(delivery: deliveries[i]),
              );
            },
          );
        },
      ),
    );
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) => ListTile(
      leading: const Icon(Icons.local_shipping),
      title: Text(formatDeliveryDateLine(delivery.scheduledDate)),
      subtitle: Text(_basketSummary(delivery)),
      trailing: DeliveryStatusChip(status: delivery.status),
    );

  String _basketSummary(Delivery delivery) {
    final count = delivery.contracts.length;
    if (count == 0) return '';
    return count == 1 ? '1 contrat lié' : '$count contrats liés';
  }
}
