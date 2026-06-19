import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeRequestOptions()));

  late _MockDio dio;
  late AdminApi api;

  setUp(() {
    dio = _MockDio();
    api = AdminApi(dio);
  });

  group('searchProducers', () {
    test('returns decoded list', () async {
      when(
        () => dio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/v1/admin/producer-accounts/search',
          ),
          statusCode: 200,
          data: const [
            {
              'producer_account_id': 'producer-1',
              'name': 'Ferme des Prés',
              'management_mode': 'NO_ACCOUNT',
              'linked_producer_account': {
                'producer_account_id': 'producer-2',
                'name': 'Ferme liée',
              },
            },
          ],
        ),
      );

      final result = await api.searchProducers('ferme');

      expect(result, const [
        ProducerAccount(
          producerAccountId: 'producer-1',
          name: 'Ferme des Prés',
          managementMode: ProducerManagementMode.noAccount,
          linkedProducerAccount: LinkedProducerAccount(
            producerAccountId: 'producer-2',
            name: 'Ferme liée',
          ),
        ),
      ]);
      verify(
        () => dio.get<List<dynamic>>(
          '/v1/admin/producer-accounts/search',
          queryParameters: {'q': 'ferme'},
        ),
      ).called(1);
    });
  });

  group('exportOrganization', () {
    test('returns the raw archive string', () async {
      when(
        () => dio.get<String>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/v1/admin/organizations/org-1/export',
          ),
          statusCode: 200,
          data: '{"format_version":1}',
        ),
      );

      final result = await api.exportOrganization('org-1');

      expect(result, '{"format_version":1}');
      verify(
        () => dio.get<String>(
          '/v1/admin/organizations/org-1/export',
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('importOrganization', () {
    test('posts the archive and returns the result map', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/v1/admin/organizations/org-1/import',
          ),
          statusCode: 200,
          data: const {'organization_id': 'org-1', 'members': 3},
        ),
      );

      final result = await api.importOrganization(
        'org-1',
        '{"format_version":1}',
      );

      expect(result['members'], 3);
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v1/admin/organizations/org-1/import',
          data: '{"format_version":1}',
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('propagates a DioException on conflict', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/admin/organizations/org-1/import',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/v1/admin/organizations/org-1/import',
            ),
            statusCode: 409,
          ),
        ),
      );

      expect(
        () => api.importOrganization('org-1', '{}'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
