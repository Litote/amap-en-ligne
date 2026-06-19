import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProducerRequestRepository extends Mock
    implements ProducerRequestRepository {}

final _pending = AdminProducerRequest(
  requestId: 'req-1',
  producerName: 'Ferme des Collines',
  adminFirstName: 'Alice',
  adminLastName: 'Martin',
  adminEmail: 'alice@example.fr',
  status: ProducerRequestStatus.pendingValidation,
  submittedAt: '2026-01-01T00:00:00Z',
);

void main() {
  late _MockProducerRequestRepository repo;

  setUpAll(() {
    registerFallbackValue(_pending);
  });

  setUp(() {
    repo = _MockProducerRequestRepository();
    when(() => repo.watch()).thenAnswer((_) => Stream.value([_pending]));
  });

  blocTest<ProducerRequestsBloc, ProducerRequestsState>(
    'loads producer requests from repository stream',
    build: () => ProducerRequestsBloc(producerRequestRepository: repo),
    act: (bloc) => bloc.add(const ProducerRequestsEvent.loadRequested()),
    expect: () => [
      const ProducerRequestsState.loading(),
      isA<ProducerRequestsLoaded>().having(
        (s) => s.requests.single.requestId,
        'requestId',
        'req-1',
      ),
    ],
  );

  blocTest<ProducerRequestsBloc, ProducerRequestsState>(
    'approve toggles actionInProgress and clears it on success',
    setUp: () => when(() => repo.approve(_pending)).thenAnswer((_) async {}),
    build: () => ProducerRequestsBloc(producerRequestRepository: repo),
    seed: () => ProducerRequestsState.loaded(requests: [_pending]),
    act: (bloc) =>
        bloc.add(ProducerRequestsEvent.approveRequested(request: _pending)),
    expect: () => [
      isA<ProducerRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        isTrue,
      ),
      isA<ProducerRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        isFalse,
      ),
    ],
  );

  blocTest<ProducerRequestsBloc, ProducerRequestsState>(
    'resendRequested emits actionInProgress then clears it on success',
    setUp: () => when(() => repo.resend(_pending)).thenAnswer((_) async {}),
    build: () => ProducerRequestsBloc(producerRequestRepository: repo),
    seed: () => ProducerRequestsState.loaded(requests: [_pending]),
    act: (bloc) =>
        bloc.add(ProducerRequestsEvent.resendRequested(request: _pending)),
    expect: () => [
      isA<ProducerRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        isTrue,
      ),
      isA<ProducerRequestsLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', false)
          .having((s) => s.actionError, 'actionError', isNull),
    ],
  );

  blocTest<ProducerRequestsBloc, ProducerRequestsState>(
    'resendRequested emits actionError when repository throws',
    setUp: () =>
        when(() => repo.resend(any())).thenThrow(Exception('network error')),
    build: () => ProducerRequestsBloc(producerRequestRepository: repo),
    seed: () => ProducerRequestsState.loaded(requests: [_pending]),
    act: (bloc) =>
        bloc.add(ProducerRequestsEvent.resendRequested(request: _pending)),
    expect: () => [
      isA<ProducerRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        isTrue,
      ),
      isA<ProducerRequestsLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', false)
          .having((s) => s.actionError, 'actionError', isNotNull),
    ],
  );
}
