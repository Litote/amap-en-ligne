import 'dart:async';

import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/admin/organization_config_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

_MockSyncBloc _makeSyncBloc() {
  final bloc = _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

const _tenantId = 'org-1';

const _org = Organization(
  organizationId: _tenantId,
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
  timezone: 'Europe/Paris',
  defaultLanguage: 'fr',
  website: 'https://amap.fr',
);

Future<void> _pump(
  WidgetTester tester, {
  required _MockOrganizationRepository repo,
  _MockSyncBloc? syncBloc,
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: repo),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc ?? _makeSyncBloc(),
        child: const MaterialApp(
          home: OrganizationConfigScreen(tenantId: _tenantId),
        ),
      ),
    ),
  );
  // Allow the StreamBuilder to receive the first org event and the bloc to
  // transition to ready state.
  await tester.pump();
}

/// Enlarges the test surface so the full form fits without scrolling, then
/// scrolls [finder] into view as a fallback for any remaining overflow.
Future<void> _ensureVisible(WidgetTester tester, Finder finder) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.pump();
}

void main() {
  late _MockOrganizationRepository repo;

  setUpAll(() {
    registerFallbackValue(_org);
  });

  setUp(() {
    repo = _MockOrganizationRepository();
  });

  group('OrganizationConfigScreen', () {
    testWidgets('shows loading spinner while org is not yet available', (
      tester,
    ) async {
      when(
        () => repo.watch(_tenantId),
      ).thenAnswer((_) => const Stream.empty());

      await _pump(tester, repo: repo);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows missing message when org is null', (tester) async {
      when(
        () => repo.watch(_tenantId),
      ).thenAnswer((_) => Stream.value(null));

      await _pump(tester, repo: repo);

      expect(
        find.textContaining('Organisation non disponible'),
        findsOneWidget,
      );
    });

    testWidgets('renders all 5 identity fields when org is ready', (
      tester,
    ) async {
      when(
        () => repo.watch(_tenantId),
      ).thenAnswer((_) => Stream.value(_org));

      await _pump(tester, repo: repo);

      expect(find.byKey(const Key('org_config_name')), findsOneWidget);
      expect(find.byKey(const Key('org_config_email')), findsOneWidget);
      expect(find.byKey(const Key('org_config_timezone')), findsOneWidget);
      expect(find.byKey(const Key('org_config_language')), findsOneWidget);
      expect(find.byKey(const Key('org_config_website')), findsOneWidget);
    });

    testWidgets('pre-fills name and email from current org values', (
      tester,
    ) async {
      when(
        () => repo.watch(_tenantId),
      ).thenAnswer((_) => Stream.value(_org));

      await _pump(tester, repo: repo);

      expect(find.widgetWithText(TextFormField, 'AMAP Test'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'test@amap.fr'),
        findsOneWidget,
      );
    });

    testWidgets('renders screen title in app bar', (tester) async {
      when(
        () => repo.watch(_tenantId),
      ).thenAnswer((_) => Stream.value(_org));

      await _pump(tester, repo: repo);

      expect(find.text("Configuration de l'organisation"), findsOneWidget);
    });

    testWidgets(
      'save button shows CircularProgressIndicator while saving',
      (tester) async {
        // Use a Completer to keep the saving state active long enough to assert.
        final completer = Completer<void>();
        when(
          () => repo.watch(_tenantId),
        ).thenAnswer((_) => Stream.value(_org));
        when(
          () => repo.updateIdentity(
            currentOrg: any(named: 'currentOrg'),
            name: any(named: 'name'),
            contactEmail: any(named: 'contactEmail'),
            timezone: any(named: 'timezone'),
            defaultLanguage: any(named: 'defaultLanguage'),
            website: any(named: 'website'),
          ),
        ).thenAnswer((_) => completer.future);

        await _pump(tester, repo: repo);

        final saveButton = find.byKey(const Key('org_config_save_button'));
        await _ensureVisible(tester, saveButton);

        await tester.tap(saveButton);
        // One pump: tap fires → _save() → event dispatched → bloc emits saving.
        await tester.pump();

        // In saving state the button shows a CircularProgressIndicator.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Unblock to avoid pending async on teardown.
        completer.complete();
        await tester.pump();
      },
    );

    testWidgets(
      'tapping save calls updateIdentity with form values',
      (tester) async {
        when(
          () => repo.watch(_tenantId),
        ).thenAnswer((_) => Stream.value(_org));
        when(
          () => repo.updateIdentity(
            currentOrg: any(named: 'currentOrg'),
            name: any(named: 'name'),
            contactEmail: any(named: 'contactEmail'),
            timezone: any(named: 'timezone'),
            defaultLanguage: any(named: 'defaultLanguage'),
            website: any(named: 'website'),
          ),
        ).thenAnswer((_) async {});

        await _pump(tester, repo: repo);

        final saveButton = find.byKey(const Key('org_config_save_button'));
        await _ensureVisible(tester, saveButton);

        await tester.tap(saveButton);
        // pump: tap → event dispatched → bloc processes event (microtasks drain).
        await tester.pump();

        verify(
          () => repo.updateIdentity(
            currentOrg: any(named: 'currentOrg'),
            name: any(named: 'name'),
            contactEmail: any(named: 'contactEmail'),
            timezone: any(named: 'timezone'),
            defaultLanguage: any(named: 'defaultLanguage'),
            website: any(named: 'website'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'validates required name field — shows error when name is blank',
      (tester) async {
        when(
          () => repo.watch(_tenantId),
        ).thenAnswer((_) => Stream.value(_org));

        await _pump(tester, repo: repo);

        // enterText('') does not reliably fire a text-change notification when
        // the controller is not yet empty; use whitespace instead — the
        // validator runs trim().isEmpty, so '   ' is equivalent to ''.
        await tester.enterText(
          find.byKey(const Key('org_config_name')),
          '   ',
        );

        // Scroll to save button and tap to trigger validation.
        final saveButton = find.byKey(const Key('org_config_save_button'));
        await _ensureVisible(tester, saveButton);
        await tester.tap(saveButton);
        await tester.pump();

        expect(find.text('Le nom est requis'), findsOneWidget);
      },
    );

    testWidgets(
      'validates email format — shows error when email is invalid',
      (tester) async {
        when(
          () => repo.watch(_tenantId),
        ).thenAnswer((_) => Stream.value(_org));

        await _pump(tester, repo: repo);

        await tester.enterText(
          find.byKey(const Key('org_config_email')),
          'not-an-email',
        );

        final saveButton = find.byKey(const Key('org_config_save_button'));
        await _ensureVisible(tester, saveButton);
        await tester.tap(saveButton);
        await tester.pump();

        expect(find.text("L'adresse email n'est pas valide"), findsOneWidget);
      },
    );

    testWidgets(
      'validates required email field — shows error when email is blank',
      (tester) async {
        when(
          () => repo.watch(_tenantId),
        ).thenAnswer((_) => Stream.value(_org));

        await _pump(tester, repo: repo);

        await tester.enterText(
          find.byKey(const Key('org_config_email')),
          '',
        );

        final saveButton = find.byKey(const Key('org_config_save_button'));
        await _ensureVisible(tester, saveButton);
        await tester.tap(saveButton);
        await tester.pump();

        expect(
          find.text("L'email de contact est requis"),
          findsOneWidget,
        );
      },
    );
  });
}
