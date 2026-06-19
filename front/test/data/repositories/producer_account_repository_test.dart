import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProducerAccountRepository repo;

  const kInstant = '2026-01-01T00:00:00.000Z';

  ProducerAccount buildProducer({
    String producerAccountId = 'pa-1',
    UserPreferences? userPreferences,
  }) => ProducerAccount(
    producerAccountId: producerAccountId,
    name: 'Ferme du Test',
    userPreferences: userPreferences,
  );

  UserPreferences buildPrefs({
    bool emailNotificationsEnabled = true,
    bool pushNotificationsEnabled = true,
    String lastUpdatedInstant = kInstant,
  }) => UserPreferences(
    emailNotificationsEnabled: emailNotificationsEnabled,
    pushNotificationsEnabled: pushNotificationsEnabled,
    lastUpdatedInstant: lastUpdatedInstant,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProducerAccountRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProducerAccountRepository', () {
    group('updateUserPreferences', () {
      test(
        'enqueues an Upsert mutation on the producer-account scope',
        () async {
          await db.upsertProducerAccount('org-1', buildProducer());

          final newPrefs = buildPrefs(emailNotificationsEnabled: false);
          await repo.updateUserPreferences('pa-1', newPrefs);

          final entries = await db.readPendingMutationEntries();
          expect(entries.length, 1);
          expect(entries.first.scopeKey, producerAccountScopeKey('pa-1'));
          final op = entries.first.mutation.op;
          expect(op, isA<Upsert>());
          final upsert = op as Upsert;
          expect(upsert.payload.entityType, EntityType.producerAccount);
          final payload = upsert.payload as ProducerAccountPayload;
          expect(
            payload.producerAccount.userPreferences?.emailNotificationsEnabled,
            isFalse,
          );
          expect(
            payload.producerAccount.userPreferences?.pushNotificationsEnabled,
            isTrue,
          );
        },
      );

      test('updates the local drift cache', () async {
        await db.upsertProducerAccount('org-1', buildProducer());

        final newPrefs = buildPrefs(pushNotificationsEnabled: false);
        await repo.updateUserPreferences('pa-1', newPrefs);

        final cached = await repo.watchMine('pa-1').first;
        expect(cached, isNotNull);
        expect(cached!.userPreferences?.pushNotificationsEnabled, isFalse);
        expect(cached.userPreferences?.emailNotificationsEnabled, isTrue);
      });

      test(
        'is a no-op (no mutation enqueued) when the producer is not in the cache',
        () async {
          // Do NOT seed any row — producerAccountId unknown locally.
          await repo.updateUserPreferences('unknown-pa', buildPrefs());

          final entries = await db.readPendingMutationEntries();
          expect(entries, isEmpty);
        },
      );

      test(
        'enqueues Upsert carrying the full producer payload (name preserved)',
        () async {
          await db.upsertProducerAccount('org-1', buildProducer());

          await repo.updateUserPreferences('pa-1', buildPrefs());

          final entries = await db.readPendingMutationEntries();
          expect(entries.length, 1);
          final payload =
              (entries.first.mutation.op as Upsert).payload
                  as ProducerAccountPayload;
          // The name must survive the round-trip through the local cache.
          expect(payload.producerAccount.name, 'Ferme du Test');
          expect(payload.producerAccount.producerAccountId, 'pa-1');
        },
      );
    });
  });
}
