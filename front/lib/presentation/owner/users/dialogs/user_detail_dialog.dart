import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/common/error_feedback.dart';
import 'package:amap_en_ligne/presentation/owner/users/dialogs/modify_membership_dialog.dart';
import 'package:amap_en_ligne/presentation/owner/users/dialogs/owner_lifecycle_dialogs.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_detail_bloc.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_detail_event.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_detail_state.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the user detail dialog for a given [userId].
///
/// Instantiates a local [UserDetailBloc] inside the dialog so that the list
/// screen does not need to carry detail state.
Future<void> showUserDetailDialog(BuildContext context, String userId) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => BlocProvider(
      create: (_) => UserDetailBloc(
        ownerRepository: context.read<OwnerRepository>(),
        memberRepository: context.read<MemberRepository>(),
        organizationRepository: context.read<OrganizationRepository>(),
        producerAccountRepository: context.read<ProducerAccountRepository>(),
      )..add(UserDetailEvent.loaded(userId)),
      child: _UserDetailDialog(userId: userId),
    ),
  );
}

class _UserDetailDialog extends StatelessWidget {
  const _UserDetailDialog({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDetailBloc, UserDetailState>(
      builder: (context, state) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: switch (state) {
              UserDetailInitial() ||
              UserDetailLoading() => const _LoadingContent(),
              UserDetailNotFound() => const _NotFoundContent(),
              UserDetailError(:final message) => _ErrorContent(
                message: message,
              ),
              UserDetailLoaded(:final userRow) => _LoadedContent(row: userRow),
            },
          ),
        );
      },
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _NotFoundContent extends StatelessWidget {
  const _NotFoundContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Utilisateur introuvable.'),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({required this.row});

  final UserRow row;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dialog title row.
          Row(
            children: [
              Expanded(
                child: Text(
                  row.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
            ],
          ),
          Text(
            _statusHeader(row),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          // COMPTE section.
          _SectionCard(
            title: 'COMPTE',
            children: [
              _InfoRow(label: 'Prénom', value: row.firstName),
              _InfoRow(label: 'Nom', value: row.lastName),
              _InfoRow(label: 'Email', value: row.email),
              _InfoRow(label: 'Téléphone', value: row.phone ?? ''),
            ],
          ),
          const SizedBox(height: 12),
          // Role-specific section.
          if (row.isOwner)
            const _OwnerRoleCard()
          else if (row.isProducer)
            _ProducerCard(row: row)
          else
            _AmapCard(row: row),
          const SizedBox(height: 16),
          _DangerZone(row: row),
        ],
      ),
    );
  }

  String _statusHeader(UserRow row) {
    final statusLabel = switch (row.displayStatus) {
      UserDisplayStatus.active => 'Actif',
      UserDisplayStatus.pendingInvitation => 'Invitation en attente',
      UserDisplayStatus.suspended => 'Suspendu',
    };
    final registeredStr = row.registeredAt != null
        ? ' · Inscrit le ${_formatDate(row.registeredAt!)}'
        : '';
    return '$statusLabel$registeredStr';
  }
}

class _AmapCard extends StatelessWidget {
  const _AmapCard({required this.row});

  final UserRow row;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<UserDetailBloc>();
    return _SectionCard(
      title: 'AMAP',
      children: row.memberships.isEmpty
          ? const [Text('Aucune appartenance AMAP.')]
          : row.memberships
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(m.organizationName)),
                        Text(_rolesLabel(m.roles)),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          key: Key('modify_membership_${m.organizationId}'),
                          onPressed: () => _openModifyDialog(context, bloc, m),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Modifier'),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
    );
  }

  void _openModifyDialog(
    BuildContext context,
    UserDetailBloc bloc,
    UserMembership membership,
  ) async {
    final result = await showDialog<MembershipEditResult>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => ModifyMembershipDialog(
        userRow: row,
        membership: membership,
        isLastAdmin: false,
        canEditAdminRole: context.read<AuthBloc>().state.isAdmin,
      ),
    );
    if (result == null || !context.mounted) return;

    final memberRepository = context.read<MemberRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final rolesChanged = !_sameRoles(result.roles, membership.roles);
    final profileChanged =
        result.firstName != row.firstName ||
        result.lastName != row.lastName ||
        result.email != row.email ||
        result.phone != (row.phone ?? '');

    if (profileChanged) {
      await memberRepository.updateProfile(
        memberId: membership.memberId,
        organizationId: membership.organizationId,
        firstName: _nullIfEmpty(result.firstName),
        lastName: _nullIfEmpty(result.lastName),
        email: _nullIfEmpty(result.email),
        phone: _nullIfEmpty(result.phone),
      );
    }

    if (!context.mounted) return;

    if (rolesChanged) {
      bloc.add(
        UserDetailEvent.membershipRolesChanged(
          memberId: membership.memberId,
          organizationId: membership.organizationId,
          newRoles: result.roles,
        ),
      );
    }

    final statusChanged = result.status != row.displayStatus;
    if (statusChanged) {
      await _saveStatusChange(context, membership, result.status);
      return;
    }

    if (profileChanged || rolesChanged) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Utilisateur mis à jour.')),
      );
    }
  }

  Future<void> _saveStatusChange(
    BuildContext context,
    UserMembership membership,
    UserDisplayStatus status,
  ) async {
    if (status == UserDisplayStatus.pendingInvitation) return;
    final repository = context.read<MemberRepository>();
    final syncRepository = context.read<SyncRepository>();
    final tenantId = context.read<AuthBloc>().state.producerId ?? '';
    final messenger = ScaffoldMessenger.of(context);
    final clientOpId = status == UserDisplayStatus.suspended
        ? await repository.suspend(
            memberId: membership.memberId,
            organizationId: membership.organizationId,
          )
        : await repository.reactivate(
            memberId: membership.memberId,
            organizationId: membership.organizationId,
          );

    final outcome = await syncRepository.sync(tenantId: tenantId);
    if (!context.mounted) return;

    final rejected = outcome is SyncSuccess
        ? outcome.rejectedMutations
              .where((mutation) => mutation.clientOpId == clientOpId)
              .firstOrNull
        : null;
    if (rejected != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(_mutationErrorMessage(rejected.error))),
      );
      return;
    }
    if (outcome is SyncFailure) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec : ${outcome.message}')),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Utilisateur mis à jour.')),
    );
  }
}

