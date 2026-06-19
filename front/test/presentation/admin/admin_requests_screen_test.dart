import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRequestRepository extends Mock
    implements OrganizationRequestRepository {}

class _MockProducerRequestRepository extends Mock
    implements ProducerRequestRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

AdminOrganizationRequest _orgRequest({
  required String id,
  required OrganizationRequestStatus status,
  OrganizationType type = OrganizationType.amap,
}) => AdminOrganizationRequest(
  requestId: id,
  organizationName: 'Org $id',
  organizationType: type,
  timezone: 'Europe/Paris',
  defaultLanguage: 'fr',
  adminFirstName: 'Admin',
  adminLastName: id,
  adminEmail: '$id@example.fr',
  status: status,
  submittedAt: '2024-01-01T00:00:00Z',
);

AdminProducerRequest _producerRequest({
  required String id,
  required ProducerRequestStatus status,
}) => AdminProducerRequest(
  requestId: id,
  producerName: 'Producer $id',
  adminFirstName: 'Admin',
  adminLastName: id,
  adminEmail: '$id@example.fr',
  status: status,
  submittedAt: '2024-01-01T00:00:00Z',
);

Future<void> _pump(
  WidgetTester tester, {
  required _MockOrganizationRequestRepository orgRepo,
  required _MockProducerRequestRepository producerRepo,
  _MockSyncBloc? syncBloc,
}) async {
  final bloc = syncBloc ?? _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  await tester.pumpWidget(
    MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrganizationRequestRepository>.value(
            value: orgRepo,
          ),
          RepositoryProvider<ProducerRequestRepository>.value(
            value: producerRepo,
          ),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: bloc,
          child: const AdminRequestsScreen(),
        ),
      ),
    ),
  );
  // Pump twice: first to trigger BLoC load, second for stream emission.
  await tester.pump();
  await tester.pump();
}

