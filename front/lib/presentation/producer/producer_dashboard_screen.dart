import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hub screen for the producer role.
///
/// Shows a greeting header and navigation tiles to producer sub-sections.
/// The optional [tenantId] is accepted for future data loading.
class ProducerDashboardScreen extends StatelessWidget {
  const ProducerDashboardScreen({super.key, this.tenantId});

  final String? tenantId;

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Mon tableau de bord',
      actions: const [SyncButton()],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Bonjour 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          _DashboardTile(
            icon: Icons.inventory,
            label: 'Catalogue de produits',
            subtitle: 'Gérez vos types de produits',
            route: '/product-types',
          ),
          _DashboardTile(
            icon: Icons.local_shipping,
            label: 'Mes livraisons',
            subtitle: 'Suivez vos livraisons à venir',
            route: '/producer-deliveries',
          ),
          _DashboardTile(
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
  Widget build(BuildContext context) {
    return Card(
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
}
