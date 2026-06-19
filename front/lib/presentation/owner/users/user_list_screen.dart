import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/owner/users/dialogs/user_detail_dialog.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_bloc.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_event.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_state.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  static const String _title = 'Utilisateurs';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserListBloc(
        ownerRepository: context.read<OwnerRepository>(),
        memberRepository: context.read<MemberRepository>(),
        organizationRepository: context.read<OrganizationRepository>(),
        producerAccountRepository: context.read<ProducerAccountRepository>(),
      )..add(const UserListEvent.loaded()),
      child: const _UserListView(),
    );
  }
}

class _UserListView extends StatefulWidget {
  const _UserListView();

  @override
  State<_UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<_UserListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: UserListScreen._title,
      actions: const [SyncButton()],
      body: BlocBuilder<UserListBloc, UserListState>(
        builder: (context, state) => switch (state) {
          UserListInitial() ||
          UserListLoading() => const Center(child: CircularProgressIndicator()),
          UserListError(:final message) => _ErrorView(message: message),
          UserListLoaded() => _loadedBody(context, state),
        },
      ),
    );
  }

  Widget _loadedBody(BuildContext context, UserListLoaded state) {
    final bloc = context.read<UserListBloc>();
    return CustomScrollView(
      slivers: [
        // Header: title, search, filters.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Utilisateurs de l'instance",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _countLabel(state),
                  key: const Key('user_count_label'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('user_search_field'),
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher',
                    helperText: '(nom, prénom, email)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      bloc.add(UserListEvent.searchQueryChanged(value)),
                ),
                const SizedBox(height: 12),
                _FiltersSection(state: state, bloc: bloc),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // Empty state.
        if (state.visibleRows.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Aucun utilisateur ne correspond aux critères.'),
              ),
            ),
          ),
        // User list.
        if (state.visibleRows.isNotEmpty)
          SliverList.separated(
            itemCount: state.visibleRows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _UserListTile(row: state.visibleRows[index]),
          ),
        // Footer.
        SliverToBoxAdapter(
          child: Column(
            children: [
              _PaginationFooter(state: state, bloc: bloc),
              const _ActionFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({required this.state, required this.bloc});

  final UserListLoaded state;
  final UserListBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AMAP dropdown (kept as dropdown — list can be large).
        Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                'AMAP :',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('amap_filter_dropdown'),
                initialValue: state.amapIdFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Toutes'),
                  ),
                  ...state.allOrganizations.map(
                    (o) => DropdownMenuItem<String?>(
                      value: o.organizationId,
                      child: Text(o.name),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    bloc.add(UserListEvent.amapFilterChanged(value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Producteur dropdown (kept as dropdown — list can be large).
        Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                'Producteur :',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('producer_filter_dropdown'),
                initialValue: state.producerIdFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tous'),
                  ),
                  ...state.allProducerAccounts.map(
                    (p) => DropdownMenuItem<String?>(
                      value: p.producerAccountId,
                      child: Text(p.name),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    bloc.add(UserListEvent.producerFilterChanged(value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Rôle filter chips.
        Text('Rôle :', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _RoleChip(
                label: 'Tous',
                selected: state.roleFilter == null,
                onSelected: () =>
                    bloc.add(const UserListEvent.roleFilterChanged(null)),
              ),
              const SizedBox(width: 6),
              _RoleChip(
                label: 'Owner',
                selected: state.roleFilter == UserListRoleFilter.owner,
                onSelected: () => bloc.add(
                  const UserListEvent.roleFilterChanged(
                    UserListRoleFilter.owner,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RoleChip(
                label: 'Admin',
                selected: state.roleFilter == UserListRoleFilter.admin,
                onSelected: () => bloc.add(
                  const UserListEvent.roleFilterChanged(
                    UserListRoleFilter.admin,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RoleChip(
                label: 'Coordinateur',
                selected: state.roleFilter == UserListRoleFilter.coordinator,
                onSelected: () => bloc.add(
                  const UserListEvent.roleFilterChanged(
                    UserListRoleFilter.coordinator,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RoleChip(
                label: 'Amapien',
                selected: state.roleFilter == UserListRoleFilter.volunteer,
                onSelected: () => bloc.add(
                  const UserListEvent.roleFilterChanged(
                    UserListRoleFilter.volunteer,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RoleChip(
                label: 'Producteur',
                selected: state.roleFilter == UserListRoleFilter.producer,
                onSelected: () => bloc.add(
                  const UserListEvent.roleFilterChanged(
                    UserListRoleFilter.producer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Statut filter chips.
        Text('Statut :', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusChip(
                label: 'Tous',
                selected: state.statusFilter == null,
                onSelected: () =>
                    bloc.add(const UserListEvent.statusFilterChanged(null)),
              ),
              const SizedBox(width: 6),
              _StatusChip(
                label: 'Actif',
                selected: state.statusFilter == UserDisplayStatus.active,
                onSelected: () => bloc.add(
                  const UserListEvent.statusFilterChanged(
                    UserDisplayStatus.active,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _StatusChip(
                label: 'Invitation en attente',
                selected:
                    state.statusFilter == UserDisplayStatus.pendingInvitation,
                onSelected: () => bloc.add(
                  const UserListEvent.statusFilterChanged(
                    UserDisplayStatus.pendingInvitation,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _StatusChip(
                label: 'Suspendu',
                selected: state.statusFilter == UserDisplayStatus.suspended,
                onSelected: () => bloc.add(
                  const UserListEvent.statusFilterChanged(
                    UserDisplayStatus.suspended,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({required this.row});

  final UserRow row;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('user_row_tile_${row.ownerId}'),
      onTap: () => showUserDetailDialog(context, row.ownerId),
      title: Text(row.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (row.email.isNotEmpty) Text(row.email),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _StatusBadge(status: row.displayStatus),
              ...row.badgeRoles.map((role) => _RoleBadge(role: role)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _affiliationSummary(row),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      isThreeLine: true,
    );
  }

  String _affiliationSummary(UserRow row) {
    if (row.isOwner) return '(instance)   Owner';
    if (row.isProducer) {
      return 'Producteur de : ${row.producerAccountName ?? ''}';
    }
    if (row.memberships.isEmpty) return 'Aucune appartenance';
    return row.memberships
        .map((m) => '${m.organizationName}   ${_rolesLabel(m.roles)}')
        .join(' / ');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final UserDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_statusLabel(status), style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
      backgroundColor: _roleColor(role),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

Color _roleColor(Role role) => switch (role) {
  Role.owner => Colors.indigo,
  Role.admin => Colors.purple,
  Role.coordinator => Colors.green,
  Role.volunteer => Colors.blue,
  Role.producer => Colors.orange,
};

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.state, required this.bloc});

  final UserListLoaded state;
  final UserListBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Page ${state.currentPage} sur ${state.totalPages} · 50 lignes par page',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: state.currentPage > 1
                ? () =>
                      bloc.add(UserListEvent.pageChanged(state.currentPage - 1))
                : null,
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
            child: const Text('Précédent'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: state.currentPage < state.totalPages
                ? () =>
                      bloc.add(UserListEvent.pageChanged(state.currentPage + 1))
                : null,
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }
}

class _ActionFooter extends StatelessWidget {
  const _ActionFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Tooltip(
            message: 'Phase 8',
            child: OutlinedButton.icon(
              key: const Key('export_button'),
              onPressed: null,
              icon: const Icon(Icons.download),
              label: const Text('EXPORTER LA LISTE'),
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            ),
          ),
        ],
      ),
    );
  }
}

String _rolesLabel(Set<Role> roles) {
  final labels = <String>[];
  if (roles.contains(Role.admin)) labels.add('Admin');
  if (roles.contains(Role.coordinator)) labels.add('Coord.');
  if (roles.contains(Role.volunteer)) labels.add('Amapien');
  if (roles.contains(Role.producer)) labels.add('Producteur');
  if (roles.contains(Role.owner)) labels.add('Owner');
  return labels.join(' · ');
}

String _roleLabel(Role role) => switch (role) {
  Role.admin => 'Admin',
  Role.coordinator => 'Coordinateur',
  Role.volunteer => 'Amapien',
  Role.producer => 'Producteur',
  Role.owner => 'Owner',
};

String _statusLabel(UserDisplayStatus status) => switch (status) {
  UserDisplayStatus.active => 'Actif',
  UserDisplayStatus.pendingInvitation => 'Invitation en attente',
  UserDisplayStatus.suspended => 'Suspendu',
};

String _countLabel(UserListLoaded state) {
  final noun = state.totalCount > 1 ? 'utilisateurs' : 'utilisateur';
  if (_hasActiveFilters(state)) {
    final verb = state.totalCount > 1 ? 'correspondent' : 'correspond';
    return '${state.totalCount} $noun $verb aux filtres';
  }
  return '${state.totalCount} $noun au total';
}

bool _hasActiveFilters(UserListLoaded state) =>
    state.searchQuery.isNotEmpty ||
    state.amapIdFilter != null ||
    state.producerIdFilter != null ||
    state.roleFilter != null ||
    state.statusFilter != null;
