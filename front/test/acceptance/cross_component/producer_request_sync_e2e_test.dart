@Tags(['acceptance'])
library;

import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/producer_creation_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
// Producer requests live on the instance-owner scope, which requires OWNER role.
// Use a separate OWNER_BEARER_TOKEN (owner@example.com) for this test.
const _ownerBearerToken = String.fromEnvironment('OWNER_BEARER_TOKEN');
// Per-run unique name and email for the submitted producer request.
// The back checks both producer_name (excluding REJECTED) and admin_email for
// uniqueness, so a previous run leaving a pending/approved request would
// conflict unless both differ across runs.
const _producerRequestName = String.fromEnvironment(
  'PRODUCER_REQUEST_NAME',
  defaultValue: 'Test Producer Request',
);
const _producerRequestEmail = String.fromEnvironment(
  'PRODUCER_REQUEST_EMAIL',
  defaultValue: 'prod-req@test.invalid',
);

class _StaticTokenAuthService implements AuthService {
  const _StaticTokenAuthService();

  @override
  Stream<AuthState> get authState => Stream.value(
    const AuthState.authenticated(
      producerId: 'cross-component-producer-request-sync',
      accessToken: _ownerBearerToken,
    ),
  );

  @override
  AuthState get currentState => const AuthState.authenticated(
    producerId: 'cross-component-producer-request-sync',
    accessToken: _ownerBearerToken,
  );

  @override
  Future<void> bootstrap() async {}

  @override
  Future<String?> currentAccessToken() async => _ownerBearerToken;

  @override
  Future<void> signIn({
    required String email,
    required String password,
    bool? rememberSession,
  }) async {}

  @override
  Future<void> signOut() async {}

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
}

void main() {
  final skip =
      _backUrl.isEmpty ||
          _ownerBearerToken.isEmpty ||
          _producerRequestEmail.isEmpty
      ? 'BACK_URL / OWNER_BEARER_TOKEN / PRODUCER_REQUEST_EMAIL not set'
      : false;

  group('cross-component producer request sync', () {
    late AppDatabase db;
    late SyncRepository syncRepo;
    late ProducerRequestRepository requestRepo;
    late PublicApi publicApi;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      final auth = const _StaticTokenAuthService();
      syncRepo = SyncRepository(
        db: db,
        api: SyncApi(buildSyncDio(backendUrl: _backUrl, auth: auth)),
      );
      requestRepo = ProducerRequestRepository(
        db: db,
        idGenerator: IdGenerator(Random(0)),
      );
      publicApi = PublicApi(buildPublicDio(backendUrl: _backUrl));
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'public submission syncs into owner cache and approval provisions a producer account',
      () async {
        const adminFirstName = 'Jeanne';
        const adminLastName = 'Martin';
        const tenantId = 'cross-component-producer-request-sync';

        final created = await publicApi.createProducerRequest(
          ProducerCreationRequest(
            producerName: _producerRequestName,
            adminFirstName: adminFirstName,
            adminLastName: adminLastName,
            adminEmail: _producerRequestEmail,
          ),
        );
        expect(created.status, 'PENDING_VALIDATION');

        final bootstrapOutcome = await syncRepo.sync(tenantId: tenantId);
        expect(bootstrapOutcome, isA<SyncSuccess>());
        expect((bootstrapOutcome as SyncSuccess).rejectedMutations, isEmpty);

        final pending = (await requestRepo.watch().first).singleWhere(
          (request) => request.adminEmail == _producerRequestEmail,
        );
        expect(pending.producerName, _producerRequestName);
        expect(pending.status, ProducerRequestStatus.pendingValidation);

        await requestRepo.approve(pending);
        expect(await db.readPendingMutations(), hasLength(1));

        final localApproved = (await requestRepo.watch().first).singleWhere(
          (request) => request.adminEmail == _producerRequestEmail,
        );
        expect(localApproved.status, ProducerRequestStatus.approved);
        expect(localApproved.reviewedAt, isNotNull);

        final approvalOutcome = await syncRepo.sync(tenantId: tenantId);
        expect(approvalOutcome, isA<SyncSuccess>());
        expect((approvalOutcome as SyncSuccess).rejectedMutations, isEmpty);

        await db.writeCursor(instanceOwnerScopeKey, null);
        final refreshOutcome = await syncRepo.sync(tenantId: tenantId);
        expect(refreshOutcome, isA<SyncSuccess>());
        expect((refreshOutcome as SyncSuccess).rejectedMutations, isEmpty);

        final approved = (await requestRepo.watch().first).singleWhere(
          (request) => request.adminEmail == _producerRequestEmail,
        );
        expect(approved.status, ProducerRequestStatus.approved);
        expect(approved.reviewedAt, isNotNull);

        final producer = (await db.watchAllProducerAccounts().first)
            .singleWhere(
              (account) => account.contactEmail == _producerRequestEmail,
            );
        expect(producer.name, _producerRequestName);
        expect(producer.contactEmail, _producerRequestEmail);
        expect(producer.activeStatus, isTrue);
        expect(producer.organizations, isEmpty);

        expect(await db.readPendingMutations(), isEmpty);
        expect(await db.readCursor(instanceOwnerScopeKey), isNotNull);
      },
      tags: ['cross-component'],
      skip: skip,
    );
  });
}
