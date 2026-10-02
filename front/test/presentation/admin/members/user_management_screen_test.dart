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

const _invitation1 = MemberInvitation(
  invitationId: 'inv-1',
  organizationId: _orgId,
  email: 'alice@example.com',
  firstName: 'Alice',
  lastName: 'Martin',
  roles: {Role.volunteer},
  status: InvitationStatus.pendingActivation,
  createdAt: '2026-01-02T00:00:00Z',
  expiresAt: '2026-01-09T00:00:00Z',
);

const _invitation2 = MemberInvitation(
  invitationId: 'inv-2',
  organizationId: _orgId,
  email: 'bob@example.com',
  firstName: 'Bob',
  lastName: 'Dupont',
  roles: {Role.admin},
  status: InvitationStatus.pendingActivation,
  createdAt: '2026-01-01T00:00:00Z',
  expiresAt: '2026-01-08T00:00:00Z',
);

const _producerInvitation = MemberInvitation(
  invitationId: 'inv-prod',
  organizationId: _orgId,
  email: 'producer@example.com',
  firstName: 'Pierre',
  lastName: 'Producteur',
  roles: {Role.producer},
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
  String currentMemberId = 'caller-admin',
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
        child: MaterialApp(
          home: UserManagementScreen(
            organizationId: _orgId,
            canEditAdminRole: true,
            currentMemberId: currentMemberId,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(FilterChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
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
          const Member(
            memberId: 'volunteer-1',
            organizationId: _orgId,
            firstName: 'Alice',
            lastName: 'Dupont',
            roles: {Role.volunteer},
          ),
          const Member(
            memberId: 'producer-1',
            organizationId: _orgId,
            firstName: 'Bob',
            lastName: 'Martin',
            roles: {Role.producer},
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
      'invitation tile shows the creation date when never resent, without '
      'claiming an email was sent (imported invitations are not emailed)',
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
          find.textContaining('Invitation créée le'),
          findsOneWidget,
          reason: 'invitation tile should show when the invitation was created',
        );
        expect(find.textContaining('Envoyée le'), findsNothing);
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
            const Member(
              memberId: 'alice-member',
              organizationId: _orgId,
              firstName: 'Alice',
              lastName: 'Martin',
              email: 'Alice@Example.com', // different casing on purpose
              roles: {Role.volunteer},
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
        // Same status label as the owner user list.
        expect(find.text('Invité'), findsOneWidget);
        expect(find.byTooltip('Modifier les rôles'), findsNothing);
      },
    );

    testWidgets('GIVEN a member with no matching pending invitation '
        'THEN the member row is still shown', (tester) async {
      when(() => memberRepo.watch(_orgId)).thenAnswer(
        (_) => Stream.value([
          const Member(
            memberId: 'carol-member',
            organizationId: _orgId,
            firstName: 'Carol',
            lastName: 'Durand',
            email: 'carol@example.com',
            roles: {Role.volunteer},
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
    });
  });

  group('UserManagementScreen — members list & role editing', () {
    const member = Member(
      memberId: 'claire-1',
      organizationId: _orgId,
      firstName: 'Claire',
      lastName: 'Bernard',
      roles: {Role.volunteer, Role.coordinator},
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

    testWidgets('an empty invitation marks each missing field', (tester) async {
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

      // The shell hosts the FAB outside the test surface: trigger it.
      tester
          .widget<FloatingActionButton>(
            find.byKey(const Key('invite_member_fab')),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      // Screen readers announce the dialog by its title, not the generic
      // "Alerte" Flutter falls back to outside iOS.
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).semanticLabel,
        'Inviter un membre',
      );
      // No error before a submit attempt.
      expect(find.text('Ce champ est requis.'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Inviter'));
      await tester.pumpAndSettle();

      // First name, last name and email, plus the roles.
      expect(find.text('Ce champ est requis.'), findsNWidgets(3));
      expect(find.text('Choisissez au moins un rôle.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Prénom *'),
        'Alice',
      );
      await tester.pumpAndSettle();
      expect(find.text('Ce champ est requis.'), findsNWidgets(2));
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
          const Member(
            memberId: 'david-2',
            organizationId: _orgId,
            firstName: 'David',
            lastName: 'Petit',
            roles: {Role.volunteer},
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
          const Member(
            memberId: 'admin-1',
            organizationId: _orgId,
            firstName: 'Adèle',
            lastName: 'Admin',
            roles: {Role.admin},
          ),
          const Member(
            memberId: 'vol-1',
            organizationId: _orgId,
            firstName: 'Victor',
            lastName: 'Volontaire',
            roles: {Role.volunteer},
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

  group('UserManagementScreen — former users filter', () {
    const activeMember = Member(
      memberId: 'active-1',
      organizationId: _orgId,
      firstName: 'Anna',
      lastName: 'Active',
      roles: {Role.volunteer},
    );
    const suspendedMember = Member(
      memberId: 'suspended-1',
      organizationId: _orgId,
      firstName: 'Sam',
      lastName: 'Suspendu',
      roles: {Role.volunteer},
      accountStatus: MemberAccountStatus.suspended,
    );

    Future<void> pumpWithMembersAndInvitation(WidgetTester tester) async {
      when(
        () => memberRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([activeMember, suspendedMember]));
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const [_invitation1]));
      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();
    }

    testWidgets('GIVEN active, suspended members and a pending invitation '
        'WHEN "Anciens utilisateurs" is selected '
        'THEN only the suspended member is listed', (tester) async {
      await pumpWithMembersAndInvitation(tester);

      expect(find.text('Anna Active'), findsOneWidget);
      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('Sam Suspendu'), findsNothing);

      await tapChip(tester, 'Anciens utilisateurs');
      await tester.pumpAndSettle();

      expect(find.text('Sam Suspendu'), findsOneWidget);
      expect(find.text('Anna Active'), findsNothing);
      expect(find.text('Alice Martin'), findsNothing);
      expect(
        find.textContaining('ne se sont pas encore connectés'),
        findsNothing,
      );
      final allChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Tous'),
      );
      expect(allChip.selected, isFalse);
    });

    testWidgets('GIVEN "Anciens utilisateurs" selected '
        'WHEN "Tous" is tapped '
        'THEN active members and pending invitations are listed again', (
      tester,
    ) async {
      await pumpWithMembersAndInvitation(tester);
      await tapChip(tester, 'Anciens utilisateurs');
      await tester.pumpAndSettle();

      await tapChip(tester, 'Tous');
      await tester.pumpAndSettle();

      expect(find.text('Anna Active'), findsOneWidget);
      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('Sam Suspendu'), findsNothing);
    });

    testWidgets('GIVEN "Anciens utilisateurs" selected '
        'WHEN "Invitations passées" is tapped '
        'THEN "Anciens utilisateurs" is deselected', (tester) async {
      await pumpWithMembersAndInvitation(tester);
      await tapChip(tester, 'Anciens utilisateurs');
      await tester.pumpAndSettle();

      await tapChip(tester, 'Invitations passées');
      await tester.pumpAndSettle();

      final formerChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Anciens utilisateurs'),
      );
      expect(formerChip.selected, isFalse);
      expect(find.text('Sam Suspendu'), findsNothing);
    });
  });

  group('UserManagementScreen — search highlighting', () {
    List<TextSpan> highlightedSpans(WidgetTester tester) =>
        tester.widgetList<RichText>(find.byType(RichText)).expand((rich) {
          final spans = <TextSpan>[];
          rich.text.visitChildren((span) {
            if (span is TextSpan &&
                span.text != null &&
                span.style?.backgroundColor != null) {
              spans.add(span);
            }
            return true;
          });
          return spans;
        }).toList();

    testWidgets('GIVEN a search query '
        'THEN the matching parts of names and emails are highlighted', (
      tester,
    ) async {
      when(() => memberRepo.watch(_orgId)).thenAnswer(
        (_) => Stream.value(const [
          Member(
            memberId: 'claire-1',
            organizationId: _orgId,
            firstName: 'Claire',
            lastName: 'Bernard',
            email: 'claire.bernard@example.com',
            roles: {Role.volunteer},
          ),
        ]),
      );
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const [_invitation1]));
      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      expect(highlightedSpans(tester), isEmpty);

      await tester.enterText(find.byType(TextField), 'BERN');
      await tester.pumpAndSettle();

      expect(
        highlightedSpans(tester).map((s) => s.text),
        containsAll(<String>['Bern', 'bern']),
      );
      expect(find.text('Claire Bernard'), findsOneWidget);
      expect(find.text('Alice Martin'), findsNothing);

      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pumpAndSettle();

      expect(
        highlightedSpans(tester).map((s) => s.text),
        containsAll(<String>['Alice', 'alice']),
      );
    });
  });

  group('UserManagementScreen — floating action button clearance', () {
    testWidgets('GIVEN a list scrolled to its end '
        'THEN the last member action is not covered by the add button', (
      tester,
    ) async {
      when(() => memberRepo.watch(_orgId)).thenAnswer(
        (_) => Stream.value([
          for (var i = 0; i < 30; i++)
            Member(
              memberId: 'm-$i',
              organizationId: _orgId,
              firstName: 'Membre',
              lastName: 'N$i',
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

      await tester.dragUntilVisible(
        find.text('Membre N29'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      final lastAction = find.descendant(
        of: find.ancestor(
          of: find.text('Membre N29'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Modifier les rôles'),
      );
      final actionRect = tester.getRect(lastAction);
      final fabRect = tester.getRect(find.byType(FloatingActionButton));
      expect(actionRect.overlaps(fabRect), isFalse);
    });
  });

  group('UserManagementScreen — member deletion', () {
    const self = Member(
      memberId: 'caller-admin',
      organizationId: _orgId,
      firstName: 'Moi',
      lastName: 'Admin',
      roles: {Role.admin},
    );
    const other = Member(
      memberId: 'other-1',
      organizationId: _orgId,
      firstName: 'Olga',
      lastName: 'Autre',
      roles: {Role.volunteer},
    );

    testWidgets('GIVEN the members list '
        'THEN every member but the caller offers a delete action', (
      tester,
    ) async {
      when(
        () => memberRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const [self, other]));
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));
      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      Finder deleteActionOf(String name) => find.descendant(
        of: find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
        matching: find.byTooltip('Supprimer le membre'),
      );
      expect(deleteActionOf('Olga Autre'), findsOneWidget);
      expect(deleteActionOf('Moi Admin'), findsNothing);
    });

    testWidgets('GIVEN a delete action '
        'WHEN the admin confirms '
        'THEN the member is deleted and synced', (tester) async {
      final syncRepo = _MockSyncRepository();
      when(
        () => syncRepo.sync(tenantId: any(named: 'tenantId')),
      ).thenAnswer((_) async => const SyncOutcome.success());
      when(
        () => memberRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const [self, other]));
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => memberRepo.delete(
          memberId: any(named: 'memberId'),
          organizationId: any(named: 'organizationId'),
        ),
      ).thenAnswer((_) async => 'op-del');
      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
        syncRepo: syncRepo,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Supprimer le membre'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer ce membre ?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'SUPPRIMER'));
      await tester.pumpAndSettle();

      verify(
        () => memberRepo.delete(memberId: 'other-1', organizationId: _orgId),
      ).called(1);
      verify(() => syncRepo.sync(tenantId: _orgId)).called(1);
    });

    testWidgets('GIVEN a delete action '
        'WHEN the admin cancels '
        'THEN nothing is deleted', (tester) async {
      when(
        () => memberRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const [self, other]));
      when(
        () => invitationRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value(const []));
      await _pumpScreen(
        tester,
        memberRepo: memberRepo,
        invitationRepo: invitationRepo,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Supprimer le membre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      verifyNever(
        () => memberRepo.delete(
          memberId: any(named: 'memberId'),
          organizationId: any(named: 'organizationId'),
        ),
      );
    });
  });
}
