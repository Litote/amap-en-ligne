import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_associations.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DeliveryTemplateListScreen extends StatelessWidget {
  const DeliveryTemplateListScreen({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DeliveryTemplateBloc(
        repository: context.read<DeliveryTemplateRepository>(),
        organizationId: organizationId,
      )..add(const DeliveryTemplateEvent.loadTemplates()),
      child: _DeliveryTemplateListView(organizationId: organizationId),
    );
  }
}

class _DeliveryTemplateListView extends StatelessWidget {
  const _DeliveryTemplateListView({required this.organizationId});

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    final organizationRepository = context.read<OrganizationRepository>();
    return ConnectedScaffold(
      title: 'Modèles de livraison',
      actions: const [SyncButton()],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/delivery-templates/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau modèle'),
      ),
      body: StreamBuilder<Organization?>(
        stream: organizationRepository.watch(organizationId),
        builder: (context, organizationSnapshot) {
          return BlocBuilder<DeliveryTemplateBloc, DeliveryTemplateState>(
            builder: (context, state) => switch (state) {
              DeliveryTemplateInitial() || DeliveryTemplateLoading() =>
                const Center(child: CircularProgressIndicator()),
              DeliveryTemplateError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<DeliveryTemplateBloc>().add(
                  const DeliveryTemplateEvent.loadTemplates(),
                ),
              ),
              DeliveryTemplateLoaded(:final templates) =>
                templates.isEmpty
                    ? const Center(
                        child: Text('Aucun modèle de livraison configuré.'),
                      )
                    : _TemplateList(
                        templates: templates,
                        organization: organizationSnapshot.data,
                        organizationId: organizationId,
                      ),
            },
          );
        },
      ),
    );
  }
}

class _TemplateList extends StatelessWidget {
  const _TemplateList({
    required this.templates,
    required this.organization,
    required this.organizationId,
  });

  final List<DeliveryTemplate> templates;
  final Organization? organization;
  final String organizationId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: templates.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateTile(
          template: template,
          organization: organization,
          organizationId: organizationId,
        );
      },
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.organization,
    required this.organizationId,
  });

  final DeliveryTemplate template;
  final Organization? organization;
  final String organizationId;

  @override
  Widget build(BuildContext context) {
    final earlySlot = template.earlySlot;
    final associations = computeDeliveryTemplateAssociations(
      organization,
      template.deliveryTemplateId,
    );
    return ListTile(
      title: Text(template.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${template.standardStartTime} – ${template.standardEndTime}'
            '${earlySlot != null ? ' · Livraison anticipée ${earlySlot.arrivalTime}' : ''}',
          ),
          const SizedBox(height: 4),
          Text(
            '${associations.associationCount} livraison${associations.associationCount == 1 ? '' : 's'} associée${associations.associationCount == 1 ? '' : 's'}',
          ),
          if (associations.associationCount > 0)
            TextButton.icon(
              key: ValueKey('view_deliveries_${template.deliveryTemplateId}'),
              onPressed: () => _showAssociatedDeliveries(context, associations),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Voir livraisons'),
            ),
        ],
      ),
      trailing: PopupMenuButton<_TemplateAction>(
        icon: const Icon(Icons.more_horiz),
        onSelected: (action) {
          if (action == _TemplateAction.edit) {
            context.push(
              '/admin/delivery-templates/${template.deliveryTemplateId}',
              extra: template,
            );
            return;
          }
          _handleDelete(context, associations);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: _TemplateAction.edit, child: Text('Modifier')),
          PopupMenuItem(
            value: _TemplateAction.delete,
            child: Text('Supprimer'),
          ),
        ],
      ),
      onTap: () => context.push(
        '/admin/delivery-templates/${template.deliveryTemplateId}',
        extra: template,
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    DeliveryTemplateAssociations associations,
  ) async {
    if (associations.futureAssociatedDeliveries.isNotEmpty) {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: const Text(
            'Ce modèle ne peut pas être supprimé tant que des livraisons futures y sont associées.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await _confirmDelete(
      context,
      associations.associationCount,
    );
    if (confirmed != true || !context.mounted) return;
    context.read<DeliveryTemplateBloc>().add(
      DeliveryTemplateEvent.deleteTemplate(
        templateId: template.deliveryTemplateId,
        organizationId: organizationId,
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, int associationCount) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le modèle'),
        content: Text(
          associationCount == 0
              ? 'Voulez-vous supprimer le modèle "${template.name}" ?'
              : 'Voulez-vous supprimer le modèle "${template.name}" ? '
                    '$associationCount livraison${associationCount == 1 ? '' : 's'} passée${associationCount == 1 ? '' : 's'} restera${associationCount == 1 ? '' : 'ont'} non associée${associationCount == 1 ? '' : 's'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssociatedDeliveries(
    BuildContext context,
    DeliveryTemplateAssociations associations,
  ) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Livraisons associées'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: associations.associatedDeliveries
                .map(
                  (delivery) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_formatDeliveryDate(delivery.scheduledDate)),
                    subtitle: Text(_deliveryStatusLabel(delivery.status)),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
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

String _formatDeliveryDate(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;
  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year à $hour:$minute';
}

String _deliveryStatusLabel(DeliveryStatus status) => switch (status) {
  DeliveryStatus.planned => 'Planifiée',
  DeliveryStatus.confirmed => 'Confirmée',
  DeliveryStatus.inProgress => 'En cours',
  DeliveryStatus.completed => 'Terminée',
  DeliveryStatus.cancelled => 'Annulée',
};

enum _TemplateAction { edit, delete }
