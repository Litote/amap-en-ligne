import 'dart:async';

import 'package:amap_en_ligne/data/local/database_export_save.dart';
import 'package:amap_en_ligne/data/local/local_database_export_service.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_preferences.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/presentation/common/alert_templates_bloc.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_bloc.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOwnerRepository extends Mock implements OwnerRepository {}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _MockAlertTemplatesBloc
    extends MockBloc<AlertTemplatesEvent, AlertTemplatesState>
    implements AlertTemplatesBloc {}

class _MockLocalDatabaseExportService extends Mock
    implements LocalDatabaseExportService {}

class _FakeMemberPreferences extends Fake implements MemberPreferences {}

class _FakeUserPreferences extends Fake implements UserPreferences {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _kInstant = '2025-01-01T00:00:00.000Z';

const _memberPrefs = MemberPreferences(
  deliveryRemindersEnabled: true,
  volunteerAlertsEnabled: true,
  reminder24hEnabled: true,
  reminder2hEnabled: true,
  reminder30minEnabled: false,
  urgentNeedAlertsEnabled: true,
  incompleteSlotRemindersEnabled: false,
  planningChangesAlertsEnabled: true,
  lastUpdatedInstant: _kInstant,
);

const _userPrefs = UserPreferences(
  emailNotificationsEnabled: true,
  pushNotificationsEnabled: true,
  lastUpdatedInstant: _kInstant,
);

Member _member({
  String id = 'm-1',
  String orgId = 'org-1',
  MemberPreferences? memberPreferences = _memberPrefs,
  UserPreferences? userPreferences = _userPrefs,
}) => Member(
  memberId: id,
  organizationId: orgId,
  roles: const {Role.volunteer},
  memberPreferences: memberPreferences,
  userPreferences: userPreferences,
);

Owner _owner({
  String id = 'o-1',
  UserPreferences? userPreferences = _userPrefs,
}) => Owner(
  ownerId: id,
  firstName: 'Alice',
  lastName: 'Dupont',
  email: 'alice@example.com',
  registeredAt: _kInstant,
  updatedAt: _kInstant,
  userPreferences: userPreferences,
);

ProducerAccount _producer({
  String id = 'pa-1',
  UserPreferences? userPreferences = _userPrefs,
}) => ProducerAccount(
  producerAccountId: id,
  name: 'Ferme du Test',
  userPreferences: userPreferences,
);

// A minimal valid JWT with given_name, family_name, email claims.
// Payload (base64url): {"sub":"s-1","email":"alice@example.com",
//   "given_name":"Alice","family_name":"Dupont"}
const _kFakeAccessToken =
    'eyJhbGciOiJIUzI1NiJ9'
    '.eyJzdWIiOiJzLTEiLCJlbWFpbCI6ImFsaWNlQGV4YW1wbGUuY29tIiwiZ2l2ZW5fbmFtZSI6IkFsaWNlIiwiZmFtaWx5X25hbWUiOiJEdXBvbnQifQ'
    '.FAKE';

// ---------------------------------------------------------------------------
// Pump helpers
// ---------------------------------------------------------------------------

/// Pumps the [UserPreferencesScreen] widget tree inside a fresh [BlocProvider].
///
/// The bloc is created via [BlocProvider]'s `create` callback so it is
/// constructed inside the test framework's fake-async zone, which means
/// stream subscriptions are subject to the tester's clock and pumps.
///
/// Returns the created [UserPreferencesBloc] so tests can inspect its state.
Future<UserPreferencesBloc> _pump(
  WidgetTester tester, {
  required _MockMemberRepository memberRepo,
  required _MockAuthService authService,
  required _MockSyncBloc syncBloc,
  LocalDatabaseExportService? exportService,
}) async {
  late UserPreferencesBloc capturedBloc;
  await tester.pumpWidget(
    RepositoryProvider<AuthService>.value(
      value: authService,
      child: RepositoryProvider<LocalDatabaseExportService?>.value(
        value: exportService,
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: MaterialApp(
            home: BlocProvider<UserPreferencesBloc>(
              create: (_) {
                capturedBloc = UserPreferencesBloc(
                  source: MemberSource(
                    memberId: 's-1',
                    memberRepository: memberRepo,
                  ),
                );
                return capturedBloc;
              },
              child: const UserPreferencesScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  // Two pumps to drain the microtask queue:
  //   pump 1 → Stream.value listener fires, bloc.add() is called
  //   pump 2 → bloc handler emits new state, BlocBuilder rebuilds
  await tester.pump();
  await tester.pump();
  return capturedBloc;
}

/// Pumps the [UserPreferencesScreen] backed by [OwnerSource].
Future<UserPreferencesBloc> _pumpOwner(
  WidgetTester tester, {
  required _MockOwnerRepository ownerRepo,
  required _MockAuthService authService,
  required _MockSyncBloc syncBloc,
}) async {
  late UserPreferencesBloc capturedBloc;
  await tester.pumpWidget(
    RepositoryProvider<AuthService>.value(
      value: authService,
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: BlocProvider<UserPreferencesBloc>(
            create: (_) {
              capturedBloc = UserPreferencesBloc(
                source: OwnerSource(ownerId: 's-1', ownerRepository: ownerRepo),
              );
              return capturedBloc;
            },
            child: const UserPreferencesScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return capturedBloc;
}

/// Pumps the [UserPreferencesScreen] backed by [ProducerSource].
Future<UserPreferencesBloc> _pumpProducer(
  WidgetTester tester, {
  required _MockProducerAccountRepository producerRepo,
  required _MockAuthService authService,
  required _MockSyncBloc syncBloc,
}) async {
  late UserPreferencesBloc capturedBloc;
  await tester.pumpWidget(
    RepositoryProvider<AuthService>.value(
      value: authService,
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: BlocProvider<UserPreferencesBloc>(
            create: (_) {
              capturedBloc = UserPreferencesBloc(
                source: ProducerSource(
                  producerAccountId: 'pa-1',
                  producerAccountRepository: producerRepo,
                ),
              );
              return capturedBloc;
            },
            child: const UserPreferencesScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return capturedBloc;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMemberPreferences());
    registerFallbackValue(_FakeUserPreferences());
    registerFallbackValue(const SyncEvent.mutationApplied());
  });

  late _MockMemberRepository memberRepo;
  late _MockAuthService authService;
  late _MockSyncBloc syncBloc;
  late _MockLocalDatabaseExportService exportService;

  setUp(() {
    memberRepo = _MockMemberRepository();
    authService = _MockAuthService();
    syncBloc = _MockSyncBloc();
    exportService = _MockLocalDatabaseExportService();

    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());

    // Default: authenticated session with a minimal fake JWT.
    when(() => authService.currentState).thenReturn(
      const AuthState.authenticated(
        producerId: 'pa-1',
        accessToken: _kFakeAccessToken,
        roles: [],
      ),
    );

    // Default: repository emits a single member.
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(_member()));
    when(
      () => memberRepo.updatePreferences(
        memberId: any(named: 'memberId'),
        organizationId: any(named: 'organizationId'),
        memberPreferences: any(named: 'memberPreferences'),
        userPreferences: any(named: 'userPreferences'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => memberRepo.updateProfile(
        memberId: any(named: 'memberId'),
        organizationId: any(named: 'organizationId'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async => 'client-op-1');
    when(
      () =>
          exportService.exportCurrentUserDatabase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const DatabaseExportResult(
        filename: 'amap_en_ligne_s-1_data.zip',
        path: '/exports/amap_en_ligne_s-1_data.zip',
      ),
    );
  });

  // --------------------------------------------------------------------------
  // Loading state
  // --------------------------------------------------------------------------

  testWidgets('shows CircularProgressIndicator while loading', (tester) async {
    // Stream that never emits — bloc stays in loading.
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      RepositoryProvider<AuthService>.value(
        value: authService,
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: MaterialApp(
            home: BlocProvider<UserPreferencesBloc>(
              create: (_) => UserPreferencesBloc(
                source: MemberSource(
                  memberId: 's-1',
                  memberRepository: memberRepo,
                ),
              ),
              child: const UserPreferencesScreen(),
            ),
          ),
        ),
      ),
    );
    // Single pump — bloc stays in loading because the stream never emits.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('exports the local database from the preferences page', (
    tester,
  ) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
      exportService: exportService,
    );

    await tester.tap(find.byKey(const Key('export_local_database_button')));
    await tester.pump();

    verify(
      () => exportService.exportCurrentUserDatabase(userId: 'm-1'),
    ).called(1);
    expect(find.textContaining('Export ZIP enregistré'), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Missing state
  // --------------------------------------------------------------------------

  testWidgets('shows only profile card when member is null', (tester) async {
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(null));

    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    expect(find.text('Profil utilisateur'), findsOneWidget);
    expect(find.textContaining('Nom :'), findsOneWidget);
    expect(find.textContaining('Email :'), findsOneWidget);
    expect(find.textContaining('Téléphone :'), findsOneWidget);
  });

  testWidgets(
    'does not show notifications card or save button when member is null',
    (tester) async {
      when(
        () => memberRepo.watchMyMember(any()),
      ).thenAnswer((_) => Stream.value(null));

      await _pump(
        tester,
        memberRepo: memberRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.text('Notifications bénévolat'), findsNothing);
      expect(
        find.widgetWithText(FilledButton, 'ENREGISTRER LES MODIFICATIONS'),
        findsNothing,
      );
    },
  );

  // --------------------------------------------------------------------------
  // Profil utilisateur card
  // --------------------------------------------------------------------------

  testWidgets(
    'shows Profil utilisateur card with Nom / Email / Téléphone labels',
    (tester) async {
      await _pump(
        tester,
        memberRepo: memberRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.text('Profil utilisateur'), findsOneWidget);
      expect(find.textContaining('Nom :'), findsOneWidget);
      expect(find.textContaining('Email :'), findsOneWidget);
      expect(find.textContaining('Téléphone :'), findsOneWidget);
    },
  );

  testWidgets('MODIFIER MES INFORMATIONS button is enabled for member', (
    tester,
  ) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    final finder = find.widgetWithText(
      FilledButton,
      'MODIFIER MES INFORMATIONS',
    );
    expect(finder, findsOneWidget);
    expect(tester.widget<FilledButton>(finder).onPressed, isNotNull);
  });

  testWidgets('MODIFIER MES INFORMATIONS button has no tooltip for member', (
    tester,
  ) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    final tooltipFinder = find.ancestor(
      of: find.widgetWithText(FilledButton, 'MODIFIER MES INFORMATIONS'),
      matching: find.byType(Tooltip),
    );
    expect(tooltipFinder, findsNothing);
  });

  testWidgets(
    'tapping MODIFIER MES INFORMATIONS opens dialog with member fields',
    (tester) async {
      await _pump(
        tester,
        memberRepo: memberRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'MODIFIER MES INFORMATIONS'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modifier mes informations'), findsOneWidget);
      expect(find.text('Prénom'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Email'), findsAtLeastNWidgets(1));
      expect(find.text('Téléphone (optionnel)'), findsOneWidget);
    },
  );

  testWidgets('submitting member dialog dispatches profileSaved event', (
    tester,
  ) async {
    final bloc = await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    await tester.tap(
      find.widgetWithText(FilledButton, 'MODIFIER MES INFORMATIONS'),
    );
    await tester.pumpAndSettle();

    final firstNameField = find.widgetWithText(TextFormField, 'Alice');
    await tester.enterText(firstNameField, 'Alicia');

    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));

    verify(
      () => memberRepo.updateProfile(
        memberId: 'm-1',
        organizationId: 'org-1',
        firstName: 'Alicia',
        lastName: 'Dupont',
        email: 'alice@example.com',
        phone: null,
      ),
    ).called(1);

    expect(
      (bloc.state as UserPreferencesReady).profileSaveStatus,
      SaveStatus.success,
    );
  });

  // --------------------------------------------------------------------------
  // Notifications card
  // --------------------------------------------------------------------------

  testWidgets(
    'shows Notifications bénévolat card with three subsection headers',
    (tester) async {
      await _pump(
        tester,
        memberRepo: memberRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.text('Notifications bénévolat'), findsOneWidget);
      expect(find.textContaining("Rappels d'inscription"), findsOneWidget);
      expect(find.textContaining("Alertes d'urgence"), findsOneWidget);
      expect(find.textContaining('Canaux de notification'), findsOneWidget);
    },
  );

  testWidgets('shows 8 checkboxes for notifications', (tester) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    expect(find.byType(CheckboxListTile), findsNWidgets(8));
  });

  // --------------------------------------------------------------------------
  // Save button state
  // --------------------------------------------------------------------------

  testWidgets('save button is disabled when dirty=false', (tester) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    final saveFinder = find.widgetWithText(
      FilledButton,
      'ENREGISTRER LES MODIFICATIONS',
    );
    expect(tester.widget<FilledButton>(saveFinder).onPressed, isNull);
  });

  testWidgets('save button is enabled after a checkbox toggle', (tester) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    // Toggle the 30min reminder (starts unchecked).
    final checkbox = find.widgetWithText(
      CheckboxListTile,
      'Rappel 30min avant le créneau',
    );
    await tester.tap(checkbox);
    await tester.pump();

    final saveFinder = find.widgetWithText(
      FilledButton,
      'ENREGISTRER LES MODIFICATIONS',
    );
    expect(tester.widget<FilledButton>(saveFinder).onPressed, isNotNull);
  });

  // --------------------------------------------------------------------------
  // Snackbars
  // --------------------------------------------------------------------------

  testWidgets('success snackbar appears when save succeeds', (tester) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    // Toggle to make dirty — 30min is near the top of the notifications card.
    final checkbox = find.widgetWithText(
      CheckboxListTile,
      'Rappel 30min avant le créneau',
    );
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();

    // Scroll the save button into view before tapping.
    final saveFinder = find.widgetWithText(
      FilledButton,
      'ENREGISTRER LES MODIFICATIONS',
    );
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('enregistrées avec succès'), findsOneWidget);
  });

  testWidgets('failure snackbar appears when save throws', (tester) async {
    when(
      () => memberRepo.updatePreferences(
        memberId: any(named: 'memberId'),
        organizationId: any(named: 'organizationId'),
        memberPreferences: any(named: 'memberPreferences'),
        userPreferences: any(named: 'userPreferences'),
      ),
    ).thenThrow(Exception('network error'));

    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    final checkbox = find.widgetWithText(
      CheckboxListTile,
      'Rappel 30min avant le créneau',
    );
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();

    final saveFinder = find.widgetWithText(
      FilledButton,
      'ENREGISTRER LES MODIFICATIONS',
    );
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Checkbox → bloc event dispatch
  // --------------------------------------------------------------------------

  testWidgets('toggling reminder checkbox updates bloc state and sets dirty', (
    tester,
  ) async {
    final bloc = await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    final checkbox = find.widgetWithText(
      CheckboxListTile,
      'Rappel 30min avant le créneau',
    );
    await tester.tap(checkbox);
    await tester.pump();

    final state = bloc.state as UserPreferencesReady;
    expect(state.memberPreferences.reminder30minEnabled, isTrue);
    expect(state.dirty, isTrue);
  });

  testWidgets('toggling alert checkbox updates bloc state and sets dirty', (
    tester,
  ) async {
    final bloc = await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    final checkbox = find.widgetWithText(
      CheckboxListTile,
      'Rappels pour manque de volontaire(s) sur la livraison',
    );
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();

    final state = bloc.state as UserPreferencesReady;
    expect(state.memberPreferences.incompleteSlotRemindersEnabled, isTrue);
    expect(state.dirty, isTrue);
  });

  testWidgets('toggling channel checkbox updates bloc state and sets dirty', (
    tester,
  ) async {
    final bloc = await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
    );

    final checkbox = find.widgetWithText(CheckboxListTile, 'Email');
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();

    final state = bloc.state as UserPreferencesReady;
    expect(state.userPreferences.emailNotificationsEnabled, isFalse);
    expect(state.dirty, isTrue);
  });

  // --------------------------------------------------------------------------
  // Owner role — _ChannelsCard
  // --------------------------------------------------------------------------

  group('OwnerSource screen', () {
    late _MockOwnerRepository ownerRepo;

    setUp(() {
      ownerRepo = _MockOwnerRepository();
      when(
        () => ownerRepo.watchMySelf(any()),
      ).thenAnswer((_) => Stream.value(_owner()));
      when(
        () => ownerRepo.updateUserPreferences(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => ownerRepo.updateProfile(
          ownerId: any(named: 'ownerId'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async {});
    });

    testWidgets('shows _ChannelsCard title for owner', (tester) async {
      await _pumpOwner(
        tester,
        ownerRepo: ownerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.text('Canaux de notification'), findsOneWidget);
    });

    testWidgets('profile card shows owner first/last name, email and phone', (
      tester,
    ) async {
      when(() => ownerRepo.watchMySelf(any())).thenAnswer(
        (_) => Stream.value(
          Owner(
            ownerId: 'o-1',
            firstName: 'Alice',
            lastName: 'Dupont',
            email: 'alice@example.com',
            phone: '06 12 34 56 78',
            registeredAt: _kInstant,
            updatedAt: _kInstant,
          ),
        ),
      );

      await _pumpOwner(
        tester,
        ownerRepo: ownerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.textContaining('Alice Dupont'), findsOneWidget);
      expect(find.textContaining('alice@example.com'), findsOneWidget);
      expect(find.textContaining('06 12 34 56 78'), findsOneWidget);
    });

    testWidgets('does not show Notifications bénévolat for owner', (
      tester,
    ) async {
      await _pumpOwner(
        tester,
        ownerRepo: ownerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.text('Notifications bénévolat'), findsNothing);
    });

    testWidgets('shows exactly 2 checkboxes for owner', (tester) async {
      await _pumpOwner(
        tester,
        ownerRepo: ownerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('save button enabled after channel toggle for owner', (
      tester,
    ) async {
      final bloc = await _pumpOwner(
        tester,
        ownerRepo: ownerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Email'));
      await tester.pump();

      final state = bloc.state as UserPreferencesReady;
      expect(state.dirty, isTrue);

      final saveFinder = find.widgetWithText(
        FilledButton,
        'ENREGISTRER LES MODIFICATIONS',
      );
      await tester.ensureVisible(saveFinder);
      expect(tester.widget<FilledButton>(saveFinder).onPressed, isNotNull);
    });

    testWidgets('MODIFIER MES INFORMATIONS button is enabled for owner', (
      tester,
    ) async {
      await _pumpOwner(
        tester,
        ownerRepo: ownerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      final finder = find.widgetWithText(
        FilledButton,
        'MODIFIER MES INFORMATIONS',
      );
      expect(finder, findsOneWidget);
      expect(tester.widget<FilledButton>(finder).onPressed, isNotNull);
    });

    testWidgets('MODIFIER MES INFORMATIONS button has no tooltip for owner', (
      tester,
    ) async {
      await _pumpOwner(
        tester,
        ownerRepo: ownerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      final tooltipFinder = find.ancestor(
        of: find.widgetWithText(FilledButton, 'MODIFIER MES INFORMATIONS'),
        matching: find.byType(Tooltip),
      );
      // No tooltip wrapping the button when it is enabled.
      expect(tooltipFinder, findsNothing);
    });

    testWidgets(
      'tapping MODIFIER MES INFORMATIONS opens dialog with owner fields',
      (tester) async {
        await _pumpOwner(
          tester,
          ownerRepo: ownerRepo,
          authService: authService,
          syncBloc: syncBloc,
        );

        await tester.tap(
          find.widgetWithText(FilledButton, 'MODIFIER MES INFORMATIONS'),
        );
        await tester.pumpAndSettle();

        // Dialog title.
        expect(find.text('Modifier mes informations'), findsOneWidget);
        // Owner-specific fields.
        expect(find.text('Prénom'), findsOneWidget);
        expect(find.text('Nom'), findsOneWidget);
        // "Email" label also appears in the profile card, so find ≥1.
        expect(find.text('Email'), findsAtLeastNWidgets(1));
        expect(find.text('Téléphone (optionnel)'), findsOneWidget);
      },
    );

    testWidgets('submitting owner dialog dispatches profileSaved event', (
      tester,
    ) async {
      final bloc = await _pumpOwner(
        tester,
        ownerRepo: ownerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'MODIFIER MES INFORMATIONS'),
      );
      await tester.pumpAndSettle();

      // Clear and re-fill the Prénom field.
      final firstNameField = find.widgetWithText(TextFormField, 'Alice');
      await tester.enterText(firstNameField, 'Alicia');

      // Tap Enregistrer.
      await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
      await tester.pumpAndSettle();
      // Allow the async handler to complete.
      await tester.pump(const Duration(milliseconds: 50));

      verify(
        () => ownerRepo.updateProfile(
          ownerId: 'o-1',
          firstName: 'Alicia',
          lastName: 'Dupont',
          email: 'alice@example.com',
          phone: null,
        ),
      ).called(1);

      // Profile save success status should be emitted.
      expect(
        (bloc.state as UserPreferencesReady).profileSaveStatus,
        SaveStatus.success,
      );
    });
  });

  // --------------------------------------------------------------------------
  // Producer role — _ChannelsCard
  // --------------------------------------------------------------------------

  group('ProducerSource screen', () {
    late _MockProducerAccountRepository producerRepo;

    setUp(() {
      producerRepo = _MockProducerAccountRepository();
      when(
        () => producerRepo.watchMine(any()),
      ).thenAnswer((_) => Stream.value(_producer()));
      when(
        () => producerRepo.updateUserPreferences(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => producerRepo.updateProfile(
          producerAccountId: any(named: 'producerAccountId'),
          name: any(named: 'name'),
          contactEmail: any(named: 'contactEmail'),
          address: any(named: 'address'),
          website: any(named: 'website'),
        ),
      ).thenAnswer((_) async {});
    });

    testWidgets('shows _ChannelsCard title for producer', (tester) async {
      await _pumpProducer(
        tester,
        producerRepo: producerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.text('Canaux de notification'), findsOneWidget);
    });

    testWidgets(
      'profile card shows producer name, contact email, address and website',
      (tester) async {
        when(() => producerRepo.watchMine(any())).thenAnswer(
          (_) => Stream.value(
            const ProducerAccount(
              producerAccountId: 'pa-1',
              name: 'Ferme du Test',
              contactEmail: 'contact@ferme.test',
              address: '1 rue des Champs',
              website: 'https://ferme.test',
            ),
          ),
        );

        await _pumpProducer(
          tester,
          producerRepo: producerRepo,
          authService: authService,
          syncBloc: syncBloc,
        );

        expect(find.textContaining('Ferme du Test'), findsAtLeastNWidgets(1));
        expect(find.textContaining('contact@ferme.test'), findsOneWidget);
        expect(find.textContaining('1 rue des Champs'), findsOneWidget);
        expect(find.textContaining('https://ferme.test'), findsOneWidget);
      },
    );

    testWidgets('does not show Notifications bénévolat for producer', (
      tester,
    ) async {
      await _pumpProducer(
        tester,
        producerRepo: producerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.text('Notifications bénévolat'), findsNothing);
    });

    testWidgets('shows exactly 2 checkboxes for producer', (tester) async {
      await _pumpProducer(
        tester,
        producerRepo: producerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('MODIFIER MES INFORMATIONS button is enabled for producer', (
      tester,
    ) async {
      await _pumpProducer(
        tester,
        producerRepo: producerRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      final finder = find.widgetWithText(
        FilledButton,
        'MODIFIER MES INFORMATIONS',
      );
      expect(finder, findsOneWidget);
      expect(tester.widget<FilledButton>(finder).onPressed, isNotNull);
    });

    testWidgets(
      'tapping MODIFIER MES INFORMATIONS opens dialog with producer fields',
      (tester) async {
        await _pumpProducer(
          tester,
          producerRepo: producerRepo,
          authService: authService,
          syncBloc: syncBloc,
        );

        await tester.tap(
          find.widgetWithText(FilledButton, 'MODIFIER MES INFORMATIONS'),
        );
        await tester.pumpAndSettle();

        // Dialog title.
        expect(find.text('Modifier mes informations'), findsOneWidget);
        // Producer-specific fields. The profile card also renders the
        // entreprise / contact email / adresse / site web labels using the
        // synced producer data, so the dialog labels appear at least twice.
        expect(
          find.textContaining("Nom de l'entreprise"),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.textContaining('Email de contact (optionnel)'),
          findsOneWidget,
        );
        expect(find.textContaining('Adresse (optionnel)'), findsOneWidget);
        expect(find.textContaining('Site web (optionnel)'), findsOneWidget);
      },
    );
  });

  // --------------------------------------------------------------------------
  // Missing state — MODIFIER MES INFORMATIONS button stays disabled
  // --------------------------------------------------------------------------

  testWidgets(
    'MODIFIER MES INFORMATIONS button is disabled with tooltip when missing',
    (tester) async {
      when(
        () => memberRepo.watchMyMember(any()),
      ).thenAnswer((_) => Stream.value(null));

      await _pump(
        tester,
        memberRepo: memberRepo,
        authService: authService,
        syncBloc: syncBloc,
      );

      final finder = find.widgetWithText(
        FilledButton,
        'MODIFIER MES INFORMATIONS',
      );
      expect(finder, findsOneWidget);
      expect(tester.widget<FilledButton>(finder).onPressed, isNull);
    },
  );

  // --------------------------------------------------------------------------
  // Admin alert templates card
  // --------------------------------------------------------------------------

  group('Alert templates card', () {
    late _MockAlertTemplatesBloc alertBloc;

    setUp(() {
      alertBloc = _MockAlertTemplatesBloc();
      whenListen(
        alertBloc,
        const Stream<AlertTemplatesState>.empty(),
        initialState: const AlertTemplatesState.ready(
          organization: Organization(
            organizationId: 'org-1',
            name: 'AMAP Test',
            contactEmail: 'test@amap.fr',
          ),
        ),
      );
    });

    Future<void> pumpWithAlertCard(WidgetTester tester) async {
      await tester.pumpWidget(
        RepositoryProvider<AuthService>.value(
          value: authService,
          child: BlocProvider<SyncBloc>.value(
            value: syncBloc,
            child: MaterialApp(
              home: MultiBlocProvider(
                providers: [
                  BlocProvider<UserPreferencesBloc>(
                    create: (_) => UserPreferencesBloc(
                      source: MemberSource(
                        memberId: 's-1',
                        memberRepository: memberRepo,
                      ),
                    ),
                  ),
                  BlocProvider<AlertTemplatesBloc>.value(value: alertBloc),
                ],
                child: const UserPreferencesScreen(showAlertTemplates: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
      'shows the customisation card with the default copy as helper text',
      (tester) async {
        await pumpWithAlertCard(tester);
        expect(find.text('Personnalisation des alertes'), findsOneWidget);
        // The default body for "Créneau annulé" is surfaced as helper text.
        expect(
          find.text('Par défaut : Le créneau du {date} a été annulé.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '"Repartir du défaut" prefills the title and body fields with the defaults',
      (tester) async {
        await pumpWithAlertCard(tester);

        // Field starts empty (no override on the organization).
        final titleField = tester.widget<TextField>(
          find.byKey(const Key('alert_title_slotCancelled')),
        );
        expect(titleField.controller!.text, isEmpty);

        final resetButton = find.byKey(const Key('alert_reset_slotCancelled'));
        await tester.ensureVisible(resetButton);
        await tester.pump();
        await tester.tap(resetButton);
        await tester.pump();

        expect(
          tester
              .widget<TextField>(
                find.byKey(const Key('alert_title_slotCancelled')),
              )
              .controller!
              .text,
          'Créneau annulé',
        );
        expect(
          tester
              .widget<TextField>(
                find.byKey(const Key('alert_body_slotCancelled')),
              )
              .controller!
              .text,
          'Le créneau du {date} a été annulé.',
        );
      },
    );
  });
}
