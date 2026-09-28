import 'package:amap_en_ligne/data/repositories/producer_schedule_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule_view.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_format.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_status_chip.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/producer/producer_composition_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Upcoming deliveries of the producer's contracts, across every linked AMAP.
///
/// Read-only, fed by the [ProducerSchedule] projections of the producer's own
/// `producer-account:{id}` feed (a producer never receives the AMAPs' own
/// scopes, which carry members' personal data). Soonest first.
class ProducerDeliveriesScreen extends StatelessWidget {
  const ProducerDeliveriesScreen({super.key, required this.producerAccountId});

  final String producerAccountId;

  @override
  Widget build(BuildContext context) => ConnectedScaffold(
    title: 'Mes livraisons',
    actions: const [SyncButton()],
    body: StreamBuilder<List<ProducerSchedule>>(
      stream: context.read<ProducerScheduleRepository>().watch(
        producerAccountId,
      ),
      builder: (context, snapshot) {
        final schedules = snapshot.data;
        if (schedules == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final upcoming = _upcomingDeliveries(schedules, DateTime.now());
        if (upcoming.isEmpty) {
          return const Center(
            child: Text('Aucune livraison à venir pour vos produits.'),
          );
        }
        return ListView.builder(
          itemCount: upcoming.length,
          itemBuilder: (context, i) => _DeliveryTile(
            organizationId: upcoming[i].organizationId,
            organizationName: upcoming[i].organizationName,
            delivery: upcoming[i].delivery,
          ),
        );
      },
    ),
  );
}

/// Deliveries from today on (the whole day of today stays listed), soonest
/// first, each with the name of its AMAP.
List<
  ({
    String organizationId,
    String organizationName,
    ProducerScheduleDelivery delivery,
  })
>
_upcomingDeliveries(List<ProducerSchedule> schedules, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    for (final schedule in schedules)
      for (final delivery in schedule.deliveries)
        if (!(DateTime.tryParse(delivery.scheduledDate) ?? today).isBefore(
          today,
        ))
          (
            organizationId: schedule.organizationId,
            organizationName: schedule.organizationName,
            delivery: delivery,
          ),
  ]..sort(
    (a, b) => a.delivery.scheduledDate.compareTo(b.delivery.scheduledDate),
  );
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({
    required this.organizationId,
    required this.organizationName,
    required this.delivery,
  });

  final String organizationId;
  final String organizationName;
  final ProducerScheduleDelivery delivery;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.local_shipping),
    title: Text(formatDeliveryDateLine(delivery.scheduledDate)),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(organizationName),
        for (final contract in delivery.contracts)
          Text(
            '${contract.contractName} — ${contract.basketQuantity} '
            'panier${contract.basketQuantity > 1 ? 's' : ''}'
            '${scheduleContractStatusSuffix(contract)}',
          ),
        // A completed or cancelled delivery's composition is frozen.
        if (delivery.status.isActive)
          Align(
            alignment: Alignment.centerLeft,
            child: ProducerCompositionButton(
              organizationId: organizationId,
              deliveryId: delivery.deliveryId,
            ),
          ),
      ],
    ),
    trailing: DeliveryStatusChip(status: delivery.status),
  );
}
