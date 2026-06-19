@Tags(['acceptance'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/organization_request_response.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_state.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_event.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_bloc.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_event.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_state.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final story = _loadStory('organization-request-creation');

  test('${story.title} [${story.id}]', () async {
    // === Step 1: requester submits an organization creation request ===
    final publicApi = _ScriptedPublicApi([
      const OrganizationRequestResponse(
        requestId: 'req-1',
        status: 'PENDING_VALIDATION',
      ),
    ]);

    final creationBloc = OrganizationCreationBloc(publicApi: publicApi);

    final creationSuccessFuture = creationBloc.stream
        .where((s) => s is OrganizationCreationSuccess)
        .cast<OrganizationCreationSuccess>()
        .first;

    creationBloc.add(
      const OrganizationCreationSubmitted(
        organizationName: 'AMAP des Collines',
        timezone: 'Europe/Paris',
        defaultLanguage: 'fr',
        adminFirstName: 'Alice',
        adminLastName: 'Martin',
        adminEmail: 'alice@collines.fr',
        organizationType: OrganizationType.amap,
      ),
    );

    final creationSuccess = await creationSuccessFuture;
    expect(creationSuccess.response.requestId, 'req-1');
    expect(creationSuccess.response.status, 'PENDING_VALIDATION');
    await creationBloc.close();
    publicApi.assertDrained();

    // === Step 2: owner approves the request via the offline-first repository ===
    const submittedAt = '2026-05-07T10:00:00Z';

    final pendingRequest = AdminOrganizationRequest(
      requestId: 'req-1',
      organizationName: 'AMAP des Collines',
      timezone: 'Europe/Paris',
      defaultLanguage: 'fr',
      adminFirstName: 'Alice',
      adminLastName: 'Martin',
      adminEmail: 'alice@collines.fr',
      status: OrganizationRequestStatus.pendingValidation,
      submittedAt: submittedAt,
    );

    final db = AppDatabase(NativeDatabase.memory());
    final repo = OrganizationRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );

    // Seed the local cache as if a sync had just populated it.
    await db.upsertOrganizationRequest(pendingRequest);

    final adminBloc = AdminRequestsBloc(organizationRequestRepository: repo);

    final loadedFuture = adminBloc.stream
        .where((s) => s is AdminRequestsLoaded)
        .cast<AdminRequestsLoaded>()
        .first;
    adminBloc.add(const AdminRequestsEvent.loadRequested());
    final loadedState = await loadedFuture;

    expect(
      loadedState.requests.any(
        (r) => r.status == OrganizationRequestStatus.pendingValidation,
      ),
      isTrue,
    );

    // Approve: optimistic update reflected in the Drift stream.
    final approvedStateFuture = adminBloc.stream
        .where((s) => s is AdminRequestsLoaded)
        .cast<AdminRequestsLoaded>()
        .where(
          (s) => s.requests.any(
            (r) => r.status == OrganizationRequestStatus.approved,
          ),
        )
        .first;

    adminBloc.add(AdminRequestsEvent.approveRequested(pendingRequest));
    final approvedState = await approvedStateFuture;

    expect(
      approvedState.requests.single.status,
      OrganizationRequestStatus.approved,
    );
    expect(approvedState.requests.single.requestId, 'req-1');

    // Verify the pending mutation was enqueued.
    final pending = await db.readPendingMutations();
    expect(pending.length, 1);

    await adminBloc.close();
    await db.close();

    // === Step 3: new admin authenticates ===
    final authService = _ScriptedAuthService();
    final authDb = AppDatabase(NativeDatabase.memory());
    final authBloc = AuthBloc(service: authService, db: authDb);

    final bootstrappedFuture = authBloc.stream.firstWhere(
      (s) => !s.initializing,
    );
    await bootstrappedFuture;

    final authenticatedFuture = authBloc.stream.firstWhere(
      (s) => s.producerId != null,
    );

    authBloc.add(
      const AuthLoginSubmitted(
        email: 'alice@collines.fr',
        password: 'activation-password',
        rememberMe: true,
      ),
    );

    final authenticatedState = await authenticatedFuture;
    expect(authenticatedState.producerId, isNotNull);
    expect(authenticatedState.submitting, isFalse);

    await authBloc.close();
    await authDb.close();
    await authService.dispose();
  });
}

// ── Scripted PublicApi ────────────────────────────────────────────────────────

class _ScriptedPublicApi extends PublicApi {
  _ScriptedPublicApi(Iterable<OrganizationRequestResponse> responses)
    : _responses = responses.toList(),
      super(Dio());

  final List<OrganizationRequestResponse> _responses;

  @override
  Future<OrganizationRequestResponse> createOrganizationRequest(
    OrganizationCreationRequest request,
  ) async {
    expect(
      _responses,
      isNotEmpty,
      reason: 'Unexpected createOrganizationRequest call',
    );
    return _responses.removeAt(0);
  }

  void assertDrained() {
    expect(
      _responses,
      isEmpty,
      reason: 'Unconsumed scripted PublicApi responses remain.',
    );
  }
}

// ── Scripted AuthService ──────────────────────────────────────────────────────

class _ScriptedAuthService implements AuthService {
  final _controller = StreamController<AuthState>.broadcast();
  AuthState _state = const AuthState.unauthenticated();

  @override
  Stream<AuthState> get authState => _controller.stream;

  @override
  AuthState get currentState => _state;

  @override
  Future<void> bootstrap() async {
    _state = const AuthState.unauthenticated();
    _controller.add(_state);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
    bool? rememberSession,
  }) async {
    _state = const AuthState.authenticated(
      producerId: 'new-admin-account-id',
      accessToken: 'scripted-access-token',
    );
    _controller.add(_state);
  }

  @override
  Future<void> signOut() async {
    _state = const AuthState.unauthenticated();
    _controller.add(_state);
  }

  @override
  Future<String?> currentAccessToken() async => switch (_state) {
    Authenticated(:final accessToken) => accessToken,
    Unauthenticated() => null,
  };

  @override
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  }) async {}

  @override
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<void> signInWithSession({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    bool? rememberSession,
  }) async {}

  @override
  Future<void> refreshSession() async {}

  Future<void> dispose() => _controller.close();
}

// ── Story loader ──────────────────────────────────────────────────────────────

class _AcceptanceStory {
  const _AcceptanceStory({required this.id, required this.title});
  final String id;
  final String title;
}

_AcceptanceStory _loadStory(String id) {
  final uri = Directory.current.uri.resolve('../acceptance/scenarios/$id.json');
  final content = File.fromUri(uri).readAsStringSync();
  final json = jsonDecode(content) as Map<String, Object?>;
  return _AcceptanceStory(
    id: json['id']! as String,
    title: json['title']! as String,
  );
}
