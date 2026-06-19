import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_event.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_state.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:bloc/bloc.dart';

const _pageSize = 50;

/// Combined data snapshot used to drive the list screen state.
class _Snapshot {
  const _Snapshot({
    required this.owners,
    required this.members,
    required this.organizations,
    required this.producerAccounts,
  });

  final List<Owner> owners;
  final List<Member> members;
  final List<Organization> organizations;
  final List<ProducerAccount> producerAccounts;
}

class UserListBloc extends Bloc<UserListEvent, UserListState> {
  UserListBloc({
    required OwnerRepository ownerRepository,
    required MemberRepository memberRepository,
    required OrganizationRepository organizationRepository,
    required ProducerAccountRepository producerAccountRepository,
  }) : _ownerRepo = ownerRepository,
       _memberRepo = memberRepository,
       _orgRepo = organizationRepository,
       _producerAccountRepo = producerAccountRepository,
       super(const UserListState.initial()) {
    on<UserListLoadRequested>(_onLoaded);
    on<UserListSearchQueryChanged>(_onSearchQueryChanged);
    on<UserListAmapFilterChanged>(_onAmapFilterChanged);
    on<UserListProducerFilterChanged>(_onProducerFilterChanged);
    on<UserListRoleFilterChanged>(_onRoleFilterChanged);
    on<UserListStatusFilterChanged>(_onStatusFilterChanged);
    on<UserListPageChanged>(_onPageChanged);
  }

  final OwnerRepository _ownerRepo;
  final MemberRepository _memberRepo;
  final OrganizationRepository _orgRepo;
  final ProducerAccountRepository _producerAccountRepo;

  // Latest snapshot — updated by the combined stream, used for re-filtering.
  _Snapshot _snapshot = const _Snapshot(
    owners: [],
    members: [],
    organizations: [],
    producerAccounts: [],
  );

  Future<void> _onLoaded(
    UserListLoadRequested event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserListState.loading());

    // Combine three independent streams into a single snapshot stream by
    // merging updates through a local accumulator. The stream closes only
    // when the emitter is cancelled (bloc closed or handler superseded).
    final owners = <Owner>[];
    final members = <Member>[];
    final organizations = <Organization>[];
    final producerAccounts = <ProducerAccount>[];

    final controller = StreamController<_Snapshot>();

    _Snapshot snapshot() => _Snapshot(
      owners: List.of(owners),
      members: List.of(members),
      organizations: List.of(organizations),
      producerAccounts: List.of(producerAccounts),
    );

    final ownersSub = _ownerRepo.watchAll().listen((data) {
      owners
        ..clear()
        ..addAll(data);
      if (!controller.isClosed) controller.add(snapshot());
    });
    final membersSub = _memberRepo.watchAll().listen((data) {
      members
        ..clear()
        ..addAll(data);
      if (!controller.isClosed) controller.add(snapshot());
    });
    final orgsSub = _orgRepo.watchAll().listen((data) {
      organizations
        ..clear()
        ..addAll(data);
      if (!controller.isClosed) controller.add(snapshot());
    });
    final producersSub = _producerAccountRepo.watchAll().listen((data) {
      producerAccounts
        ..clear()
        ..addAll(data);
      if (!controller.isClosed) controller.add(snapshot());
    });

    await emit.forEach<_Snapshot>(
      controller.stream,
      onData: (snapshot) {
        _snapshot = snapshot;
        final current = state;
        final String searchQuery;
        final String? amapFilter;
        final String? producerFilter;
        final UserListRoleFilter? roleFilter;
        final UserDisplayStatus? statusFilter;
        var page = 1;
        if (current is UserListLoaded) {
          searchQuery = current.searchQuery;
          amapFilter = current.amapIdFilter;
          producerFilter = current.producerIdFilter;
          roleFilter = current.roleFilter;
          statusFilter = current.statusFilter;
          page = current.currentPage;
        } else {
          searchQuery = '';
          amapFilter = null;
          producerFilter = null;
          roleFilter = null;
          statusFilter = null;
        }
        return _computeLoaded(
          snapshot: snapshot,
          searchQuery: searchQuery,
          amapFilter: amapFilter,
          producerFilter: producerFilter,
          roleFilter: roleFilter,
          statusFilter: statusFilter,
          page: page,
        );
      },
      onError: (error, _) => const UserListState.error('Erreur de chargement.'),
    );

