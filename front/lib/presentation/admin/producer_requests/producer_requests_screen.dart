import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_state.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProducerRequestsScreen extends StatelessWidget {
  const ProducerRequestsScreen({super.key, this.initialRequest});

  final AdminProducerRequest? initialRequest;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProducerRequestsBloc(
            producerRequestRepository: context
                .read<ProducerRequestRepository>(),
          )..add(
            const ProducerRequestsEvent.loadRequested(
              statusFilter: ProducerRequestStatus.pendingValidation,
            ),
          ),
      child: _ProducerRequestsView(initialRequest: initialRequest),
    );
  }
}

class _ProducerRequestsView extends StatefulWidget {
  const _ProducerRequestsView({this.initialRequest});

  final AdminProducerRequest? initialRequest;

  @override
  State<_ProducerRequestsView> createState() => _ProducerRequestsViewState();
}

class _ProducerRequestsViewState extends State<_ProducerRequestsView> {
  AdminProducerRequest? _selectedRequest;

  @override
  void initState() {
    super.initState();
    _selectedRequest = widget.initialRequest;
  }

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Demandes producteurs',
      actions: const [SyncButton()],
      body: BlocConsumer<ProducerRequestsBloc, ProducerRequestsState>(
        listenWhen: (previous, current) {
          if (previous is! ProducerRequestsLoaded ||
              current is! ProducerRequestsLoaded) {
            return false;
          }
          return previous.actionInProgress && !current.actionInProgress;
        },
        listener: (context, state) {
          if (state is ProducerRequestsLoaded && state.actionError != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionError!)));
            return;
          }
          // Success: close detail view if open.
          setState(() => _selectedRequest = null);
        },
        builder: (context, state) => switch (state) {
          ProducerRequestsInitial() || ProducerRequestsLoading() =>
            const Center(child: CircularProgressIndicator()),
          ProducerRequestsError(:final message) => _ErrorView(
            message: message,
            onRetry: () => context.read<ProducerRequestsBloc>().add(
              const ProducerRequestsEvent.loadRequested(),
            ),
          ),
          ProducerRequestsLoaded(
            :final requests,
            :final statusFilter,
            :final actionInProgress,
            :final actionError,
          ) =>
            _loadedBody(
              context,
              requests: requests,
              statusFilter: statusFilter,
              actionInProgress: actionInProgress,
              actionError: actionError,
            ),
        },
      ),
    );
  }

  Widget _loadedBody(
    BuildContext context, {
    required List<AdminProducerRequest> requests,
    required ProducerRequestStatus? statusFilter,
    required bool actionInProgress,
    required String? actionError,
  }) {
    if (_selectedRequest != null) {
      final updated = requests
          .where((r) => r.requestId == _selectedRequest!.requestId)
          .firstOrNull;
      return _DetailView(
        request: updated ?? _selectedRequest!,
        actionInProgress: actionInProgress,
        actionError: actionError,
        onBack: () => setState(() => _selectedRequest = null),
        onApprove: () => context.read<ProducerRequestsBloc>().add(
          ProducerRequestsEvent.approveRequested(
            request: updated ?? _selectedRequest!,
          ),
        ),
        onReject: (comment) => context.read<ProducerRequestsBloc>().add(
          ProducerRequestsEvent.rejectRequested(
            request: updated ?? _selectedRequest!,
            reviewComment: comment,
          ),
        ),
        onResend: () => context.read<ProducerRequestsBloc>().add(
          ProducerRequestsEvent.resendRequested(
            request: updated ?? _selectedRequest!,
          ),
        ),
      );
    }

    final filtered = requests
        .where((r) => statusFilter == null || r.status == statusFilter)
        .toList();

    return Column(
      children: [
        const SyncStatusBanner(),
        _StatusFilterBar(
          selected: statusFilter,
          onSelected: (status) => context.read<ProducerRequestsBloc>().add(
            ProducerRequestsEvent.loadRequested(statusFilter: status),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aucune demande trouvée.'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final request = filtered[index];
                    return _RequestTile(
                      request: request,
                      onTap: () => setState(() => _selectedRequest = request),
                    );
                  },
                ),
        ),
      ],
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
            label: const Text('En attente'),
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

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.onTap});

  final AdminProducerRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(request.producerName),
      subtitle: Text(request.adminEmail),
      trailing: _StatusBadge(status: request.status),
      onTap: onTap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ProducerRequestStatus status;

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

  final AdminProducerRequest request;
  final bool actionInProgress;
  final String? actionError;
  final VoidCallback onBack;
  final VoidCallback onApprove;
  final ValueChanged<String?> onReject;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == ProducerRequestStatus.pendingValidation;
    final isApproved = request.status == ProducerRequestStatus.approved;
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
                          request.producerName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      _StatusBadge(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Administrateur',
                    value: '${request.adminFirstName} ${request.adminLastName}',
                  ),
                  _InfoRow(label: 'Email', value: request.adminEmail),
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

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

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
          labelText: 'Commentaire (optionnel)',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('REJETER'),
        ),
      ],
    );
  }
}

String _statusLabel(ProducerRequestStatus status) => switch (status) {
  ProducerRequestStatus.pendingValidation => 'En attente',
  ProducerRequestStatus.approved => 'Approuvée',
  ProducerRequestStatus.rejected => 'Rejetée',
};

Color _statusColor(ProducerRequestStatus status) => switch (status) {
  ProducerRequestStatus.pendingValidation => Colors.orange,
  ProducerRequestStatus.approved => Colors.green,
  ProducerRequestStatus.rejected => Colors.red,
};
