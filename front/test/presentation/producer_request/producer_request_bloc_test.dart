import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/producer_creation_request.dart';
import 'package:amap_en_ligne/domain/model/producer_request_response.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_bloc.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_event.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPublicApi extends Mock implements PublicApi {}

class _FakeProducerCreationRequest extends Fake
    implements ProducerCreationRequest {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeProducerCreationRequest()));

  const validEvent = ProducerRequestEvent.submitted(
    producerName: 'Ferme test',
    adminFirstName: 'Jean',
    adminLastName: 'Dupont',
    adminEmail: 'jean@example.fr',
  );

  late _MockPublicApi api;

  setUp(() => api = _MockPublicApi());

  blocTest<ProducerRequestBloc, ProducerRequestState>(
    'emits submitting then success on 201',
    setUp: () => when(() => api.createProducerRequest(any())).thenAnswer(
      (_) async => const ProducerRequestResponse(
        requestId: 'req-1',
        status: 'PENDING_VALIDATION',
      ),
    ),
    build: () => ProducerRequestBloc(publicApi: api),
    act: (bloc) => bloc.add(validEvent),
    expect: () => [
      const ProducerRequestState.submitting(),
      isA<ProducerRequestSuccess>().having(
        (s) => s.response.requestId,
        'requestId',
        'req-1',
      ),
    ],
  );

  blocTest<ProducerRequestBloc, ProducerRequestState>(
    'emits conflict error on 409',
    setUp: () => when(() => api.createProducerRequest(any())).thenThrow(
      const ProducerConflictException(ProducerConflictField.producerName),
    ),
    build: () => ProducerRequestBloc(publicApi: api),
    act: (bloc) => bloc.add(validEvent),
    expect: () => [
      const ProducerRequestState.submitting(),
      isA<ProducerRequestError>()
          .having(
            (s) => s.conflictField,
            'conflictField',
            ProducerConflictField.producerName,
          )
          .having(
            (s) => s.message,
            'message',
            'Ce nom de producteur est déjà utilisé.',
          ),
    ],
  );

  blocTest<ProducerRequestBloc, ProducerRequestState>(
    'emits PENDING_VALIDATION message for adminEmail conflict',
    setUp: () => when(() => api.createProducerRequest(any())).thenThrow(
      const ProducerConflictException(
        ProducerConflictField.adminEmail,
        existingStatus: 'PENDING_VALIDATION',
      ),
    ),
    build: () => ProducerRequestBloc(publicApi: api),
    act: (bloc) => bloc.add(validEvent),
    expect: () => [
      const ProducerRequestState.submitting(),
      isA<ProducerRequestError>()
          .having(
            (s) => s.conflictField,
            'conflictField',
            ProducerConflictField.adminEmail,
          )
          .having(
            (s) => s.message,
            'message',
            'Une demande avec cette adresse e-mail est déjà en cours d\'examen.',
          ),
    ],
  );

  blocTest<ProducerRequestBloc, ProducerRequestState>(
    'emits APPROVED message for producerName conflict',
    setUp: () => when(() => api.createProducerRequest(any())).thenThrow(
      const ProducerConflictException(
        ProducerConflictField.producerName,
        existingStatus: 'APPROVED',
      ),
    ),
    build: () => ProducerRequestBloc(publicApi: api),
    act: (bloc) => bloc.add(validEvent),
    expect: () => [
      const ProducerRequestState.submitting(),
      isA<ProducerRequestError>().having(
        (s) => s.message,
        'message',
        'Un producteur avec ce nom a déjà été approuvé.',
      ),
    ],
  );
}
