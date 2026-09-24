part of '../database.dart';

mixin _OrganizationQueries on _$AppDatabase {
  /// Returns a reactive stream of all [Organization] rows in the cache.
  /// Used by instance-wide views (OWNER role) that need all organisations.
  Stream<List<Organization>> watchAllOrganizations() =>
      select(organizations).watch().map(
        (rows) => rows
            .map(
              (r) => Organization.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Stream<Organization?> watchOrganization(String organizationId) =>
      (select(organizations)
            ..where((t) => t.organizationId.equals(organizationId)))
          .watchSingleOrNull()
          .map(
            (row) => row == null
                ? null
                : Organization.fromJson(
                    jsonDecode(row.dataJson) as Map<String, dynamic>,
                  ),
          );

  /// Watches the organization matching [tenantId], with a cursor-based fallback.
  ///
  /// Cognito access tokens do not carry the organizationId claim, so non-producer
  /// users (admin/coordinator/volunteer) have tenantId == sub, which never matches
  /// an organization row. In that case, we derive the orgId from the
  /// `organization:*` scope cursor written after the first successful sync.
  Stream<Organization?> watchOrganizationForTenant(String tenantId) =>
      customSelect(
        'SELECT o.data_json FROM organizations o WHERE o.organization_id IN ('
        'SELECT organization_id FROM ('
        'SELECT organization_id, 1 AS priority FROM organizations '
        'WHERE organization_id = ? '
        'UNION ALL '
        'SELECT SUBSTR(scope_key, 14), 2 AS priority FROM sync_cursors '
        "WHERE scope_key LIKE 'organization:%' "
        ') ORDER BY priority LIMIT 1'
        ')',
        variables: [Variable.withString(tenantId)],
        readsFrom: {organizations, syncCursors},
      ).watchSingleOrNull().map(
        (row) => row == null
            ? null
            : Organization.fromJson(
                jsonDecode(row.read<String>('data_json'))
                    as Map<String, dynamic>,
              ),
      );

  /// Resolves the effective organization ID for [tenantId] (exact match first,
  /// then cursor fallback). Exposed for repos that query tables other than
  /// `organizations` but still need a valid orgId.
  Stream<String?> watchEffectiveOrganizationId(String tenantId) => customSelect(
    'SELECT organization_id FROM ('
    'SELECT organization_id, 1 AS priority FROM organizations '
    'WHERE organization_id = ? '
    'UNION ALL '
    'SELECT SUBSTR(scope_key, 14), 2 AS priority FROM sync_cursors '
    "WHERE scope_key LIKE 'organization:%' "
    ') ORDER BY priority LIMIT 1',
    variables: [Variable.withString(tenantId)],
    readsFrom: {organizations, syncCursors},
  ).watchSingleOrNull().map((row) => row?.read<String>('organization_id'));

  Future<void> upsertOrganization(Organization org) =>
      into(organizations).insertOnConflictUpdate(
        OrganizationsCompanion.insert(
          organizationId: org.organizationId,
          dataJson: jsonEncode(org.toJson()),
        ),
      );

  Future<void> clearOrganizationsForTenant(String tenantId) => (delete(
    organizations,
  )..where((t) => t.organizationId.equals(tenantId))).go();

  Stream<List<Contract>> watchContracts(String organizationId) =>
      (select(
        contracts,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => Contract.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertContract(String organizationId, Contract c) =>
      into(contracts).insertOnConflictUpdate(
        ContractsCompanion.insert(
          organizationId: organizationId,
          contractId: c.contractId,
          dataJson: jsonEncode(c.toJson()),
        ),
      );

  Future<void> deleteContract(String organizationId, String contractId) =>
      (delete(contracts)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.contractId.equals(contractId),
          ))
          .go();

  Future<void> clearContractsForOrganization(String organizationId) => (delete(
    contracts,
  )..where((t) => t.organizationId.equals(organizationId))).go();

  Stream<List<DeliveryTemplate>> watchDeliveryTemplates(
    String organizationId,
  ) =>
      (select(
        deliveryTemplates,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => DeliveryTemplate.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertDeliveryTemplate(
    String organizationId,
    DeliveryTemplate template,
  ) => into(deliveryTemplates).insertOnConflictUpdate(
    DeliveryTemplatesCompanion.insert(
      organizationId: organizationId,
      deliveryTemplateId: template.deliveryTemplateId,
      dataJson: jsonEncode(template.toJson()),
    ),
  );

  Future<void> deleteDeliveryTemplate(
    String organizationId,
    String deliveryTemplateId,
  ) =>
      (delete(deliveryTemplates)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.deliveryTemplateId.equals(deliveryTemplateId),
          ))
          .go();

  Future<void> clearDeliveryTemplatesForOrganization(String organizationId) =>
      (delete(
        deliveryTemplates,
      )..where((t) => t.organizationId.equals(organizationId))).go();

  Future<void> _remapContractInOrganizations(String oldId, String newId) async {
    final orgRows = await select(organizations).get();
    for (final row in orgRows) {
      final organization = Organization.fromJson(
        jsonDecode(row.dataJson) as Map<String, dynamic>,
      );
      final hasRef = organization.deliveries.any(
        (d) => d.contracts.any((dc) => dc.contractId == oldId),
      );
      if (!hasRef) continue;
      final updatedOrg = organization.copyWith(
        deliveries: organization.deliveries.map((d) {
          final dHasRef = d.contracts.any((dc) => dc.contractId == oldId);
          if (!dHasRef) return d;
          return d.copyWith(
            contracts: d.contracts
                .map(
                  (dc) => dc.contractId == oldId
                      ? dc.copyWith(contractId: newId)
                      : dc,
                )
                .toList(),
          );
        }).toList(),
      );
      await upsertOrganization(updatedOrg);
    }
  }

  Future<void> remapContractId({
    required String organizationId,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(contracts)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.contractId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    final contract = Contract.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(contractId: newId);
    await (delete(contracts)..where(
          (t) =>
              t.organizationId.equals(organizationId) &
              t.contractId.equals(oldId),
        ))
        .go();
    await upsertContract(organizationId, contract);
    await _remapContractInOrganizations(oldId, newId);
  });

  Future<void> remapDeliveryTemplateId({
    required String organizationId,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(deliveryTemplates)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.deliveryTemplateId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    final template = DeliveryTemplate.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(deliveryTemplateId: newId);
    await (delete(deliveryTemplates)..where(
          (t) =>
              t.organizationId.equals(organizationId) &
              t.deliveryTemplateId.equals(oldId),
        ))
        .go();
    await upsertDeliveryTemplate(organizationId, template);

    // Rewrite delivery[].delivery_template_id references in organizations.
    final orgRows = await select(organizations).get();
    for (final row in orgRows) {
      final organization = Organization.fromJson(
        jsonDecode(row.dataJson) as Map<String, dynamic>,
      );
      final hasRef = organization.deliveries.any(
        (d) => d.deliveryTemplateId == oldId,
      );
      if (!hasRef) continue;
      final updatedOrg = organization.copyWith(
        deliveries: organization.deliveries
            .map(
              (d) => d.deliveryTemplateId == oldId
                  ? d.copyWith(deliveryTemplateId: newId)
                  : d,
            )
            .toList(),
      );
      await upsertOrganization(updatedOrg);
    }
  });
}
