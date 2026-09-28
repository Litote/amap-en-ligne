import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/organization_request_response.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_bloc.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_event.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPublicApi extends Mock implements PublicApi {}

class _FakeOrganizationCreationRequest extends Fake
    implements OrganizationCreationRequest {}

const _validEvent = OrganizationCreationEvent.submitted(
  organizationName: 'AMAP test',
  timezone: 'Europe/Paris',
  defaultLanguage: 'fr',
  adminFirstName: 'Jean',
  adminLastName: 'Dupont',
  adminEmail: 'jean@example.fr',
  organizationType: OrganizationType.amap,
);

void main() {
  setUpAll(() => registerFallbackValue(_FakeOrganizationCreationRequest()));

  late _MockPublicApi api;

  setUp(() => api = _MockPublicApi());

  blocTest<OrganizationCreationBloc, OrganizationCreationState>(
    'emits submitting then success on 201',
    setUp: () => when(() => api.createOrganizationRequest(any())).thenAnswer(
      (_) async => const OrganizationRequestResponse(
        requestId: 'req-1',
        status: 'PENDING_VALIDATION',
      ),
    ),
    build: () => OrganizationCreationBloc(publicApi: api),
    act: (bloc) => bloc.add(_validEvent),
    expect: () => [
      const OrganizationCreationState.submitting(),
      isA<OrganizationCreationSuccess>().having(
        (s) => s.response.requestId,
        'requestId',
        'req-1',
      ),
    ],
  );

  blocTest<OrganizationCreationBloc, OrganizationCreationState>(
    'emits error with organizationName conflict field on 409',
    setUp: () => when(() => api.createOrganizationRequest(any())).thenThrow(
      const OrganizationConflictException(
        OrganizationConflictField.organizationName,
      ),
    ),
    build: () => OrganizationCreationBloc(publicApi: api),
    act: (bloc) => bloc.add(_validEvent),
    expect: () => [
      const OrganizationCreationState.submitting(),
      isA<OrganizationCreationError>()
          .having(
            (s) => s.conflictField,
            'conflictField',
            OrganizationConflictField.organizationName,
          )
          .having(
            (s) => s.message,
            'message',
            'Ce nom d\'AMAP est déjà utilisé.',
          ),
    ],
  );

  blocTest<OrganizationCreationBloc, OrganizationCreationState>(
    'emits PENDING_VALIDATION message for adminEmail conflict',
    setUp: () => when(() => api.createOrganizationRequest(any())).thenThrow(
      const OrganizationConflictException(
        OrganizationConflictField.adminEmail,
        existingStatus: 'PENDING_VALIDATION',
      ),
    ),
    build: () => OrganizationCreationBloc(publicApi: api),
    act: (bloc) => bloc.add(_validEvent),
    expect: () => [
      const OrganizationCreationState.submitting(),
      isA<OrganizationCreationError>()
          .having(
            (s) => s.conflictField,
            'conflictField',
            OrganizationConflictField.adminEmail,
          )
          .having(
            (s) => s.message,
            'message',
            'Une demande avec cette adresse e-mail est déjà en cours d\'examen.',
          ),
    ],
  );

  blocTest<OrganizationCreationBloc, OrganizationCreationState>(
    'emits APPROVED message for organizationName conflict',
    setUp: () => when(() => api.createOrganizationRequest(any())).thenThrow(
      const OrganizationConflictException(
        OrganizationConflictField.organizationName,
        existingStatus: 'APPROVED',
      ),
    ),
    build: () => OrganizationCreationBloc(publicApi: api),
    act: (bloc) => bloc.add(_validEvent),
    expect: () => [
      const OrganizationCreationState.submitting(),
      isA<OrganizationCreationError>().having(
        (s) => s.message,
        'message',
        'Une AMAP avec ce nom a déjà été approuvée.',
      ),
    ],
  );

  blocTest<OrganizationCreationBloc, OrganizationCreationState>(
    'emits generic error on network failure',
    setUp: () => when(
      () => api.createOrganizationRequest(any()),
    ).thenThrow(Exception('network')),
    build: () => OrganizationCreationBloc(publicApi: api),
    act: (bloc) => bloc.add(_validEvent),
    expect: () => [
      const OrganizationCreationState.submitting(),
      isA<OrganizationCreationError>().having(
        (s) => s.conflictField,
        'conflictField',
        isNull,
      ),
    ],
  );
}
