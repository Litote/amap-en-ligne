import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/owner_invitation.dart';
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

class UserDetailBloc extends Bloc<UserDetailEvent, UserDetailState> {
  UserDetailBloc({
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
       super(const UserDetailState.initial()) {
    on<UserDetailLoadRequested>(_onLoaded);
    on<UserDetailMembershipRolesChanged>(_onMembershipRolesChanged);
  }

  final OwnerRepository _ownerRepo;
  final MemberRepository _memberRepo;
  final OrganizationRepository _orgRepo;
  final ProducerAccountRepository _producerAccountRepo;
  final OwnerInvitationRepository _ownerInvitationRepo;
  final MemberInvitationRepository _memberInvitationRepo;

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
    final ownerInvitations = <OwnerInvitation>[];
    final memberInvitations = <MemberInvitation>[];

    final controller = StreamController<_DetailSnapshot>();

    _DetailSnapshot snapshot() => _DetailSnapshot(
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
    await ownerInvitationsSub.cancel();
    await memberInvitationsSub.cancel();
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
    // Same rows as the list (the list opens the detail with `row.ownerId`).
    final row = snapshot.rows.where((r) => r.ownerId == userId).firstOrNull;
    return row == null
        ? const UserDetailState.notFound()
        : UserDetailState.loaded(userRow: row);
  }
}
