import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

const String instanceOwnerScopeKey = 'instance-owner';

String producerAccountScopeKey(String producerAccountId) =>
    'producer-account:$producerAccountId';

String organizationScopeKey(String organizationId) =>
    'organization:$organizationId';

/// Private per-recipient notification feed scopes (ADR-005), keyed by the auth subject.
String memberScopeKey(String subject) => 'member:$subject';

String ownerScopeKey(String subject) => 'owner:$subject';

sealed class SyncScope {
  const SyncScope();

  String get key;

  factory SyncScope.fromKey(String key) {
    if (key == instanceOwnerScopeKey) {
      return const InstanceOwnerSyncScope();
    }
    if (key.startsWith('producer-account:')) {
      return ProducerAccountSyncScope(
        producerAccountId: key.substring('producer-account:'.length),
      );
    }
    if (key.startsWith('organization:')) {
      return OrganizationSyncScope(
        organizationId: key.substring('organization:'.length),
      );
    }
    if (key.startsWith('member:')) {
      return MemberSyncScope(subject: key.substring('member:'.length));
    }
    if (key.startsWith('owner:')) {
      return OwnerSyncScope(subject: key.substring('owner:'.length));
    }
    throw FormatException('Unknown sync scope: $key');
  }
}

final class ProducerAccountSyncScope extends SyncScope {
  const ProducerAccountSyncScope({required this.producerAccountId});

  final String producerAccountId;

  @override
  String get key => producerAccountScopeKey(producerAccountId);
}

final class OrganizationSyncScope extends SyncScope {
  const OrganizationSyncScope({required this.organizationId});

  final String organizationId;

  @override
  String get key => organizationScopeKey(organizationId);
}

final class InstanceOwnerSyncScope extends SyncScope {
  const InstanceOwnerSyncScope();

  @override
  String get key => instanceOwnerScopeKey;
}

final class MemberSyncScope extends SyncScope {
  const MemberSyncScope({required this.subject});

  final String subject;

  @override
  String get key => memberScopeKey(subject);
}

final class OwnerSyncScope extends SyncScope {
  const OwnerSyncScope({required this.subject});

  final String subject;

  @override
  String get key => ownerScopeKey(subject);
}

String scopeKeyForPayload(EntityPayload payload) => switch (payload) {
  ProductTypePayload(:final productType) => producerAccountScopeKey(
    productType.producerAccountId,
  ),
  OrganizationPayload(:final organization) => organizationScopeKey(
    organization.organizationId,
  ),
  ProducerAccountPayload(:final producerAccount) => producerAccountScopeKey(
    producerAccount.producerAccountId,
  ),
  MemberPayload(:final member) => organizationScopeKey(member.organizationId),
  MemberJoinRequestPayload(:final memberJoinRequest) => organizationScopeKey(
    memberJoinRequest.organizationId,
  ),
  ContractPayload(:final contract) => organizationScopeKey(
    contract.organizationId,
  ),
  DeliveryTemplatePayload(:final deliveryTemplate) => organizationScopeKey(
    deliveryTemplate.organizationId,
  ),
  OrganizationRequestPayload() => instanceOwnerScopeKey,
  ProducerRequestPayload() => instanceOwnerScopeKey,
  OwnerPayload() => instanceOwnerScopeKey,
  MemberInvitationPayload(:final memberInvitation) => organizationScopeKey(
    memberInvitation.organizationId,
  ),
  OwnerInvitationPayload() => instanceOwnerScopeKey,
  BasketExchangePayload(:final basketExchange) => organizationScopeKey(
    basketExchange.organizationId,
  ),
  NotificationPayload(:final notification) => notification.recipientScope,
  DeviceTokenPayload(:final deviceToken) => deviceToken.recipientScope,
  AttendanceEmailRequestPayload(:final attendanceEmailRequest) =>
    organizationScopeKey(attendanceEmailRequest.organizationId),
  // ErrorReport scope is resolved at enqueue time from the available cursors;
  // this branch is unreachable in normal flow but required for exhaustiveness.
  ErrorReportPayload() => throw UnsupportedError(
    'ErrorReport scope must be resolved from sync cursors at enqueue time.',
  ),
};

String? scopeKeyForDelete({
  required EntityType entityType,
  required String entityId,
}) => switch (entityType) {
  EntityType.organization => organizationScopeKey(entityId),
  EntityType.producerAccount => producerAccountScopeKey(entityId),
  EntityType.organizationRequest => instanceOwnerScopeKey,
  EntityType.producerRequest => instanceOwnerScopeKey,
  EntityType.owner => instanceOwnerScopeKey,
  EntityType.ownerInvitation => instanceOwnerScopeKey,
  EntityType.productType ||
  EntityType.member ||
  EntityType.memberJoinRequest ||
  EntityType.memberInvitation ||
  EntityType.contract ||
  EntityType.deliveryTemplate ||
  EntityType.basketExchange ||
  EntityType.attendanceEmailRequest ||
  // Notification / DeviceToken deletes carry only the entity id; the recipient
  // scope (member:{id}) is not derivable from the id alone, so this stays
  // local-only metadata (null) like the other org/member-scoped entities.
  EntityType.notification ||
  EntityType.deviceToken ||
  // ErrorReport scope is resolved at enqueue time from the available cursors.
  EntityType.errorReport => null,
};

String? scopeKeyForMutation(ClientMutation mutation) => switch (mutation.op) {
  Upsert(:final payload) => scopeKeyForPayload(payload),
  Delete(:final entityType, :final entityId) => scopeKeyForDelete(
    entityType: entityType,
    entityId: entityId,
  ),
};
