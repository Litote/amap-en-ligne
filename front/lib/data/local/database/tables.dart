part of '../database.dart';

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
  TextColumn get scopeKey => text()();
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
