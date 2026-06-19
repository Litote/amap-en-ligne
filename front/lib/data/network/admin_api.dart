import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:dio/dio.dart';

class AdminApi {
  AdminApi(this._dio);

  final Dio _dio;

  Future<List<ProducerAccount>> searchProducers(String query) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/admin/producer-accounts/search',
      queryParameters: {'q': query},
    );
    final body = response.data;
    if (body == null) return [];
    return body
        .cast<Map<String, dynamic>>()
        .map(ProducerAccount.fromJson)
        .toList();
  }

  /// Downloads the native-JSON backup archive of [organizationId] as a raw
  /// string (kept opaque on the client — it is only saved to / read from a file).
  Future<String> exportOrganization(String organizationId) async {
    final response = await _dio.get<String>(
      '/v1/admin/organizations/$organizationId/export',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  /// Restores a native-JSON backup archive into [organizationId].
  /// Returns the server's `ImportResult` summary as a map.
  Future<Map<String, dynamic>> importOrganization(
    String organizationId,
    String archiveJson,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/admin/organizations/$organizationId/import',
      data: archiveJson,
      options: Options(contentType: Headers.jsonContentType),
    );
    return response.data ?? <String, dynamic>{};
  }
}
