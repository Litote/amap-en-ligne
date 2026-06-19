import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/attendance_email_request.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/device_token.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/owner_invitation.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/drift.dart';

import 'database_open_stub.dart'
    if (dart.library.js_interop) 'database_open_web.dart'
    if (dart.library.ffi) 'database_open_native.dart';

part 'database.g.dart';

/// Local cache of `ProductType` rows. Composite PK matches the back's schema
/// so that `(producer_account_id, product_type_id)` uniqueness is enforced
/// identically on both sides.
@DataClassName('ProductTypeRow')
class ProductTypes extends Table {
  TextColumn get producerAccountId => text()();
  TextColumn get productTypeId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get supportedBasketSizes =>
      text().map(const _BasketSizesConverter())();

  @override
  Set<Column<Object>> get primaryKey => {producerAccountId, productTypeId};
}

/// Per-scope last cursor seen by the client. A row absent or with
/// `cursor IS NULL` means the client must bootstrap that scope on the next
/// sync. The scope key also doubles as the authoritative local registry of
/// known scopes discovered from `authorized_scopes`.
class SyncCursors extends Table {
  TextColumn get scopeKey => text()();
  TextColumn get cursor => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {scopeKey};
}

/// Local queue of pending `ClientMutation`s (offline-first writes). Drained
/// by the sync repository when the corresponding `MutationOutcome` confirms
/// the mutation was `APPLIED` or `REJECTED`.
class PendingMutations extends Table {
  TextColumn get clientOpId => text()();
  TextColumn get scopeKey => text().nullable()();
  TextColumn get payloadJson => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {clientOpId};
}

/// Local cache of `Organization` rows stored as a JSON blob.
@DataClassName('OrganizationRow')
class Organizations extends Table {
  TextColumn get organizationId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId};
}

/// Local cache of `ProducerAccount` rows scoped to an organization, stored
/// as a JSON blob.
@DataClassName('ProducerAccountRow')
class ProducerAccounts extends Table {
  TextColumn get organizationId => text()();
  TextColumn get producerAccountId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, producerAccountId};
}

/// Local cache of `Member` rows scoped to an organization, stored as a JSON
/// blob.
@DataClassName('MemberRow')
class Members extends Table {
  TextColumn get organizationId => text()();
  TextColumn get memberId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, memberId};
}

/// Local cache of `MemberInvitation` rows scoped to an organization, stored as
/// a JSON blob.
@DataClassName('MemberInvitationRow')
class MemberInvitations extends Table {
  TextColumn get organizationId => text()();
  TextColumn get invitationId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, invitationId};
}

/// Local cache of `AdminMemberJoinRequest` rows scoped to an organization,
/// stored as a JSON blob.
@DataClassName('MemberJoinRequestRow')
class MemberJoinRequests extends Table {
  TextColumn get organizationId => text()();
  TextColumn get requestId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, requestId};
}

/// Local cache of `Contract` rows scoped to an organization, stored as a JSON
/// blob.
@DataClassName('ContractRow')
class Contracts extends Table {
  TextColumn get organizationId => text()();
  TextColumn get contractId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, contractId};
}

/// Local cache of `DeliveryTemplate` rows scoped to an organization, stored as
/// a JSON blob.
@DataClassName('DeliveryTemplateRow')
class DeliveryTemplates extends Table {
  TextColumn get organizationId => text()();
  TextColumn get deliveryTemplateId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, deliveryTemplateId};
}

/// Local cache of `AdminOrganizationRequest` rows stored as a JSON blob.
/// These are synced from the back via `POST /v1/sync` for OWNER/ADMIN callers.
@DataClassName('OrganizationRequestRow')
class OrganizationRequests extends Table {
  TextColumn get requestId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {requestId};
}

/// Local cache of `AdminProducerRequest` rows stored as a JSON blob.
@DataClassName('ProducerRequestRow')
class ProducerRequests extends Table {
  TextColumn get requestId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {requestId};
}

/// Local cache of instance-level [Owner] rows with native columns.
/// Synced from the back via `POST /v1/sync` for OWNER callers.
/// Presence of a row materialises the OWNER role (no roles field).
@DataClassName('OwnerRow')
class Owners extends Table {
  TextColumn get ownerId => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get accountStatus => text()();
  TextColumn get registeredAt => text()();
  TextColumn get updatedAt => text()();

  /// Nullable JSON blob for [UserPreferences]. Added in schema v11.
  TextColumn get userPreferences => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId};
}

/// Local cache of instance-level `OwnerInvitation` rows stored as a JSON blob.
@DataClassName('OwnerInvitationRow')
class OwnerInvitations extends Table {
  TextColumn get invitationId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {invitationId};
}

/// Local cache of [BasketExchange] rows scoped to an organization.
///
/// [requestsJson] stores the embedded [List<BasketExchangeRequest>] as a JSON
/// text blob since drift does not natively support nested lists. This avoids a
/// separate join table while keeping the full aggregate available for optimistic
/// updates and sync handler remaps.
@DataClassName('BasketExchangeRow')
class BasketExchanges extends Table {
  TextColumn get basketExchangeId => text()();
  TextColumn get organizationId => text()();
  TextColumn get deliveryId => text()();
  TextColumn get contractId => text()();
  TextColumn get offeringMemberId => text()();
  TextColumn get motive => text().nullable()();
  TextColumn get status => text()();
  // ISO-8601 instant string.
  TextColumn get createdAt => text()();
  // ISO-8601 instant string; null until decided.
  TextColumn get decidedAt => text().nullable()();
  // Null until a request is accepted.
  TextColumn get acceptedRequestId => text().nullable()();
  // JSON-encoded List<BasketExchangeRequest>.
  TextColumn get requestsJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {basketExchangeId};
}

/// Local cache of `AppNotification` rows on the recipient's private scope
/// (`member:{id}` today), stored as a JSON blob (ADR-005).
@DataClassName('NotificationRow')
class Notifications extends Table {
  TextColumn get recipientScope => text()();
  TextColumn get notificationId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {recipientScope, notificationId};
}

