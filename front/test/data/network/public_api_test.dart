import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/member_join_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/organization_request_response.dart';
import 'package:amap_en_ligne/domain/model/producer_creation_request.dart';
import 'package:amap_en_ligne/domain/model/producer_request_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ignore_for_file: lines_longer_than_80_chars

class _MockDio extends Mock implements Dio {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeRequestOptions()));

  late _MockDio dio;
  late PublicApi api;

  setUp(() {
    dio = _MockDio();
    api = PublicApi(dio);
  });

  group('listOrganizations', () {
    test('returns decoded list on 200', () async {
      when(() => dio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/public/organizations'),
          statusCode: 200,
          data: [
            {
              'organization_id': 'org-1',
              'name': 'AMAP des Collines',
              'contact_email': 'contact@collines.fr',
              'active_status': true,
            },
          ],
        ),
      );

      final orgs = await api.listOrganizations();
      expect(orgs, hasLength(1));
      expect(orgs.first.organizationId, 'org-1');
    });

    test('returns empty list when body is null', () async {
      when(() => dio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/public/organizations'),
          statusCode: 200,
        ),
      );

      expect(await api.listOrganizations(), isEmpty);
    });

    test('propagates DioException on network failure', () async {
      when(() => dio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/public/organizations'),
        ),
      );

      expect(() => api.listOrganizations(), throwsA(isA<DioException>()));
    });
  });

  group('createOrganizationRequest', () {
    final request = const OrganizationCreationRequest(
      organizationName: 'AMAP test',
      timezone: 'Europe/Paris',
      defaultLanguage: 'fr',
      adminFirstName: 'Jean',
      adminLastName: 'Dupont',
      adminEmail: 'jean@example.fr',
      organizationType: OrganizationType.amap,
    );

    test('returns OrganizationRequestResponse on 201', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/organization-requests'),
          statusCode: 201,
          data: {'request_id': 'req-1', 'status': 'PENDING_VALIDATION'},
        ),
      );

      final resp = await api.createOrganizationRequest(request);
      expect(resp, isA<OrganizationRequestResponse>());
      expect(resp.requestId, 'req-1');
      expect(resp.status, 'PENDING_VALIDATION');
    });

    test(
      'throws OrganizationConflictException with organizationName on 409',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/organization-requests'),
            response: Response(
              requestOptions: RequestOptions(path: '/v1/organization-requests'),
              statusCode: 409,
              data: {
                'error': {
                  'code': 'CONFLICT',
                  'details': {'field': 'organization_name'},
                },
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => api.createOrganizationRequest(request),
          throwsA(
            isA<OrganizationConflictException>().having(
              (e) => e.field,
              'field',
              OrganizationConflictField.organizationName,
            ),
          ),
        );
      },
    );

    test(
      'throws OrganizationConflictException with adminEmail on 409',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/organization-requests'),
            response: Response(
              requestOptions: RequestOptions(path: '/v1/organization-requests'),
              statusCode: 409,
              data: {
                'error': {
                  'code': 'CONFLICT',
                  'details': {'field': 'admin_email'},
                },
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => api.createOrganizationRequest(request),
          throwsA(
            isA<OrganizationConflictException>().having(
              (e) => e.field,
              'field',
              OrganizationConflictField.adminEmail,
            ),
          ),
        );
      },
    );

    test(
      'throws OrganizationConflictException with existingStatus on 409',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/organization-requests'),
            response: Response(
              requestOptions: RequestOptions(path: '/v1/organization-requests'),
              statusCode: 409,
              data: {
                'error': {
                  'code': 'CONFLICT',
                  'details': {
                    'field': 'admin_email',
                    'existing_status': 'PENDING_VALIDATION',
                  },
                },
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => api.createOrganizationRequest(request),
          throwsA(
            isA<OrganizationConflictException>()
                .having(
                  (e) => e.field,
                  'field',
                  OrganizationConflictField.adminEmail,
                )
                .having(
                  (e) => e.existingStatus,
                  'existingStatus',
                  'PENDING_VALIDATION',
                ),
          ),
        );
      },
    );

    test('propagates non-409 DioException', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/organization-requests'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => api.createOrganizationRequest(request),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('createMemberJoinRequest', () {
    final request = const MemberJoinRequest(
      organizationId: 'org-1',
      email: 'jean@example.fr',
      firstName: 'Jean',
      lastName: 'Dupont',
    );

    test('returns MemberJoinRequestResponse on 201', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/v1/public/member-join-requests',
          ),
          statusCode: 201,
          data: {'request_id': 'req-1', 'status': 'PENDING'},
        ),
      );

      final resp = await api.createMemberJoinRequest(request);
      expect(resp, isA<MemberJoinRequestResponse>());
      expect(resp.requestId, 'req-1');
      expect(resp.status, 'PENDING');
    });

    group('createProducerRequest', () {
      final request = const ProducerCreationRequest(
        producerName: 'Ferme test',
        adminFirstName: 'Jean',
        adminLastName: 'Dupont',
        adminEmail: 'jean@example.fr',
      );

      test('returns ProducerRequestResponse on 201', () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/v1/producer-requests'),
            statusCode: 201,
            data: {'request_id': 'req-1', 'status': 'PENDING_VALIDATION'},
          ),
        );

        final response = await api.createProducerRequest(request);
        expect(response, isA<ProducerRequestResponse>());
        expect(response.requestId, 'req-1');
        expect(response.status, 'PENDING_VALIDATION');
      });

      test(
        'throws ProducerConflictException with producerName on 409',
        () async {
          when(
            () =>
                dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/v1/producer-requests'),
              response: Response(
                requestOptions: RequestOptions(path: '/v1/producer-requests'),
                statusCode: 409,
                data: {
                  'error': {
                    'code': 'CONFLICT',
                    'details': {'field': 'producer_name'},
                  },
                },
              ),
              type: DioExceptionType.badResponse,
            ),
          );

          expect(
            () => api.createProducerRequest(request),
            throwsA(
              isA<ProducerConflictException>().having(
                (e) => e.field,
                'field',
                ProducerConflictField.producerName,
              ),
            ),
          );
        },
      );

      test(
        'throws ProducerConflictException with existingStatus on 409',
        () async {
          when(
            () =>
                dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/v1/producer-requests'),
              response: Response(
                requestOptions: RequestOptions(path: '/v1/producer-requests'),
                statusCode: 409,
                data: {
                  'error': {
                    'code': 'CONFLICT',
                    'details': {
                      'field': 'admin_email',
                      'existing_status': 'PENDING_VALIDATION',
                    },
                  },
                },
              ),
              type: DioExceptionType.badResponse,
            ),
          );

          expect(
            () => api.createProducerRequest(request),
            throwsA(
              isA<ProducerConflictException>()
                  .having(
                    (e) => e.field,
                    'field',
                    ProducerConflictField.adminEmail,
                  )
                  .having(
                    (e) => e.existingStatus,
                    'existingStatus',
                    'PENDING_VALIDATION',
                  ),
            ),
          );
        },
      );

      test('rethrows non-409 DioException', () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/producer-requests'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => api.createProducerRequest(request),
          throwsA(isA<DioException>()),
        );
      });
    });

    test(
      'throws MemberJoinConflictException with email on 409 with field=email',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/v1/public/member-join-requests',
            ),
            response: Response(
              requestOptions: RequestOptions(
                path: '/v1/public/member-join-requests',
              ),
              statusCode: 409,
              data: {'field': 'email'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => api.createMemberJoinRequest(request),
          throwsA(
            isA<MemberJoinConflictException>().having(
              (e) => e.field,
              'field',
              MemberJoinConflictField.email,
            ),
          ),
        );
      },
    );

    test(
      'throws MemberJoinConflictException with unknown on 409 with unknown field',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/v1/public/member-join-requests',
            ),
            response: Response(
              requestOptions: RequestOptions(
                path: '/v1/public/member-join-requests',
              ),
              statusCode: 409,
              data: {'field': 'other'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => api.createMemberJoinRequest(request),
          throwsA(
            isA<MemberJoinConflictException>().having(
              (e) => e.field,
              'field',
              MemberJoinConflictField.unknown,
            ),
          ),
        );
      },
    );

    test(
      'throws MemberJoinConflictException with emailMember on 409 with field=email_member',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/v1/public/member-join-requests',
            ),
            response: Response(
              requestOptions: RequestOptions(
                path: '/v1/public/member-join-requests',
              ),
              statusCode: 409,
              data: {'field': 'email_member'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => api.createMemberJoinRequest(request),
          throwsA(
            isA<MemberJoinConflictException>().having(
              (e) => e.field,
              'field',
              MemberJoinConflictField.emailMember,
            ),
          ),
        );
      },
    );

    test(
      'throws MemberJoinConflictException with emailOwner on 409 with field=email_owner',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/v1/public/member-join-requests',
            ),
            response: Response(
              requestOptions: RequestOptions(
                path: '/v1/public/member-join-requests',
              ),
              statusCode: 409,
              data: {'field': 'email_owner'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => api.createMemberJoinRequest(request),
          throwsA(
            isA<MemberJoinConflictException>().having(
              (e) => e.field,
              'field',
              MemberJoinConflictField.emailOwner,
            ),
          ),
        );
      },
    );

    test(
      'throws MemberJoinConflictException with emailProducer on 409 with field=email_producer',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/v1/public/member-join-requests',
            ),
            response: Response(
              requestOptions: RequestOptions(
                path: '/v1/public/member-join-requests',
              ),
              statusCode: 409,
              data: {'field': 'email_producer'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => api.createMemberJoinRequest(request),
          throwsA(
            isA<MemberJoinConflictException>().having(
              (e) => e.field,
              'field',
              MemberJoinConflictField.emailProducer,
            ),
          ),
        );
      },
    );

    test('rethrows DioException on network error', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/public/member-join-requests',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => api.createMemberJoinRequest(request),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('activate', () {
    test(
      'returns ActivationResult with organizationAdmin kind on 200',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/v1/activate'),
            statusCode: 200,
            data: {
              'kind': 'ORGANIZATION_ADMIN',
              'organization_name': 'AMAP des Collines',
              'email': 'admin@example.com',
            },
          ),
        );

        final result = await api.activate(
          token: 'test-token',
          password: 'Secret123',
        );
        expect(result.kind, ActivationKind.organizationAdmin);
        expect(result.organizationName, 'AMAP des Collines');
        expect(result.email, 'admin@example.com');
      },
    );

    test('returns ActivationResult with owner kind when kind=OWNER', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/activate'),
          statusCode: 200,
          data: {'kind': 'OWNER', 'email': 'owner@example.com'},
        ),
      );

      final result = await api.activate(
        token: 'owner-token',
        password: 'Secret123',
      );
      expect(result.kind, ActivationKind.owner);
      expect(result.email, 'owner@example.com');
      expect(result.organizationName, isNull);
    });

    test(
      'returns ActivationResult with producer kind when kind=PRODUCER',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/v1/activate'),
            statusCode: 200,
            data: {
              'kind': 'PRODUCER',
              'organization_name': 'Ferme des Collines',
              'email': 'producer@example.com',
            },
          ),
        );

        final result = await api.activate(
          token: 'producer-token',
          password: 'Secret123',
        );
        expect(result.kind, ActivationKind.producer);
        expect(result.organizationName, 'Ferme des Collines');
        expect(result.email, 'producer@example.com');
      },
    );

    test('throws ActivationException with invalidToken on 404', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/activate'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/activate'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => api.activate(token: 'bad-token', password: 'Secret123'),
        throwsA(
          isA<ActivationException>().having(
            (e) => e.error,
            'error',
            ActivationError.invalidToken,
          ),
        ),
      );
    });

    test('throws ActivationException with alreadyActivated on 409', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/activate'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/activate'),
            statusCode: 409,
            data: {'error': 'ALREADY_ACTIVATED'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => api.activate(token: 'used-token', password: 'Secret123'),
        throwsA(
          isA<ActivationException>().having(
            (e) => e.error,
            'error',
            ActivationError.alreadyActivated,
          ),
        ),
      );
    });

    test('throws ActivationException with expired on 410', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/activate'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/activate'),
            statusCode: 410,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => api.activate(token: 'expired-token', password: 'Secret123'),
        throwsA(
          isA<ActivationException>().having(
            (e) => e.error,
            'error',
            ActivationError.expired,
          ),
        ),
      );
    });

    test('throws serverError on network failure', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/activate'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => api.activate(token: 'token', password: 'Secret123'),
        throwsA(
          isA<ActivationException>().having(
            (e) => e.error,
            'error',
            ActivationError.serverError,
          ),
        ),
      );
    });

    test('throws serverError on 500', () async {
      when(
        () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/activate'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/activate'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => api.activate(token: 'token', password: 'Secret123'),
        throwsA(
          isA<ActivationException>().having(
            (e) => e.error,
            'error',
            ActivationError.serverError,
          ),
        ),
      );
    });
  });
}
