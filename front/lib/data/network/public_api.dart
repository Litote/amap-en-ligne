import 'package:amap_en_ligne/domain/model/member_join_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/organization_request_response.dart';
import 'package:amap_en_ligne/domain/model/producer_creation_request.dart';
import 'package:amap_en_ligne/domain/model/producer_request_response.dart';
import 'package:amap_en_ligne/domain/model/public_organization.dart';
import 'package:dio/dio.dart';

const _emptyBodyError = FormatException('Empty body');

/// Client for the unauthenticated public endpoints.
///
/// [backendUrl] is the base URL of the target instance.
/// No auth interceptor — these endpoints are open.
Dio buildPublicDio({required String backendUrl}) => Dio(
  BaseOptions(
    baseUrl: backendUrl,
    headers: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ),
);

class PublicApi {
  PublicApi(this._dio);

  final Dio _dio;

  Future<List<PublicOrganization>> listOrganizations() async {
    final response = await _dio.get<List<dynamic>>('/v1/public/organizations');
    final body = response.data;
    if (body == null) return [];
    return body
        .cast<Map<String, dynamic>>()
        .map(PublicOrganization.fromJson)
        .toList();
  }

  /// Returns [OrganizationRequestResponse] on success (201).
  /// Throws [OrganizationConflictException] on 409.
  Future<OrganizationRequestResponse> createOrganizationRequest(
    OrganizationCreationRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/organization-requests',
        data: request.toJson(),
      );
      final body = response.data;
      if (body == null) throw _emptyBodyError;
      return OrganizationRequestResponse.fromJson(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final details =
            ((e.response?.data as Map<String, dynamic>?)?['error']
                    as Map<String, dynamic>?)?['details']
                as Map<String, dynamic>?;
        final field = details?['field'] as String?;
        final existingStatus = details?['existing_status'] as String?;
        throw OrganizationConflictException(
          _parseConflictField(field),
          existingStatus: existingStatus,
        );
      }
      rethrow;
    }
  }

  /// Returns [ProducerRequestResponse] on success (201).
  /// Throws [ProducerConflictException] on 409.
  Future<ProducerRequestResponse> createProducerRequest(
    ProducerCreationRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/producer-requests',
        data: request.toJson(),
      );
      final body = response.data;
      if (body == null) throw _emptyBodyError;
      return ProducerRequestResponse.fromJson(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final details =
            ((e.response?.data as Map<String, dynamic>?)?['error']
                    as Map<String, dynamic>?)?['details']
                as Map<String, dynamic>?;
        final field = details?['field'] as String?;
        final existingStatus = details?['existing_status'] as String?;
        throw ProducerConflictException(
          _parseProducerConflictField(field),
          existingStatus: existingStatus,
        );
      }
      rethrow;
    }
  }

  /// Returns [MemberJoinRequestResponse] on success (201).
  /// Throws [MemberJoinConflictException] on 409.
  Future<MemberJoinRequestResponse> createMemberJoinRequest(
    MemberJoinRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/public/member-join-requests',
        data: request.toJson(),
      );
      final body = response.data;
      if (body == null) throw _emptyBodyError;
      return MemberJoinRequestResponse.fromJson(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final details =
            ((e.response?.data as Map<String, dynamic>?)?['error']
                    as Map<String, dynamic>?)?['details']
                as Map<String, dynamic>?;
        final field = details?['field'] as String?;
        throw MemberJoinConflictException(switch (field) {
          'email' => MemberJoinConflictField.email,
          'email_member' => MemberJoinConflictField.emailMember,
          'email_owner' => MemberJoinConflictField.emailOwner,
          'email_producer' => MemberJoinConflictField.emailProducer,
          _ => MemberJoinConflictField.unknown,
        });
      }
      rethrow;
    }
  }

  /// Describes the account an activation [token] is about to activate
  /// (email, kind, organization / producer name) without activating it.
  /// Throws [ActivationException] on 404, 409, or 410.
  Future<ActivationResult> describeActivation(String token) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/activate',
        queryParameters: {'token': token},
      );
      final body = response.data;
      if (body == null) throw _emptyBodyError;
      return _parseActivationResult(body);
    } on DioException catch (e) {
      throw ActivationException(_activationErrorOf(e));
    }
  }

  /// Activates an account using the token from the activation email.
  /// Returns the organization name and email on success.
  /// Throws [ActivationException] on 400 (weak password), 404, 409, or 410.
  Future<ActivationResult> activate({
    required String token,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/activate',
        data: {'token': token, 'password': password},
      );
      final body = response.data;
      if (body == null) throw _emptyBodyError;
      return _parseActivationResult(body);
    } on DioException catch (e) {
      throw ActivationException(_activationErrorOf(e));
    }
  }

  static ActivationResult _parseActivationResult(Map<String, dynamic> body) {
    final kind = switch (body['kind'] as String?) {
      'OWNER' => ActivationKind.owner,
      'PRODUCER' => ActivationKind.producer,
      _ => ActivationKind.organizationAdmin,
    };
    return ActivationResult(
      kind: kind,
      email: body['email'] as String,
      organizationName: body['organization_name'] as String?,
    );
  }

  static ActivationError _activationErrorOf(DioException e) {
    final response = e.response;
    switch (response?.statusCode) {
      case 400:
        final data = response?.data;
        final error = data is Map ? data['error'] : null;
        final code = error is Map ? error['code'] : null;
        return code == 'WEAK_PASSWORD'
            ? ActivationError.weakPassword
            : ActivationError.serverError;
      case 404:
        return ActivationError.invalidToken;
      case 409:
        return ActivationError.alreadyActivated;
      case 410:
        return ActivationError.expired;
      default:
        return ActivationError.serverError;
    }
  }

  static OrganizationConflictField _parseConflictField(String? field) {
    switch (field) {
      case 'organization_name':
        return OrganizationConflictField.organizationName;
      case 'admin_email':
        return OrganizationConflictField.adminEmail;
      default:
        return OrganizationConflictField.unknown;
    }
  }

  static ProducerConflictField _parseProducerConflictField(String? field) {
    switch (field) {
      case 'producer_name':
        return ProducerConflictField.producerName;
      case 'admin_email':
        return ProducerConflictField.adminEmail;
      default:
        return ProducerConflictField.unknown;
    }
  }
}

class OrganizationConflictException implements Exception {
  const OrganizationConflictException(this.field, {this.existingStatus});
  final OrganizationConflictField field;
  final String? existingStatus;
}

class ProducerConflictException implements Exception {
  const ProducerConflictException(this.field, {this.existingStatus});
  final ProducerConflictField field;
  final String? existingStatus;
}

// ---------------------------------------------------------------------------
// Activation
// ---------------------------------------------------------------------------

/// Discriminator for the activation flow that produced this token.
///
/// Mirrors back `ActivationKind` enum.
enum ActivationKind {
  /// Org-request approval flow — the new user becomes the organisation admin.
  organizationAdmin,

  /// Owner invitation flow — the new user becomes an instance-level Owner.
  owner,

  /// Producer-request approval flow — the new user becomes a producer admin.
  producer,
}

class ActivationResult {
  const ActivationResult({
    required this.kind,
    required this.email,
    this.organizationName,
  });

  final ActivationKind kind;
  final String email;

  /// Non-null for organization / producer activations, null for owner.
  final String? organizationName;
}

enum ActivationError {
  invalidToken,
  expired,
  alreadyActivated,

  /// The server rejected the password against the instance policy.
  weakPassword,
  serverError,
}

class ActivationException implements Exception {
  const ActivationException(this.error);
  final ActivationError error;
}