/// Local cache of `DeviceToken` rows on the recipient's private scope
/// (`member:{id}` / `owner:{id}` / `producer-account:{id}`), stored as a JSON blob
/// (ADR-005). Client-authored push registration tokens.
@DataClassName('DeviceTokenRow')
class DeviceTokens extends Table {
  TextColumn get recipientScope => text()();
  TextColumn get deviceTokenId => text()();
  TextColumn get dataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {recipientScope, deviceTokenId};
}

/// Local cache of [AttendanceEmailRequest] rows scoped to an organization.
///
/// The client creates rows with `tmp_*` ids; the server allocates real ids and
/// sets [sentAt] once the email has been dispatched.
@DataClassName('AttendanceEmailRequestRow')
class AttendanceEmailRequests extends Table {
  TextColumn get attendanceEmailRequestId => text()();
  TextColumn get organizationId => text()();
  TextColumn get deliveryId => text()();
  TextColumn get recipientEmail => text()();
  // ISO-8601 instant string.
  TextColumn get requestedAt => text()();
  // ISO-8601 instant string; null until the email has been sent.
  TextColumn get sentAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {attendanceEmailRequestId};
}

/// Local cache of [ErrorReport] rows submitted by the user via the sync
/// status banner. The client creates rows with `tmp_*` ids; the server
/// allocates real ids on apply.
@DataClassName('ErrorReportRow')
class ErrorReports extends Table {
  TextColumn get errorReportId => text()();
  TextColumn get errorMessage => text()();
  // ISO-8601 instant string.
  TextColumn get reportedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {errorReportId};
}

