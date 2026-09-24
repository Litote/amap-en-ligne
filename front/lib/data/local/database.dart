import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/sync/sync_repository.dart'
    show SyncRepository;
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/attendance_email_request.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/device_token.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
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
import 'package:amap_en_ligne/domain/sync/entity_snapshot.dart'
    show EntitySnapshot;
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart'
    show ScopeSyncResult;
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/drift.dart';

import 'database_open_stub.dart'
    if (dart.library.js_interop) 'database_open_web.dart'
    if (dart.library.ffi) 'database_open_native.dart';

part 'database.g.dart';
part 'database/tables.dart';
part 'database/sync_state_queries.dart';
part 'database/organization_queries.dart';
part 'database/producer_queries.dart';
part 'database/member_queries.dart';
part 'database/owner_queries.dart';
part 'database/basket_exchange_queries.dart';
part 'database/feed_queries.dart';

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
class AppDatabase extends _$AppDatabase
    with
        _SyncStateQueries,
        _OrganizationQueries,
        _ProducerQueries,
        _MemberQueries,
        _OwnerQueries,
        _BasketExchangeQueries,
        _FeedQueries {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onUpgrade: _rebuildOnVersionMismatch);

  /// The local database is a server-authoritative cache, so any schema version
  /// mismatch (e.g. a database created before migrations were squashed) is
  /// dropped and recreated; the next sync repopulates it. Tables are listed
  /// from `sqlite_master` so obsolete ones are dropped too.
  Future<void> _rebuildOnVersionMismatch(Migrator m, int from, int to) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%'",
    ).get();
    for (final row in rows) {
      final name = row.read<String>('name').replaceAll('"', '""');
      await customStatement('DROP TABLE IF EXISTS "$name"');
    }
    await m.createAll();
  }

  static QueryExecutor _open() => openDatabaseExecutor();

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
}