void main() {
  late _MockOrganizationRequestRepository orgRepo;
  late _MockProducerRequestRepository producerRepo;

  setUp(() {
    orgRepo = _MockOrganizationRequestRepository();
    producerRepo = _MockProducerRequestRepository();
    when(() => orgRepo.watch()).thenAnswer((_) => const Stream.empty());
    when(() => producerRepo.watch()).thenAnswer((_) => const Stream.empty());
  });

  group('AdminRequestsScreen — status filter', () {
    final pending = _orgRequest(
      id: 'req-pending',
      status: OrganizationRequestStatus.pendingValidation,
    );
    final approved = _orgRequest(
      id: 'req-approved',
      status: OrganizationRequestStatus.approved,
    );
    final rejected = _orgRequest(
      id: 'req-rejected',
      status: OrganizationRequestStatus.rejected,
    );

    testWidgets(
      'shows only pending requests by default (initial filter is En attente)',
      (tester) async {
        when(
          () => orgRepo.watch(),
        ).thenAnswer((_) => Stream.value([pending, approved, rejected]));
        await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

        expect(find.text('Org req-pending'), findsOneWidget);
        expect(find.text('Org req-approved'), findsNothing);
        expect(find.text('Org req-rejected'), findsNothing);
      },
    );

    testWidgets('shows only pending requests when pending filter is selected', (
      tester,
    ) async {
      when(
        () => orgRepo.watch(),
      ).thenAnswer((_) => Stream.value([pending, approved, rejected]));
      await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

      // Use find.widgetWithText to target the FilterChip specifically,
      // avoiding ambiguity with tile labels that share the same text.
      await tester.tap(find.widgetWithText(FilterChip, 'En attente'));
      await tester.pump();

      expect(find.text('Org req-pending'), findsOneWidget);
      expect(find.text('Org req-approved'), findsNothing);
      expect(find.text('Org req-rejected'), findsNothing);
    });

    testWidgets(
      'shows only approved requests when approved filter is selected',
      (tester) async {
        when(
          () => orgRepo.watch(),
        ).thenAnswer((_) => Stream.value([pending, approved, rejected]));
        await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

        await tester.tap(find.widgetWithText(FilterChip, 'Approuvée'));
        await tester.pump();

        expect(find.text('Org req-pending'), findsNothing);
        expect(find.text('Org req-approved'), findsOneWidget);
        expect(find.text('Org req-rejected'), findsNothing);
      },
    );

    testWidgets(
      'shows only rejected requests when rejected filter is selected',
      (tester) async {
        when(
          () => orgRepo.watch(),
        ).thenAnswer((_) => Stream.value([pending, approved, rejected]));
        await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

        await tester.tap(find.widgetWithText(FilterChip, 'Rejetée'));
        await tester.pump();

        expect(find.text('Org req-pending'), findsNothing);
        expect(find.text('Org req-approved'), findsNothing);
        expect(find.text('Org req-rejected'), findsOneWidget);
      },
    );

    testWidgets('selecting Toutes after a filter shows all requests again', (
      tester,
    ) async {
      when(
        () => orgRepo.watch(),
      ).thenAnswer((_) => Stream.value([pending, approved, rejected]));
      await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

      await tester.tap(find.widgetWithText(FilterChip, 'En attente'));
      await tester.pump();
      expect(find.text('Org req-approved'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Toutes'));
      await tester.pump();

      expect(find.text('Org req-pending'), findsOneWidget);
      expect(find.text('Org req-approved'), findsOneWidget);
      expect(find.text('Org req-rejected'), findsOneWidget);
    });
  });

  group('AdminRequestsScreen — Producteurs tab', () {
    final pendingProducer = _producerRequest(
      id: 'pr-1',
      status: ProducerRequestStatus.pendingValidation,
    );
    final approvedProducer = _producerRequest(
      id: 'pr-2',
      status: ProducerRequestStatus.approved,
    );

    testWidgets('Producteurs tab shows producer requests from repository', (
      tester,
    ) async {
      // The org stream must emit so the BLoC reaches Loaded and shows the TabBar.
      when(() => orgRepo.watch()).thenAnswer((_) => Stream.value(const []));
      when(
        () => producerRepo.watch(),
      ).thenAnswer((_) => Stream.value([pendingProducer, approvedProducer]));
      await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

      // Switch to the Producteurs tab.
      await tester.tap(find.text('Producteurs'));
      await tester.pump();

      // The tab starts with the "En attente" filter active; clear it to see all.
      await tester.tap(find.widgetWithText(FilterChip, 'Toutes'));
      await tester.pump();

      expect(find.text('Producer pr-1'), findsOneWidget);
      expect(find.text('Producer pr-2'), findsOneWidget);
    });

    testWidgets(
      'Producteurs tab shows empty message when no producer requests exist',
      (tester) async {
        // The org stream must emit so the BLoC reaches Loaded and shows the TabBar.
        when(() => orgRepo.watch()).thenAnswer((_) => Stream.value(const []));
        when(
          () => producerRepo.watch(),
        ).thenAnswer((_) => Stream.value(const []));
        await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

        await tester.tap(find.text('Producteurs'));
        await tester.pump();

        expect(find.text('Aucune demande trouvée.'), findsOneWidget);
      },
    );

    testWidgets('producer status filter bar is visible on Producteurs tab', (
      tester,
    ) async {
      when(() => orgRepo.watch()).thenAnswer((_) => Stream.value(const []));
      when(
        () => producerRepo.watch(),
      ).thenAnswer((_) => Stream.value([pendingProducer, approvedProducer]));
      await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

      await tester.tap(find.text('Producteurs'));
      await tester.pump();

      expect(find.widgetWithText(FilterChip, 'Toutes'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'En attente'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Approuvées'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Rejetées'), findsOneWidget);
    });

    testWidgets('producer filter shows only pending requests when selected', (
      tester,
    ) async {
      final rejected = _producerRequest(
        id: 'pr-3',
        status: ProducerRequestStatus.rejected,
      );
      when(() => orgRepo.watch()).thenAnswer((_) => Stream.value(const []));
      when(() => producerRepo.watch()).thenAnswer(
        (_) => Stream.value([pendingProducer, approvedProducer, rejected]),
      );
      await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

      await tester.tap(find.text('Producteurs'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'En attente'));
      await tester.pump();

      expect(find.text('Producer pr-1'), findsOneWidget);
      expect(find.text('Producer pr-2'), findsNothing);
      expect(find.text('Producer pr-3'), findsNothing);
    });

    testWidgets('producer filter shows only approved requests when selected', (
      tester,
    ) async {
      when(() => orgRepo.watch()).thenAnswer((_) => Stream.value(const []));
      when(
        () => producerRepo.watch(),
      ).thenAnswer((_) => Stream.value([pendingProducer, approvedProducer]));
      await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

      await tester.tap(find.text('Producteurs'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Approuvées'));
      await tester.pump();

      expect(find.text('Producer pr-1'), findsNothing);
      expect(find.text('Producer pr-2'), findsOneWidget);
    });

    testWidgets('producer filter Toutes resets to show all requests', (
      tester,
    ) async {
      when(() => orgRepo.watch()).thenAnswer((_) => Stream.value(const []));
      when(
        () => producerRepo.watch(),
      ).thenAnswer((_) => Stream.value([pendingProducer, approvedProducer]));
      await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

      await tester.tap(find.text('Producteurs'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Approuvées'));
      await tester.pump();
      expect(find.text('Producer pr-1'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Toutes'));
      await tester.pump();

      expect(find.text('Producer pr-1'), findsOneWidget);
      expect(find.text('Producer pr-2'), findsOneWidget);
    });

    testWidgets('AMAP tab is not polluted by producer requests', (
      tester,
    ) async {
      when(() => orgRepo.watch()).thenAnswer(
        (_) => Stream.value([
          _orgRequest(
            id: 'amap-1',
            status: OrganizationRequestStatus.pendingValidation,
          ),
        ]),
      );
      when(
        () => producerRepo.watch(),
      ).thenAnswer((_) => Stream.value([pendingProducer]));
      await _pump(tester, orgRepo: orgRepo, producerRepo: producerRepo);

      // AMAP tab is active by default.
      expect(find.text('Org amap-1'), findsOneWidget);
      expect(find.text('Producer pr-1'), findsNothing);
    });
  });
}
