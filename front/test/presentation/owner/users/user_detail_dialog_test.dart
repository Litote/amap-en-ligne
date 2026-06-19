import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/common/error_feedback.dart';
import 'package:amap_en_ligne/presentation/owner/users/dialogs/user_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_auth_bloc.dart';

class _MockOwnerRepository extends Mock implements OwnerRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

class _FakeMember extends Fake implements Member {}

Owner _owner({
  String id = 'o-1',
  String first = 'Alice',
  String last = 'Martin',
}) => Owner(
  ownerId: id,
  firstName: first,
  lastName: last,
  email: 'alice@exemple.fr',
  accountStatus: AccountStatus.active,
  registeredAt: '2025-01-03T00:00:00Z',
  updatedAt: '2025-01-03T00:00:00Z',
);

Member _member({
  String id = 'm-1',
  String orgId = 'org-1',
  Set<Role> roles = const {Role.admin},
  String? firstName,
  String? lastName,
  String? email,
  String? phone,
  MemberAccountStatus? accountStatus,
}) => Member(
  memberId: id,
  organizationId: orgId,
  roles: roles,
  firstName: firstName,
  lastName: lastName,
  email: email,
  phone: phone,
  accountStatus: accountStatus,
);

/// Pumps the [showUserDetailDialog] inside a MaterialApp with the required
/// repo providers and a mocked [AuthBloc].
Future<void> _pump(
  WidgetTester tester, {
  required String userId,
  required _MockOwnerRepository ownerRepo,
  required _MockMemberRepository memberRepo,
  required _MockOrganizationRepository orgRepo,
  required _MockProducerAccountRepository producerRepo,
  String? callerProducerAccountId,
  bool isAdmin = false,
}) async {
  final authBloc = MockAuthBloc();
  when(() => authBloc.state).thenReturn(
    AuthViewState(producerId: callerProducerAccountId, isAdmin: isAdmin),
  );
  when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());

  final syncRepo = _MockSyncRepository();
  when(
    () => syncRepo.sync(tenantId: any(named: 'tenantId')),
  ).thenAnswer((_) async => const SyncOutcome.success());

  // We pump a host screen that immediately opens the dialog via
  // showUserDetailDialog so we can exercise the dialog widget tree.
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OwnerRepository>.value(value: ownerRepo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<ProducerAccountRepository>.value(
          value: producerRepo,
        ),
        RepositoryProvider<SyncRepository>.value(value: syncRepo),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              // Open the dialog after the first frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showUserDetailDialog(context, userId);
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      ),
    ),
  );
  // First pump triggers addPostFrameCallback.
  await tester.pump();
  // Second pump opens the dialog and starts the bloc.
  await tester.pump();
  // Third pump lets the stream(s) emit initial data.
  await tester.pump();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMember());
    registerFallbackValue(<Role>{});
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
    when(() => orgRepo.watchAll()).thenAnswer((_) => Stream.value([]));
    when(() => producerRepo.watchAll()).thenAnswer((_) => Stream.value([]));
  });

  group('UserDetailDialog — AMAP variant', () {
    setUp(() {
      when(() => ownerRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => memberRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          _member(
            id: 'm-1',
            firstName: 'Alice',
            lastName: 'Martin',
            email: 'alice@exemple.fr',
            phone: '06 01 02 03 04',
          ),
        ]),
      );
      when(
        () => memberRepo.updateProfile(
          memberId: any(named: 'memberId'),
          organizationId: any(named: 'organizationId'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => 'profile-op');
      when(
        () => memberRepo.setRoles(any(), any<Member>(), any()),
      ).thenAnswer((_) async {});
      when(
        () => memberRepo.suspend(
          memberId: any(named: 'memberId'),
          organizationId: any(named: 'organizationId'),
        ),
      ).thenAnswer((_) async => 'status-op');
    });

    testWidgets('renders COMPTE block', (tester) async {
      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text('COMPTE'), findsOneWidget);
    });

    testWidgets('renders AMAP block with [Modifier] per row', (tester) async {
      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text('AMAP'), findsOneWidget);
      expect(find.byKey(const Key('modify_membership_org-1')), findsOneWidget);
    });

    testWidgets('modify dialog exposes profile fields and gated admin role', (
      tester,
    ) async {
      when(() => memberRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          _member(
            id: 'm-1',
            firstName: 'Alice',
            lastName: 'Martin',
            email: 'alice@exemple.fr',
            phone: '06 01 02 03 04',
            accountStatus: MemberAccountStatus.active,
          ),
        ]),
      );

      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
        isAdmin: false,
      );

      await tester.tap(find.byKey(const Key('modify_membership_org-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('first_name_field')), findsOneWidget);
      expect(find.byKey(const Key('last_name_field')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
      expect(find.byKey(const Key('status_dropdown')), findsOneWidget);
      // Active member shows "Actif" in the status dropdown.
      expect(find.text('Actif'), findsAtLeastNWidgets(1));
      final adminCheckbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('admin_checkbox')),
      );
      expect(adminCheckbox.onChanged, isNull);
    });

    testWidgets('saving edit updates profile and roles', (tester) async {
      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
        isAdmin: true,
      );

      await tester.tap(find.byKey(const Key('modify_membership_org-1')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('first_name_field')),
        'Alicia',
      );
      await tester.ensureVisible(find.byKey(const Key('coordinator_checkbox')));
      await tester.tap(find.byKey(const Key('coordinator_checkbox')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pumpAndSettle();

      verify(
        () => memberRepo.updateProfile(
          memberId: 'm-1',
          organizationId: 'org-1',
          firstName: 'Alicia',
          lastName: 'Martin',
          email: 'alice@exemple.fr',
          phone: '06 01 02 03 04',
        ),
      ).called(1);
      verify(
        () => memberRepo.setRoles('org-1', any<Member>(), {
          Role.admin,
          Role.coordinator,
        }),
      ).called(1);
    });

    testWidgets('does NOT render RÔLE PLATEFORME / PRODUCTEUR blocks', (
      tester,
    ) async {
      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text('RÔLE PLATEFORME'), findsNothing);
      expect(find.text("Administrateur d'instance"), findsNothing);
      expect(find.text('PRODUCTEUR'), findsNothing);
      expect(find.text('RATTACHEMENT PRODUCTEUR'), findsNothing);
    });

    testWidgets('does NOT render removed action buttons', (tester) async {
      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text('PROMOUVOIR EN OWNER'), findsNothing);
      expect(find.text('+ Ajouter'), findsNothing);
      expect(find.text('RETIRER LE RÔLE PRODUCTEUR'), findsNothing);
    });

    testWidgets('renders Zone sensible + SUSPENDRE + SUPPRIMER enabled', (
      tester,
    ) async {
      // Caller is a different sub than the AMAP member's sub, so the
      // self-action guard does not fire and both actions stay enabled.
      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
        callerProducerAccountId: 'sub-other',
      );

      expect(find.text('Zone sensible'), findsOneWidget);
      final suspend = tester.widget<OutlinedButton>(
        find.byKey(const Key('suspend_button')),
      );
      expect(suspend.onPressed, isNotNull);
      final delete = tester.widget<OutlinedButton>(
        find.byKey(const Key('delete_button')),
      );
      expect(delete.onPressed, isNotNull);
    });

    testWidgets(
      'a failing suspend shows the generic error snackbar, never the raw exception',
      (tester) async {
        when(
          () => memberRepo.suspend(
            memberId: any(named: 'memberId'),
            organizationId: any(named: 'organizationId'),
          ),
        ).thenThrow(Exception('boom'));
        await _pump(
          tester,
          userId: 'm-1',
          ownerRepo: ownerRepo,
          memberRepo: memberRepo,
          orgRepo: orgRepo,
          producerRepo: producerRepo,
          callerProducerAccountId: 'sub-other',
        );

        await tester.ensureVisible(find.byKey(const Key('suspend_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('suspend_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_suspend_button')));
        await tester.pump();
        await tester.pump();

        expect(find.text(kUnexpectedErrorMessage), findsOneWidget);
        expect(find.textContaining('boom'), findsNothing);

        // Let the snackbar auto-dismiss so no timer is left pending.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('dialog does NOT render a Retour à la liste back link', (
      tester,
    ) async {
      // The dialog is closed via the X button, not a back link.
      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text('Retour à la liste'), findsNothing);
    });

    testWidgets('dialog has a close button', (tester) async {
      await _pump(
        tester,
        userId: 'm-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('UserDetailDialog — Owner variant', () {
    setUp(() {
      when(
        () => ownerRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_owner(id: 'o-1')]));
      when(() => memberRepo.watchAll()).thenAnswer((_) => Stream.value([]));
    });

    testWidgets("renders Administrateur d'instance block (empty)", (
      tester,
    ) async {
      await _pump(
        tester,
        userId: 'o-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text("Administrateur d'instance"), findsOneWidget);
      // No AMAP or PRODUCTEUR block for Owner.
      expect(find.text('AMAP'), findsNothing);
      expect(find.text('PRODUCTEUR'), findsNothing);
    });

    testWidgets('does NOT render RÉVOQUER LE RÔLE OWNER button', (
      tester,
    ) async {
      await _pump(
        tester,
        userId: 'o-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text('RÉVOQUER LE RÔLE OWNER'), findsNothing);
      expect(find.byKey(const Key('revoke_owner_button')), findsNothing);
    });

    testWidgets('renders Zone sensible + SUSPENDRE + SUPPRIMER buttons', (
      tester,
    ) async {
      await _pump(
        tester,
        userId: 'o-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
      );

      expect(find.text('Zone sensible'), findsOneWidget);
      expect(find.byKey(const Key('suspend_button')), findsOneWidget);
      expect(find.byKey(const Key('delete_button')), findsOneWidget);
    });

    testWidgets('SUSPENDRE + SUPPRIMER buttons are enabled for another owner', (
      tester,
    ) async {
      await _pump(
        tester,
        userId: 'o-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
        callerProducerAccountId: 'sub-other',
      );

      final suspend = tester.widget<OutlinedButton>(
        find.byKey(const Key('suspend_button')),
      );
      expect(suspend.onPressed, isNotNull);
      final delete = tester.widget<OutlinedButton>(
        find.byKey(const Key('delete_button')),
      );
      expect(delete.onPressed, isNotNull);
    });

    testWidgets('SUSPENDRE + SUPPRIMER disabled when caller is the target', (
      tester,
    ) async {
      await _pump(
        tester,
        userId: 'o-1',
        ownerRepo: ownerRepo,
        memberRepo: memberRepo,
        orgRepo: orgRepo,
        producerRepo: producerRepo,
        callerProducerAccountId: 'o-1',
      );

      final suspend = tester.widget<OutlinedButton>(
        find.byKey(const Key('suspend_button')),
      );
      expect(suspend.onPressed, isNull);
      final delete = tester.widget<OutlinedButton>(
        find.byKey(const Key('delete_button')),
      );
      expect(delete.onPressed, isNull);
    });
  });
}
