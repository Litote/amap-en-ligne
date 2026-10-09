import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/owner_invitation.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/validation/search_text.dart';
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
    required this.ownerInvitations,
    required this.memberInvitations,
  });

  final List<Owner> owners;
  final List<Member> members;
  final List<Organization> organizations;
  final List<ProducerAccount> producerAccounts;
  final List<OwnerInvitation> ownerInvitations;
  final List<MemberInvitation> memberInvitations;

  List<UserRow> get rows => buildInstanceUserRows(
    owners: owners,
    members: members,
    organizations: organizations,
    producerAccounts: producerAccounts,
    ownerInvitations: ownerInvitations,
    memberInvitations: memberInvitations,
  );
}

class UserListBloc extends Bloc<UserListEvent, UserListState> {
  UserListBloc({
    required OwnerRepository ownerRepository,
    required MemberRepository memberRepository,
    required OrganizationRepository organizationRepository,
    required ProducerAccountRepository producerAccountRepository,
    required OwnerInvitationRepository ownerInvitationRepository,
    required MemberInvitationRepository memberInvitationRepository,
  }) : _ownerRepo = ownerRepository,
       _memberRepo = memberRepository,
       _orgRepo = organizationRepository,
       _producerAccountRepo = producerAccountRepository,
       _ownerInvitationRepo = ownerInvitationRepository,
       _memberInvitationRepo = memberInvitationRepository,
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
  final OwnerInvitationRepository _ownerInvitationRepo;
  final MemberInvitationRepository _memberInvitationRepo;

  // Latest snapshot — updated by the combined stream, used for re-filtering.
  _Snapshot _snapshot = const _Snapshot(
    owners: [],
    members: [],
    organizations: [],
    producerAccounts: [],
    ownerInvitations: [],
    memberInvitations: [],
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
    final ownerInvitations = <OwnerInvitation>[];
    final memberInvitations = <MemberInvitation>[];

    final controller = StreamController<_Snapshot>();

    _Snapshot snapshot() => _Snapshot(
      owners: List.of(owners),
      members: List.of(members),
      organizations: List.of(organizations),
      producerAccounts: List.of(producerAccounts),
      ownerInvitations: List.of(ownerInvitations),
      memberInvitations: List.of(memberInvitations),
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
    final ownerInvitationsSub = _ownerInvitationRepo.watchAll().listen((data) {
      ownerInvitations
        ..clear()
        ..addAll(data);
      if (!controller.isClosed) controller.add(snapshot());
    });
    final memberInvitationsSub = _memberInvitationRepo.watchAll().listen((
      data,
    ) {
      memberInvitations
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
    await ownerInvitationsSub.cancel();
    await memberInvitationsSub.cancel();
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
    final allRows = snapshot.rows;
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
      result = result
          .where(
            (r) =>
                matchesSearch(searchQuery, [r.firstName, r.lastName, r.email]),
          )
          .toList();
    }

    if (amapId != null) {
      result = result
          .where((r) => r.memberships.any((m) => m.organizationId == amapId))
          .toList();
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
