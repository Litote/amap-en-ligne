import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_state.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MembershipRequestsScreen extends StatelessWidget {
  const MembershipRequestsScreen({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MembershipRequestsBloc(
        organizationId: organizationId,
        memberJoinRequestRepository: context
            .read<MemberJoinRequestRepository>(),
        syncRepository: context.read<SyncRepository>(),
      )..add(const MembershipRequestsEvent.loadRequested()),
      child: const _MembershipRequestsView(),
    );
  }
}

class _MembershipRequestsView extends StatefulWidget {
  const _MembershipRequestsView();

  @override
  State<_MembershipRequestsView> createState() =>
      _MembershipRequestsViewState();
}

class _MembershipRequestsViewState extends State<_MembershipRequestsView> {
  AdminMemberJoinRequest? _selectedRequest;

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: "Demandes d'adhésion",
      actions: const [SyncButton()],
      body: BlocConsumer<MembershipRequestsBloc, MembershipRequestsState>(
        listenWhen: (previous, current) {
          if (previous is! MembershipRequestsLoaded ||
              current is! MembershipRequestsLoaded) {
            return false;
          }
          return previous.actionInProgress &&
              !current.actionInProgress &&
              current.actionError == null;
        },
        listener: (context, state) {
          setState(() => _selectedRequest = null);
        },
        builder: (context, state) => switch (state) {
          MembershipRequestsInitial() || MembershipRequestsLoading() =>
            const Center(child: CircularProgressIndicator()),
          MembershipRequestsError(:final message) => _ErrorView(
            message: message,
            onRetry: () => context.read<MembershipRequestsBloc>().add(
              const MembershipRequestsEvent.loadRequested(),
            ),
          ),
          MembershipRequestsLoaded(
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
    required List<AdminMemberJoinRequest> requests,
    required MemberJoinRequestStatus? statusFilter,
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
        onApprove: () => context.read<MembershipRequestsBloc>().add(
          MembershipRequestsEvent.approveRequested(
            request: updated ?? _selectedRequest!,
          ),
        ),
        onReject: (comment) => context.read<MembershipRequestsBloc>().add(
          MembershipRequestsEvent.rejectRequested(
            request: updated ?? _selectedRequest!,
            reviewComment: comment,
          ),
        ),
      );
    }

    return Column(
      children: [
        _StatusFilterBar(
          selected: statusFilter,
          onSelected: (status) => context.read<MembershipRequestsBloc>().add(
            MembershipRequestsEvent.loadRequested(statusFilter: status),
          ),
        ),
        Expanded(
          child: requests.isEmpty
              ? const Center(child: Text('Aucune demande trouvée.'))
              : ListView.separated(
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final request = requests[index];
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

  final MemberJoinRequestStatus? selected;
  final ValueChanged<MemberJoinRequestStatus?> onSelected;

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
            selected: selected == MemberJoinRequestStatus.pending,
            onSelected: (_) => onSelected(MemberJoinRequestStatus.pending),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Approuvées'),
            selected: selected == MemberJoinRequestStatus.approved,
            onSelected: (_) => onSelected(MemberJoinRequestStatus.approved),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Rejetées'),
            selected: selected == MemberJoinRequestStatus.rejected,
            onSelected: (_) => onSelected(MemberJoinRequestStatus.rejected),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.onTap});

  final AdminMemberJoinRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${request.firstName} ${request.lastName}'),
      subtitle: Text(request.email),
      trailing: _StatusBadge(status: request.status),
      onTap: onTap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MemberJoinRequestStatus status;

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
  });

  final AdminMemberJoinRequest request;
  final bool actionInProgress;
  final String? actionError;
  final VoidCallback onBack;
  final VoidCallback onApprove;
  final ValueChanged<String?> onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == MemberJoinRequestStatus.pending;
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
                          '${request.firstName} ${request.lastName}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      _StatusBadge(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Email', value: request.email),
                  _InfoRow(label: 'Soumise le', value: request.submittedAt),
                  if (request.reviewedAt != null)
                    _InfoRow(label: 'Traitée le', value: request.reviewedAt!),
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

String _statusLabel(MemberJoinRequestStatus status) => switch (status) {
  MemberJoinRequestStatus.pending => 'En attente',
  MemberJoinRequestStatus.approved => 'Approuvée',
  MemberJoinRequestStatus.rejected => 'Rejetée',
};

Color _statusColor(MemberJoinRequestStatus status) => switch (status) {
  MemberJoinRequestStatus.pending => Colors.orange,
  MemberJoinRequestStatus.approved => Colors.green,
  MemberJoinRequestStatus.rejected => Colors.red,
};
