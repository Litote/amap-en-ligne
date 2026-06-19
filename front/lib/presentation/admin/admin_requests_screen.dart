import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_state.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const _kStatusPending = 'En attente';
const _kStatusApproved = 'Approuvée';
const _kStatusRejected = 'Rejetée';

class AdminRequestsScreen extends StatelessWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final producerRequestRepository = context.read<ProducerRequestRepository>();
    return BlocProvider(
      create: (_) =>
          AdminRequestsBloc(
            organizationRequestRepository: context
                .read<OrganizationRequestRepository>(),
          )..add(
            const AdminRequestsEvent.loadRequested(
              statusFilter: OrganizationRequestStatus.pendingValidation,
            ),
          ),
      child: StreamBuilder<List<AdminProducerRequest>>(
        stream: producerRequestRepository.watch(),
        builder: (context, snapshot) {
          final producerRequests = snapshot.data ?? const [];
          return _AdminRequestsView(producerRequests: producerRequests);
        },
      ),
    );
  }
}

class _AdminRequestsView extends StatefulWidget {
  const _AdminRequestsView({required this.producerRequests});

  final List<AdminProducerRequest> producerRequests;

  @override
  State<_AdminRequestsView> createState() => _AdminRequestsViewState();
}

class _AdminRequestsViewState extends State<_AdminRequestsView>
    with SingleTickerProviderStateMixin {
  AdminOrganizationRequest? _selectedRequest;
  ProducerRequestStatus? _producerStatusFilter =
      ProducerRequestStatus.pendingValidation;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      final orgType = _tabController.index == 0
          ? OrganizationType.amap
          : OrganizationType.producer;
      context.read<AdminRequestsBloc>().add(
        AdminRequestsEvent.organizationTypeFilterChanged(orgType),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Demandes d\'organisation',
      actions: const [SyncButton()],
      body: BlocConsumer<AdminRequestsBloc, AdminRequestsState>(
        listenWhen: (previous, current) {
          if (previous is! AdminRequestsLoaded ||
              current is! AdminRequestsLoaded) {
            return false;
          }
          return previous.actionInProgress && !current.actionInProgress;
        },
        listener: (context, state) {
          if (state is AdminRequestsLoaded && state.actionError != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionError!)));
            return;
          }
          // Success: close detail view if open.
          setState(() => _selectedRequest = null);
        },
        builder: (context, state) => switch (state) {
          AdminRequestsInitial() || AdminRequestsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AdminRequestsError(:final message) => _ErrorView(
            message: message,
            onRetry: () => context.read<AdminRequestsBloc>().add(
              const AdminRequestsEvent.loadRequested(),
            ),
          ),
          AdminRequestsLoaded(
            :final requests,
            :final statusFilter,
            :final organizationTypeFilter,
            :final actionInProgress,
            :final actionError,
          ) =>
            _loadedBody(
              context,
              requests: requests,
              producerRequests: widget.producerRequests,
              statusFilter: statusFilter,
              organizationTypeFilter: organizationTypeFilter,
              actionInProgress: actionInProgress,
              actionError: actionError,
            ),
        },
      ),
    );
  }

  Widget _loadedBody(
    BuildContext context, {
    required List<AdminOrganizationRequest> requests,
    required List<AdminProducerRequest> producerRequests,
    required OrganizationRequestStatus? statusFilter,
    required OrganizationType organizationTypeFilter,
    required bool actionInProgress,
    required String? actionError,
  }) {
    // Detail view is only available for AMAP requests.
    if (_selectedRequest != null) {
      final updated = requests
          .where((r) => r.requestId == _selectedRequest!.requestId)
          .firstOrNull;
      return _DetailView(
        request: updated ?? _selectedRequest!,
        actionInProgress: actionInProgress,
        actionError: actionError,
        onBack: () => setState(() => _selectedRequest = null),
        onApprove: () => context.read<AdminRequestsBloc>().add(
          AdminRequestsEvent.approveRequested(_selectedRequest!),
        ),
        onReject: (comment) => context.read<AdminRequestsBloc>().add(
          AdminRequestsEvent.rejectRequested(
            request: _selectedRequest!,
            reviewComment: comment,
          ),
        ),
        onResend: () => context.read<AdminRequestsBloc>().add(
          AdminRequestsEvent.resendRequested(updated ?? _selectedRequest!),
        ),
      );
    }

    final isProducerTab = organizationTypeFilter == OrganizationType.producer;

    final filteredAmapRequests = requests
        .where((r) => r.organizationType == OrganizationType.amap)
        .where((r) => statusFilter == null || r.status == statusFilter)
        .toList();

    return Column(
      children: [
        const SyncStatusBanner(),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'AMAPs'),
            Tab(text: 'Producteurs'),
          ],
        ),
        if (!isProducerTab)
          _StatusFilterBar(
            selected: statusFilter,
            onSelected: (status) => context.read<AdminRequestsBloc>().add(
              AdminRequestsEvent.loadRequested(statusFilter: status),
            ),
          )
        else
          _ProducerStatusFilterBar(
            selected: _producerStatusFilter,
            onSelected: (status) =>
                setState(() => _producerStatusFilter = status),
          ),
        Expanded(
          child: isProducerTab
              ? _ProducerRequestList(
                  producerRequests: producerRequests
                      .where(
                        (r) =>
                            _producerStatusFilter == null ||
                            r.status == _producerStatusFilter,
                      )
                      .toList(),
                )
              : (filteredAmapRequests.isEmpty
                    ? const Center(child: Text('Aucune demande trouvée.'))
                    : ListView.separated(
                        itemCount: filteredAmapRequests.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final request = filteredAmapRequests[index];
                          return _RequestTile(
                            request: request,
                            onTap: () =>
                                setState(() => _selectedRequest = request),
                          );
                        },
                      )),
        ),
      ],
    );
  }
}

