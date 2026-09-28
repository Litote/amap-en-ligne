import 'package:amap_en_ligne/data/repositories/producer_schedule_repository.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule_view.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_format.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_status_chip.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/producer/producer_composition_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Home screen of the producer role (screen-producer-01-home).
///
/// Greets the producer by name, then summarises its activity from its
/// [ProducerSchedule] projections — the only view a producer has of the AMAPs'
/// deliveries: overview, next deliveries, contracts in progress — and ends
/// with the quick-access tiles.
class ProducerDashboardScreen extends StatefulWidget {
  const ProducerDashboardScreen({super.key, this.tenantId});

  /// The producer account id; null ⇒ no schedule is loaded (tiles only).
  final String? tenantId;

  @override
  State<ProducerDashboardScreen> createState() =>
      _ProducerDashboardScreenState();
}

class _ProducerDashboardScreenState extends State<ProducerDashboardScreen> {
  // Created once: a fresh drift query stream on every rebuild would
  // resubscribe (and re-emit) endlessly.
  Stream<List<ProducerSchedule>>? _schedules;

  @override
  void initState() {
    super.initState();
    _schedules = _watch(widget.tenantId);
  }

  @override
  void didUpdateWidget(ProducerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenantId != widget.tenantId) {
      _schedules = _watch(widget.tenantId);
    }
  }

  Stream<List<ProducerSchedule>>? _watch(String? tenantId) => tenantId == null
      ? null
      : context.read<ProducerScheduleRepository>().watch(tenantId);

  @override
  Widget build(BuildContext context) {
    final schedules = _schedules;
    return ConnectedScaffold(
      title: 'Mon tableau de bord',
      actions: const [SyncButton()],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Greeting(),
          if (schedules == null)
            const _FirstSyncNotice()
          else
            StreamBuilder<List<ProducerSchedule>>(
              stream: schedules,
              builder: (context, snapshot) {
                final schedules = snapshot.data;
                final summary = schedules == null
                    ? const SizedBox.shrink()
                    : _Summary(
                        summary: producerDashboardSummary(
                          schedules,
                          DateTime.now(),
                        ),
                      );
                // Nothing cached yet (first sync after login): say the data
                // is coming rather than showing nothing or empty states.
                return schedules == null || schedules.isEmpty
                    ? _FirstSyncNotice(orElse: summary)
                    : summary;
              },
            ),
          const _SectionTitle('Accès rapides'),
          const _DashboardTile(
            icon: Icons.inventory,
            label: 'Catalogue de produits',
            subtitle: 'Gérez vos types de produits',
            route: '/product-types',
          ),
          const _DashboardTile(
            icon: Icons.local_shipping,
            label: 'Mes livraisons',
            subtitle: 'Suivez vos livraisons à venir',
            route: '/producer-deliveries',
          ),
          const _DashboardTile(
            icon: Icons.tune,
            label: 'Préférences',
            subtitle: 'Paramètres du compte',
            route: '/preferences',
          ),
        ],
      ),
    );
  }
}

/// "Bonjour {nom} 👋" — the producer account name the menu header shows too.
/// « Synchronisation en cours… » while a sync runs, else [orElse]. Text only:
/// an endless progress animation would keep the screen from settling.
class _FirstSyncNotice extends StatelessWidget {
  const _FirstSyncNotice({this.orElse = const SizedBox.shrink()});

  final Widget orElse;

  @override
  Widget build(BuildContext context) => BlocBuilder<SyncBloc, SyncState>(
    builder: (context, state) => state is SyncRunning
        ? const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('🔄 Synchronisation en cours…'),
          )
        : orElse,
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: BlocSelector<AuthBloc, AuthViewState, String>(
      selector: (state) => [
        state.firstName?.trim() ?? '',
        state.lastName?.trim() ?? '',
      ].where((part) => part.isNotEmpty).join(' '),
      builder: (context, name) => Text(
        name.isEmpty ? 'Bonjour 👋' : 'Bonjour $name 👋',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final ProducerDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final next = summary.upcoming.firstOrNull;
    final partners = summary.partnerCount;
    final contracts = summary.activeContracts.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle("📊 Vue d'ensemble"),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• $partners organisme${partners > 1 ? 's' : ''} '
                  'partenaire${partners > 1 ? 's' : ''}',
                ),
                Text(
                  '• $contracts contrat${contracts > 1 ? 's' : ''} '
                  'en cours',
                ),
                Text(
                  next == null
                      ? '• Aucune livraison à venir'
                      : '• Prochaine livraison : '
                            '${formatDeliveryDateLine(next.delivery.scheduledDate)}'
                            ' • ${next.organizationName}',
                ),
              ],
            ),
          ),
        ),
        const _SectionTitle('📅 Prochaines livraisons'),
        if (summary.upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune livraison à venir pour vos produits.'),
          )
        else ...[
          for (final entry in summary.upcoming) _UpcomingCard(entry: entry),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/producer-deliveries'),
              child: const Text('VOIR TOUTES MES LIVRAISONS'),
            ),
          ),
        ],
        const _SectionTitle('📊 Mes contrats actifs'),
        if (summary.activeContracts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun contrat en cours.'),
          )
        else
          for (final contract in summary.activeContracts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• ${contract.organizationName} - ${contract.contractName} '
                '(${contract.basketQuantity} '
                'panier${contract.basketQuantity > 1 ? 's' : ''}/livraison)',
              ),
            ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.entry});

  final ProducerUpcomingDelivery entry;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      title: Text(
        '📅 ${formatDeliveryDateLine(entry.delivery.scheduledDate)} • '
        '${entry.organizationName}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final contract in entry.delivery.contracts)
            Text(
              '${contract.contractName} • ${contract.basketQuantity} '
              'panier${contract.basketQuantity > 1 ? 's' : ''}'
              '${scheduleContractStatusSuffix(contract)}',
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: ProducerCompositionButton(
              organizationId: entry.organizationId,
              deliveryId: entry.delivery.deliveryId,
            ),
          ),
        ],
      ),
      trailing: DeliveryStatusChip(status: entry.delivery.status),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(route),
    ),
  );
}
