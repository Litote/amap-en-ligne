import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/presentation/coordinator/delivery_volunteer_summary.dart';
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slots_bloc.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_format.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_status_chip.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Screen 02 — Coordinator: delivery time slot management.
///
/// Lists all deliveries for the organization and allows creating new ones or
/// deleting existing ones.
class TimeSlotsScreen extends StatelessWidget {
  const TimeSlotsScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    if (tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: 'Gestion des livraisons',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return BlocProvider(
      create: (_) => TimeSlotsBloc(
        orgRepo: context.read<OrganizationRepository>(),
        syncBloc: context.read<SyncBloc>(),
      ),
      child: _TimeSlotsView(tenantId: tenantId),
    );
  }
}

class _TimeSlotsView extends StatelessWidget {
  const _TimeSlotsView({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Gestion des livraisons',
      actions: const [SyncButton()],
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/coordinator/time-slots/new'),
        tooltip: 'Ajouter livraison',
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<Organization?>(
        stream: context.read<OrganizationRepository>().watch(tenantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final org = snapshot.data;
          if (org == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _DeliveryList(org: org);
        },
      ),
    );
  }
}

class _DeliveryList extends StatelessWidget {
  const _DeliveryList({required this.org});

  final Organization org;

  @override
  Widget build(BuildContext context) {
    if (org.deliveries.isEmpty) {
      return const Center(child: Text('Aucun créneau de livraison.'));
    }

    final now = DateTime.now();
    final inProgress = <Delivery>[];
    final upcoming = <Delivery>[];
    final past = <Delivery>[];
    for (final delivery in org.deliveries) {
      if (delivery.status == DeliveryStatus.inProgress) {
        inProgress.add(delivery);
      } else if (delivery.status.isActive &&
          DateTime.parse(delivery.scheduledDate).isAfter(now)) {
        upcoming.add(delivery);
      } else {
        past.add(delivery);
      }
    }
    _sortByDate(inProgress);
    _sortByDate(upcoming);
    _sortByDate(past);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._section(context, 'En cours', inProgress),
        ..._section(context, 'À venir', upcoming),
        ..._section(context, 'Passées', past),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<Delivery> deliveries,
  ) {
    if (deliveries.isEmpty) return const [];
    return [
      _SectionHeader(title: title),
      for (final delivery in deliveries)
        Dismissible(
          key: ValueKey(delivery.deliveryId),
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Icon(Icons.delete),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context.read<TimeSlotsBloc>().add(
              TimeSlotsEvent.deleteRequested(
                currentOrg: org,
                deliveryId: delivery.deliveryId,
              ),
            );
          },
          child: _DeliveryCard(org: org, delivery: delivery),
        ),
      const SizedBox(height: 16),
    ];
  }

  static void _sortByDate(List<Delivery> deliveries) {
    deliveries.sort(
      (a, b) => DateTime.parse(
        a.scheduledDate,
      ).compareTo(DateTime.parse(b.scheduledDate)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.org, required this.delivery});

  final Organization org;
  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final title = formatDeliveryDateTime(delivery.scheduledDate);
    final summary = deliveryVolunteerSummary(delivery);
    final productNames = org.productNamesForDelivery(delivery);
    final coordinators = _getAllCoordinators();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlotStatusChip(slotStatus: deliverySlotStatus(delivery)),
                const SizedBox(height: 4),
                Text('${summary.current}/${summary.required} bénévoles'),
                if (coordinators.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '👥 ${coordinators.length} coordinateur${coordinators.length > 1 ? 's' : ''}',
                  ),
                ],
                if (productNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Produits : ${productNames.join(' + ')}'),
                ],
              ],
            ),
            isThreeLine: true,
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => context.push(
                  '/coordinator/time-slots/${delivery.deliveryId}',
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('MODIFIER'),
              ),
              TextButton.icon(
                onPressed: () => context.push(
                  '/coordinator/tracking/${delivery.deliveryId}',
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('SUIVRE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _getAllCoordinators() {
    final coordinators = <String>{};
    for (final contract in delivery.contracts) {
      coordinators.addAll(contract.coordinators);
    }
    return coordinators.toList();
  }
}
