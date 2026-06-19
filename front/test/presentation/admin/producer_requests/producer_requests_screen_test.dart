import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProducerRequestRepository extends Mock
    implements ProducerRequestRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

AdminProducerRequest _request({
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
  required _MockProducerRequestRepository repo,
}) async {
  final syncBloc = _MockSyncBloc();
  when(() => syncBloc.state).thenReturn(const SyncState.idle());
  when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
  await tester.pumpWidget(
    MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ProducerRequestRepository>.value(value: repo),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: const ProducerRequestsScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late _MockProducerRequestRepository repo;

  setUp(() {
    repo = _MockProducerRequestRepository();
    when(() => repo.watch()).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('shows only pending requests by default', (tester) async {
    when(() => repo.watch()).thenAnswer(
      (_) => Stream.value([
        _request(
          id: 'pending',
          status: ProducerRequestStatus.pendingValidation,
        ),
        _request(id: 'approved', status: ProducerRequestStatus.approved),
      ]),
    );
    await _pump(tester, repo: repo);

    expect(find.text('Producer pending'), findsOneWidget);
    expect(find.text('Producer approved'), findsNothing);
  });

  testWidgets('shows all requests when Toutes filter is selected', (
    tester,
  ) async {
    when(() => repo.watch()).thenAnswer(
      (_) => Stream.value([
        _request(
          id: 'pending',
          status: ProducerRequestStatus.pendingValidation,
        ),
        _request(id: 'approved', status: ProducerRequestStatus.approved),
      ]),
    );
    await _pump(tester, repo: repo);

    await tester.tap(find.widgetWithText(FilterChip, 'Toutes'));
    await tester.pump();

    expect(find.text('Producer pending'), findsOneWidget);
    expect(find.text('Producer approved'), findsOneWidget);
  });
}
