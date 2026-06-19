import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/presentation/admin/members/user_management_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockMemberInvitationRepository extends Mock
    implements MemberInvitationRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

_MockSyncBloc _makeSyncBloc() {
  final bloc = _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

const _orgId = 'org-1';

final _invitation1 = MemberInvitation(
  invitationId: 'inv-1',
  organizationId: _orgId,
  email: 'alice@example.com',
  firstName: 'Alice',
  lastName: 'Martin',
  roles: const {Role.volunteer},
  status: InvitationStatus.pendingActivation,
  createdAt: '2026-01-02T00:00:00Z',
  expiresAt: '2026-01-09T00:00:00Z',
);

final _invitation2 = MemberInvitation(
  invitationId: 'inv-2',
  organizationId: _orgId,
  email: 'bob@example.com',
  firstName: 'Bob',
  lastName: 'Dupont',
  roles: const {Role.admin},
  status: InvitationStatus.pendingActivation,
  createdAt: '2026-01-01T00:00:00Z',
  expiresAt: '2026-01-08T00:00:00Z',
);

final _producerInvitation = MemberInvitation(
  invitationId: 'inv-prod',
  organizationId: _orgId,
  email: 'producer@example.com',
  firstName: 'Pierre',
  lastName: 'Producteur',
  roles: const {Role.producer},
  status: InvitationStatus.pendingActivation,
  createdAt: '2026-01-03T00:00:00Z',
  expiresAt: '2026-01-10T00:00:00Z',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockMemberRepository memberRepo,
  required _MockMemberInvitationRepository invitationRepo,
  _MockSyncRepository? syncRepo,
  _MockAppDatabase? database,
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<MemberInvitationRepository>.value(
          value: invitationRepo,
        ),
        RepositoryProvider<SyncRepository>.value(
          value: syncRepo ?? _MockSyncRepository(),
        ),
        RepositoryProvider<AppDatabase>.value(
          value: database ?? _MockAppDatabase(),
        ),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: _makeSyncBloc(),
        child: const MaterialApp(
          home: UserManagementScreen(
            organizationId: _orgId,
            canEditAdminRole: true,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late _MockMemberRepository memberRepo;
  late _MockMemberInvitationRepository invitationRepo;

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    memberRepo = _MockMemberRepository();
    invitationRepo = _MockMemberInvitationRepository();
    when(
      () => memberRepo.watch(_orgId),
    ).thenAnswer((_) => Stream.value(const []));
  });

  group('UserManagementScreen — producer visibility', () {
    testWidgets('producer-role members are hidden from admin view', (
      tester,
    ) async {
      when(() => memberRepo.watch(_orgId)).thenAnswer(
        (_) => Stream.value([
          Member(
            memberId: 'volunteer-1',
            organizationId: _orgId,
            firstName: 'Alice',
            lastName: 'Dupont',
            roles: const {Role.volunteer},
          ),
          Member(
            memberId: 'producer-1',
            organizationId: _orgId,
            firstName: 'Bob',
            lastName: 'Martin',
            roles: const {Role.producer},
          ),
        ]),
      );
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      expect(find.text('Alice Dupont'), findsOneWidget);
      expect(
        find.text('Bob Martin'),
        findsNothing,
        reason:
            'producer users are managed via /admin/producers, '
            'admin should not see them in user management',
      );
    });

    testWidgets('producer-role invitations are hidden from admin view', (
      tester,
    ) async {
      when(
        () => memberRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([_invitation1, _producerInvitation]));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      expect(find.text('alice@example.com'), findsOneWidget);
      expect(
        find.text('producer@example.com'),
        findsNothing,
        reason:
            'producer invitations should not appear in admin user management',
      );
    });
  });

  group('UserManagementScreen — invitations list', () {
    testWidgets(
      'GIVEN an activated invitation WHEN default filter THEN it is hidden',
      (tester) async {
        final activatedInvitation = _invitation1.copyWith(
          status: InvitationStatus.activated,
        );
        when(
          () => invitationRepo.watch(_orgId),
        ).thenAnswer((_) => Stream.value([activatedInvitation, _invitation2]));

        await _pumpScreen(
          tester,
          memberRepo: memberRepo,
          invitationRepo: invitationRepo,
        );
        await tester.pump();

        expect(
          find.text('alice@example.com'),
          findsNothing,
          reason:
              'activated invitations should not appear in the active filter — '
              'the member already has an account and shows in the members list',
        );
        expect(find.text('bob@example.com'), findsOneWidget);
      },
    );

    testWidgets(
      'renders invitations without throwing when no search/filter applied '
      '(regression for UnsupportedError: Cannot modify an unmodifiable list)',
      (tester) async {
        // Two invitations, no search or role filter → _filteredInvitations
        // used to call .sort() directly on the Freezed unmodifiable list.
        when(
          () => invitationRepo.watch(_orgId),
        ).thenAnswer((_) => Stream.value([_invitation1, _invitation2]));

        await _pumpScreen(
          tester,
          memberRepo: memberRepo,
          invitationRepo: invitationRepo,
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('alice@example.com'), findsOneWidget);
        expect(find.text('bob@example.com'), findsOneWidget);
      },
    );

    testWidgets(
      'invitation tile shows sent date from createdAt when never resent',
      (tester) async {
        when(
          () => invitationRepo.watch(_orgId),
        ).thenAnswer((_) => Stream.value([_invitation1]));

        await _pumpScreen(
          tester,
          memberRepo: memberRepo,
          invitationRepo: invitationRepo,
        );
        await tester.pump();

        expect(
          find.textContaining('Envoyée le'),
          findsOneWidget,
          reason: 'invitation tile should show when the invitation was sent',
        );
      },
    );

    testWidgets(
      'invitation tile shows relance date when resendRequestedAt is set',
      (tester) async {
        final invitationWithResend = _invitation1.copyWith(
          resendRequestedAt: '2026-02-15T10:00:00Z',
        );
        when(
          () => invitationRepo.watch(_orgId),
        ).thenAnswer((_) => Stream.value([invitationWithResend]));

        await _pumpScreen(
          tester,
          memberRepo: memberRepo,
          invitationRepo: invitationRepo,
        );
        await tester.pump();

        expect(
          find.textContaining('Dernière relance le'),
          findsOneWidget,
          reason:
              'invitation tile should show when the last resend was triggered',
        );
      },
    );

    testWidgets('invitations are sorted newest-first (no filter)', (
      tester,
    ) async {
      // inv1 createdAt 2026-01-02, inv2 createdAt 2026-01-01 → inv1 first.
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([_invitation2, _invitation1]));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      final alice = tester.getTopLeft(find.text('alice@example.com'));
      final bob = tester.getTopLeft(find.text('bob@example.com'));
      expect(
        alice.dy,
        lessThan(bob.dy),
        reason:
            'newest invitation (alice, Jan 2) should appear above bob (Jan 1)',
      );
    });
  });

  group('UserManagementScreen — member/invitation de-duplication', () {
    testWidgets(
      'GIVEN a member and a pending invitation sharing an email '
      'WHEN default filter THEN the person appears once (invitation row only)',
      (tester) async {
        // Reproduces the import duplicate: import creates both a Member (PII)
        // and an auto PENDING_ACTIVATION invitation for the same email.
        when(() => memberRepo.watch(_orgId)).thenAnswer(
          (_) => Stream.value([
            Member(
              memberId: 'alice-member',
              organizationId: _orgId,
              firstName: 'Alice',
              lastName: 'Martin',
              email: 'Alice@Example.com', // different casing on purpose
              roles: const {Role.volunteer},
            ),
          ]),
        );
        when(
          () => invitationRepo.watch(_orgId),
        ).thenAnswer((_) => Stream.value([_invitation1]));

        await _pumpScreen(
          tester,
          memberRepo: memberRepo,
          invitationRepo: invitationRepo,
        );
        await tester.pump();

        expect(
          find.text('alice@example.com'),
          findsOneWidget,
          reason:
              'the person must appear exactly once, not duplicated as both a '
              'member tile and a pending-invitation tile',
        );
        // The pending-invitation representation is kept (offers resend), the
        // duplicate member row is suppressed while the invitation is pending.
        expect(find.text('Relancer'), findsOneWidget);
        expect(find.byTooltip('Modifier les rôles'), findsNothing);
      },
    );

    testWidgets(
      'GIVEN a member with no matching pending invitation '
      'THEN the member row is still shown',
      (tester) async {
        when(() => memberRepo.watch(_orgId)).thenAnswer(
          (_) => Stream.value([
            Member(
              memberId: 'carol-member',
              organizationId: _orgId,
              firstName: 'Carol',
              lastName: 'Durand',
              email: 'carol@example.com',
              roles: const {Role.volunteer},
            ),
          ]),
        );
        when(
          () => invitationRepo.watch(_orgId),
        ).thenAnswer((_) => Stream.value([_invitation1]));

        await _pumpScreen(
          tester,
          memberRepo: memberRepo,
          invitationRepo: invitationRepo,
        );
        await tester.pump();

        expect(find.text('Carol Durand'), findsOneWidget);
        expect(find.byTooltip('Modifier les rôles'), findsOneWidget);
      },
    );
  });

  group('UserManagementScreen — members list & role editing', () {
    final member = Member(
      memberId: 'claire-1',
      organizationId: _orgId,
      firstName: 'Claire',
      lastName: 'Bernard',
      roles: const {Role.volunteer, Role.coordinator},
    );

    testWidgets('renders an active member with a "modifier les rôles" action', (
      tester,
    ) async {
      when(
        () => memberRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([member]));
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      expect(find.text('Claire Bernard'), findsOneWidget);
      expect(find.byTooltip('Modifier les rôles'), findsOneWidget);
    });

    testWidgets('tapping the action opens the edit-roles dialog', (
      tester,
    ) async {
      when(
        () => memberRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([member]));
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Modifier les rôles'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AlertDialog, 'Modifier les rôles'),
        findsOneWidget,
      );
      // One checkbox per assignable role (Amapien / Coordinateur / Admin).
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
    });

    testWidgets('the search field filters out non-matching members', (
      tester,
    ) async {
      when(() => memberRepo.watch(_orgId)).thenAnswer(
        (_) => Stream.value([
          member,
          Member(
            memberId: 'david-2',
            organizationId: _orgId,
            firstName: 'David',
            lastName: 'Petit',
            roles: const {Role.volunteer},
          ),
        ]),
      );
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      expect(find.text('Claire Bernard'), findsOneWidget);
      expect(find.text('David Petit'), findsOneWidget);

      // The screen filters members by memberId substring.
      await tester.enterText(find.byType(TextField), 'claire');
      await tester.pumpAndSettle();

      expect(find.text('Claire Bernard'), findsOneWidget);
      expect(find.text('David Petit'), findsNothing);
    });

    testWidgets('the Admin role filter hides non-admin members', (
      tester,
    ) async {
      when(() => memberRepo.watch(_orgId)).thenAnswer(
        (_) => Stream.value([
          Member(
            memberId: 'admin-1',
            organizationId: _orgId,
            firstName: 'Adèle',
            lastName: 'Admin',
            roles: const {Role.admin},
          ),
          Member(
            memberId: 'vol-1',
            organizationId: _orgId,
            firstName: 'Victor',
            lastName: 'Volontaire',
            roles: const {Role.volunteer},
          ),
        ]),
      );
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilterChip, 'Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Adèle Admin'), findsOneWidget);
      expect(find.text('Victor Volontaire'), findsNothing);
    });
  });

  group('UserManagementScreen — invitation actions', () {
    testWidgets('resending a pending invitation calls the repository + sync', (
      tester,
    ) async {
      final syncRepo = _MockSyncRepository();
      when(
        () => syncRepo.sync(tenantId: any(named: 'tenantId')),
      ).thenAnswer((_) async => const SyncOutcome.success());
      when(
        () => invitationRepo.resend(
          organizationId: any(named: 'organizationId'),
          invitationId: any(named: 'invitationId'),
          customEmailSubject: any(named: 'customEmailSubject'),
          customEmailBody: any(named: 'customEmailBody'),
        ),
      ).thenAnswer((_) async => 'op-resend');
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([_invitation1]));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
        syncRepo: syncRepo,
      );
      await tester.pump();

      await tester.tap(find.text('Relancer'));
      await tester.pumpAndSettle();

      verify(
        () => invitationRepo.resend(
          organizationId: _orgId,
          invitationId: 'inv-1',
          customEmailSubject: any(named: 'customEmailSubject'),
          customEmailBody: any(named: 'customEmailBody'),
        ),
      ).called(1);
      verify(() => syncRepo.sync(tenantId: _orgId)).called(1);
    });

    testWidgets('deleting a pending invitation calls the repository + sync', (
      tester,
    ) async {
      final syncRepo = _MockSyncRepository();
      when(
        () => syncRepo.sync(tenantId: any(named: 'tenantId')),
      ).thenAnswer((_) async => const SyncOutcome.success());
      when(
        () => invitationRepo.delete(
          organizationId: any(named: 'organizationId'),
          invitationId: any(named: 'invitationId'),
        ),
      ).thenAnswer((_) async => 'op-delete');
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([_invitation1]));

      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
        syncRepo: syncRepo,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Supprimer l\'invitation'));
      await tester.pumpAndSettle();

      verify(
        () => invitationRepo.delete(
          organizationId: _orgId,
          invitationId: 'inv-1',
        ),
      ).called(1);
      verify(() => syncRepo.sync(tenantId: _orgId)).called(1);
    });
  });
}