@DriftDatabase(
  tables: [
    ProductTypes,
    SyncCursors,
    PendingMutations,
    Organizations,
    ProducerAccounts,
    Members,
    MemberInvitations,
    MemberJoinRequests,
    Contracts,
    DeliveryTemplates,
    OrganizationRequests,
    ProducerRequests,
    Owners,
    OwnerInvitations,
    BasketExchanges,
    Notifications,
    DeviceTokens,
    AttendanceEmailRequests,
    ErrorReports,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  final _mutationEnqueuedController = StreamController<void>.broadcast();

  /// Emits whenever a pending mutation is enqueued. `SyncBloc` subscribes to
  /// this stream to flush the queue immediately without requiring every screen
  /// to manually dispatch `SyncEvent.mutationApplied()`.
  Stream<void> get onMutationEnqueued => _mutationEnqueuedController.stream;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy();

  static QueryExecutor _open() => openDatabaseExecutor();

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

  Future<Map<String, String?>> readAllScopeCursors() async {
    final rows = await select(syncCursors).get();
    return {for (final row in rows) row.scopeKey: row.cursor};
  }

  Future<String?> readCursor(String scopeKey) async {
    final row = await (select(
      syncCursors,
    )..where((t) => t.scopeKey.equals(scopeKey))).getSingleOrNull();
    return row?.cursor;
  }

  Future<void> writeCursor(String scopeKey, String? cursor) =>
      into(syncCursors).insertOnConflictUpdate(
        SyncCursorsCompanion.insert(scopeKey: scopeKey, cursor: Value(cursor)),
      );

  Future<void> deleteCursor(String scopeKey) =>
      (delete(syncCursors)..where((t) => t.scopeKey.equals(scopeKey))).go();

  /// Resets every known scope cursor to null, signalling a full bootstrap on
  /// the next sync round-trip.
  Future<void> resetAllCursors() => (update(
    syncCursors,
  )).write(const SyncCursorsCompanion(cursor: Value(null)));

  Future<void> enqueuePendingMutation(
    ClientMutation mutation, {
    required String scopeKey,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(pendingMutations).insertOnConflictUpdate(
      PendingMutationsCompanion.insert(
        clientOpId: mutation.clientOpId,
        scopeKey: Value(scopeKey),
        payloadJson: jsonEncode(mutation),
        createdAt: now,
      ),
    );
    _mutationEnqueuedController.add(null);
  }

  Future<List<PendingClientMutation>> readPendingMutationEntries() async {
    final rows = await (select(
      pendingMutations,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    return _resolvePendingMutationEntries(rows);
  }

  Future<List<ClientMutation>> readPendingMutations() async {
    final rows = await readPendingMutationEntries();
    return rows.map((row) => row.mutation).toList();
  }

  Future<void> drainPendingMutations(Iterable<String> clientOpIds) {
    final ids = clientOpIds.toList();
    if (ids.isEmpty) return Future.value();
    return (delete(
      pendingMutations,
    )..where((t) => t.clientOpId.isIn(ids))).go();
  }

  Future<void> dropPendingMutationsForScopes(Iterable<String> scopeKeys) {
    final keys = scopeKeys.toList();
    if (keys.isEmpty) return Future.value();
    return (delete(pendingMutations)..where((t) => t.scopeKey.isIn(keys))).go();
  }

  Future<void> dropPendingMutationsWithoutScope() => (delete(
    pendingMutations,
  )..where((t) => t.scopeKey.isNull() | t.scopeKey.equals(''))).go();

  Future<void> replacePendingMutation(
    PendingClientMutation entry, {
    required ClientMutation mutation,
    String? scopeKey,
  }) => into(pendingMutations).insertOnConflictUpdate(
    PendingMutationsCompanion.insert(
      clientOpId: entry.clientOpId,
      scopeKey: Value(scopeKey ?? entry.scopeKey),
      payloadJson: jsonEncode(mutation),
      createdAt: entry.createdAt,
    ),
  );

  // --- Organization DAOs ---

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

  // --- ProducerAccount DAOs ---

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

  // --- Member DAOs ---

  /// Watches all [Member] rows for [tenantId].
  ///
  /// [tenantId] is the JWT `sub` for non-producer users. The real
  /// `organization_id` is resolved from the `authorized_scopes` stored in
  /// [sync_cursors] by [SyncRepository] after the first sync
  /// (scope key `organization:<orgId>`). [watchEffectiveOrganizationId]
  /// extracts that org id and switches to the concrete members query once it
  /// is available.
  Stream<List<Member>> watchMembersForTenant(String tenantId) =>
      watchEffectiveOrganizationId(tenantId).distinct().asyncExpand(
        (orgId) => orgId == null
            ? Stream.value(<Member>[])
            : (select(
                members,
              )..where((t) => t.organizationId.equals(orgId))).watch().map(
                (rows) => rows
                    .map(
                      (r) => Member.fromJson(
                        jsonDecode(r.dataJson) as Map<String, dynamic>,
                      ),
                    )
                    .toList(),
              ),
      );

  /// Watches all [MemberInvitation] rows for [tenantId].
  /// Same org-id resolution as [watchMembersForTenant].
  Stream<List<MemberInvitation>> watchMemberInvitationsForTenant(
    String tenantId,
  ) => watchEffectiveOrganizationId(tenantId).distinct().asyncExpand(
    (orgId) => orgId == null
        ? Stream.value(<MemberInvitation>[])
        : (select(
            memberInvitations,
          )..where((t) => t.organizationId.equals(orgId))).watch().map(
            (rows) => rows
                .map(
                  (r) => MemberInvitation.fromJson(
                    jsonDecode(r.dataJson) as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
  );

  /// Returns a reactive stream of **all** [Member] rows across all
  /// organisations. Used by instance-wide views (OWNER role).
  Stream<List<Member>> watchAllMembers() => select(members).watch().map(
    (rows) => rows
        .map(
          (r) =>
              Member.fromJson(jsonDecode(r.dataJson) as Map<String, dynamic>),
        )
        .toList(),
  );

  Stream<List<Member>> watchMembers(String organizationId) =>
      (select(
        members,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => Member.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertMember(String organizationId, Member m) =>
      into(members).insertOnConflictUpdate(
        MembersCompanion.insert(
          organizationId: organizationId,
          memberId: m.memberId,
          dataJson: jsonEncode(m.toJson()),
        ),
      );

  Future<void> deleteMember(String organizationId, String memberId) =>
      (delete(members)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.memberId.equals(memberId),
          ))
          .go();

  Future<void> clearMembersForOrganization(String organizationId) => (delete(
    members,
  )..where((t) => t.organizationId.equals(organizationId))).go();

  Stream<List<MemberInvitation>> watchMemberInvitations(
    String organizationId,
  ) =>
      (select(
        memberInvitations,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => MemberInvitation.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<MemberInvitation?> getMemberInvitation(
    String organizationId,
    String invitationId,
  ) async {
    final row =
        await (select(memberInvitations)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.invitationId.equals(invitationId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return MemberInvitation.fromJson(
      jsonDecode(row.dataJson) as Map<String, dynamic>,
    );
  }

  Future<List<MemberInvitation>> getMemberInvitationsForOrganization(
    String organizationId,
  ) async {
    final rows = await (select(
      memberInvitations,
    )..where((t) => t.organizationId.equals(organizationId))).get();
    return rows
        .map(
          (row) => MemberInvitation.fromJson(
            jsonDecode(row.dataJson) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> upsertMemberInvitation(
    String organizationId,
    MemberInvitation invitation,
  ) => into(memberInvitations).insertOnConflictUpdate(
    MemberInvitationsCompanion.insert(
      organizationId: organizationId,
      invitationId: invitation.invitationId,
      dataJson: jsonEncode(invitation.toJson()),
    ),
  );

  Future<void> deleteMemberInvitation(
    String organizationId,
    String invitationId,
  ) =>
      (delete(memberInvitations)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.invitationId.equals(invitationId),
          ))
          .go();

  Future<void> clearMemberInvitationsForOrganization(String organizationId) =>
      (delete(
        memberInvitations,
      )..where((t) => t.organizationId.equals(organizationId))).go();

  Stream<List<AdminMemberJoinRequest>> watchMemberJoinRequests(
    String organizationId,
  ) =>
      (select(
        memberJoinRequests,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => AdminMemberJoinRequest.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertMemberJoinRequest(AdminMemberJoinRequest request) =>
      into(memberJoinRequests).insertOnConflictUpdate(
        MemberJoinRequestsCompanion.insert(
          organizationId: request.organizationId,
          requestId: request.requestId,
          dataJson: jsonEncode(request.toJson()),
        ),
      );

  Future<void> deleteMemberJoinRequest(
    String organizationId,
    String requestId,
  ) =>
      (delete(memberJoinRequests)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.requestId.equals(requestId),
          ))
          .go();

  Future<void> clearMemberJoinRequestsForOrganization(String organizationId) =>
      (delete(
        memberJoinRequests,
      )..where((t) => t.organizationId.equals(organizationId))).go();

  /// Returns the [Member] identified by [memberId] + [organizationId], or
  /// `null` when no row exists in the local cache.
  Future<Member?> getMember(String organizationId, String memberId) async {
    final row =
        await (select(members)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.memberId.equals(memberId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return Member.fromJson(jsonDecode(row.dataJson) as Map<String, dynamic>);
  }

  // --- Contract DAOs ---

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

  // --- DeliveryTemplate DAOs ---

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

  // --- OrganizationRequest DAOs ---

  Stream<List<AdminOrganizationRequest>> watchOrganizationRequests() =>
      select(organizationRequests).watch().map(
        (rows) => rows
            .map(
              (r) => AdminOrganizationRequest.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertOrganizationRequest(AdminOrganizationRequest request) =>
      into(organizationRequests).insertOnConflictUpdate(
        OrganizationRequestsCompanion.insert(
          requestId: request.requestId,
          dataJson: jsonEncode(request.toJson()),
        ),
      );

  Future<void> deleteOrganizationRequest(String requestId) => (delete(
    organizationRequests,
  )..where((t) => t.requestId.equals(requestId))).go();

  Future<void> clearOrganizationRequests() => delete(organizationRequests).go();

  // --- ProducerRequest DAOs ---

  Stream<List<AdminProducerRequest>> watchProducerRequests() =>
      select(producerRequests).watch().map(
        (rows) => rows
            .map(
              (r) => AdminProducerRequest.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertProducerRequest(AdminProducerRequest request) =>
      into(producerRequests).insertOnConflictUpdate(
        ProducerRequestsCompanion.insert(
          requestId: request.requestId,
          dataJson: jsonEncode(request.toJson()),
        ),
      );

  Future<void> deleteProducerRequest(String requestId) => (delete(
    producerRequests,
  )..where((t) => t.requestId.equals(requestId))).go();

  Future<void> clearProducerRequests() => delete(producerRequests).go();

  // --- Owner DAOs ---

  Stream<List<Owner>> watchOwners() => select(
    owners,
  ).watch().map((rows) => rows.map(_ownerRowToDomain).toList());

  Future<List<Owner>> getAllOwners() async {
    final rows = await select(owners).get();
    return rows.map(_ownerRowToDomain).toList();
  }

  Future<Owner?> findOwnerById(String ownerId) async {
    final row = await (select(
      owners,
    )..where((t) => t.ownerId.equals(ownerId))).getSingleOrNull();
    return row == null ? null : _ownerRowToDomain(row);
  }

  /// Reactive stream of the [Owner] row whose `ownerId` matches [ownerId].
  /// Emits null when no matching row exists.
  Stream<Owner?> watchOwnerById(String ownerId) =>
      (select(owners)..where((t) => t.ownerId.equals(ownerId)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _ownerRowToDomain(row));

  Future<void> upsertOwner(Owner owner) =>
      into(owners).insertOnConflictUpdate(_ownerDomainToRow(owner));

  Future<void> deleteOwner(String ownerId) =>
      (delete(owners)..where((t) => t.ownerId.equals(ownerId))).go();

  /// Clears all owner rows. Used when applying a bootstrap [EntitySnapshot].
  Future<void> clearOwners() => delete(owners).go();

  /// Optimistically updates the [UserPreferences] for the given [ownerId].
  Future<void> updateOwnerUserPreferences(
    String ownerId,
    UserPreferences userPreferences,
  ) async {
    final existing = await findOwnerById(ownerId);
    if (existing == null) return;
    await upsertOwner(existing.copyWith(userPreferences: userPreferences));
  }

  /// Optimistically updates the profile fields for the given [ownerId].
  /// No-op when the row is not yet in the local cache.
  Future<void> updateOwnerProfile({
    required String ownerId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    final existing = await findOwnerById(ownerId);
    if (existing == null) return;
    await upsertOwner(
      existing.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      ),
    );
  }

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

  Stream<List<OwnerInvitation>> watchOwnerInvitations() =>
      select(ownerInvitations).watch().map(
        (rows) => rows
            .map(
              (r) => OwnerInvitation.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<OwnerInvitation?> findOwnerInvitationById(String invitationId) async {
    final row = await (select(
      ownerInvitations,
    )..where((t) => t.invitationId.equals(invitationId))).getSingleOrNull();
    if (row == null) return null;
    return OwnerInvitation.fromJson(
      jsonDecode(row.dataJson) as Map<String, dynamic>,
    );
  }

  Future<List<OwnerInvitation>> getOwnerInvitations() async {
    final rows = await select(ownerInvitations).get();
    return rows
        .map(
          (row) => OwnerInvitation.fromJson(
            jsonDecode(row.dataJson) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> upsertOwnerInvitation(OwnerInvitation invitation) =>
      into(ownerInvitations).insertOnConflictUpdate(
        OwnerInvitationsCompanion.insert(
          invitationId: invitation.invitationId,
          dataJson: jsonEncode(invitation.toJson()),
        ),
      );

  Future<void> deleteOwnerInvitation(String invitationId) => (delete(
    ownerInvitations,
  )..where((t) => t.invitationId.equals(invitationId))).go();

  Future<void> clearOwnerInvitations() => delete(ownerInvitations).go();

  // --- BasketExchange DAOs ---

  /// Reactive stream of all [BasketExchange] rows for the given organization.
  Stream<List<BasketExchange>> watchBasketExchangesByOrg(
    String organizationId,
  ) =>
      (select(basketExchanges)
            ..where((t) => t.organizationId.equals(organizationId)))
          .watch()
          .map((rows) => rows.map(_basketExchangeRowToDomain).toList());

  /// Inserts or replaces a [BasketExchange] row.
  Future<void> upsertBasketExchange(BasketExchange exchange) => into(
    basketExchanges,
  ).insertOnConflictUpdate(_basketExchangeDomainToRow(exchange));

  /// Deletes the [BasketExchange] row identified by [basketExchangeId].
  ///
  /// Note: the back returns FORBIDDEN for BasketExchange DELETE mutations.
  /// This method exists to mirror the protocol locally in case a tombstone
  /// arrives in a future protocol revision.
  Future<void> deleteBasketExchange(String basketExchangeId) => (delete(
    basketExchanges,
  )..where((t) => t.basketExchangeId.equals(basketExchangeId))).go();

  /// Clears all [BasketExchange] rows for the given organization. Used when
  /// applying a bootstrap [ScopeSyncResult] for an `organization:{id}` scope.
  Future<void> clearBasketExchangesForOrg(String organizationId) => (delete(
    basketExchanges,
  )..where((t) => t.organizationId.equals(organizationId))).go();

  /// Remaps the primary key of a [BasketExchange] row from a `tmp_*` id to the
  /// server-allocated real id. Done as a delete + insert inside a transaction
  /// because [basketExchangeId] is the PK.
  Future<void> remapBasketExchangeId({
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing = await (select(
      basketExchanges,
    )..where((t) => t.basketExchangeId.equals(oldId))).getSingleOrNull();
    if (existing == null) return;
    final exchange = _basketExchangeRowToDomain(existing);
    await (delete(
      basketExchanges,
    )..where((t) => t.basketExchangeId.equals(oldId))).go();
    await upsertBasketExchange(exchange.copyWith(basketExchangeId: newId));
  });

  // region notifications

  Stream<List<AppNotification>> watchNotifications(String recipientScope) =>
      (select(
        notifications,
      )..where((t) => t.recipientScope.equals(recipientScope))).watch().map(
        (rows) => rows
            .map(
              (r) => AppNotification.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<AppNotification?> getNotification(
    String recipientScope,
    String notificationId,
  ) async {
    final row =
        await (select(notifications)..where(
              (t) =>
                  t.recipientScope.equals(recipientScope) &
                  t.notificationId.equals(notificationId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return AppNotification.fromJson(
      jsonDecode(row.dataJson) as Map<String, dynamic>,
    );
  }

  Future<void> upsertNotification(AppNotification notification) =>
      into(notifications).insertOnConflictUpdate(
        NotificationsCompanion.insert(
          recipientScope: notification.recipientScope,
          notificationId: notification.notificationId,
          dataJson: jsonEncode(notification.toJson()),
        ),
      );

  Future<void> deleteNotification(
    String recipientScope,
    String notificationId,
  ) =>
      (delete(notifications)..where(
            (t) =>
                t.recipientScope.equals(recipientScope) &
                t.notificationId.equals(notificationId),
          ))
          .go();

  Future<void> clearNotificationsForScope(String recipientScope) => (delete(
    notifications,
  )..where((t) => t.recipientScope.equals(recipientScope))).go();

  // endregion

  // region device tokens

  Stream<List<DeviceToken>> watchDeviceTokens(String recipientScope) =>
      (select(
        deviceTokens,
      )..where((t) => t.recipientScope.equals(recipientScope))).watch().map(
        (rows) => rows
            .map(
              (r) => DeviceToken.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<DeviceToken?> getDeviceTokenByToken(
    String recipientScope,
    String token,
  ) async {
    final rows = await (select(
      deviceTokens,
    )..where((t) => t.recipientScope.equals(recipientScope))).get();
    for (final row in rows) {
      final deviceToken = DeviceToken.fromJson(
        jsonDecode(row.dataJson) as Map<String, dynamic>,
      );
      if (deviceToken.token == token) return deviceToken;
    }
    return null;
  }

  Future<void> upsertDeviceToken(DeviceToken deviceToken) =>
      into(deviceTokens).insertOnConflictUpdate(
        DeviceTokensCompanion.insert(
          recipientScope: deviceToken.recipientScope,
          deviceTokenId: deviceToken.deviceTokenId,
          dataJson: jsonEncode(deviceToken.toJson()),
        ),
      );

  Future<void> deleteDeviceToken(String recipientScope, String deviceTokenId) =>
      (delete(deviceTokens)..where(
            (t) =>
                t.recipientScope.equals(recipientScope) &
                t.deviceTokenId.equals(deviceTokenId),
          ))
          .go();

  Future<void> clearDeviceTokensForScope(String recipientScope) => (delete(
    deviceTokens,
  )..where((t) => t.recipientScope.equals(recipientScope))).go();

  Future<void> remapDeviceTokenId({
    required String recipientScope,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(deviceTokens)..where(
              (t) =>
                  t.recipientScope.equals(recipientScope) &
                  t.deviceTokenId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    final remapped = DeviceToken.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(deviceTokenId: newId);
    await deleteDeviceToken(recipientScope, oldId);
    await upsertDeviceToken(remapped);
  });

  // endregion

  // --- AttendanceEmailRequest DAOs ---

  /// Reactive stream of all [AttendanceEmailRequest] rows for the given organization.
  Stream<List<AttendanceEmailRequest>> watchAttendanceEmailRequestsByOrg(
    String organizationId,
  ) =>
      (select(attendanceEmailRequests)
            ..where((t) => t.organizationId.equals(organizationId)))
          .watch()
          .map((rows) => rows.map(_attendanceEmailRequestRowToDomain).toList());

  /// Inserts a new [AttendanceEmailRequest] row. Used for optimistic creation.
  Future<void> insertAttendanceEmailRequest(AttendanceEmailRequest request) =>
      into(
        attendanceEmailRequests,
      ).insert(_attendanceEmailRequestDomainToRow(request));

  /// Inserts or replaces a [AttendanceEmailRequest] row.
  Future<void> upsertAttendanceEmailRequest(AttendanceEmailRequest request) =>
      into(
        attendanceEmailRequests,
      ).insertOnConflictUpdate(_attendanceEmailRequestDomainToRow(request));

  /// Deletes the [AttendanceEmailRequest] row identified by [attendanceEmailRequestId].
  Future<void> deleteAttendanceEmailRequest(String attendanceEmailRequestId) =>
      (delete(attendanceEmailRequests)..where(
            (t) => t.attendanceEmailRequestId.equals(attendanceEmailRequestId),
          ))
          .go();

  /// Returns the [AttendanceEmailRequest] row identified by [attendanceEmailRequestId],
  /// or `null` if not cached locally.
  Future<AttendanceEmailRequest?> getAttendanceEmailRequestById(
    String attendanceEmailRequestId,
  ) async {
    final row =
        await (select(attendanceEmailRequests)..where(
              (t) =>
                  t.attendanceEmailRequestId.equals(attendanceEmailRequestId),
            ))
            .getSingleOrNull();
    return row == null ? null : _attendanceEmailRequestRowToDomain(row);
  }

  /// Clears all [AttendanceEmailRequest] rows for the given organization. Used when
  /// applying a bootstrap [ScopeSyncResult] for an `organization:{id}` scope.
  Future<void> clearAttendanceEmailRequestsForOrg(String organizationId) =>
      (delete(
        attendanceEmailRequests,
      )..where((t) => t.organizationId.equals(organizationId))).go();

  /// Remaps the primary key of a [AttendanceEmailRequest] row from a `tmp_*` id
  /// to the server-allocated real id. Done as a delete + insert in a transaction
  /// because [attendanceEmailRequestId] is the PK.
  Future<void> remapAttendanceEmailRequestId({
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(attendanceEmailRequests)
              ..where((t) => t.attendanceEmailRequestId.equals(oldId)))
            .getSingleOrNull();
    if (existing == null) return;
    final request = _attendanceEmailRequestRowToDomain(existing);
    await (delete(
      attendanceEmailRequests,
    )..where((t) => t.attendanceEmailRequestId.equals(oldId))).go();
    await upsertAttendanceEmailRequest(
      request.copyWith(attendanceEmailRequestId: newId),
    );
  });

  // --- ErrorReport DAOs ---

  /// Reactive stream of all [ErrorReport] rows in the local cache.
  Stream<List<ErrorReport>> watchAllErrorReports() => select(
    errorReports,
  ).watch().map((rows) => rows.map(_errorReportRowToDomain).toList());

  /// Inserts or replaces an [ErrorReport] row.
  Future<void> upsertErrorReport(ErrorReport report) => into(
    errorReports,
  ).insertOnConflictUpdate(_errorReportDomainToRow(report));

  /// Deletes the [ErrorReport] row identified by [errorReportId].
  Future<void> deleteErrorReport(String errorReportId) => (delete(
    errorReports,
  )..where((t) => t.errorReportId.equals(errorReportId))).go();

  /// Clears all [ErrorReport] rows. Used when applying a bootstrap result.
  Future<void> clearAllErrorReports() => delete(errorReports).go();

  /// Remaps the primary key of an [ErrorReport] row from a `tmp_*` id to the
  /// server-allocated real id. Done as delete + insert in a transaction because
  /// [errorReportId] is the PK.
  Future<void> remapErrorReportId({
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing = await (select(
      errorReports,
    )..where((t) => t.errorReportId.equals(oldId))).getSingleOrNull();
    if (existing == null) return;
    final report = _errorReportRowToDomain(existing);
    await (delete(
      errorReports,
    )..where((t) => t.errorReportId.equals(oldId))).go();
    await upsertErrorReport(report.copyWith(errorReportId: newId));
  });

  Future<void> clearScopeData(String scopeKey) async {
    final scope = SyncScope.fromKey(scopeKey);
    switch (scope) {
      case ProducerAccountSyncScope(:final producerAccountId):
        await clearProductTypesForTenant(producerAccountId);
        await clearProducerAccountsForTenant(producerAccountId);
        // Producers' private feed also carries their notifications + device tokens (ADR-005).
        await clearNotificationsForScope(scope.key);
        await clearDeviceTokensForScope(scope.key);
      case OrganizationSyncScope(:final organizationId):
        await clearOrganizationsForTenant(organizationId);
        await clearProducerAccountsForTenant(organizationId);
        await clearMembersForOrganization(organizationId);
        await clearMemberInvitationsForOrganization(organizationId);
        await clearMemberJoinRequestsForOrganization(organizationId);
        await clearContractsForOrganization(organizationId);
        await clearDeliveryTemplatesForOrganization(organizationId);
        await clearBasketExchangesForOrg(organizationId);
        await clearAttendanceEmailRequestsForOrg(organizationId);
      case MemberSyncScope():
        await clearNotificationsForScope(scope.key);
        await clearDeviceTokensForScope(scope.key);
      case OwnerSyncScope():
        await clearNotificationsForScope(scope.key);
        await clearDeviceTokensForScope(scope.key);
      case InstanceOwnerSyncScope():
        // OWNER instance-wide feed carries Organization + OrganizationRequest
        // + ProducerRequest + Owner + Member + ProducerAccount. Re-bootstrap clears every
        // table that participates in that scope to avoid stale rows.
        await clearOrganizationRequests();
        await clearProducerRequests();
        await clearOwners();
        await clearOwnerInvitations();
        await delete(organizations).go();
        await delete(members).go();
        await delete(producerAccounts).go();
    }
  }

  Future<void> clearAll() => transaction(() async {
    await delete(productTypes).go();
    await delete(syncCursors).go();
    await delete(pendingMutations).go();
    await delete(organizations).go();
    await delete(producerAccounts).go();
    await delete(members).go();
    await delete(memberInvitations).go();
    await delete(memberJoinRequests).go();
    await delete(contracts).go();
    await delete(deliveryTemplates).go();
    await delete(organizationRequests).go();
    await delete(producerRequests).go();
    await delete(owners).go();
    await delete(ownerInvitations).go();
    await delete(basketExchanges).go();
    await delete(notifications).go();
    await delete(deviceTokens).go();
    await delete(attendanceEmailRequests).go();
    await delete(errorReports).go();
  });

  Future<void> remapMemberId({
    required String organizationId,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(members)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.memberId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    final member = Member.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(memberId: newId);
    await (delete(members)..where(
          (t) =>
              t.organizationId.equals(organizationId) &
              t.memberId.equals(oldId),
        ))
        .go();
    await upsertMember(organizationId, member);
  });

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

  Future<void> remapMemberInvitationId({
    required String organizationId,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(memberInvitations)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.invitationId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    final invitation = MemberInvitation.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(invitationId: newId);
    await (delete(memberInvitations)..where(
          (t) =>
              t.organizationId.equals(organizationId) &
              t.invitationId.equals(oldId),
        ))
        .go();
    await upsertMemberInvitation(organizationId, invitation);
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

  Future<void> remapOwnerInvitationId({
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing = await (select(
      ownerInvitations,
    )..where((t) => t.invitationId.equals(oldId))).getSingleOrNull();
    if (existing == null) return;
    final invitation = OwnerInvitation.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(invitationId: newId);
    await (delete(
      ownerInvitations,
    )..where((t) => t.invitationId.equals(oldId))).go();
    await upsertOwnerInvitation(invitation);
  });

  Future<List<PendingClientMutation>> _resolvePendingMutationEntries(
    List<PendingMutation> rows,
  ) async {
    final rawEntries = rows.map(_pendingMutationFromRow).toList();
    if (rawEntries.isEmpty) return rawEntries;

    final resolvedByOpId = <String, String?>{
      for (final entry in rawEntries) entry.clientOpId: entry.scopeKey,
    };

    var changed = true;
    while (changed) {
      changed = false;
      for (final entry in rawEntries) {
        if (resolvedByOpId[entry.clientOpId] != null) continue;
        final resolved = await _resolveLegacyScopeKey(
          entry,
          rawEntries,
          resolvedByOpId,
        );
        if (resolved == null) continue;
        resolvedByOpId[entry.clientOpId] = resolved;
        changed = true;
      }
    }

    final resolvedEntries = <PendingClientMutation>[];
    for (final entry in rawEntries) {
      final resolvedScopeKey = resolvedByOpId[entry.clientOpId];
      if (entry.storedScopeKey != resolvedScopeKey &&
          resolvedScopeKey != null) {
        await _writePendingMutationScopeKey(entry.clientOpId, resolvedScopeKey);
      }
      resolvedEntries.add(entry.copyWith(scopeKey: resolvedScopeKey));
    }
    return resolvedEntries;
  }

  Future<String?> _resolveLegacyScopeKey(
    PendingClientMutation entry,
    List<PendingClientMutation> allEntries,
    Map<String, String?> resolvedByOpId,
  ) async {
    final direct = scopeKeyForMutation(entry.mutation);
    if (direct != null) return direct;

    final op = entry.mutation.op;
    if (op is! Delete) {
      return null;
    }

    final queueCandidates = allEntries
        .where((candidate) => candidate.clientOpId != entry.clientOpId)
        .map((candidate) {
          final scopeKey = resolvedByOpId[candidate.clientOpId];
          if (scopeKey == null) return null;
          if (!_mutationTargetsEntity(
            candidate.mutation,
            entityType: op.entityType,
            entityId: op.entityId,
          )) {
            return null;
          }
          return scopeKey;
        })
        .whereType<String>()
        .toSet();
    if (queueCandidates.length == 1) {
      return queueCandidates.single;
    }

    final persistedCandidates = await _scopeCandidatesForEntity(
      entityType: op.entityType,
      entityId: op.entityId,
    );
    if (persistedCandidates.length == 1) {
      return persistedCandidates.single;
    }
    return null;
  }

  bool _mutationTargetsEntity(
    ClientMutation mutation, {
    required EntityType entityType,
    required String entityId,
  }) {
    final op = mutation.op;
    return switch (op) {
      Upsert(:final payload) =>
        payload.entityType == entityType &&
            _entityIdForPayload(payload) == entityId,
      Delete(entityType: final candidateType, entityId: final candidateId) =>
        candidateType == entityType && candidateId == entityId,
    };
  }

  String _entityIdForPayload(EntityPayload payload) => switch (payload) {
    ProductTypePayload(:final productType) => productType.productTypeId,
    OrganizationPayload(:final organization) => organization.organizationId,
    ProducerAccountPayload(:final producerAccount) =>
      producerAccount.producerAccountId,
    MemberPayload(:final member) => member.memberId,
    MemberJoinRequestPayload(:final memberJoinRequest) =>
      memberJoinRequest.requestId,
    ContractPayload(:final contract) => contract.contractId,
    DeliveryTemplatePayload(:final deliveryTemplate) =>
      deliveryTemplate.deliveryTemplateId,
    OrganizationRequestPayload(:final organizationRequest) =>
      organizationRequest.requestId,
    ProducerRequestPayload(:final producerRequest) => producerRequest.requestId,
    OwnerPayload(:final owner) => owner.ownerId,
    MemberInvitationPayload(:final memberInvitation) =>
      memberInvitation.invitationId,
    OwnerInvitationPayload(:final ownerInvitation) =>
      ownerInvitation.invitationId,
    BasketExchangePayload(:final basketExchange) =>
      basketExchange.basketExchangeId,
    NotificationPayload(:final notification) => notification.notificationId,
    DeviceTokenPayload(:final deviceToken) => deviceToken.deviceTokenId,
    AttendanceEmailRequestPayload(:final attendanceEmailRequest) =>
      attendanceEmailRequest.attendanceEmailRequestId,
    ErrorReportPayload(:final errorReport) => errorReport.errorReportId,
  };

  Future<Set<String>> _scopeCandidatesForEntity({
    required EntityType entityType,
    required String entityId,
  }) async {
    switch (entityType) {
      case EntityType.productType:
        final rows = await (select(
          productTypes,
        )..where((t) => t.productTypeId.equals(entityId))).get();
        return rows
            .map((row) => producerAccountScopeKey(row.producerAccountId))
            .toSet();
      case EntityType.organization:
        return {organizationScopeKey(entityId)};
      case EntityType.producerAccount:
        return {producerAccountScopeKey(entityId)};
      case EntityType.member:
        final rows = await (select(
          members,
        )..where((t) => t.memberId.equals(entityId))).get();
        return rows
            .map((row) => organizationScopeKey(row.organizationId))
            .toSet();
      case EntityType.memberJoinRequest:
        final rows = await (select(
          memberJoinRequests,
        )..where((t) => t.requestId.equals(entityId))).get();
        return rows
            .map((row) => organizationScopeKey(row.organizationId))
            .toSet();
      case EntityType.contract:
        final rows = await (select(
          contracts,
        )..where((t) => t.contractId.equals(entityId))).get();
        return rows
            .map((row) => organizationScopeKey(row.organizationId))
            .toSet();
      case EntityType.deliveryTemplate:
        final rows = await (select(
          deliveryTemplates,
        )..where((t) => t.deliveryTemplateId.equals(entityId))).get();
        return rows
            .map((row) => organizationScopeKey(row.organizationId))
            .toSet();
      case EntityType.organizationRequest:
        return {instanceOwnerScopeKey};
      case EntityType.producerRequest:
        return {instanceOwnerScopeKey};
      case EntityType.owner:
        return {instanceOwnerScopeKey};
      case EntityType.memberInvitation:
        final rows = await (select(
          memberInvitations,
        )..where((t) => t.invitationId.equals(entityId))).get();
        return rows
            .map((row) => organizationScopeKey(row.organizationId))
            .toSet();
      case EntityType.ownerInvitation:
        return {instanceOwnerScopeKey};
      case EntityType.basketExchange:
        final rows = await (select(
          basketExchanges,
        )..where((t) => t.basketExchangeId.equals(entityId))).get();
        return rows
            .map((row) => organizationScopeKey(row.organizationId))
            .toSet();
      case EntityType.notification:
        final rows = await (select(
          notifications,
        )..where((t) => t.notificationId.equals(entityId))).get();
        return rows.map((row) => row.recipientScope).toSet();
      case EntityType.deviceToken:
        final rows = await (select(
          deviceTokens,
        )..where((t) => t.deviceTokenId.equals(entityId))).get();
        return rows.map((row) => row.recipientScope).toSet();
      case EntityType.attendanceEmailRequest:
        final rows = await (select(
          attendanceEmailRequests,
        )..where((t) => t.attendanceEmailRequestId.equals(entityId))).get();
        return rows
            .map((row) => organizationScopeKey(row.organizationId))
            .toSet();
      case EntityType.errorReport:
        // ErrorReport scope is resolved at enqueue time from the available
        // sync cursors. No entity-level scope lookup is possible here.
        return {};
    }
  }

  Future<void> _writePendingMutationScopeKey(
    String clientOpId,
    String scopeKey,
  ) => (update(pendingMutations)..where((t) => t.clientOpId.equals(clientOpId)))
      .write(PendingMutationsCompanion(scopeKey: Value(scopeKey)));
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

Owner _ownerRowToDomain(OwnerRow row) => Owner(
  ownerId: row.ownerId,
  firstName: row.firstName,
  lastName: row.lastName,
  email: row.email,
  phone: row.phone,
  accountStatus: AccountStatus.values.firstWhere(
    (s) => s.name.toUpperCase() == row.accountStatus,
    orElse: () => AccountStatus.active,
  ),
  registeredAt: row.registeredAt,
  updatedAt: row.updatedAt,
  userPreferences: row.userPreferences == null
      ? null
      : UserPreferences.fromJson(
          jsonDecode(row.userPreferences!) as Map<String, Object?>,
        ),
);

OwnersCompanion _ownerDomainToRow(Owner owner) => OwnersCompanion.insert(
  ownerId: owner.ownerId,
  firstName: owner.firstName,
  lastName: owner.lastName,
  email: owner.email,
  phone: Value(owner.phone),
  accountStatus: owner.accountStatus.name.toUpperCase(),
  registeredAt: owner.registeredAt,
  updatedAt: owner.updatedAt,
  userPreferences: Value(
    owner.userPreferences == null
        ? null
        : jsonEncode(owner.userPreferences!.toJson()),
  ),
);

PendingClientMutation _pendingMutationFromRow(PendingMutation row) {
  final mutation = ClientMutation.fromJson(
    jsonDecode(row.payloadJson) as Map<String, dynamic>,
  );
  return PendingClientMutation(
    clientOpId: row.clientOpId,
    storedScopeKey: _normalizeStoredScopeKey(row.scopeKey),
    scopeKey: _normalizeStoredScopeKey(row.scopeKey),
    mutation: mutation,
    createdAt: row.createdAt,
  );
}

String? _normalizeStoredScopeKey(String? scopeKey) =>
    scopeKey == null || scopeKey.isEmpty ? null : scopeKey;

class PendingClientMutation {
  const PendingClientMutation({
    required this.clientOpId,
    required this.storedScopeKey,
    required this.scopeKey,
    required this.mutation,
    required this.createdAt,
  });

  final String clientOpId;
  final String? storedScopeKey;
  final String? scopeKey;
  final ClientMutation mutation;
  final int createdAt;

  PendingClientMutation copyWith({
    String? storedScopeKey,
    String? scopeKey,
    ClientMutation? mutation,
    int? createdAt,
  }) => PendingClientMutation(
    clientOpId: clientOpId,
    storedScopeKey: storedScopeKey ?? this.storedScopeKey,
    scopeKey: scopeKey ?? this.scopeKey,
    mutation: mutation ?? this.mutation,
    createdAt: createdAt ?? this.createdAt,
  );
}

BasketExchange _basketExchangeRowToDomain(BasketExchangeRow row) {
  final requests = (jsonDecode(row.requestsJson) as List<dynamic>)
      .map((e) => BasketExchangeRequest.fromJson(e as Map<String, dynamic>))
      .toList();
  return BasketExchange(
    basketExchangeId: row.basketExchangeId,
    organizationId: row.organizationId,
    deliveryId: row.deliveryId,
    contractId: row.contractId,
    offeringMemberId: row.offeringMemberId,
    motive: row.motive,
    status: BasketExchangeStatus.values.firstWhere(
      (s) => s.name.toUpperCase() == row.status,
    ),
    createdAt: row.createdAt,
    decidedAt: row.decidedAt,
    acceptedRequestId: row.acceptedRequestId,
    requests: requests,
  );
}

BasketExchangesCompanion _basketExchangeDomainToRow(BasketExchange exchange) =>
    BasketExchangesCompanion.insert(
      basketExchangeId: exchange.basketExchangeId,
      organizationId: exchange.organizationId,
      deliveryId: exchange.deliveryId,
      contractId: exchange.contractId,
      offeringMemberId: exchange.offeringMemberId,
      motive: Value(exchange.motive),
      status: exchange.status.name.toUpperCase(),
      createdAt: exchange.createdAt,
      decidedAt: Value(exchange.decidedAt),
      acceptedRequestId: Value(exchange.acceptedRequestId),
      requestsJson: jsonEncode(
        exchange.requests.map((r) => r.toJson()).toList(),
      ),
    );

AttendanceEmailRequest _attendanceEmailRequestRowToDomain(
  AttendanceEmailRequestRow row,
) => AttendanceEmailRequest(
  attendanceEmailRequestId: row.attendanceEmailRequestId,
  organizationId: row.organizationId,
  deliveryId: row.deliveryId,
  recipientEmail: row.recipientEmail,
  requestedAt: row.requestedAt,
  sentAt: row.sentAt,
);

AttendanceEmailRequestsCompanion _attendanceEmailRequestDomainToRow(
  AttendanceEmailRequest request,
) => AttendanceEmailRequestsCompanion.insert(
  attendanceEmailRequestId: request.attendanceEmailRequestId,
  organizationId: request.organizationId,
  deliveryId: request.deliveryId,
  recipientEmail: request.recipientEmail,
  requestedAt: request.requestedAt,
  sentAt: Value(request.sentAt),
);

ErrorReport _errorReportRowToDomain(ErrorReportRow row) => ErrorReport(
  errorReportId: row.errorReportId,
  errorMessage: row.errorMessage,
  reportedAt: row.reportedAt,
);

ErrorReportsCompanion _errorReportDomainToRow(ErrorReport report) =>
    ErrorReportsCompanion.insert(
      errorReportId: report.errorReportId,
      errorMessage: report.errorMessage,
      reportedAt: report.reportedAt,
    );

class _BasketSizesConverter extends TypeConverter<List<BasketSize>, String> {
  const _BasketSizesConverter();

  @override
  List<BasketSize> fromSql(String fromDb) {
    try {
      final list = jsonDecode(fromDb) as List<dynamic>;
      return list
          .map((e) => BasketSize.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      return [];
    }
  }

  @override
  String toSql(List<BasketSize> value) =>
      jsonEncode(value.map((e) => e.toJson()).toList());
}
