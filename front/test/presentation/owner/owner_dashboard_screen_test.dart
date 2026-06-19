import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/presentation/owner/owner_dashboard_screen.dart';
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

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _MockProducerRequestRepository extends Mock
    implements ProducerRequestRepository {}

AdminOrganizationRequest _request({
  required String id,
  required OrganizationRequestStatus status,
  required String submittedAt,
}) => AdminOrganizationRequest(
  requestId: id,
  organizationName: 'Org $id',
  timezone: 'Europe/Paris',
  defaultLanguage: 'fr',
  adminFirstName: 'Admin',
  adminLastName: id,
  adminEmail: '$id@example.fr',
  status: status,
  submittedAt: submittedAt,
);

Future<void> _pump(
  WidgetTester tester, {
  required OrganizationRequestRepository repo,
  required ProducerRequestRepository producerRepo,
  _MockSyncBloc? syncBloc,
}) async {
  final bloc = syncBloc ?? _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  await tester.pumpWidget(
    MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrganizationRequestRepository>.value(value: repo),
          RepositoryProvider<ProducerRequestRepository>.value(
            value: producerRepo,
          ),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: bloc,
          child: const OwnerDashboardScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late _MockOrganizationRequestRepository repo;
  late _MockProducerRequestRepository producerRepo;
  late _MockSyncBloc syncBloc;

  setUp(() {
    repo = _MockOrganizationRequestRepository();
    producerRepo = _MockProducerRequestRepository();
    syncBloc = _MockSyncBloc();
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => producerRepo.watch(),
    ).thenAnswer((_) => Stream.value(const <AdminProducerRequest>[]));
  });

  group('OwnerDashboardScreen', () {
    testWidgets('renders the owner home title in the app bar', (tester) async {
      when(
        () => repo.watch(),
      ).thenAnswer((_) => Stream.value(const <AdminOrganizationRequest>[]));

      await _pump(
        tester,
        repo: repo,
        producerRepo: producerRepo,
        syncBloc: syncBloc,
      );

      expect(
        find.text('Administrateur Instance · Tableau de bord'),
        findsOneWidget,
      );
    });

    testWidgets('renders the documented sections from screen-owner-01-home', (
      tester,
    ) async {
      when(
        () => repo.watch(),
      ).thenAnswer((_) => Stream.value(const <AdminOrganizationRequest>[]));

      await _pump(
        tester,
        repo: repo,
        producerRepo: producerRepo,
        syncBloc: syncBloc,
      );

      expect(find.text('Demandes en attente'), findsOneWidget);
      expect(find.text('Vue instance'), findsOneWidget);
      expect(find.text('Organisations actives'), findsOneWidget);
      expect(find.text('Demandes ce mois'), findsOneWidget);
      expect(find.text('Demandes refusées ce mois'), findsOneWidget);
      expect(find.text("Demandes d'organisation"), findsOneWidget);
      expect(find.text('Demandes producteurs'), findsOneWidget);
      expect(find.text('VOIR LES DEMANDES'), findsOneWidget);
    });

    testWidgets(
      'derives pending count and monthly stats from the repository stream',
      (tester) async {
        final now = DateTime.now();
        final thisMonth =
            '${now.year.toString().padLeft(4, '0')}'
            '-${now.month.toString().padLeft(2, '0')}'
            '-05T10:00:00Z';
        final priorMonthDate = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(days: 1));
        final priorMonth =
            '${priorMonthDate.year.toString().padLeft(4, '0')}'
            '-${priorMonthDate.month.toString().padLeft(2, '0')}'
            '-15T10:00:00Z';

        when(() => repo.watch()).thenAnswer(
          (_) => Stream.value([
            _request(
              id: 'a',
              status: OrganizationRequestStatus.pendingValidation,
              submittedAt: thisMonth,
            ),
            _request(
              id: 'b',
              status: OrganizationRequestStatus.pendingValidation,
              submittedAt: thisMonth,
            ),
            _request(
              id: 'c',
              status: OrganizationRequestStatus.approved,
              submittedAt: thisMonth,
            ),
            _request(
              id: 'd',
              status: OrganizationRequestStatus.rejected,
              submittedAt: thisMonth,
            ),
            _request(
              id: 'e',
              status: OrganizationRequestStatus.approved,
              submittedAt: priorMonth,
            ),
          ]),
        );
        when(() => producerRepo.watch()).thenAnswer(
          (_) => Stream.value([
            AdminProducerRequest(
              requestId: 'producer-a',
              producerName: 'Ferme A',
              adminFirstName: 'Alice',
              adminLastName: 'Martin',
              adminEmail: 'alice@producer.fr',
              status: ProducerRequestStatus.pendingValidation,
              submittedAt: thisMonth,
            ),
          ]),
        );

        await _pump(
          tester,
          repo: repo,
          producerRepo: producerRepo,
          syncBloc: syncBloc,
        );

        expect(
          find.text('3 demandes à traiter (AMAP + Producteurs)'),
          findsOneWidget,
        );
        // Approved org requests across all time (this month + prior) = 2.
        expect(find.text('2'), findsWidgets);
        // Demandes ce mois = 5 (a, b, c, d + producer-a).
        expect(find.text('5'), findsOneWidget);
        // Demandes refusées ce mois = 1 (d).
        expect(find.text('1'), findsOneWidget);
      },
    );

    testWidgets('singularises copy when exactly one request is pending', (
      tester,
    ) async {
      when(() => repo.watch()).thenAnswer(
        (_) => Stream.value([
          _request(
            id: 'a',
            status: OrganizationRequestStatus.pendingValidation,
            submittedAt: '2024-01-01T00:00:00Z',
          ),
        ]),
      );

      await _pump(
        tester,
        repo: repo,
        producerRepo: producerRepo,
        syncBloc: syncBloc,
      );

      expect(
        find.text('1 demande à traiter (AMAP + Producteurs)'),
        findsOneWidget,
      );
    });
  });
}
