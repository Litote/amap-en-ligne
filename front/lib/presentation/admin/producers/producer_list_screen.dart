import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/admin/producers/edit_producer_products_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_management_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_ui_helpers.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProducerListScreen extends StatelessWidget {
  const ProducerListScreen({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProducerManagementBloc(
        organizationRepository: context.read<OrganizationRepository>(),
        adminApi: context.read<AdminApi>(),
        organizationId: organizationId,
      )..add(const ProducerManagementEvent.loadRequested()),
      child: const _ProducerListView(),
    );
  }
}

class _ProducerListView extends StatelessWidget {
  const _ProducerListView();

  @override
  Widget build(BuildContext context) {
    final producerAccountRepository = context.read<ProducerAccountRepository>();
    return ConnectedScaffold(
      title: 'Producteurs',
      actions: const [SyncButton()],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('add_producer_button'),
                onPressed: () => context.push('/admin/producers/enroll'),
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter un producteur'),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProducerAccount>>(
              stream: producerAccountRepository.watchAll(),
              initialData: const <ProducerAccount>[],
              builder: (context, snapshot) {
                final producerDirectory = {
                  for (final producer
                      in snapshot.data ?? const <ProducerAccount>[])
                    producer.producerAccountId: producer,
                };
                return BlocBuilder<
                  ProducerManagementBloc,
                  ProducerManagementState
                >(
                  builder: (context, state) => switch (state) {
                    ProducerManagementInitial() ||
                    ProducerManagementLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    ProducerManagementError(:final message) => _ErrorView(
                      message: message,
                      onRetry: () => context.read<ProducerManagementBloc>().add(
                        const ProducerManagementEvent.loadRequested(),
                      ),
                    ),
                    ProducerManagementListLoaded(
                      :final organization,
                      :final statusFilter,
                    ) =>
                      _LoadedBody(
                        organization: organization,
                        statusFilter: statusFilter,
                        producerDirectory: producerDirectory,
                      ),
                    ProducerManagementDetailLoaded() ||
                    ProducerManagementEnrollStep1() ||
                    ProducerManagementEnrollStep2() ||
                    ProducerManagementEnrollNoAccountStep2() =>
                      const SizedBox.shrink(),
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.organization,
    required this.statusFilter,
    required this.producerDirectory,
  });

  final Organization organization;
  final OrganizationProducerStatus? statusFilter;
  final Map<String, ProducerAccount> producerDirectory;

  @override
  Widget build(BuildContext context) {
    final filtered = statusFilter == null
        ? organization.producers.toList()
        : organization.producers
              .where((p) => p.status == statusFilter)
              .toList();

    return Column(
      children: [
        _StatusFilterBar(
          selected: statusFilter,
          onSelected: (status) => context.read<ProducerManagementBloc>().add(
            ProducerManagementEvent.statusFilterChanged(status),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aucun producteur trouvé.'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, idx) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final producer = filtered[index];
                    final producerProducts = organization.products
                        .where(
                          (p) =>
                              p.producerAccountId == producer.producerAccountId,
                        )
                        .toList();
                    return _ProducerTile(
                      organization: organization,
                      producer: producer,
                      producerProfile:
                          producerDirectory[producer.producerAccountId],
                      productCount: producerProducts.length,
                      onTap: () => context.push(
                        '/admin/producers/${producer.producerAccountId}',
                        extra: organization,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onSelected});

  final OrganizationProducerStatus? selected;
  final ValueChanged<OrganizationProducerStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tous'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Actifs'),
            selected: selected == OrganizationProducerStatus.active,
            onSelected: (_) => onSelected(OrganizationProducerStatus.active),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Suspendus'),
            selected: selected == OrganizationProducerStatus.suspended,
            onSelected: (_) => onSelected(OrganizationProducerStatus.suspended),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Terminés'),
            selected: selected == OrganizationProducerStatus.terminated,
            onSelected: (_) =>
                onSelected(OrganizationProducerStatus.terminated),
          ),
        ],
      ),
    );
  }
}

class _ProducerTile extends StatelessWidget {
  const _ProducerTile({
    required this.organization,
    required this.producer,
    required this.producerProfile,
    required this.productCount,
    required this.onTap,
  });

  final Organization organization;
  final OrganizationProducer producer;
  final ProducerAccount? producerProfile;
  final int productCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = producerProfile?.name ?? producer.producerAccountId;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (producerProfile != null) ...[
            ProducerManagementModeBadge(mode: producerProfile!.managementMode),
            const SizedBox(height: 4),
          ],
          if (producerProfile?.contactEmail != null)
            Text(producerProfile!.contactEmail!),
          if (producerProfile?.linkedProducerAccount != null) ...[
            Text(
              'Lié à ${producerProfile!.linkedProducerAccount!.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
          ],
          Text('$productCount produit${productCount != 1 ? 's' : ''}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusBadge(status: producer.status),
          const SizedBox(width: 8),
          PopupMenuButton<_ProducerRowAction>(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'Actions',
            onSelected: (action) {
              if (action == _ProducerRowAction.viewDetails) {
                onTap();
                return;
              }
              final profile = producerProfile;
              if (profile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Le profil synchronisé du producteur est indisponible.',
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ProducerManagementBloc>(),
                    child: EditProducerProductsScreen(
                      organization: organization,
                      producerAccount: profile,
                    ),
                  ),
                ),
              );
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _ProducerRowAction.viewDetails,
                child: Text('Voir la fiche'),
              ),
              const PopupMenuItem(
                value: _ProducerRowAction.editProducts,
                child: Text('Modifier les produits'),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrganizationProducerStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(context, status);
    return Chip(
      label: Text(
        _statusLabel(status),
        style: TextStyle(color: colors.text, fontSize: 12),
      ),
      backgroundColor: colors.background,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

String _statusLabel(OrganizationProducerStatus status) => switch (status) {
  OrganizationProducerStatus.active => 'Actif',
  OrganizationProducerStatus.suspended => 'Suspendu',
  OrganizationProducerStatus.terminated => 'Terminé',
};

({Color background, Color text}) _statusColors(
  BuildContext context,
  OrganizationProducerStatus status,
) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (status) {
    OrganizationProducerStatus.active => (
      background: colorScheme.primary,
      text: colorScheme.onPrimary,
    ),
    OrganizationProducerStatus.suspended => (
      background: colorScheme.secondary,
      text: colorScheme.onSecondary,
    ),
    OrganizationProducerStatus.terminated => (
      background: colorScheme.error,
      text: colorScheme.onError,
    ),
  };
}

enum _ProducerRowAction { viewDetails, editProducts }
