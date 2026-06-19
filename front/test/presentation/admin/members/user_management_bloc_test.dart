import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/admin/members/user_management_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockMemberInvitationRepository extends Mock
    implements MemberInvitationRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

class _MockAppDatabase extends Mock implements AppDatabase {}

const _testOrgId = 'org-1';

final _member1 = Member(
  memberId: 'member-1',
  organizationId: _testOrgId,
  roles: const {Role.volunteer},
);

final _member2 = Member(
  memberId: 'member-2',
  organizationId: _testOrgId,
  roles: const {Role.admin, Role.coordinator},
);

final _members = [_member1, _member2];
final _invitation = MemberInvitation(
  invitationId: 'inv-1',
  organizationId: _testOrgId,
  email: 'alice@example.com',
  firstName: 'Alice',
  lastName: 'Martin',
  roles: const {Role.volunteer},
  status: InvitationStatus.pendingActivation,
  createdAt: '2026-01-01T00:00:00Z',
  expiresAt: '2026-01-08T00:00:00Z',
);

void main() {
  late _MockMemberRepository memberRepo;
  late _MockMemberInvitationRepository memberInvitationRepo;
  late _MockSyncRepository syncRepository;
  late _MockAppDatabase database;

  setUpAll(() {
    registerFallbackValue(_member1);
    registerFallbackValue(<Role>{});
    registerFallbackValue(Role.volunteer);
  });

  setUp(() {
    memberRepo = _MockMemberRepository();
    memberInvitationRepo = _MockMemberInvitationRepository();
    syncRepository = _MockSyncRepository();
    database = _MockAppDatabase();
  });

  UserManagementBloc buildBloc({bool canEditAdminRole = true}) =>
      UserManagementBloc(
        memberRepository: memberRepo,
        memberInvitationRepository: memberInvitationRepo,
        syncRepository: syncRepository,
        database: database,
        organizationId: _testOrgId,
        canEditAdminRole: canEditAdminRole,
      );

  group('UserManagementBloc', () {
    blocTest<UserManagementBloc, UserManagementState>(
      'loadRequested emits loading then loaded with members',
      setUp: () {
        when(
          () => memberRepo.watch(_testOrgId),
        ).thenAnswer((_) => Stream.value(_members));
        when(
          () => memberInvitationRepo.watch(_testOrgId),
        ).thenAnswer((_) => Stream.value(const []));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const UserManagementEvent.loadRequested()),
      expect: () => [
        const UserManagementState.loading(),
        isA<UserManagementLoaded>().having(
          (s) => s.members,
          'members',
          _members,
        ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'searchChanged updates searchQuery in loaded state',
      build: buildBloc,
      seed: () => UserManagementState.loaded(members: _members),
      act: (bloc) =>
          bloc.add(const UserManagementEvent.searchChanged('member-1')),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.searchQuery,
          'searchQuery',
          'member-1',
        ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'roleFilterChanged updates roleFilter in loaded state',
      build: buildBloc,
      seed: () => UserManagementState.loaded(members: _members),
      act: (bloc) =>
          bloc.add(const UserManagementEvent.roleFilterChanged(Role.admin)),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.roleFilter,
          'roleFilter',
          Role.admin,
        ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'editRolesRequested sets editingMember and pendingRoles',
      build: buildBloc,
      seed: () => UserManagementState.loaded(members: _members),
      act: (bloc) => bloc.add(UserManagementEvent.editRolesRequested(_member1)),
      expect: () => [
        isA<UserManagementLoaded>()
            .having((s) => s.editingMember, 'editingMember', _member1)
            .having(
              (s) => s.pendingRoles,
              'pendingRoles',
              contains(Role.volunteer),
            ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'roleToggled adds role when isChecked is true',
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        editingMember: _member1,
        pendingRoles: const {Role.volunteer},
      ),
      act: (bloc) => bloc.add(
        const UserManagementEvent.roleToggled(Role.coordinator, true),
      ),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.pendingRoles,
          'pendingRoles',
          containsAll([Role.volunteer, Role.coordinator]),
        ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'roleToggled removes role when isChecked is false',
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        editingMember: _member1,
        pendingRoles: const {Role.volunteer, Role.coordinator},
      ),
      act: (bloc) => bloc.add(
        const UserManagementEvent.roleToggled(Role.coordinator, false),
      ),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.pendingRoles,
          'pendingRoles',
          contains(Role.volunteer),
        ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'saveRolesRequested calls setRoles and clears editingMember',
      setUp: () => when(
        () => memberRepo.setRoles(_testOrgId, _member1, any()),
      ).thenAnswer((_) async {}),
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        editingMember: _member1,
        pendingRoles: const {Role.admin},
      ),
      act: (bloc) => bloc.add(const UserManagementEvent.saveRolesRequested()),
      expect: () => [
        isA<UserManagementLoaded>().having((s) => s.saving, 'saving', true),
        isA<UserManagementLoaded>()
            .having((s) => s.editingMember, 'editingMember', null)
            .having((s) => s.pendingRoles, 'pendingRoles', isEmpty)
            .having((s) => s.saving, 'saving', false),
      ],
      verify: (_) => verify(
        () => memberRepo.setRoles(_testOrgId, _member1, {Role.admin}),
      ).called(1),
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'editCancelled clears editingMember and pendingRoles',
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        editingMember: _member1,
        pendingRoles: const {Role.volunteer},
      ),
      act: (bloc) => bloc.add(const UserManagementEvent.editCancelled()),
      expect: () => [
        isA<UserManagementLoaded>()
            .having((s) => s.editingMember, 'editingMember', null)
            .having((s) => s.pendingRoles, 'pendingRoles', isEmpty),
      ],
    );
  });

  group('invite member', () {
    blocTest<UserManagementBloc, UserManagementState>(
      'showInviteForm sets showingInviteForm true and clears invite fields',
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        inviteFirstName: 'Old',
        inviteLastName: 'Data',
        inviteEmail: 'old@test.com',
        inviteRoles: const {Role.admin},
        inviteError: 'Previous error',
        inviteSuccess: true,
      ),
      act: (bloc) => bloc.add(const UserManagementEvent.showInviteForm()),
      expect: () => [
        isA<UserManagementLoaded>()
            .having((s) => s.showingInviteForm, 'showingInviteForm', true)
            .having((s) => s.inviteFirstName, 'inviteFirstName', '')
            .having((s) => s.inviteLastName, 'inviteLastName', '')
            .having((s) => s.inviteEmail, 'inviteEmail', '')
            .having((s) => s.inviteRoles, 'inviteRoles', isEmpty)
            .having((s) => s.inviteError, 'inviteError', null)
            .having((s) => s.inviteSuccess, 'inviteSuccess', false),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'inviteFirstNameChanged updates inviteFirstName',
      build: buildBloc,
      seed: () => UserManagementState.loaded(members: _members),
      act: (bloc) =>
          bloc.add(const UserManagementEvent.inviteFirstNameChanged('Alice')),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.inviteFirstName,
          'inviteFirstName',
          'Alice',
        ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'submitInvitation creates invitation through repository and sets inviteSuccess on success',
      setUp: () {
        when(
          () => memberInvitationRepo.create(
            organizationId: any(named: 'organizationId'),
            email: any(named: 'email'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            roles: any(named: 'roles'),
          ),
        ).thenAnswer((_) async => 'op-1');
        when(
          () => syncRepository.sync(tenantId: any(named: 'tenantId')),
        ).thenAnswer((_) async => const SyncOutcome.success());
      },
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        inviteFirstName: 'Alice',
        inviteLastName: 'Smith',
        inviteEmail: 'alice@example.com',
        inviteRoles: const {Role.volunteer},
      ),
      act: (bloc) => bloc.add(const UserManagementEvent.submitInvitation()),
      expect: () => [
        isA<UserManagementLoaded>().having((s) => s.inviting, 'inviting', true),
        isA<UserManagementLoaded>()
            .having((s) => s.inviting, 'inviting', false)
            .having((s) => s.showingInviteForm, 'showingInviteForm', false)
            .having((s) => s.inviteSuccess, 'inviteSuccess', true),
      ],
      verify: (_) => verify(
        () => memberInvitationRepo.create(
          organizationId: _testOrgId,
          email: 'alice@example.com',
          firstName: 'Alice',
          lastName: 'Smith',
          roles: {Role.volunteer},
        ),
      ).called(1),
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'submitInvitation validates required fields and sets inviteError',
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        inviteFirstName: 'Alice',
        inviteLastName: '',
        inviteEmail: 'alice@example.com',
        inviteRoles: const {},
      ),
      act: (bloc) => bloc.add(const UserManagementEvent.submitInvitation()),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.inviteError,
          'inviteError',
          'Veuillez remplir tous les champs obligatoires.',
        ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'submitInvitation sets inviteError on API failure',
      setUp: () => when(
        () => memberInvitationRepo.create(
          organizationId: any(named: 'organizationId'),
          email: any(named: 'email'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          roles: any(named: 'roles'),
        ),
      ).thenThrow(Exception('Network error')),
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        inviteFirstName: 'Alice',
        inviteLastName: 'Smith',
        inviteEmail: 'alice@example.com',
        inviteRoles: const {Role.volunteer},
      ),
      act: (bloc) => bloc.add(const UserManagementEvent.submitInvitation()),
      expect: () => [
        isA<UserManagementLoaded>().having((s) => s.inviting, 'inviting', true),
        isA<UserManagementLoaded>()
            .having((s) => s.inviting, 'inviting', false)
            .having(
              (s) => s.inviteError,
              'inviteError',
              "Erreur lors de l'envoi de l'invitation.",
            ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'resendInvitationRequested surfaces rejection feedback',
      setUp: () {
        when(
          () => memberInvitationRepo.resend(
            organizationId: any(named: 'organizationId'),
            invitationId: any(named: 'invitationId'),
          ),
        ).thenAnswer((_) async => 'op-2');
        when(
          () => syncRepository.sync(tenantId: any(named: 'tenantId')),
        ).thenAnswer(
          (_) async => SyncOutcome.success(
            rejectedMutations: const [
              MutationOutcome(
                clientOpId: 'op-2',
                status: MutationStatus.rejected,
                error: MutationError(
                  code: MutationErrorCode.conflict,
                  message: 'duplicate',
                ),
              ),
            ],
          ),
        );
      },
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        memberInvitations: [_invitation],
      ),
      act: (bloc) =>
          bloc.add(UserManagementEvent.resendInvitationRequested(_invitation)),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.resendingInvitationIds,
          'resendingInvitationIds',
          contains(_invitation.invitationId),
        ),
        isA<UserManagementLoaded>()
            .having((s) => s.feedbackIsError, 'feedbackIsError', true)
            .having(
              (s) => s.feedbackMessage,
              'feedbackMessage',
              'Cette invitation existe déjà.',
            ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'resendAllPendingRequested resends every pending invitation with the custom copy',
      setUp: () {
        when(
          () => memberInvitationRepo.resend(
            organizationId: any(named: 'organizationId'),
            invitationId: any(named: 'invitationId'),
            customEmailSubject: any(named: 'customEmailSubject'),
            customEmailBody: any(named: 'customEmailBody'),
          ),
        ).thenAnswer((_) async => 'op-bulk');
        when(
          () => syncRepository.sync(tenantId: any(named: 'tenantId')),
        ).thenAnswer((_) async => SyncOutcome.success());
      },
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        memberInvitations: [_invitation],
      ),
      act: (bloc) => bloc.add(
        const UserManagementEvent.resendAllPendingRequested(
          customEmailSubject: 'Connecte-toi',
          customEmailBody: 'Merci de finaliser.',
        ),
      ),
      verify: (_) {
        verify(
          () => memberInvitationRepo.resend(
            organizationId: _testOrgId,
            invitationId: _invitation.invitationId,
            customEmailSubject: 'Connecte-toi',
            customEmailBody: 'Merci de finaliser.',
          ),
        ).called(1);
      },
      expect: () => [
        isA<UserManagementLoaded>()
            .having((s) => s.resendingAllPending, 'resendingAllPending', true)
            .having(
              (s) => s.resendingInvitationIds,
              'resendingInvitationIds',
              contains(_invitation.invitationId),
            ),
        isA<UserManagementLoaded>()
            .having((s) => s.resendingAllPending, 'resendingAllPending', false)
            .having((s) => s.feedbackIsError, 'feedbackIsError', false)
            .having(
              (s) => s.feedbackMessage,
              'feedbackMessage',
              'Invitations relancées (1).',
            ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'deleteInvitationRequested marks invitation as deleting then shows success feedback',
      setUp: () {
        when(
          () => memberInvitationRepo.delete(
            organizationId: any(named: 'organizationId'),
            invitationId: any(named: 'invitationId'),
          ),
        ).thenAnswer((_) async => 'op-del');
        when(
          () => syncRepository.sync(tenantId: any(named: 'tenantId')),
        ).thenAnswer((_) async => const SyncOutcome.success());
      },
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        memberInvitations: [_invitation],
      ),
      act: (bloc) =>
          bloc.add(UserManagementEvent.deleteInvitationRequested(_invitation)),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.deletingInvitationIds,
          'deletingInvitationIds',
          contains(_invitation.invitationId),
        ),
        isA<UserManagementLoaded>()
            .having(
              (s) => s.deletingInvitationIds,
              'deletingInvitationIds',
              isNot(contains(_invitation.invitationId)),
            )
            .having(
              (s) => s.feedbackMessage,
              'feedbackMessage',
              'Invitation supprimée.',
            )
            .having((s) => s.feedbackIsError, 'feedbackIsError', false),
      ],
      verify: (_) => verify(
        () => memberInvitationRepo.delete(
          organizationId: _testOrgId,
          invitationId: _invitation.invitationId,
        ),
      ).called(1),
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'deleteInvitationRequested shows error feedback on sync failure',
      setUp: () {
        when(
          () => memberInvitationRepo.delete(
            organizationId: any(named: 'organizationId'),
            invitationId: any(named: 'invitationId'),
          ),
        ).thenAnswer((_) async => 'op-del');
        when(
          () => syncRepository.sync(tenantId: any(named: 'tenantId')),
        ).thenAnswer((_) async => const SyncOutcome.failure('network error'));
      },
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        memberInvitations: [_invitation],
      ),
      act: (bloc) =>
          bloc.add(UserManagementEvent.deleteInvitationRequested(_invitation)),
      expect: () => [
        isA<UserManagementLoaded>().having(
          (s) => s.deletingInvitationIds,
          'deletingInvitationIds',
          contains(_invitation.invitationId),
        ),
        isA<UserManagementLoaded>()
            .having(
              (s) => s.deletingInvitationIds,
              'deletingInvitationIds',
              isNot(contains(_invitation.invitationId)),
            )
            .having(
              (s) => s.feedbackMessage,
              'feedbackMessage',
              'La suppression a échoué. Veuillez réessayer.',
            )
            .having((s) => s.feedbackIsError, 'feedbackIsError', true),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'dismissInviteForm clears showingInviteForm',
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        showingInviteForm: true,
        inviteError: 'Some error',
      ),
      act: (bloc) => bloc.add(const UserManagementEvent.dismissInviteForm()),
      expect: () => [
        isA<UserManagementLoaded>()
            .having((s) => s.showingInviteForm, 'showingInviteForm', false)
            .having((s) => s.inviteError, 'inviteError', null),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'submitInvitation called twice rapidly only calls create once (race condition fix)',
      setUp: () {
        when(
          () => memberInvitationRepo.create(
            organizationId: _testOrgId,
            email: 'bob@example.com',
            firstName: 'Bob',
            lastName: 'Dupont',
            roles: any(named: 'roles'),
          ),
        ).thenAnswer((_) async => 'client-op-1');
        when(
          () => syncRepository.sync(tenantId: _testOrgId),
        ).thenAnswer((_) async => const SyncOutcome.success());
      },
      build: buildBloc,
      seed: () => UserManagementState.loaded(
        members: _members,
        inviteFirstName: 'Bob',
        inviteLastName: 'Dupont',
        inviteEmail: 'bob@example.com',
        inviteRoles: const {Role.volunteer, Role.coordinator, Role.admin},
      ),
      act: (bloc) async {
        bloc.add(const UserManagementEvent.submitInvitation());
        bloc.add(const UserManagementEvent.submitInvitation());
        await Future.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        isA<UserManagementLoaded>().having((s) => s.inviting, 'inviting', true),
        isA<UserManagementLoaded>()
            .having((s) => s.inviting, 'inviting', false)
            .having((s) => s.inviteSuccess, 'inviteSuccess', true),
      ],
      verify: (_) {
        verify(
          () => memberInvitationRepo.create(
            organizationId: _testOrgId,
            email: 'bob@example.com',
            firstName: 'Bob',
            lastName: 'Dupont',
            roles: const {Role.volunteer, Role.coordinator, Role.admin},
          ),
        ).called(1);
      },
    );
  });
}
