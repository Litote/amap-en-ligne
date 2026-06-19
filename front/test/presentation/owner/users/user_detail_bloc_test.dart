import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_detail_bloc.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_detail_event.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_detail_state.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOwnerRepository extends Mock implements OwnerRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

class _FakeMember extends Fake implements Member {}

Owner _owner({
  String id = 'o-1',
  String first = 'Alice',
  String last = 'Martin',
  AccountStatus status = AccountStatus.active,
}) => Owner(
  ownerId: id,
  firstName: first,
  lastName: last,
  email: 'alice@exemple.fr',
  accountStatus: status,
  registeredAt: '2025-01-03T00:00:00Z',
  updatedAt: '2025-01-03T00:00:00Z',
);

Member _member({
  String id = 'm-1',
  String orgId = 'org-1',
  Set<Role> roles = const {Role.volunteer},
  bool activeStatus = true,
  String? firstName,
  String? lastName,
  String? email,
  String? phone,
  MemberAccountStatus? accountStatus,
}) => Member(
  memberId: id,
  organizationId: orgId,
  roles: roles,
  activeStatus: activeStatus,
  firstName: firstName,
  lastName: lastName,
  email: email,
  phone: phone,
  accountStatus: accountStatus,
);

Organization _org({String id = 'org-1', String name = 'AMAP des Pins'}) =>
    Organization(
      organizationId: id,
      name: name,
      contactEmail: 'contact@org.fr',
    );

/// Waits for a stable non-loading/non-initial state. The detail bloc joins
/// three independent streams, so the first non-loading state may be transient.
Future<UserDetailState> _awaitFinalState(UserDetailBloc bloc) async {
  await bloc.stream
      .firstWhere((s) => s is! UserDetailInitial && s is! UserDetailLoading)
      .timeout(const Duration(seconds: 5));

  for (var i = 0; i < 10; i++) {
    await Future<void>.value();
  }

  final current = bloc.state;
  if (current is! UserDetailInitial && current is! UserDetailLoading) {
    return current;
  }
  return bloc.stream
      .firstWhere((s) => s is! UserDetailInitial && s is! UserDetailLoading)
      .timeout(const Duration(seconds: 5));
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMember());
  });

  late _MockOwnerRepository ownerRepo;
  late _MockMemberRepository memberRepo;
  late _MockOrganizationRepository orgRepo;
  late _MockProducerAccountRepository producerRepo;

  setUp(() {
    ownerRepo = _MockOwnerRepository();
    memberRepo = _MockMemberRepository();
    orgRepo = _MockOrganizationRepository();
    producerRepo = _MockProducerAccountRepository();
    when(
      () => producerRepo.watchAll(),
    ).thenAnswer((_) => Stream.value(const []));
  });

  UserDetailBloc buildBloc() => UserDetailBloc(
    ownerRepository: ownerRepo,
    memberRepository: memberRepo,
    organizationRepository: orgRepo,
    producerAccountRepository: producerRepo,
  );

  void mockData({
    List<Owner> owners = const [],
    List<Member> members = const [],
    List<Organization> orgs = const [],
  }) {
    when(() => ownerRepo.watchAll()).thenAnswer((_) => Stream.value(owners));
    when(() => memberRepo.watchAll()).thenAnswer((_) => Stream.value(members));
    when(() => orgRepo.watchAll()).thenAnswer((_) => Stream.value(orgs));
  }

  test('loads an AMAP member — loaded state with isOwner = false', () async {
    mockData(
      members: [
        _member(
          id: 'm-1',
          roles: {Role.admin},
          firstName: 'Alice',
          lastName: 'Martin',
          email: 'alice@exemple.fr',
          phone: '06 01 02 03 04',
          accountStatus: MemberAccountStatus.active,
        ),
      ],
      orgs: [_org()],
    );
    final bloc = buildBloc();
    bloc.add(const UserDetailEvent.loaded('m-1'));
    final state = await _awaitFinalState(bloc);

    expect(state, isA<UserDetailLoaded>());
    final loaded = state as UserDetailLoaded;
    expect(loaded.userRow.isOwner, isFalse);
    expect(loaded.userRow.memberships, isNotEmpty);
    expect(loaded.userRow.displayName, 'Alice Martin');
    expect(loaded.userRow.email, 'alice@exemple.fr');
    expect(loaded.userRow.phone, '06 01 02 03 04');
    expect(loaded.userRow.displayStatus, UserDisplayStatus.active);
    await bloc.close();
  });

  test('loads an Owner — loaded state with isOwner = true', () async {
    mockData(owners: [_owner(id: 'o-1')]);
    final bloc = buildBloc();
    bloc.add(const UserDetailEvent.loaded('o-1'));
    final state = await _awaitFinalState(bloc);

    expect(state, isA<UserDetailLoaded>());
    final loaded = state as UserDetailLoaded;
    expect(loaded.userRow.isOwner, isTrue);
    expect(loaded.userRow.memberships, isEmpty);
    await bloc.close();
  });

  test('emits notFound when userId does not match any row', () async {
    mockData();
    final bloc = buildBloc();
    bloc.add(const UserDetailEvent.loaded('unknown-id'));
    final state = await _awaitFinalState(bloc);
    expect(state, const UserDetailState.notFound());
    await bloc.close();
  });

  // After sub/id unification memberId == sub by invariant, so the `sub` field
  // being null no longer blocks identity resolution — the member is found via
  // memberId.  This test documents the new behaviour: a member with null sub
  // but a valid memberId resolves to a loaded state.
  test(
    'loads a member even when Member.sub is null (memberId is the identity)',
    () async {
      mockData(
        members: [
          _member(
            id: 'm-noSub',
            firstName: 'Jean',
            lastName: 'Dupont',
            email: 'jean@exemple.fr',
            accountStatus: MemberAccountStatus.active,
          ),
        ],
        orgs: [_org()],
      );
      final bloc = buildBloc();
      bloc.add(const UserDetailEvent.loaded('m-noSub'));
      final state = await _awaitFinalState(bloc);
      expect(state, isA<UserDetailLoaded>());
      final loaded = state as UserDetailLoaded;
      expect(loaded.userRow.isOwner, isFalse);
      expect(loaded.userRow.displayName, 'Jean Dupont');
      await bloc.close();
    },
  );

  test(
    'membershipRolesChanged delegates to MemberRepository.setRoles',
    () async {
      mockData(
        members: [
          _member(id: 'm-1', roles: {Role.volunteer}),
        ],
        orgs: [_org()],
      );
      when(
        () => memberRepo.setRoles(any(), any<Member>(), any()),
      ).thenAnswer((_) async {});

      final bloc = buildBloc();
      bloc.add(const UserDetailEvent.loaded('m-1'));
      await _awaitFinalState(bloc);

      bloc.add(
        const UserDetailEvent.membershipRolesChanged(
          memberId: 'm-1',
          organizationId: 'org-1',
          newRoles: {Role.admin},
        ),
      );

      // Drain microtasks so the handler runs.
      for (var i = 0; i < 10; i++) {
        await Future<void>.value();
      }

      verify(
        () => memberRepo.setRoles('org-1', any<Member>(), {Role.admin}),
      ).called(1);
      await bloc.close();
    },
  );
}
