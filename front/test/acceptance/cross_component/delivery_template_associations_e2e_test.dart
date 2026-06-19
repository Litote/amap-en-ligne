@Tags(['acceptance'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_associations.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
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
      producerId: _organizationId,
      accessToken: _bearerToken,
    ),
  );

  @override
  AuthState get currentState => const AuthState.authenticated(
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
  final story = _loadStory('delivery-template-association-blocks-delete');
  final shouldSkip =
      _backUrl.isEmpty || _bearerToken.isEmpty || _organizationId.isEmpty;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('cross-component delivery template associations', () {
    test(
      '${story.title} [${story.id}]',
      () async {
        final writeDb = AppDatabase(NativeDatabase.memory());
        addTearDown(writeDb.close);

        final syncRepo = _buildSyncRepository(writeDb);
        final templateRepo = DeliveryTemplateRepository(
          db: writeDb,
          idGenerator: IdGenerator(Random(0)),
        );
        final organizationRepo = OrganizationRepository(
          db: writeDb,
          idGenerator: IdGenerator(Random(1)),
        );

        final bootstrapOutcome = await syncRepo.sync(tenantId: _organizationId);
        expect(bootstrapOutcome, isA<SyncSuccess>());
        expect((bootstrapOutcome as SyncSuccess).rejectedMutations, isEmpty);

        // Snapshot pre-existing template IDs so we can identify the new one by diff.
        // NOTE: the server stores delivery templates with their tmp_ IDs unchanged
        // (no server-side ID reallocation), so the "before" snapshot may include
        // tmp_ IDs from previous test runs. We use the diff — not a tmp_ prefix
        // filter — to find our newly created template.
        final preCreateTemplateIds =
            (await templateRepo.watch(_organizationId).first)
                .map((t) => t.deliveryTemplateId)
                .toSet();

        const draftTemplate = DeliveryTemplate(
          deliveryTemplateId: 'draft-template',
          organizationId: _organizationId,
          name: 'Marché du soir',
          standardStartTime: '18:00',
          standardEndTime: '20:00',
        );
        await templateRepo.create(draftTemplate);

        // Our newly created template is the one ID not in the pre-create snapshot.
        final postLocalCreateIds =
            (await templateRepo.watch(_organizationId).first)
                .map((t) => t.deliveryTemplateId)
                .toSet();
        final optimisticTemplateId = postLocalCreateIds
            .difference(preCreateTemplateIds)
            .single;
        final optimisticTemplate =
            (await templateRepo.watch(_organizationId).first).singleWhere(
              (t) => t.deliveryTemplateId == optimisticTemplateId,
            );
        expect(optimisticTemplate.deliveryTemplateId, startsWith('tmp_'));

        final createTemplateOutcome = await syncRepo.sync(
          tenantId: _organizationId,
        );
        expect(createTemplateOutcome, isA<SyncSuccess>());
        expect(
          (createTemplateOutcome as SyncSuccess).rejectedMutations,
          isEmpty,
        );

        // The server stores delivery templates with the tmp_ ID unchanged.
        // After sync our template still has the same ID.
        final syncedTemplate = (await templateRepo.watch(_organizationId).first)
            .singleWhere((t) => t.deliveryTemplateId == optimisticTemplateId);
        final syncedTemplateId = syncedTemplate.deliveryTemplateId;
        expect(await writeDb.readPendingMutationEntries(), isEmpty);

        final currentOrg = (await organizationRepo
            .watch(_organizationId)
            .first)!;
        // Fixed delivery ID — on a persistent backend the server will upsert
        // (update) any existing delivery with this ID rather than create a duplicate.
        const deliveryId = 'delivery-template-linked';
        final delivery = Delivery(
          deliveryId: deliveryId,
          organizationId: _organizationId,
          scheduledDate: '2030-06-14T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 2,
          deliveryTemplateId: syncedTemplate.deliveryTemplateId,
        );
        // Remove any pre-existing delivery with the same ID (from a previous run)
        // before appending the new one — prevents the date-uniqueness conflict.
        final currentOrgWithoutLinked = currentOrg.copyWith(
          deliveries: currentOrg.deliveries
              .where((d) => d.deliveryId != deliveryId)
              .toList(),
        );
        await organizationRepo.addDelivery(
          currentOrg: currentOrgWithoutLinked,
          delivery: delivery,
        );

        final addDeliveryOutcome = await syncRepo.sync(
          tenantId: _organizationId,
        );
        expect(addDeliveryOutcome, isA<SyncSuccess>());
        expect((addDeliveryOutcome as SyncSuccess).rejectedMutations, isEmpty);
        expect(await writeDb.readPendingMutationEntries(), isEmpty);

        final readDb = AppDatabase(NativeDatabase.memory());
        addTearDown(readDb.close);

        final readSyncRepo = _buildSyncRepository(readDb);
        final readTemplateRepo = DeliveryTemplateRepository(
          db: readDb,
          idGenerator: IdGenerator(Random(2)),
        );
        final readOrganizationRepo = OrganizationRepository(
          db: readDb,
          idGenerator: IdGenerator(Random(3)),
        );

        final refreshOutcome = await readSyncRepo.sync(
          tenantId: _organizationId,
        );
        expect(refreshOutcome, isA<SyncSuccess>());
        expect((refreshOutcome as SyncSuccess).rejectedMutations, isEmpty);

        final syncedOrg = (await readOrganizationRepo
            .watch(_organizationId)
            .first)!;
        // Find by known delivery ID — do not assert total delivery count; other
        // deliveries from prior runs may exist on a persistent backend.
        final linkedDelivery = syncedOrg.deliveries.singleWhere(
          (d) => d.deliveryId == deliveryId,
        );
        expect(
          linkedDelivery.deliveryTemplateId,
          syncedTemplate.deliveryTemplateId,
        );
        expect(
          await readDb.readCursor(organizationScopeKey(_organizationId)),
          isNotNull,
        );
        expect(await readDb.readPendingMutationEntries(), isEmpty);
        // Find our template by ID — do not assert total template count.
        final readSyncedTemplate =
            (await readTemplateRepo.watch(_organizationId).first).singleWhere(
              (t) => t.deliveryTemplateId == syncedTemplateId,
            );
        expect(
          readSyncedTemplate.deliveryTemplateId,
          syncedTemplate.deliveryTemplateId,
        );

        final associations = computeDeliveryTemplateAssociations(
          syncedOrg,
          syncedTemplate.deliveryTemplateId,
          now: DateTime.parse('2029-01-01T00:00:00Z'),
        );
        expect(associations.associationCount, 1);
        expect(associations.associatedDeliveries.single.deliveryId, deliveryId);
        expect(
          associations.futureAssociatedDeliveries.single.deliveryId,
          deliveryId,
        );
      },
      tags: ['cross-component'],
      skip: shouldSkip,
    );
  });
}

SyncRepository _buildSyncRepository(AppDatabase db) {
  final auth = const _StaticTokenAuthService();
  return SyncRepository(
    db: db,
    api: SyncApi(buildSyncDio(backendUrl: _backUrl, auth: auth)),
  );
}

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
