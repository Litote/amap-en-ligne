@Tags(['acceptance', 'cross-component'])
library;

import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/gotrue_auth_service.dart';
import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

const _backUrl = String.fromEnvironment('BACK_URL');
const _gotrueUrl = String.fromEnvironment('GOTRUE_URL');
const _mailhogUrl = String.fromEnvironment('MAILHOG_URL');
const _ownerEmail = String.fromEnvironment('OWNER_EMAIL');
const _adminEmail = String.fromEnvironment('ADMIN_EMAIL');
const _adminPassword = String.fromEnvironment('ADMIN_PASSWORD');

void main() {
  final skip = _backUrl.isEmpty || _gotrueUrl.isEmpty
      ? 'BACK_URL / GOTRUE_URL not set'
      : false;

  group('organization admin activation E2E', () {
    late GoTrueAuthService authService;
    late GoTrueAuthService ownerAuthService;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SharedPreferencesAuthTokenStorage(prefs: prefs);
      final authDio = buildAuthDio(baseUrl: _gotrueUrl);
      authService = GoTrueAuthService(dio: authDio, storage: storage);
      ownerAuthService = GoTrueAuthService(dio: authDio, storage: storage);
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'GIVEN organization request WHEN approved and admin activates THEN admin can login and sync succeeds',
      () async {
        // 1. Owner is already logged in (created by Kotlin test setup)
        await ownerAuthService.signIn(
          email: _ownerEmail,
          password: 'Owner123!',
        );

        // 2. Submit organization request (public — no auth)
        final publicDio = http.Client();
        final orgRequestBody = {
          'organization_name':
              'AMAP Test E2E ${DateTime.now().millisecondsSinceEpoch}',
          'organization_type': 'AMAP',
          'timezone': 'Europe/Paris',
          'default_language': 'fr',
          'admin_first_name': 'Alice',
          'admin_last_name': 'Martin',
          'admin_email': _adminEmail,
        };
        final submitResponse = await publicDio.post(
          Uri.parse('$_backUrl/v1/organization-requests'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(orgRequestBody),
        );
        expect(submitResponse.statusCode, 201);
        final submitData =
            jsonDecode(submitResponse.body) as Map<String, dynamic>;
        final requestId = submitData['request_id'] as String;

        // 3. Approve the request as owner via the real sync machinery.
        // The owner bootstraps the instance-owner scope so the server-populated
        // request lands in the local cache, then flips it to APPROVED and syncs
        // the mutation back. Hand-building the SyncRequest JSON is fragile (the
        // wire shape is a discriminated MutationOp wrapping a full payload).
        final ownerAccountId =
            (ownerAuthService.currentState as dynamic).producerId as String;
        final ownerDb = AppDatabase(NativeDatabase.memory());
        final ownerSyncRepo = SyncRepository(
          db: ownerDb,
          api: SyncApi(
            buildSyncDio(backendUrl: _backUrl, auth: ownerAuthService),
          ),
        );
        final requestRepo = OrganizationRequestRepository(
          db: ownerDb,
          idGenerator: IdGenerator(Random(0)),
        );

        final ownerBootstrap = await ownerSyncRepo.sync(
          tenantId: ownerAccountId,
        );
        expect(ownerBootstrap, isA<SyncSuccess>());

        final pendingRequest = (await requestRepo.watch().first).singleWhere(
          (request) => request.requestId == requestId,
        );
        await requestRepo.approve(pendingRequest);

        final approval = await ownerSyncRepo.sync(tenantId: ownerAccountId);
        expect(approval, isA<SyncSuccess>());
        expect((approval as SyncSuccess).rejectedMutations, isEmpty);
        await ownerDb.close();

        // 4. Extract activation token from MailHog
        final activationToken = await _extractActivationToken(_adminEmail);
        expect(
          activationToken,
          isNotEmpty,
          reason: 'Activation token should be in MailHog',
        );

        // 5. Activate the admin account
        final activateBody = {
          'token': activationToken,
          'password': _adminPassword,
        };
        final activateResponse = await publicDio.post(
          Uri.parse('$_backUrl/v1/activate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(activateBody),
        );
        expect(activateResponse.statusCode, 200);
        final activateData =
            jsonDecode(activateResponse.body) as Map<String, dynamic>;
        expect(activateData['kind'], 'ORGANIZATION_ADMIN');

        // 6. Sign in with the activated admin credentials
        await authService.signIn(email: _adminEmail, password: _adminPassword);
        final state = authService.currentState;
        expect(state, isA<dynamic>()); // Should be Authenticated
        expect((state as dynamic).accessToken, isNotEmpty);

        // 7. Verify sync works (the real test — 403 if ADMIN role is missing)
        final syncDio = buildSyncDio(backendUrl: _backUrl, auth: authService);
        final syncRepo = SyncRepository(db: db, api: SyncApi(syncDio));
        final adminAccountId = (authService.currentState as dynamic).producerId;

        final outcome = await syncRepo.sync(tenantId: adminAccountId);
        expect(
          outcome,
          isA<SyncSuccess>(),
          reason: 'Sync should succeed with ADMIN role assigned',
        );
      },
      tags: ['cross-component'],
      skip: skip,
    );
  });
}

/// Extracts the activation token from MailHog by retrieving the latest email
/// sent to the given [email] address and parsing the activation link.
Future<String> _extractActivationToken(String email) async {
  // Poll MailHog until the email arrives. The activation email is delivered
  // out-of-band by the back's poll loop, so allow generous headroom (~15s).
  for (int i = 0; i < 75; i++) {
    final response = await http.get(Uri.parse('$_mailhogUrl/api/v2/messages'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final messages =
          (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      // Find the latest message to our admin email
      for (final msg in messages.reversed) {
        final to =
            (msg['To'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        final toEmails = to.map((t) => t['Mailbox'] as String?).toList();

        if (toEmails.contains(email.split('@')[0])) {
          // Plain-text emails land in Content.Body; multipart ones in MIME.Parts.
          final body =
              (msg['Content']?['Body'] as String?) ??
              (msg['MIME']?['Parts']?[0]?['Body'] as String?);
          if (body != null) {
            // Be lenient about quoted-printable soft breaks / `=3D` encoding.
            final decoded = body
                .replaceAll('=\r\n', '')
                .replaceAll('=\n', '')
                .replaceAll('=3D', '=');
            // Extract token from URL: ...activate?token=...
            final match = RegExp(r'token=([a-fA-F0-9\-]+)').firstMatch(decoded);
            if (match != null) {
              return match.group(1)!;
            }
          }
        }
      }
    }

    // Wait before retrying
    await Future.delayed(const Duration(milliseconds: 200));
  }

  throw Exception('Activation token not found in MailHog for $email');
}