class _ProducerStatusFilterBar extends StatelessWidget {
  const _ProducerStatusFilterBar({
    required this.selected,
    required this.onSelected,
  });

  final ProducerRequestStatus? selected;
  final ValueChanged<ProducerRequestStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Toutes'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text(_kStatusPending),
            selected: selected == ProducerRequestStatus.pendingValidation,
            onSelected: (_) =>
                onSelected(ProducerRequestStatus.pendingValidation),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Approuvées'),
            selected: selected == ProducerRequestStatus.approved,
            onSelected: (_) => onSelected(ProducerRequestStatus.approved),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Rejetées'),
            selected: selected == ProducerRequestStatus.rejected,
            onSelected: (_) => onSelected(ProducerRequestStatus.rejected),
          ),
        ],
      ),
    );
  }
}

class _ProducerRequestList extends StatelessWidget {
  const _ProducerRequestList({required this.producerRequests});

  final List<AdminProducerRequest> producerRequests;

  @override
  Widget build(BuildContext context) {
    if (producerRequests.isEmpty) {
      return const Center(child: Text('Aucune demande trouvée.'));
    }
    return ListView.separated(
      itemCount: producerRequests.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final request = producerRequests[index];
        return _ProducerRequestTile(
          request: request,
          onTap: () => context.go('/admin/producer-requests', extra: request),
        );
      },
    );
  }
}

class _ProducerRequestTile extends StatelessWidget {
  const _ProducerRequestTile({required this.request, required this.onTap});

  final AdminProducerRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(request.producerName),
      subtitle: Text(request.adminEmail),
      trailing: _ProducerStatusBadge(status: request.status),
      onTap: onTap,
    );
  }
}

class _ProducerStatusBadge extends StatelessWidget {
  const _ProducerStatusBadge({required this.status});