class _ProducerCard extends StatelessWidget {
  const _ProducerCard({required this.row});

  final UserRow row;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'PRODUCTEUR',
      children: [
        Text('Producteur de : ${row.producerAccountName ?? '—'}'),
        const SizedBox(height: 4),
        const TextButton(
          key: Key('view_producer_link'),
          onPressed: null,
          child: Text('Voir la fiche producteur →'),
        ),
      ],
    );
  }
}

class _OwnerRoleCard extends StatelessWidget {
  const _OwnerRoleCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: "Administrateur d'instance",
      children: [SizedBox.shrink()],
    );
  }
}

class _DangerZone extends StatefulWidget {
  const _DangerZone({required this.row});

  final UserRow row;

  @override
  State<_DangerZone> createState() => _DangerZoneState();
}

class _DangerZoneState extends State<_DangerZone> {
  bool _busy = false;

  bool get _isOwner => widget.row.isOwner;
  bool get _isProducer => widget.row.isProducer;

  bool get _isAmapMember =>
      !_isOwner && !_isProducer && widget.row.identityKey.isNotEmpty;

  bool get _supportsLifecycle => _isOwner || _isProducer || _isAmapMember;

  bool get _isSuspended =>
      widget.row.displayStatus == UserDisplayStatus.suspended;

