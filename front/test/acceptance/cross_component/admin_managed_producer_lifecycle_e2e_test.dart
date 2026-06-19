@Tags(['acceptance'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
const _bearerToken = String.fromEnvironment('BEARER_TOKEN');
const _organizationId = String.fromEnvironment('ORGANIZATION_ID');
const _noAccountName = String.fromEnvironment('NO_ACCOUNT_NAME');
const _noAccountEmail = String.fromEnvironment('NO_ACCOUNT_EMAIL');
// Unique per run to avoid server-side duplicate-delivery constraint.
const _testDeliveryDate = String.fromEnvironment(
  'TEST_DELIVERY_DATE',
  defaultValue: '2030-01-15T17:30:00',
);

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
  final story = _loadStory('admin-managed-producer-lifecycle');
  final shouldSkip =
      _backUrl.isEmpty ||
          _bearerToken.isEmpty ||
          _organizationId.isEmpty ||
          _noAccountName.isEmpty ||
          _noAccountEmail.isEmpty
      ? 'BACK_URL / BEARER_TOKEN / ORGANIZATION_ID / NO_ACCOUNT_NAME / NO_ACCOUNT_EMAIL not set'
      : false;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('cross-component admin-managed producer lifecycle', () {
    test(
      '${story.title} [${story.id}]',
      () async {
        final createDb = AppDatabase(NativeDatabase.memory());
        addTearDown(createDb.close);
        final createSyncRepo = _buildSyncRepository(createDb);
        final createOrgRepo = OrganizationRepository(
          db: createDb,
          idGenerator: IdGenerator(Random(0)),
        );

        final bootstrapOutcome = await createSyncRepo.sync(
          tenantId: _organizationId,
        );
        expect(bootstrapOutcome, isA<SyncSuccess>());
        expect((bootstrapOutcome as SyncSuccess).rejectedMutations, isEmpty);

        // Snapshot IDs after bootstrap so we can diff after the creation sync
        // to find the server-allocated ID without relying on email uniqueness.
        final preCreateIds = (await createDb.watchAllProducerAccounts().first)
            .map((p) => p.producerAccountId)
            .toSet();

        final bootstrapOrg = (await createOrgRepo
            .watch(_organizationId)
            .first)!;
        final createdDraft = await createOrgRepo.createNoAccountProducer(
          currentOrg: bootstrapOrg,
          name: _noAccountName,
          contactEmail: _noAccountEmail,
          products: const [
            ProducerProduct(
              name: 'Pommes',
              productTypeId: 'tmp_product_pommes',
              supportedBasketSizes: [
                BasketSize(name: '1 kg'),
                BasketSize(name: '2 kg'),
              ],
            ),
            ProducerProduct(
              name: 'Jus de pomme',
              productTypeId: 'tmp_product_jus',
              supportedBasketSizes: [BasketSize(name: 'Bouteille 1L')],
            ),
          ],
        );
        expect(createdDraft.producerAccountId, startsWith('tmp_'));
        expect(createdDraft.managementMode, ProducerManagementMode.noAccount);
        expect(await createDb.readPendingMutationEntries(), hasLength(2));

        final createOutcome = await createSyncRepo.sync(
          tenantId: _organizationId,
        );
        expect(createOutcome, isA<SyncSuccess>());
        expect((createOutcome as SyncSuccess).rejectedMutations, isEmpty);
        expect(await createDb.readPendingMutationEntries(), isEmpty);

        // The server-allocated ID is the only new non-tmp_ ID that appeared after
        // the creation sync. diff is safe here: createDb is in-memory and local dev
        // is quiet (no concurrent writes).
        final postCreateIds = (await createDb.watchAllProducerAccounts().first)
            .map((p) => p.producerAccountId)
            .toSet();
        final realProducerAccountId = postCreateIds
            .difference(preCreateIds)
            .single;

        final deliveryDb = AppDatabase(NativeDatabase.memory());
        addTearDown(deliveryDb.close);
        final deliverySyncRepo = _buildSyncRepository(deliveryDb);
        final deliveryOrgRepo = OrganizationRepository(
          db: deliveryDb,
          idGenerator: IdGenerator(Random(1)),
        );

        final refreshAfterCreate = await deliverySyncRepo.sync(
          tenantId: _organizationId,
        );
        expect(refreshAfterCreate, isA<SyncSuccess>());
        expect((refreshAfterCreate as SyncSuccess).rejectedMutations, isEmpty);

        // Look up by server-allocated ID — email lookup is not safe on a
        // persistent backend where previous test runs may have left duplicates.
        final createdProducer =
            (await deliveryDb.watchAllProducerAccounts().first).singleWhere(
              (producer) => producer.producerAccountId == realProducerAccountId,
            );
        expect(
          createdProducer.managementMode,
          ProducerManagementMode.noAccount,
        );
        expect(createdProducer.linkedProducerAccount, isNull);
        expect(
          createdProducer.products,
          hasLength(2),
          reason: 'ProducerAccount.products must survive the sync round-trip',
        );
        expect(
          createdProducer.products.map((p) => p.name),
          unorderedEquals(['Pommes', 'Jus de pomme']),
        );

        final createdOrg = (await deliveryOrgRepo
            .watch(_organizationId)
            .first)!;
        expect(
          createdOrg.producers
              .where(
                (producer) =>
                    producer.producerAccountId ==
                    createdProducer.producerAccountId,
              )
              .length,
          1,
        );
        final createdOrgProducts = createdOrg.products
            .where(
              (product) =>
                  product.producerAccountId ==
                  createdProducer.producerAccountId,
            )
            .toList();
        expect(createdOrgProducts, hasLength(2));
        expect(
          createdOrgProducts.map((product) => product.name),
          unorderedEquals(['Pommes', 'Jus de pomme']),
        );

        final createdDelivery = Delivery(
          deliveryId: IdGenerator(Random(2)).nextTmpId(),
          organizationId: _organizationId,
          scheduledDate: _testDeliveryDate,
          status: DeliveryStatus.planned,
          minVolunteersRequired: 2,
        );
        // Remove any pre-existing delivery on the same date (from a previous run
        // that used today + 100 years as the target date) before appending the new
        // delivery, to avoid the date-uniqueness conflict on a persistent backend.
        final deliveryDatePrefix = _testDeliveryDate.substring(0, 10);
        final createdOrgClean = createdOrg.copyWith(
          deliveries: createdOrg.deliveries
              .where((d) => !d.scheduledDate.startsWith(deliveryDatePrefix))
              .toList(),
        );
        await deliveryOrgRepo.addDelivery(
          currentOrg: createdOrgClean,
          delivery: createdDelivery,
        );
        expect(await deliveryDb.readPendingMutationEntries(), hasLength(1));

        final deliveryOutcome = await deliverySyncRepo.sync(
          tenantId: _organizationId,
        );
        expect(deliveryOutcome, isA<SyncSuccess>());
        expect((deliveryOutcome as SyncSuccess).rejectedMutations, isEmpty);
        expect(await deliveryDb.readPendingMutationEntries(), isEmpty);

        final finalDb = AppDatabase(NativeDatabase.memory());
        addTearDown(finalDb.close);
        final finalSyncRepo = _buildSyncRepository(finalDb);
        final finalOrgRepo = OrganizationRepository(
          db: finalDb,
          idGenerator: IdGenerator(Random(2)),
        );

        final finalBootstrap = await finalSyncRepo.sync(
          tenantId: _organizationId,
        );
        expect(finalBootstrap, isA<SyncSuccess>());
        expect((finalBootstrap as SyncSuccess).rejectedMutations, isEmpty);

        final finalOrg = (await finalOrgRepo.watch(_organizationId).first)!;
        expect(
          finalOrg.producers.any(
            (producer) =>
                producer.producerAccountId == createdProducer.producerAccountId,
          ),
          isTrue,
        );
        // Filter by producerAccountId — name-only filter is unsafe on a
        // persistent backend where old runs may have left homonymous products.
        final finalProducts = finalOrg.products
            .where(
              (product) =>
                  product.producerAccountId ==
                  createdProducer.producerAccountId,
            )
            .toList();
        expect(finalProducts, hasLength(2));
        expect(
          finalProducts.map((p) => p.name),
          unorderedEquals(['Pommes', 'Jus de pomme']),
        );
        // Find by scheduled date — asserting hasLength(1) on all deliveries
        // fails on a persistent backend that may have deliveries from prior runs.
        final savedDeliveries = finalOrg.deliveries
            .where(
              (d) =>
                  DateTime.parse(d.scheduledDate) ==
                  DateTime.parse(createdDelivery.scheduledDate),
            )
            .toList();
        expect(savedDeliveries, hasLength(1));
        expect(savedDeliveries.single.status, DeliveryStatus.planned);
        expect(
          savedDeliveries.single.minVolunteersRequired,
          createdDelivery.minVolunteersRequired,
        );

        expect(
          await finalDb.readCursor(organizationScopeKey(_organizationId)),
          isNotNull,
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
