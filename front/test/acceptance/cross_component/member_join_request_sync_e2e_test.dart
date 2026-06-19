@Tags(['acceptance'])
library;

import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member_join_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
const _bearerToken = String.fromEnvironment('BEARER_TOKEN');
const _organizationId = String.fromEnvironment('ORGANIZATION_ID');
const _requesterEmail = String.fromEnvironment('REQUESTER_EMAIL');

class _StaticTokenAuthService implements AuthService {
  const _StaticTokenAuthService();

  @override
  Stream<AuthState> get authState => Stream.value(
    AuthState.authenticated(
      producerId: _organizationId,
      accessToken: _bearerToken,
    ),
  );

  @override
  AuthState get currentState => AuthState.authenticated(
    producerId: _organizationId,
    accessToken: _bearerToken,
  );

  @override
  Future<void> bootstrap() async {}

  @override
  Future<String?> currentAccessToken() async => _bearerToken;

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
          _bearerToken.isEmpty ||
          _organizationId.isEmpty ||
          _requesterEmail.isEmpty
      ? 'BACK_URL / BEARER_TOKEN / ORGANIZATION_ID / REQUESTER_EMAIL not set'
      : false;

  group('cross-component member join request sync', () {
    late AppDatabase db;
    late SyncRepository syncRepo;
    late MemberJoinRequestRepository requestRepo;
    late PublicApi publicApi;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      final auth = const _StaticTokenAuthService();
      syncRepo = SyncRepository(
        db: db,
        api: SyncApi(buildSyncDio(backendUrl: _backUrl, auth: auth)),
      );
      requestRepo = MemberJoinRequestRepository(
        db: db,
        idGenerator: IdGenerator(Random(0)),
      );
      publicApi = PublicApi(buildPublicDio(backendUrl: _backUrl));
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'public submission, sync approval, and pending member data all happen end-to-end',
      () async {
        const firstName = 'Jean';
        const lastName = 'Dupont';

        final created = await publicApi.createMemberJoinRequest(
          MemberJoinRequest(
            organizationId: _organizationId,
            email: _requesterEmail,
            firstName: firstName,
            lastName: lastName,
          ),
        );
        expect(created.status, 'PENDING');

        final bootstrapOutcome = await syncRepo.sync(tenantId: _organizationId);
        expect(bootstrapOutcome, isA<SyncSuccess>());
        expect((bootstrapOutcome as SyncSuccess).rejectedMutations, isEmpty);

        // A persistent backend accumulates requests from previous runs; find ours.
        final allRequests = await requestRepo.watch(_organizationId).first;
        final request = allRequests.singleWhere(
          (r) => r.email == _requesterEmail,
        );
        expect(request.status, MemberJoinRequestStatus.pending);

        await requestRepo.approve(request);
        expect(await db.readPendingMutations(), hasLength(1));

        // The local list contains all requests for the org from the bootstrap.
        final localBeforeSync = await requestRepo.watch(_organizationId).first;
        final localRequest = localBeforeSync.singleWhere(
          (r) => r.email == _requesterEmail,
        );
        expect(localRequest.status, MemberJoinRequestStatus.pending);

        final approvalOutcome = await syncRepo.sync(tenantId: _organizationId);
        expect(approvalOutcome, isA<SyncSuccess>());
        expect((approvalOutcome as SyncSuccess).rejectedMutations, isEmpty);

        final reviewedRequests = await requestRepo.watch(_organizationId).first;
        final approved = reviewedRequests.singleWhere(
          (r) => r.email == _requesterEmail,
        );
        expect(approved.status, MemberJoinRequestStatus.approved);
        expect(approved.reviewedAt, isNotNull);

        final invitations = await db
            .watchMemberInvitations(_organizationId)
            .first;
        final invitation = invitations.singleWhere(
          (i) => i.email == _requesterEmail,
        );
        expect(invitation.firstName, firstName);
        expect(invitation.lastName, lastName);
        expect(invitation.status, InvitationStatus.pendingActivation);
        expect(invitation.resendRequestedAt, isNull);

        expect(await db.readPendingMutations(), isEmpty);
        expect(
          await db.readCursor(organizationScopeKey(_organizationId)),
          isNotNull,
        );
      },
      tags: ['cross-component'],
      skip: skip,
    );
  });
}