  final ProducerRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _producerStatusLabel(status),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: _producerStatusColor(status),
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

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onSelected});

  final OrganizationRequestStatus? selected;
  final ValueChanged<OrganizationRequestStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Toutes'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text(_kStatusPending),
            selected: selected == OrganizationRequestStatus.pendingValidation,
            onSelected: (_) =>
                onSelected(OrganizationRequestStatus.pendingValidation),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text(_kStatusApproved),
            selected: selected == OrganizationRequestStatus.approved,
            onSelected: (_) => onSelected(OrganizationRequestStatus.approved),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text(_kStatusRejected),
            selected: selected == OrganizationRequestStatus.rejected,
            onSelected: (_) => onSelected(OrganizationRequestStatus.rejected),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.onTap});

  final AdminOrganizationRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(request.organizationName),
      subtitle: Text(request.adminEmail),
      trailing: _StatusBadge(status: request.status),
      onTap: onTap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrganizationRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _statusLabel(status),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: _statusColor(status),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.request,
    required this.actionInProgress,
    required this.actionError,
    required this.onBack,
    required this.onApprove,
    required this.onReject,
    required this.onResend,
  });

  final AdminOrganizationRequest request;
  final bool actionInProgress;
  final String? actionError;
  final VoidCallback onBack;
  final VoidCallback onApprove;
  final ValueChanged<String?> onReject;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final isPending =
        request.status == OrganizationRequestStatus.pendingValidation;
    final isApproved = request.status == OrganizationRequestStatus.approved;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
          ),
          const SizedBox(height: 16),
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
                          request.organizationName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      _StatusBadge(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Type',
                    value: _organizationTypeLabel(request.organizationType),
                  ),
                  _InfoRow(
                    label: 'Administrateur',
                    value: '${request.adminFirstName} ${request.adminLastName}',
                  ),
                  _InfoRow(label: 'Email', value: request.adminEmail),
                  _InfoRow(label: 'Fuseau horaire', value: request.timezone),
                  _InfoRow(label: 'Langue', value: request.defaultLanguage),
                  _InfoRow(label: 'Soumise le', value: request.submittedAt),
                  if (request.reviewedAt != null)
                    _InfoRow(label: 'Traitée le', value: request.reviewedAt!),
                  if (request.submitterComment != null)
                    _InfoRow(
                      label: 'Message du demandeur',
                      value: request.submitterComment!,
                    ),
                  if (request.reviewComment != null)
                    _InfoRow(
                      label: 'Commentaire',
                      value: request.reviewComment!,
                    ),
                ],
              ),
            ),
          ),
          if (actionError != null) ...[
            const SizedBox(height: 8),
            Text(
              actionError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 16),
            if (actionInProgress)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Approuver'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Rejeter'),
                    ),
                  ),
                ],
              ),
          ],
          if (isApproved) ...[
            const SizedBox(height: 16),
            if (actionInProgress)
              const Center(child: CircularProgressIndicator())
            else
              TextButton.icon(
                onPressed: onResend,
                icon: const Icon(Icons.send),
                label: const Text('Renvoyer l\'invitation'),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final comment = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _RejectDialog(),
    );
    if (comment != null) {
      onReject(comment.isEmpty ? null : comment);
    }
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
            width: 120,
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

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  late final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejeter la demande'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Commentaire (facultatif)',
          hintText: 'Motif du rejet',
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

String _statusLabel(OrganizationRequestStatus status) => switch (status) {
  OrganizationRequestStatus.pendingValidation => _kStatusPending,
  OrganizationRequestStatus.approved => _kStatusApproved,
  OrganizationRequestStatus.rejected => _kStatusRejected,
};

Color _statusColor(OrganizationRequestStatus status) => switch (status) {
  OrganizationRequestStatus.pendingValidation => Colors.orange,
  OrganizationRequestStatus.approved => Colors.green,
  OrganizationRequestStatus.rejected => Colors.red,
};

String _producerStatusLabel(ProducerRequestStatus status) => switch (status) {
  ProducerRequestStatus.pendingValidation => _kStatusPending,
  ProducerRequestStatus.approved => _kStatusApproved,
  ProducerRequestStatus.rejected => _kStatusRejected,
};

Color _producerStatusColor(ProducerRequestStatus status) => switch (status) {
  ProducerRequestStatus.pendingValidation => Colors.orange,
  ProducerRequestStatus.approved => Colors.green,
  ProducerRequestStatus.rejected => Colors.red,
};

String _organizationTypeLabel(OrganizationType type) => switch (type) {
  OrganizationType.amap => 'AMAP',
  OrganizationType.producer => 'Producteur',
};
