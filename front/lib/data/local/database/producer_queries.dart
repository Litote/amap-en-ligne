part of '../database.dart';

mixin _ProducerQueries on _$AppDatabase, _OrganizationQueries {
  /// Reactive list of product types for a tenant.
  Stream<List<ProductType>> watchProductTypes(String producerAccountId) =>
      (select(productTypes)
            ..where((t) => t.producerAccountId.equals(producerAccountId)))
          .watch()
          .map((rows) => rows.map(_toProductType).toList());

  Future<void> upsertProductType(ProductType pt) =>
      into(productTypes).insertOnConflictUpdate(_toRow(pt));

  Future<void> deleteProductType({
    required String producerAccountId,
    required String productTypeId,
  }) =>
      (delete(productTypes)..where(
            (t) =>
                t.producerAccountId.equals(producerAccountId) &
                t.productTypeId.equals(productTypeId),
          ))
          .go();

  /// Clears all product types belonging to a tenant. Used when applying a
  /// bootstrap `EntitySnapshot`: the snapshot is the new ground truth so
  /// stale local rows must be evicted before re-inserting.
  Future<void> clearProductTypesForTenant(String producerAccountId) => (delete(
    productTypes,
  )..where((t) => t.producerAccountId.equals(producerAccountId))).go();

  /// Replaces a row's primary key after the server allocated a real id for a
  /// `tmp_*` creation. Done in a transaction (delete + insert) because the
  /// composite PK is part of the row identity.
  Future<void> remapProductTypeId({
    required String producerAccountId,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(productTypes)..where(
              (t) =>
                  t.producerAccountId.equals(producerAccountId) &
                  t.productTypeId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    await (delete(productTypes)..where(
          (t) =>
              t.producerAccountId.equals(producerAccountId) &
              t.productTypeId.equals(oldId),
        ))
        .go();
    await into(
      productTypes,
    ).insertOnConflictUpdate(existing.copyWith(productTypeId: newId));
  });

  Stream<List<ProducerAccount>> watchProducerAccounts(String organizationId) =>
      (select(
        producerAccounts,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => ProducerAccount.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  /// Reactive stream of every [ProducerAccount] cached locally (across all
  /// tenants). Dedupes by `producerAccountId` — the same producer can be
  /// linked to multiple organisations. Used by instance-wide views (OWNER role).
  Stream<List<ProducerAccount>> watchAllProducerAccounts() =>
      select(producerAccounts).watch().map((rows) {
        final byId = <String, ProducerAccount>{};
        for (final r in rows) {
          final pa = ProducerAccount.fromJson(
            jsonDecode(r.dataJson) as Map<String, dynamic>,
          );
          byId[pa.producerAccountId] = pa;
        }
        return byId.values.toList();
      });

  Future<void> upsertProducerAccount(
    String organizationId,
    ProducerAccount pa,
  ) => into(producerAccounts).insertOnConflictUpdate(
    ProducerAccountsCompanion.insert(
      organizationId: organizationId,
      producerAccountId: pa.producerAccountId,
      dataJson: jsonEncode(pa.toJson()),
    ),
  );

  Future<void> _remapProducerAccountRows(String oldId, String newId) async {
    final producerRows = await (select(
      producerAccounts,
    )..where((t) => t.producerAccountId.equals(oldId))).get();
    for (final row in producerRows) {
      final producer = ProducerAccount.fromJson(
        jsonDecode(row.dataJson) as Map<String, dynamic>,
      ).copyWith(producerAccountId: newId);
      await (delete(producerAccounts)..where(
            (t) =>
                t.organizationId.equals(row.organizationId) &
                t.producerAccountId.equals(oldId),
          ))
          .go();
      await into(producerAccounts).insertOnConflictUpdate(
        row.copyWith(
          organizationId: row.organizationId == oldId
              ? newId
              : row.organizationId,
          producerAccountId: newId,
          dataJson: jsonEncode(producer.toJson()),
        ),
      );
    }
  }

  Future<void> _remapProductTypeRows(String oldId, String newId) async {
    final productTypeRows = await (select(
      productTypes,
    )..where((t) => t.producerAccountId.equals(oldId))).get();
    for (final row in productTypeRows) {
      final updatedProductType = _toProductType(
        row,
      ).copyWith(producerAccountId: newId);
      await (delete(productTypes)..where(
            (t) =>
                t.producerAccountId.equals(oldId) &
                t.productTypeId.equals(row.productTypeId),
          ))
          .go();
      await into(
        productTypes,
      ).insertOnConflictUpdate(_toRow(updatedProductType));
    }
  }

  Future<void> _remapProducerInOrganizations(String oldId, String newId) async {
    final orgRows = await select(organizations).get();
    for (final row in orgRows) {
      final organization = Organization.fromJson(
        jsonDecode(row.dataJson) as Map<String, dynamic>,
      );
      final hasProducerReference = organization.producers.any(
        (producer) => producer.producerAccountId == oldId,
      );
      final hasProductReference = organization.products.any(
        (product) => product.producerAccountId == oldId,
      );
      if (!hasProducerReference && !hasProductReference) {
        continue;
      }
      final updatedOrganization = organization.copyWith(
        producers: organization.producers
            .map(
              (producer) => producer.producerAccountId == oldId
                  ? producer.copyWith(producerAccountId: newId)
                  : producer,
            )
            .toList(),
        products: organization.products
            .map(
              (product) => product.producerAccountId == oldId
                  ? product.copyWith(producerAccountId: newId)
                  : product,
            )
            .toList(),
      );
      await upsertOrganization(updatedOrganization);
    }
  }

  Future<void> remapProducerAccountId({
    required String oldId,
    required String newId,
  }) => transaction(() async {
    await _remapProducerAccountRows(oldId, newId);
    await _remapProductTypeRows(oldId, newId);
    await _remapProducerInOrganizations(oldId, newId);
  });

  Future<void> deleteProducerAccount(
    String organizationId,
    String producerAccountId,
  ) =>
      (delete(producerAccounts)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.producerAccountId.equals(producerAccountId),
          ))
          .go();

  Future<void> clearProducerAccountsForTenant(String organizationId) => (delete(
    producerAccounts,
  )..where((t) => t.organizationId.equals(organizationId))).go();

  /// Reactive stream of a single [ProducerAccount] by [producerAccountId].
  /// Emits null when no matching row is cached locally.
  Stream<ProducerAccount?> watchProducerAccountById(String producerAccountId) =>
      (select(producerAccounts)
            ..where((t) => t.producerAccountId.equals(producerAccountId)))
          .watch()
          .map(
            (rows) => rows.isEmpty
                ? null
                : ProducerAccount.fromJson(
                    jsonDecode(rows.first.dataJson) as Map<String, dynamic>,
                  ),
          );

  /// Optimistically updates the [UserPreferences] on every locally-cached row
  /// for the given [producerAccountId] (a producer may be linked to multiple
  /// organisations). The back will confirm the value on the next sync.
  Future<void> updateProducerAccountUserPreferences(
    String producerAccountId,
    UserPreferences userPreferences,
  ) async {
    final rows = await (select(
      producerAccounts,
    )..where((t) => t.producerAccountId.equals(producerAccountId))).get();
    for (final row in rows) {
      final pa = ProducerAccount.fromJson(
        jsonDecode(row.dataJson) as Map<String, dynamic>,
      ).copyWith(userPreferences: userPreferences);
      await upsertProducerAccount(row.organizationId, pa);
    }
  }

  /// Optimistically updates the profile fields on every locally-cached row for
  /// the given [producerAccountId]. No-op when no rows exist in the local cache.
  Future<void> updateProducerAccountProfile({
    required String producerAccountId,
    required String name,
    String? contactEmail,
    String? address,
    String? website,
  }) async {
    final rows = await (select(
      producerAccounts,
    )..where((t) => t.producerAccountId.equals(producerAccountId))).get();
    for (final row in rows) {
      // Reconstruct from JSON so we preserve all other fields, then
      // selectively overwrite the profile columns.
      final existing = jsonDecode(row.dataJson) as Map<String, dynamic>;
      final updated = Map<String, dynamic>.from(existing)
        ..['name'] = name
        ..['contact_email'] = contactEmail
        ..['address'] = address
        ..['website'] = website;
      await upsertProducerAccount(
        row.organizationId,
        ProducerAccount.fromJson(updated),
      );
    }
  }
}

ProductType _toProductType(ProductTypeRow row) => ProductType(
  productTypeId: row.productTypeId,
  producerAccountId: row.producerAccountId,
  supportedBasketSizes: row.supportedBasketSizes,
  name: row.name,
  description: row.description,
);

ProductTypesCompanion _toRow(ProductType pt) => ProductTypesCompanion.insert(
  producerAccountId: pt.producerAccountId,
  productTypeId: pt.productTypeId,
  name: pt.name,
  description: Value(pt.description),
  supportedBasketSizes: pt.supportedBasketSizes,
);
