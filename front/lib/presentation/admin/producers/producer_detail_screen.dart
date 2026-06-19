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

/// Screen that shows the detail of a single producer in an organization.
///
/// Accepts an [organizationId] and a [producerAccountId]. The BLoC is created
/// fresh here so the screen owns the lifecycle of its bloc.
class ProducerDetailScreen extends StatelessWidget {
  const ProducerDetailScreen({
    required this.organizationId,
    required this.producerAccountId,
    super.key,
  });

  final String organizationId;
  final String producerAccountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProducerManagementBloc(
              organizationRepository: context.read<OrganizationRepository>(),
              adminApi: context.read<AdminApi>(),
              organizationId: organizationId,
            )
            ..add(const ProducerManagementEvent.loadRequested())
            ..add(ProducerManagementEvent.detailRequested(producerAccountId)),
      child: _ProducerDetailView(producerAccountId: producerAccountId),
    );
  }
}

class _ProducerDetailView extends StatelessWidget {
  const _ProducerDetailView({required this.producerAccountId});

  final String producerAccountId;

  @override
  Widget build(BuildContext context) {
    final producerAccountRepository = context.read<ProducerAccountRepository>();
    return StreamBuilder<List<ProducerAccount>>(
      stream: producerAccountRepository.watchAll(),
      initialData: const <ProducerAccount>[],
      builder: (context, snapshot) {
        final producerDirectory = {
          for (final producer in snapshot.data ?? const <ProducerAccount>[])
            producer.producerAccountId: producer,
        };
        return BlocBuilder<ProducerManagementBloc, ProducerManagementState>(
          builder: (context, state) => switch (state) {
            ProducerManagementInitial() ||
            ProducerManagementLoading() => const ConnectedScaffold(
              title: 'Producteur',
              body: Center(child: CircularProgressIndicator()),
            ),
            ProducerManagementError(:final message) => ConnectedScaffold(
              title: 'Producteur',
              body: Center(child: Text(message)),
            ),
            ProducerManagementDetailLoaded(
              :final organization,
              :final producerAccountId,
              :final actionInProgress,
              :final actionError,
            ) =>
              _DetailBody(
                organization: organization,
                producerAccountId: producerAccountId,
                producerProfile: producerDirectory[producerAccountId],
                actionInProgress: actionInProgress,
                actionError: actionError,
              ),
            ProducerManagementListLoaded(:final organization) => _DetailBody(
              organization: organization,
              producerAccountId: producerAccountId,
              producerProfile: producerDirectory[producerAccountId],
              actionInProgress: false,
              actionError: null,
            ),
            ProducerManagementEnrollStep1() ||
            ProducerManagementEnrollStep2() ||
            ProducerManagementEnrollNoAccountStep2() => const ConnectedScaffold(
              title: 'Producteur',
              body: SizedBox.shrink(),
            ),
          },
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.organization,
    required this.producerAccountId,
    required this.producerProfile,
    required this.actionInProgress,
    required this.actionError,
  });

  final Organization organization;
  final String producerAccountId;
  final ProducerAccount? producerProfile;
  final bool actionInProgress;
  final String? actionError;

  @override
  Widget build(BuildContext context) {
    final producer = organization.producers
        .where((p) => p.producerAccountId == producerAccountId)
        .firstOrNull;

    final products = organization.products
        .where((p) => p.producerAccountId == producerAccountId)
        .toList();
    final canEditProducts =
        producerProfile?.managementMode == ProducerManagementMode.noAccount;
    final colorScheme = Theme.of(context).colorScheme;

    return ConnectedScaffold(
      title: 'Producteur',
      actions: const [SyncButton()],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
            const SizedBox(height: 16),
            if (producer == null)
              const Text('Producteur introuvable.')
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              producerProfile?.name ?? producerAccountId,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (producerProfile != null)
                                ProducerManagementModeBadge(
                                  mode: producerProfile!.managementMode,
                                ),
                              const SizedBox(height: 8),
                              _StatusBadge(status: producer.status),
                            ],
                          ),
                        ],
                      ),
                      if (producerProfile?.contactEmail != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Email',
                          value: producerProfile!.contactEmail!,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Inscrit le',
                        value: DateTime.parse(
                          producer.associationInstant,
                        ).toLocal().toString().substring(0, 10),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Identifiant', value: producerAccountId),
                      if (producerProfile?.linkedProducerAccount != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Compte lié',
                          value: producerProfile!.linkedProducerAccount!.name,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Produits (${products.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (canEditProducts)
                    OutlinedButton.icon(
                      key: const Key('edit_producer_products_button'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: context.read<ProducerManagementBloc>(),
                            child: EditProducerProductsScreen(
                              organization: organization,
                              producerAccount: producerProfile!,
                            ),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (products.isEmpty)
                const Text('Aucun produit assigné.')
              else
                ...products.map(
                  (p) => ListTile(
                    title: Text(p.name),
                    subtitle: p.description != null
                        ? Text(p.description!)
                        : null,
                    dense: true,
                  ),
                ),
              if (actionError != null) ...[
                const SizedBox(height: 8),
                Text(actionError!, style: TextStyle(color: colorScheme.error)),
              ],
              const SizedBox(height: 16),
              if (actionInProgress)
                const Center(child: CircularProgressIndicator())
              else
                _ActionButtons(
                  producer: producer,
                  onSuspend: () => _confirmAndUpdateStatus(
                    context,
                    OrganizationProducerStatus.suspended,
                    'Suspendre le producteur',
                    'Confirmer la suspension de ce producteur ?',
                  ),
                  onReactivate: () =>
                      context.read<ProducerManagementBloc>().add(
                        ProducerManagementEvent.updateStatusRequested(
                          producerAccountId: producerAccountId,
                          newStatus: OrganizationProducerStatus.active,
                        ),
                      ),
                  onTerminate: () => _confirmAndUpdateStatus(
                    context,
                    OrganizationProducerStatus.terminated,
                    'Mettre fin à l\'association',
                    'Cette action est irréversible. Confirmer ?',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndUpdateStatus(
    BuildContext context,
    OrganizationProducerStatus status,
    String title,
    String content,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ProducerManagementBloc>().add(
        ProducerManagementEvent.updateStatusRequested(
          producerAccountId: producerAccountId,
          newStatus: status,
        ),
      );
    }
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.producer,
    required this.onSuspend,
    required this.onReactivate,
    required this.onTerminate,
  });

  final OrganizationProducer producer;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  final VoidCallback onTerminate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (producer.status == OrganizationProducerStatus.active) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onSuspend,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.secondary,
              ),
              child: const Text('Suspendre'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (producer.status == OrganizationProducerStatus.suspended) ...[
          Expanded(
            child: FilledButton(
              onPressed: onReactivate,
              child: const Text('Réactiver'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (producer.status != OrganizationProducerStatus.terminated)
          Expanded(
            child: OutlinedButton(
              onPressed: onTerminate,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
              child: const Text('Mettre fin'),
            ),
          ),
      ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
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
