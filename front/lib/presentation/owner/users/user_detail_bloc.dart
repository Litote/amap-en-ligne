import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_detail_event.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_detail_state.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:bloc/bloc.dart';

/// Combined data snapshot for the detail view.
class _DetailSnapshot {
  const _DetailSnapshot({
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

class UserDetailBloc extends Bloc<UserDetailEvent, UserDetailState> {
  UserDetailBloc({
    required OwnerRepository ownerRepository,
    required MemberRepository memberRepository,
    required OrganizationRepository organizationRepository,
    required ProducerAccountRepository producerAccountRepository,
  }) : _ownerRepo = ownerRepository,
       _memberRepo = memberRepository,
       _orgRepo = organizationRepository,
       _producerAccountRepo = producerAccountRepository,
       super(const UserDetailState.initial()) {
    on<UserDetailLoadRequested>(_onLoaded);
    on<UserDetailMembershipRolesChanged>(_onMembershipRolesChanged);
  }

  final OwnerRepository _ownerRepo;
  final MemberRepository _memberRepo;
  final OrganizationRepository _orgRepo;
  final ProducerAccountRepository _producerAccountRepo;

  Future<void> _onLoaded(
    UserDetailLoadRequested event,
    Emitter<UserDetailState> emit,
  ) async {
    final userId = event.userId;
    emit(const UserDetailState.loading());

    final owners = <Owner>[];
    final members = <Member>[];
    final organizations = <Organization>[];
    final producerAccounts = <ProducerAccount>[];

    final controller = StreamController<_DetailSnapshot>();

    _DetailSnapshot snapshot() => _DetailSnapshot(
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

    await emit.forEach<_DetailSnapshot>(
      controller.stream,
      onData: (snapshot) => _computeDetailState(userId, snapshot),
      onError: (error, _) =>
          const UserDetailState.error('Erreur de chargement.'),
    );

    await ownersSub.cancel();
    await membersSub.cancel();
    await orgsSub.cancel();
    await producersSub.cancel();
    await controller.close();
  }

  Future<void> _onMembershipRolesChanged(
    UserDetailMembershipRolesChanged event,
    Emitter<UserDetailState> emit,
  ) async {
    final member = Member(
      memberId: event.memberId,
      organizationId: event.organizationId,
    );
    await _memberRepo.setRoles(event.organizationId, member, event.newRoles);
  }

  UserDetailState _computeDetailState(String userId, _DetailSnapshot snapshot) {
    final organizationNamesById = {
      for (final organization in snapshot.organizations)
        organization.organizationId: organization.name,
    };

    final ownerRow = snapshot.owners
        .where((o) => o.ownerId == userId)
        .firstOrNull;
    if (ownerRow != null) {
      return UserDetailState.loaded(userRow: userRowFromOwner(ownerRow));
    }

    // Producer detail — keyed on producerAccountId (which is what the list
    // surfaces as the row id for producer users).
    final producerRow = snapshot.producerAccounts
        .where((p) => p.producerAccountId == userId)
        .firstOrNull;
    if (producerRow != null) {
      return UserDetailState.loaded(
        userRow: userRowFromProducerAccount(producerRow),
      );
    }

    final matchingMember = snapshot.members
        .where((m) => m.memberId == userId)
        .firstOrNull;
    if (matchingMember == null) return const UserDetailState.notFound();

    // After sub/id unification: memberId == sub by invariant. The wire no
    // longer emits a `sub` field; use memberId to identify the user.
    final sub = matchingMember.memberId;

    final memberList = snapshot.members
        .where((m) => m.memberId == sub)
        .toList();
    final userRow = userRowFromMembers(memberList, organizationNamesById);
    if (userRow == null) return const UserDetailState.notFound();

    return UserDetailState.loaded(userRow: userRow);
  }
}
