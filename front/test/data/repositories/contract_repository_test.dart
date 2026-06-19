import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ContractRepository repo;

  Contract buildContract({
    String contractId = 'c-1',
    String organizationId = 'org-1',
    String producerAccountId = 'pa-1',
    String name = 'Contrat test',
    String minDeliveryDate = '2026-01-01',
    String maxDeliveryDate = '2026-12-31',
    int deliveryCount = 12,
    List<ProductPrice> productPrices = const [
      ProductPrice(productTypeId: 'pt-1', price: 240),
    ],
    int seasonYear = 2026,
    List<String> coordinators = const [],
    List<ContractMember> members = const [],
  }) => Contract(
    contractId: contractId,
    name: name,
    organizationId: organizationId,
    producerAccountId: producerAccountId,
    minDeliveryDate: minDeliveryDate,
    maxDeliveryDate: maxDeliveryDate,
    deliveryCount: deliveryCount,
    productPrices: productPrices,
    seasonYear: seasonYear,
    coordinators: coordinators,
    members: members,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ContractRepository(db: db, idGenerator: IdGenerator(Random(0)));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create stores a tmp contract and enqueues an Upsert mutation',
    () async {
      final created = await repo.create(buildContract(contractId: 'ignored'));

      expect(created.contractId, startsWith('tmp_'));
      final contracts = await db.watchContracts('org-1').first;
      expect(contracts.single.contractId, created.contractId);

      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, organizationScopeKey('org-1'));
      final mutations = await db.readPendingMutations();
      final upsert = mutations.single.op as Upsert;
      expect(upsert.payload, isA<ContractPayload>());
      expect(
        (upsert.payload as ContractPayload).contract.contractId,
        created.contractId,
      );
    },
  );

  test('update overwrites the local row and enqueues an Upsert', () async {
    await db.upsertContract('org-1', buildContract());

    await repo.update(
      buildContract(
        productPrices: const [ProductPrice(productTypeId: 'pt-1', price: 300)],
        deliveryCount: 10,
      ),
    );

    final contracts = await db.watchContracts('org-1').first;
    expect(contracts.single.productPrices.first.price, 300);
    expect(contracts.single.deliveryCount, 10);

    final mutations = await db.readPendingMutations();
    expect(mutations.single.op, isA<Upsert>());
  });

  test('delete removes the local row and enqueues a Delete mutation', () async {
    await db.upsertContract('org-1', buildContract());

    await repo.delete('c-1', 'org-1');

    expect(await db.watchContracts('org-1').first, isEmpty);
    final mutations = await db.readPendingMutations();
    final delete = mutations.single.op as Delete;
    expect(delete.entityType, EntityType.contract);
    expect(delete.entityId, 'c-1');
  });

  test('remapContractId replaces the temporary contract id', () async {
    await db.upsertContract(
      'org-1',
      buildContract(contractId: 'tmp_contract-1'),
    );

    await db.remapContractId(
      organizationId: 'org-1',
      oldId: 'tmp_contract-1',
      newId: 'c-server-1',
    );

    final contracts = await db.watchContracts('org-1').first;
    expect(contracts.single.contractId, 'c-server-1');
  });
}
