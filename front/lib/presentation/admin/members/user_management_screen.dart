import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/presentation/admin/members/user_management_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Admin screen for managing organization members and their roles.
///
/// Reads members from [MemberRepository] via [UserManagementBloc].
/// Role edits are applied optimistically through [MemberRepository.setRoles].
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({
    required this.organizationId,
    required this.canEditAdminRole,
    super.key,
  });

  final String organizationId;
  final bool canEditAdminRole;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserManagementBloc(
        memberRepository: context.read<MemberRepository>(),
        memberInvitationRepository: context.read<MemberInvitationRepository>(),
        syncRepository: context.read<SyncRepository>(),
        database: context.read<AppDatabase>(),
        organizationId: organizationId,
        canEditAdminRole: canEditAdminRole,
      )..add(const UserManagementEvent.loadRequested()),
      child: const _UserManagementView(),
    );
  }
}

class _UserManagementView extends StatelessWidget {
  const _UserManagementView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserManagementBloc, UserManagementState>(
      listenWhen: (previous, current) {
        if (previous is UserManagementLoaded &&
            current is UserManagementLoaded) {
          // Show invite dialog when showingInviteForm becomes true.
          if (!previous.showingInviteForm && current.showingInviteForm) {
            return true;
          }
          // Show success SnackBar when inviteSuccess becomes true.
          if (!previous.inviteSuccess && current.inviteSuccess) {
            return true;
          }
          if (previous.feedbackMessage != current.feedbackMessage &&
              current.feedbackMessage != null) {
            return true;
          }
          // Show edit-roles dialog when editingMember changes.
          if (previous.editingMember != current.editingMember) {
            return true;
          }
        }
        return false;
      },
      listener: (context, state) {
        if (state is UserManagementLoaded) {
          if (state.showingInviteForm) {
            _showInviteDialog(context);
          }
          if (state.inviteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invitation envoyée avec succès.')),
            );
          }
          if (state.feedbackMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.feedbackMessage!)));
            context.read<UserManagementBloc>().add(
              const UserManagementEvent.feedbackDismissed(),
            );
          }
          if (state.editingMember != null) {
            _showEditRolesDialog(context, state);
          }
        }
      },
      child: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          final fab = state is UserManagementLoaded
              ? FloatingActionButton(
                  key: const Key('invite_member_fab'),
                  onPressed: () => context.read<UserManagementBloc>().add(
                    const UserManagementEvent.showInviteForm(),
                  ),
                  tooltip: 'Inviter un membre',
                  child: const Icon(Icons.person_add),
                )
              : null;

          return ConnectedScaffold(
            title: 'Gestion des membres',
            actions: const [SyncButton()],
            floatingActionButton: fab,
            body: switch (state) {
              UserManagementInitial() || UserManagementLoading() =>
                const Center(child: CircularProgressIndicator()),
              UserManagementError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<UserManagementBloc>().add(
                  const UserManagementEvent.loadRequested(),
                ),
              ),
              UserManagementLoaded() => _LoadedBody(state: state),
            },
          );
        },
      ),
    );
  }

  void _showEditRolesDialog(BuildContext context, UserManagementLoaded state) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<UserManagementBloc>(),
        child: _EditRolesDialog(
          canEditAdminRole: context.read<UserManagementBloc>().canEditAdminRole,
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<UserManagementBloc>(),
        child: _InviteDialog(
          canEditAdminRole: context.read<UserManagementBloc>().canEditAdminRole,
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});

  final UserManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final filteredInvitations = _filteredInvitations(
      state.memberInvitations,
      state.searchQuery,
      state.roleFilter,
      state.invitationStatusFilter,
    );

    final items = <Object>[
      ...filteredInvitations,
      if (state.invitationStatusFilter == InvitationStatusFilter.active)
        ..._filteredMembers(
          state.members,
          state.searchQuery,
          state.roleFilter,
          state.userStatusFilter,
        ),
    ];

    final pendingCount = state.memberInvitations
        .where((i) => i.status == InvitationStatus.pendingActivation)
        .length;

    return Column(
      children: [
        _SearchAndFilterBar(
          searchQuery: state.searchQuery,
          roleFilter: state.roleFilter,
          invitationStatusFilter: state.invitationStatusFilter,
          userStatusFilter: state.userStatusFilter,
        ),
        if (state.invitationStatusFilter == InvitationStatusFilter.active &&
            pendingCount > 0)
          _PendingConnectionBanner(
            pendingCount: pendingCount,
            busy: state.resendingAllPending,
          ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Aucun membre ou invitation trouvé.'))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return switch (item) {
                      MemberInvitation() => _MemberInvitationTile(
                        invitation: item,
                        resending: state.resendingInvitationIds.contains(
                          item.invitationId,
                        ),
                        deleting: state.deletingInvitationIds.contains(
                          item.invitationId,
                        ),
                      ),
                      Member() => _MemberTile(member: item),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
        ),
      ],
    );
  }

  List<Member> _filteredMembers(
    List<Member> members,
    String searchQuery,
    Role? roleFilter,
    UserStatusFilter userStatusFilter,
  ) {
    // Producers are managed via /admin/producers and visible to owners only.
    var result = members
        .where((m) => !m.roles.contains(Role.producer))
        .toList();

    // Filter by user account status
    if (userStatusFilter == UserStatusFilter.active) {
      result = result
          .where((m) => m.accountStatus != MemberAccountStatus.suspended)
          .toList();
    } else if (userStatusFilter == UserStatusFilter.suspended) {
      result = result
          .where((m) => m.accountStatus == MemberAccountStatus.suspended)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result
          .where((m) => m.memberId.toLowerCase().contains(query))
          .toList();
    }
    if (roleFilter != null) {
      result = result.where((m) => m.roles.contains(roleFilter)).toList();
    }
    return result;
  }

  List<MemberInvitation> _filteredInvitations(
    List<MemberInvitation> invitations,
    String searchQuery,
    Role? roleFilter,
    InvitationStatusFilter invitationStatusFilter,
  ) {
    // Producers are managed via /admin/producers and visible to owners only.
    var result = invitations
        .where((i) => !i.roles.contains(Role.producer))
        .toList();

    // Filter by invitation status (active vs cancelled).
    // Activated invitations are hidden from both views — the member already
    // has an account and appears in the members list instead.
    if (invitationStatusFilter == InvitationStatusFilter.active) {
      result = result
          .where((i) => i.status == InvitationStatus.pendingActivation)
          .toList();
    } else if (invitationStatusFilter == InvitationStatusFilter.cancelled) {
      result = result
          .where((i) => i.status == InvitationStatus.cancelled)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((invitation) {
        final fullName = '${invitation.firstName} ${invitation.lastName}'
            .toLowerCase();
        return invitation.email.toLowerCase().contains(query) ||
            fullName.contains(query) ||
            invitation.invitationId.toLowerCase().contains(query);
      }).toList();
    }
    if (roleFilter != null) {
      result = result
          .where((invitation) => invitation.roles.contains(roleFilter))
          .toList();
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.searchQuery,
    required this.roleFilter,
    required this.invitationStatusFilter,
    required this.userStatusFilter,
  });

  final String searchQuery;
  final Role? roleFilter;
  final InvitationStatusFilter invitationStatusFilter;
  final UserStatusFilter userStatusFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un membre…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (query) => context.read<UserManagementBloc>().add(
              UserManagementEvent.searchChanged(query),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected:
                      roleFilter == null &&
                      invitationStatusFilter == InvitationStatusFilter.active,
                  onSelected: (_) {
                    context.read<UserManagementBloc>().add(
                      const UserManagementEvent.roleFilterChanged(null),
                    );
                    context.read<UserManagementBloc>().add(
                      const UserManagementEvent.invitationStatusFilterChanged(
                        InvitationStatusFilter.active,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Admin'),
                  selected: roleFilter == Role.admin,
                  onSelected: (_) => context.read<UserManagementBloc>().add(
                    const UserManagementEvent.roleFilterChanged(Role.admin),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Coordinateur'),
                  selected: roleFilter == Role.coordinator,
                  onSelected: (_) => context.read<UserManagementBloc>().add(
                    const UserManagementEvent.roleFilterChanged(
                      Role.coordinator,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Amapien'),
                  selected: roleFilter == Role.volunteer,
                  onSelected: (_) => context.read<UserManagementBloc>().add(
                    const UserManagementEvent.roleFilterChanged(Role.volunteer),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Invitations passées'),
                  selected:
                      invitationStatusFilter ==
                      InvitationStatusFilter.cancelled,
                  onSelected: (_) {
                    final newFilter =
                        invitationStatusFilter ==
                            InvitationStatusFilter.cancelled
                        ? InvitationStatusFilter.active
                        : InvitationStatusFilter.cancelled;
                    context.read<UserManagementBloc>().add(
                      UserManagementEvent.invitationStatusFilterChanged(
                        newFilter,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Anciens utilisateurs'),
                  selected: userStatusFilter == UserStatusFilter.suspended,
                  onSelected: (_) {
                    final newFilter =
                        userStatusFilter == UserStatusFilter.suspended
                        ? UserStatusFilter.active
                        : UserStatusFilter.suspended;
                    context.read<UserManagementBloc>().add(
                      UserManagementEvent.userStatusFilterChanged(newFilter),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final displayName = _formatMemberName(member);
    final subtitleLines = <Widget>[];

    if (member.email != null && member.email!.isNotEmpty) {
      subtitleLines.add(Text(member.email!));
    }

    if (subtitleLines.isNotEmpty && member.roles.isNotEmpty) {
      subtitleLines.add(const SizedBox(height: 4));
    }

    if (member.roles.isNotEmpty) {
      subtitleLines.add(
        Wrap(
          spacing: 4,
          children: member.roles.map((r) => _RoleBadge(role: r)).toList(),
        ),
      );
    } else if (subtitleLines.isEmpty) {
      subtitleLines.add(const Text('Aucun rôle'));
    }

    return ListTile(
      title: Text(displayName),
      subtitle: subtitleLines.length == 1
          ? subtitleLines[0]
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subtitleLines,
            ),
      trailing: IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Modifier les rôles',
        onPressed: () => context.read<UserManagementBloc>().add(
          UserManagementEvent.editRolesRequested(member),
        ),
      ),
    );
  }

  String _formatMemberName(Member member) {
    final fullName = '${member.firstName ?? ''} ${member.lastName ?? ''}'
        .trim();
    return fullName.isEmpty ? '(aucun nom)' : fullName;
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _roleLabel(role),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: _roleColor(role),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MemberInvitationTile extends StatelessWidget {
  const _MemberInvitationTile({
    required this.invitation,
    required this.resending,
    required this.deleting,
  });

  final MemberInvitation invitation;
  final bool resending;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final title = '${invitation.firstName} ${invitation.lastName}'.trim();
    final lastSentLabel = _formatLastSent(invitation);
    final statusLabel = _formatInvitationStatus(invitation);
    final subtitleLines = <Widget>[
      Text(invitation.email),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          if (statusLabel != null) Chip(label: Text(statusLabel)),
          ...invitation.roles.map((role) => _RoleBadge(role: role)),
        ],
      ),
      if (lastSentLabel != null) ...[
        const SizedBox(height: 2),
        Text(lastSentLabel, style: Theme.of(context).textTheme.bodySmall),
      ],
    ];
    return ListTile(
      title: Text(title.isEmpty ? invitation.email : title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtitleLines,
      ),
      trailing: invitation.status == InvitationStatus.pendingActivation
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: resending
                      ? null
                      : () => context.read<UserManagementBloc>().add(
                          UserManagementEvent.resendInvitationRequested(
                            invitation,
                          ),
                        ),
                  child: resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Relancer'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Supprimer l\'invitation',
                  onPressed: deleting
                      ? null
                      : () => context.read<UserManagementBloc>().add(
                          UserManagementEvent.deleteInvitationRequested(
                            invitation,
                          ),
                        ),
                ),
              ],
            )
          : null,
    );
  }
}

class _EditRolesDialog extends StatelessWidget {
  const _EditRolesDialog({required this.canEditAdminRole});

  final bool canEditAdminRole;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, state) {
        if (state is! UserManagementLoaded) return const SizedBox.shrink();
        final pendingRoles = state.pendingRoles;
        return AlertDialog(
          title: const Text('Modifier les rôles'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Amapien'),
                value: pendingRoles.contains(Role.volunteer),
                onChanged: (checked) => context.read<UserManagementBloc>().add(
                  UserManagementEvent.roleToggled(
                    Role.volunteer,
                    checked ?? false,
                  ),
                ),
              ),
              CheckboxListTile(
                title: const Text('Coordinateur'),
                value: pendingRoles.contains(Role.coordinator),
                onChanged: (checked) => context.read<UserManagementBloc>().add(
                  UserManagementEvent.roleToggled(
                    Role.coordinator,
                    checked ?? false,
                  ),
                ),
              ),
              CheckboxListTile(
                title: const Text('Admin'),
                value: pendingRoles.contains(Role.admin),
                enabled: canEditAdminRole,
                onChanged: canEditAdminRole
                    ? (checked) => context.read<UserManagementBloc>().add(
                        UserManagementEvent.roleToggled(
                          Role.admin,
                          checked ?? false,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<UserManagementBloc>().add(
                  const UserManagementEvent.editCancelled(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: state.saving
                  ? null
                  : () {
                      context.read<UserManagementBloc>().add(
                        const UserManagementEvent.saveRolesRequested(),
                      );
                      Navigator.of(context).pop();
                    },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}

class _InviteDialog extends StatelessWidget {
  const _InviteDialog({required this.canEditAdminRole});

  final bool canEditAdminRole;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserManagementBloc, UserManagementState>(
      listenWhen: (previous, current) {
        if (previous is UserManagementLoaded &&
            current is UserManagementLoaded) {
          return !previous.inviteSuccess && current.inviteSuccess;
        }
        return false;
      },
      listener: (context, state) {
        Navigator.of(context).pop();
      },
      builder: (context, state) {
        if (state is! UserManagementLoaded) return const SizedBox.shrink();
        return AlertDialog(
          title: const Text('Inviter un membre'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Prénom *'),
                  onChanged: (value) => context.read<UserManagementBloc>().add(
                    UserManagementEvent.inviteFirstNameChanged(value),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  onChanged: (value) => context.read<UserManagementBloc>().add(
                    UserManagementEvent.inviteLastNameChanged(value),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => context.read<UserManagementBloc>().add(
                    UserManagementEvent.inviteEmailChanged(value),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Rôles *'),
                CheckboxListTile(
                  title: const Text('Amapien'),
                  value: state.inviteRoles.contains(Role.volunteer),
                  onChanged: (checked) =>
                      context.read<UserManagementBloc>().add(
                        UserManagementEvent.inviteRoleToggled(
                          Role.volunteer,
                          checked ?? false,
                        ),
                      ),
                ),
                CheckboxListTile(
                  title: const Text('Coordinateur'),
                  value: state.inviteRoles.contains(Role.coordinator),
                  onChanged: (checked) =>
                      context.read<UserManagementBloc>().add(
                        UserManagementEvent.inviteRoleToggled(
                          Role.coordinator,
                          checked ?? false,
                        ),
                      ),
                ),
                if (canEditAdminRole)
                  CheckboxListTile(
                    title: const Text('Admin'),
                    value: state.inviteRoles.contains(Role.admin),
                    onChanged: (checked) =>
                        context.read<UserManagementBloc>().add(
                          UserManagementEvent.inviteRoleToggled(
                            Role.admin,
                            checked ?? false,
                          ),
                        ),
                  ),
                if (state.inviteError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.inviteError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<UserManagementBloc>().add(
                  const UserManagementEvent.dismissInviteForm(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: state.inviting
                  ? null
                  : () => context.read<UserManagementBloc>().add(
                      const UserManagementEvent.submitInvitation(),
                    ),
              child: state.inviting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Inviter'),
            ),
          ],
        );
      },
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

String? _formatLastSent(MemberInvitation invitation) {
  final rawDate = invitation.resendRequestedAt ?? invitation.createdAt;
  final dt = DateTime.tryParse(rawDate)?.toLocal();
  if (dt == null) return null;
  final formatted = DateFormat('d MMM yyyy', 'fr').format(dt);
  return invitation.resendRequestedAt != null
      ? 'Dernière relance le $formatted'
      : 'Envoyée le $formatted';
}

String? _formatInvitationStatus(MemberInvitation invitation) {
  if (invitation.status == InvitationStatus.cancelled) {
    return null;
  }
  return 'Invitation en attente';
}

Color _roleColor(Role role) => switch (role) {
  Role.admin => Colors.purple,
  Role.coordinator => Colors.green,
  Role.volunteer => Colors.blue,
  Role.owner || Role.producer => Colors.grey,
};

String _roleLabel(Role role) => switch (role) {
  Role.admin => 'Admin',
  Role.coordinator => 'Coordinateur',
  Role.volunteer => 'Amapien',
  Role.owner => 'Owner',
  Role.producer => 'Producteur',
};

/// Default invitation email copy shown as a hint in the bulk-resend dialog.
/// Leaving a field empty keeps the per-member default copy server-side.
const String _defaultInvitationSubject = 'Invitation à rejoindre votre AMAP';
const String _defaultInvitationBody =
    'Bonjour,\n\nVous avez été invité(e) à rejoindre votre AMAP sur AMAP en '
    'ligne. Connectez-vous pour finaliser votre inscription.';

/// Banner shown above the list when there are still-pending invitations,
/// offering to re-send the connection email to everyone at once.
class _PendingConnectionBanner extends StatelessWidget {
  const _PendingConnectionBanner({
    required this.pendingCount,
    required this.busy,
  });

  final int pendingCount;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$pendingCount membre(s) ne se sont pas encore connectés.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            key: const Key('resend_all_pending_button'),
            onPressed: busy ? null : () => _showBulkResendDialog(context),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mark_email_unread_outlined),
            label: const Text('Demander la connexion'),
          ),
        ],
      ),
    );
  }

  void _showBulkResendDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => BlocProvider.value(
        value: context.read<UserManagementBloc>(),
        child: _BulkResendDialog(pendingCount: pendingCount),
      ),
    );
  }
}

/// Dialog letting the admin optionally override the subject/body of the
/// connection email before re-sending it to every pending member.
class _BulkResendDialog extends StatefulWidget {
  const _BulkResendDialog({required this.pendingCount});

  final int pendingCount;

  @override
  State<_BulkResendDialog> createState() => _BulkResendDialogState();
}

class _BulkResendDialogState extends State<_BulkResendDialog> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Demander la connexion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "L'e-mail d'invitation sera renvoyé à ${widget.pendingCount} "
              'membre(s). Laissez les champs vides pour utiliser le message par '
              'défaut.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('bulk_resend_reset_button'),
                onPressed: () {
                  _subjectController.text = _defaultInvitationSubject;
                  _bodyController.text = _defaultInvitationBody;
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Repartir de l\'alerte par défaut'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('bulk_resend_subject_field'),
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Titre du message (optionnel)',
                hintText: _defaultInvitationSubject,
                helperText: 'Par défaut : $_defaultInvitationSubject',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('bulk_resend_body_field'),
              controller: _bodyController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Corps du message (optionnel)',
                hintText: _defaultInvitationBody,
                helperText: 'Par défaut : $_defaultInvitationBody',
                helperMaxLines: 4,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('bulk_resend_confirm_button'),
          onPressed: () {
            final subject = _subjectController.text.trim();
            final body = _bodyController.text.trim();
            context.read<UserManagementBloc>().add(
              UserManagementEvent.resendAllPendingRequested(
                customEmailSubject: subject.isEmpty ? null : subject,
                customEmailBody: body.isEmpty ? null : body,
              ),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Renvoyer'),
        ),
      ],
    );
  }
}