  bool get _isSelf {
    final caller = context.read<AuthBloc>().state.producerId;
    return caller != null && caller == widget.row.identityKey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Zone sensible', style: theme.textTheme.labelLarge),
            ],
          ),
        ),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _suspendOrReactivateButton()),
            const SizedBox(width: 12),
            Expanded(child: _deleteButton()),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }

  /// Tooltip shown when lifecycle actions are disabled, or null when enabled.
  String? get _lifecycleDisabledTooltip {
    if (!_supportsLifecycle) return 'Action indisponible pour cet utilisateur';
    if (_isSelf) return 'Vous ne pouvez pas modifier votre propre compte';
    return null;
  }

  Widget _suspendOrReactivateButton() {
    final enabled = _supportsLifecycle && !_isSelf && !_busy;
    final tooltip = _lifecycleDisabledTooltip;
    final label = _isSuspended ? 'RÉACTIVER LE COMPTE' : 'SUSPENDRE LE COMPTE';
    final button = OutlinedButton(
      key: const Key('suspend_button'),
      onPressed: enabled
          ? () => _isSuspended ? _runReactivate() : _runSuspend()
          : null,
      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
      child: Text(label),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _deleteButton() {
    final enabled = _supportsLifecycle && !_isSelf && !_busy;
    final tooltip = _lifecycleDisabledTooltip;
    final button = OutlinedButton(
      key: const Key('delete_button'),
      onPressed: enabled ? _runDelete : null,
      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
      child: const Text("SUPPRIMER DE L'INSTANCE"),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Future<void> _runSuspend() async {
    final Widget dialog;
    if (_isProducer) {
      dialog = ConfirmSuspendProducerDialog(userRow: widget.row);
    } else if (_isAmapMember) {
      dialog = ConfirmSuspendMemberDialog(userRow: widget.row);
    } else {
      dialog = ConfirmSuspendOwnerDialog(userRow: widget.row);
    }
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => dialog,
    );
    if (confirmed != true || !mounted) return;
    final Future<String> Function() action;
    if (_isAmapMember) {
      action = () => context.read<MemberRepository>().suspend(
        memberId: widget.row.memberships.first.memberId,
        organizationId: widget.row.memberships.first.organizationId,
      );
    } else if (_isProducer) {
      action = () => context.read<ProducerAccountRepository>().suspend(
        widget.row.producerAccountId ?? widget.row.ownerId,
      );
    } else {
      action = () =>
          context.read<OwnerRepository>().suspend(widget.row.ownerId);
    }
    await _executeMutation(
      action: action,
      successMessage: _isProducer ? 'Producteur suspendu.' : 'Compte suspendu.',
    );
  }

  Future<void> _runReactivate() async {
    final Widget dialog;
    if (_isProducer) {
      dialog = ConfirmReactivateProducerDialog(userRow: widget.row);
    } else if (_isAmapMember) {
      dialog = ConfirmReactivateMemberDialog(userRow: widget.row);
    } else {
      dialog = ConfirmReactivateOwnerDialog(userRow: widget.row);
    }
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => dialog,
    );
    if (confirmed != true || !mounted) return;
    final Future<String> Function() action;
    if (_isAmapMember) {
      action = () => context.read<MemberRepository>().reactivate(
        memberId: widget.row.memberships.first.memberId,
        organizationId: widget.row.memberships.first.organizationId,
      );
    } else if (_isProducer) {
      action = () => context.read<ProducerAccountRepository>().reactivate(
        widget.row.producerAccountId ?? widget.row.ownerId,
      );
    } else {
      action = () =>
          context.read<OwnerRepository>().reactivate(widget.row.ownerId);
    }
    await _executeMutation(
      action: action,
      successMessage: _isProducer ? 'Producteur réactivé.' : 'Compte réactivé.',
    );
  }

  Future<void> _runDelete() async {
    final Widget dialog;
    if (_isProducer) {
      dialog = ConfirmDeleteProducerDialog(userRow: widget.row);
    } else if (_isAmapMember) {
      dialog = ConfirmDeleteMemberDialog(userRow: widget.row);
    } else {
      dialog = ConfirmDeleteOwnerDialog(userRow: widget.row);
    }
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => dialog,
    );
    if (confirmed != true || !mounted) return;
    final Future<String> Function() action;
    if (_isAmapMember) {
      action = () => context.read<MemberRepository>().delete(
        memberId: widget.row.memberships.first.memberId,
        organizationId: widget.row.memberships.first.organizationId,
      );
    } else if (_isProducer) {
      action = () => context.read<ProducerAccountRepository>().delete(
        widget.row.producerAccountId ?? widget.row.ownerId,
      );
    } else {
      action = () => context.read<OwnerRepository>().delete(widget.row.ownerId);
    }
    await _executeMutation(
      action: action,
      successMessage: _isProducer ? 'Producteur supprimé.' : 'Compte supprimé.',
    );
  }

  Future<void> _executeMutation({
    required Future<String> Function() action,
    required String successMessage,
  }) async {
    setState(() => _busy = true);
    final syncRepo = context.read<SyncRepository>();
    final tenantId = context.read<AuthBloc>().state.producerId ?? '';
    try {
      final clientOpId = await action();
      final outcome = await syncRepo.sync(tenantId: tenantId);
      if (!mounted) return;
      final rejected = outcome is SyncSuccess
          ? outcome.rejectedMutations
                .where((m) => m.clientOpId == clientOpId)
                .firstOrNull
          : null;
      if (rejected != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mutationErrorMessage(rejected.error))),
        );
      } else if (outcome is SyncFailure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec : ${outcome.message}')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      showUnexpectedErrorSnackBar(context, e, stackTrace);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
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
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}

String _rolesLabel(Set<Role> roles) {
  final labels = <String>[];
  if (roles.contains(Role.admin)) labels.add('Admin');
  if (roles.contains(Role.coordinator)) labels.add('Coordinateur');
  if (roles.contains(Role.volunteer)) labels.add('Amapien');
  if (roles.contains(Role.producer)) labels.add('Producteur');
  if (roles.contains(Role.owner)) labels.add('Owner');
  return labels.join(' · ');
}

bool _sameRoles(Set<Role> a, Set<Role> b) =>
    a.length == b.length && a.containsAll(b);

String? _nullIfEmpty(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String _mutationErrorMessage(MutationError? error) {
  if (error == null) return 'Opération refusée.';
  return switch (error.code) {
    MutationErrorCode.lastOwner =>
      "Au moins un Owner actif est obligatoire sur l'instance.",
    MutationErrorCode.selfActionForbidden =>
      'Vous ne pouvez pas modifier votre propre compte.',
    MutationErrorCode.lastAdmin =>
      'Cette AMAP doit conserver au moins un Admin.',
    MutationErrorCode.lastProducer =>
      "Le producteur doit conserver au moins un utilisateur PRODUCER.",
    MutationErrorCode.forbidden => 'Action non autorisée.',
    MutationErrorCode.notFound => 'Compte introuvable.',
    _ => error.message,
  };
}

String _formatDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
