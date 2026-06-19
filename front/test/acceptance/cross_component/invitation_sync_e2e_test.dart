@Tags(['acceptance'])
library;

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
const _bearerToken = String.fromEnvironment('BEARER_TOKEN');
const _organizationId = String.fromEnvironment('ORGANIZATION_ID');

class _StaticTokenAuthService implements AuthService {
  const _StaticTokenAuthService();

  @override
  Stream<AuthState> get authState => Stream.value(
    const AuthState.authenticated(
      producerId: 'cross-component-invitation-sync',
      accessToken: _bearerToken,
    ),
  );

  @override
  AuthState get currentState => const AuthState.authenticated(
    producerId: 'cross-component-invitation-sync',
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
      _backUrl.isEmpty || _bearerToken.isEmpty || _organizationId.isEmpty
      ? 'BACK_URL / BEARER_TOKEN / ORGANIZATION_ID not set'
      : false;

  group('cross-component invitation sync', () {
    late AppDatabase db;
    late SyncRepository syncRepo;
    late MemberInvitationRepository invitationRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      final auth = const _StaticTokenAuthService();
      final dio = buildSyncDio(backendUrl: _backUrl, auth: auth);
      syncRepo = SyncRepository(db: db, api: SyncApi(dio));
      invitationRepo = MemberInvitationRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'creating a member invitation syncs it with a real server id and pending status',
      () async {
        // Per-run unique so repeated runs on the same persistent backend don't
        // conflict with a still-pending invitation from a previous run.
        const email = String.fromEnvironment(
          'INVITE_CREATE_EMAIL',
          defaultValue: 'member-create-invite@test.invalid',
        );
        await invitationRepo.create(
          organizationId: _organizationId,
          email: email,
          firstName: 'Alice',
          lastName: 'Martin',
          roles: const {Role.volunteer},
        );

        final optimistic =
            (await invitationRepo.watch(_organizationId).first).single;
        expect(optimistic.invitationId, startsWith('tmp_'));
        expect(optimistic.status, InvitationStatus.pendingActivation);

        final outcome = await syncRepo.sync(
          tenantId: 'cross-component-invitation-sync',
        );
        expect(outcome, isA<SyncSuccess>());
        expect((outcome as SyncSuccess).rejectedMutations, isEmpty);
        final invitations = await invitationRepo.watch(_organizationId).first;
        final synced = invitations.singleWhere(
          (invitation) => invitation.email == email,
        );
        expect(synced.invitationId, isNot(startsWith('tmp_')));
        expect(synced.invitationId, isNot(equals(optimistic.invitationId)));
        expect(synced.email, email);
        expect(synced.status, InvitationStatus.pendingActivation);
        expect(synced.resendRequestedAt, isNull);
        expect(
          await db.readCursor(organizationScopeKey(_organizationId)),
          isNotNull,
        );
        expect(await db.readPendingMutationEntries(), isEmpty);
      },
      tags: ['cross-component'],
      skip: skip,
    );

    test(
      'resending a synced member invitation keeps it pending and records resendRequestedAt',
      () async {
        // Per-run unique — a resent invitation from a previous run would have
        // non-null resendRequestedAt and break the initial-null assertion.
        const email = String.fromEnvironment(
          'INVITE_RESEND_EMAIL',
          defaultValue: 'member-resend-invite@test.invalid',
        );
        await invitationRepo.create(
          organizationId: _organizationId,
          email: email,
          firstName: 'Bob',
          lastName: 'Durand',
          roles: const {Role.admin},
        );
        final createOutcome = await syncRepo.sync(
          tenantId: 'cross-component-invitation-sync',
        );
        expect(createOutcome, isA<SyncSuccess>());

        final created = (await invitationRepo.watch(_organizationId).first)
            .singleWhere((invitation) => invitation.email == email);
        expect(created.resendRequestedAt, isNull);

        await invitationRepo.resend(
          organizationId: _organizationId,
          invitationId: created.invitationId,
        );
        final locallyUpdated =
            (await invitationRepo.watch(_organizationId).first).singleWhere(
              (invitation) => invitation.email == email,
            );
        expect(locallyUpdated.resendRequestedAt, isNotNull);

        final resendOutcome = await syncRepo.sync(
          tenantId: 'cross-component-invitation-sync',
        );
        expect(resendOutcome, isA<SyncSuccess>());
        expect((resendOutcome as SyncSuccess).rejectedMutations, isEmpty);

        final resent = (await invitationRepo.watch(_organizationId).first)
            .singleWhere((invitation) => invitation.email == email);
        expect(resent.invitationId, created.invitationId);
        expect(resent.status, InvitationStatus.pendingActivation);
        expect(resent.resendRequestedAt, isNotNull);
        expect(await db.readPendingMutationEntries(), isEmpty);
      },
      tags: ['cross-component'],
      skip: skip,
    );

    test(
      'resending with a custom email subject/body is accepted and round-trips the override',
      () async {
        const email = String.fromEnvironment(
          'INVITE_CUSTOM_EMAIL',
          defaultValue: 'member-custom-invite@test.invalid',
        );
        await invitationRepo.create(
          organizationId: _organizationId,
          email: email,
          firstName: 'Carol',
          lastName: 'Petit',
          roles: const {Role.volunteer},
        );
        final createOutcome = await syncRepo.sync(
          tenantId: 'cross-component-invitation-sync',
        );
        expect(createOutcome, isA<SyncSuccess>());

        final created = (await invitationRepo.watch(_organizationId).first)
            .singleWhere((invitation) => invitation.email == email);

        await invitationRepo.resend(
          organizationId: _organizationId,
          invitationId: created.invitationId,
          customEmailSubject: 'Connecte-toi à ton AMAP',
          customEmailBody:
              'Merci de finaliser ton inscription dès que possible.',
        );

        final resendOutcome = await syncRepo.sync(
          tenantId: 'cross-component-invitation-sync',
        );
        expect(resendOutcome, isA<SyncSuccess>());
        expect((resendOutcome as SyncSuccess).rejectedMutations, isEmpty);

        final resent = (await invitationRepo.watch(_organizationId).first)
            .singleWhere((invitation) => invitation.email == email);
        expect(resent.status, InvitationStatus.pendingActivation);
        expect(resent.customEmailSubject, 'Connecte-toi à ton AMAP');
        expect(
          resent.customEmailBody,
          'Merci de finaliser ton inscription dès que possible.',
        );
        expect(await db.readPendingMutationEntries(), isEmpty);
      },
      tags: ['cross-component'],
      skip: skip,
    );
  });
}