    await ownersSub.cancel();
    await membersSub.cancel();
    await orgsSub.cancel();
    await producersSub.cancel();
    await controller.close();
  }

  void _onSearchQueryChanged(
    UserListSearchQueryChanged event,
    Emitter<UserListState> emit,
  ) {
    final current = state;
    if (current is! UserListLoaded) return;
    emit(
      _computeLoaded(
        snapshot: _snapshot,
        searchQuery: event.query,
        amapFilter: current.amapIdFilter,
        producerFilter: current.producerIdFilter,
        roleFilter: current.roleFilter,
        statusFilter: current.statusFilter,
        page: 1,
      ),
    );
  }

  void _onAmapFilterChanged(
    UserListAmapFilterChanged event,
    Emitter<UserListState> emit,
  ) {
    final current = state;
    if (current is! UserListLoaded) return;
    emit(
      _computeLoaded(
        snapshot: _snapshot,
        searchQuery: current.searchQuery,
        amapFilter: event.organizationId,
        producerFilter: current.producerIdFilter,
        roleFilter: current.roleFilter,
        statusFilter: current.statusFilter,
        page: 1,
      ),
    );
  }

  void _onProducerFilterChanged(
    UserListProducerFilterChanged event,
    Emitter<UserListState> emit,
  ) {
    final current = state;
    if (current is! UserListLoaded) return;
    emit(
      _computeLoaded(
        snapshot: _snapshot,
        searchQuery: current.searchQuery,
        amapFilter: current.amapIdFilter,
        producerFilter: event.organizationId,
        roleFilter: current.roleFilter,
        statusFilter: current.statusFilter,
        page: 1,
      ),
    );
  }

  void _onRoleFilterChanged(
    UserListRoleFilterChanged event,
    Emitter<UserListState> emit,
  ) {
    final current = state;
    if (current is! UserListLoaded) return;
    emit(
      _computeLoaded(
        snapshot: _snapshot,
        searchQuery: current.searchQuery,
        amapFilter: current.amapIdFilter,
        producerFilter: current.producerIdFilter,
        roleFilter: event.filter,
        statusFilter: current.statusFilter,
        page: 1,
      ),
    );
  }

  void _onStatusFilterChanged(
    UserListStatusFilterChanged event,
    Emitter<UserListState> emit,
  ) {
    final current = state;
    if (current is! UserListLoaded) return;
    emit(
      _computeLoaded(
        snapshot: _snapshot,
        searchQuery: current.searchQuery,
        amapFilter: current.amapIdFilter,
        producerFilter: current.producerIdFilter,
        roleFilter: current.roleFilter,
        statusFilter: event.status,
        page: 1,
      ),
    );
  }

  void _onPageChanged(UserListPageChanged event, Emitter<UserListState> emit) {
    final current = state;
    if (current is! UserListLoaded) return;
    emit(
      _computeLoaded(
        snapshot: _snapshot,
        searchQuery: current.searchQuery,
        amapFilter: current.amapIdFilter,
        producerFilter: current.producerIdFilter,
        roleFilter: current.roleFilter,
        statusFilter: current.statusFilter,
        page: event.page,
      ),
    );
  }

  UserListState _computeLoaded({
    required _Snapshot snapshot,
    required String searchQuery,
    required String? amapFilter,
    required String? producerFilter,
    required UserListRoleFilter? roleFilter,
    required UserDisplayStatus? statusFilter,
    required int page,
  }) {
    final allRows = _buildAllRows(snapshot);
    final filtered = _applyFilters(
      allRows,
      searchQuery: searchQuery,
      amapId: amapFilter,
      producerId: producerFilter,
      roleFilter: roleFilter,
      statusFilter: statusFilter,
    );
    final totalCount = filtered.length;
    final totalPages = (totalCount / _pageSize).ceil().clamp(1, 999999);
    final safePage = page.clamp(1, totalPages);
    final start = (safePage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, totalCount);

    return UserListState.loaded(
      allOrganizations: snapshot.organizations,
      allProducerAccounts: snapshot.producerAccounts,
      visibleRows: filtered.sublist(start, end),
      totalCount: totalCount,
      currentPage: safePage,
      totalPages: totalPages,
      searchQuery: searchQuery,
      amapIdFilter: amapFilter,
      producerIdFilter: producerFilter,
      roleFilter: roleFilter,
      statusFilter: statusFilter,
    );
  }

  /// Aggregates owners + members + producer accounts into a sorted,
  /// deduplicated list of [UserRow]s. Users identified by [identityKey] appear
  /// at most
  /// once; owners take precedence over member-only records, producers are
  /// keyed by `producerAccountId`.
  List<UserRow> _buildAllRows(_Snapshot snapshot) {
    final organizationNamesById = {
      for (final organization in snapshot.organizations)
        organization.organizationId: organization.name,
    };

    // Start with all owners.
    final byIdentityMap = <String, UserRow>{};
    for (final owner in snapshot.owners) {
      byIdentityMap[owner.ownerId] = userRowFromOwner(owner);
    }

    // Producer rows — keyed by producerAccountId since the wire payload does
    // not carry a user-level identity key yet.
    for (final pa in snapshot.producerAccounts) {
      byIdentityMap.putIfAbsent(
        pa.producerAccountId,
        () => userRowFromProducerAccount(pa),
      );
    }

    final membersByIdentity = <String, List<Member>>{};
    for (final member in snapshot.members) {
      membersByIdentity.putIfAbsent(member.memberId, () => []).add(member);
    }

    for (final entry in membersByIdentity.entries) {
      final identityKey = entry.key;
      final memberList = entry.value;
      if (byIdentityMap.containsKey(identityKey)) continue;

      final row = userRowFromMembers(memberList, organizationNamesById);
      if (row != null) byIdentityMap[identityKey] = row;
    }

    final sorted = byIdentityMap.values.toList()
      ..sort((a, b) {
        final lastCmp = a.lastName.toLowerCase().compareTo(
          b.lastName.toLowerCase(),
        );
        if (lastCmp != 0) return lastCmp;
        return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      });

    return sorted;
  }

  List<UserRow> _applyFilters(
    List<UserRow> rows, {
    required String searchQuery,
    required String? amapId,
    required String? producerId,
    required UserListRoleFilter? roleFilter,
    required UserDisplayStatus? statusFilter,
  }) {
    var result = rows;

    if (searchQuery.isNotEmpty) {
      final query = _normalize(searchQuery);
      result = result.where((r) {
        return _normalize(r.firstName).contains(query) ||
            _normalize(r.lastName).contains(query) ||
            _normalize(r.email).contains(query);
      }).toList();
    }

    if (amapId != null) {
      result = result.where((r) {
        return r.memberships.any((m) => m.organizationId == amapId);
      }).toList();
    }

    if (producerId != null) {
      result = result.where((r) => r.producerAccountId == producerId).toList();
    }

    if (roleFilter != null) {
      result = result.where((r) => _matchesRoleFilter(r, roleFilter)).toList();
    }

    if (statusFilter != null) {
      result = result.where((r) => r.displayStatus == statusFilter).toList();
    }

    return result;
  }

  bool _matchesRoleFilter(UserRow row, UserListRoleFilter filter) {
    switch (filter) {
      case UserListRoleFilter.owner:
        return row.isOwner;
      case UserListRoleFilter.producer:
        return row.isProducer;
      case UserListRoleFilter.admin:
        return row.memberships.any((m) => m.roles.contains(Role.admin));
      case UserListRoleFilter.coordinator:
        return row.memberships.any((m) => m.roles.contains(Role.coordinator));
      case UserListRoleFilter.volunteer:
        return row.memberships.any((m) => m.roles.contains(Role.volunteer));
    }
  }
}

/// ASCII-safe lowercase + basic diacritic removal for search.
/// Full diacritic normalisation would require the `diacritic` package which
/// is not in pubspec.yaml. This helper covers the most common French chars.
String _normalize(String s) {
  const from = 'àâäéèêëîïôùûüÿçœæÀÂÄÉÈÊËÎÏÔÙÛÜŸÇŒÆ';
  const to = 'aaaeeeeiioouuuycoeAAEEEEEIIOOUUUYCOEAE';
  final buffer = StringBuffer();
  for (final char in s.toLowerCase().split('')) {
    final idx = from.indexOf(char);
    buffer.write(idx >= 0 ? to[idx] : char);
  }
  return buffer.toString();
}
