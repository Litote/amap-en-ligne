import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRequestOptions());
  });

  late _MockDio dio;
  late SyncApi api;

  setUp(() {
    dio = _MockDio();
    api = SyncApi(dio);
  });

  test('POSTs to /v1/sync and decodes the response', () async {
    when(
      () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/v1/sync'),
        statusCode: 200,
        data: {
          'authorized_scopes': ['producer-account:producer-1'],
          'results': {
            'producer-account:producer-1': {
              'mode': 'bootstrap',
              'items': <Map<String, Object?>>[],
              'next_cursor': 'c1',
            },
          },
          'mutations': <Map<String, Object?>>[],
        },
      ),
    );

    final response = await api.sync(
      const SyncRequest(cursors: {'producer-account:producer-1': 'c0'}),
    );

    expect(response.authorizedScopes, ['producer-account:producer-1']);
    expect(
      response.results['producer-account:producer-1'],
      isA<BootstrapScopeSyncResult>(),
    );
    final captured = verify(
      () => dio.post<Map<String, dynamic>>(
        captureAny(),
        data: captureAny(named: 'data'),
      ),
    ).captured;
    expect(captured[0], '/v1/sync');
    expect((captured[1] as Map<String, dynamic>)['cursors'], {
      'producer-account:producer-1': 'c0',
    });
  });

  test('propagates DioException on network failure', () async {
    when(
      () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '/v1/sync')));

    expect(() => api.sync(const SyncRequest()), throwsA(isA<DioException>()));
  });

  test('throws FormatException when the body is empty', () async {
    when(
      () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/v1/sync'),
        statusCode: 200,
      ),
    );

    expect(
      () => api.sync(const SyncRequest()),
      throwsA(isA<FormatException>()),
    );
  });
}
