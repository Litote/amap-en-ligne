import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

abstract interface class EntitySyncHandler {
  EntityType get entityType;

  Future<void> applyPayload(AppDatabase db, EntityPayload payload);

  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  });

  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  });

  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  });
}

Map<EntityType, EntitySyncHandler> buildEntitySyncHandlers([
  Iterable<EntitySyncHandler> handlers = const [
    ProductTypeSyncHandler(),
    OrganizationSyncHandler(),
    ProducerAccountSyncHandler(),
    MemberSyncHandler(),
    MemberJoinRequestSyncHandler(),
    ContractSyncHandler(),
    DeliveryTemplateSyncHandler(),
    OrganizationRequestSyncHandler(),
    ProducerRequestSyncHandler(),
    OwnerSyncHandler(),
    MemberInvitationSyncHandler(),
    OwnerInvitationSyncHandler(),
    BasketExchangeSyncHandler(),
    NotificationSyncHandler(),
    DeviceTokenSyncHandler(),
    AttendanceEmailRequestSyncHandler(),
    ErrorReportSyncHandler(),
  ],
]) {
  final indexed = <EntityType, EntitySyncHandler>{};
  for (final handler in handlers) {
    final previous = indexed[handler.entityType];
    if (previous != null) {
      throw StateError(
        'Duplicate sync handlers registered for ${handler.entityType}.',
      );
    }
    indexed[handler.entityType] = handler;
  }

  final missing = EntityType.values
      .where((type) => !indexed.containsKey(type))
      .toList();
  if (missing.isNotEmpty) {
    throw StateError('Missing sync handlers for: ${missing.join(', ')}');
  }

  return indexed;
}

final class ProductTypeSyncHandler implements EntitySyncHandler {
  const ProductTypeSyncHandler();

  @override
  EntityType get entityType => EntityType.productType;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final productTypePayload = _requireProductTypePayload(payload);
    return db.upsertProductType(productTypePayload.productType);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteProductType(
    producerAccountId: (SyncScope.fromKey(scopeKey) as ProducerAccountSyncScope)
        .producerAccountId,
    productTypeId: entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final productTypePayload = _requireProductTypePayload(payload);
    final productType = productTypePayload.productType;
    final localId = productType.productTypeId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    return db.remapProductTypeId(
      producerAccountId: productType.producerAccountId,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! ProductTypePayload) return mutation;
      final productType = payload.productType;
      if (productType.productTypeId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: ProductTypePayload(
            productType: productType.copyWith(productTypeId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.productType,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.productType, entityId: newId),
      );
    }
    return mutation;
  }

  ProductTypePayload _requireProductTypePayload(EntityPayload payload) {
    if (payload is ProductTypePayload) {
      return payload;
    }
    throw StateError(
      'Handler for $entityType cannot process payload for ${payload.entityType}.',
    );
  }
}

final class OrganizationSyncHandler implements EntitySyncHandler {
  const OrganizationSyncHandler();

  @override
  EntityType get entityType => EntityType.organization;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! OrganizationPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertOrganization(payload.organization);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) =>
      // Organization id = entityId; clear it.
      db.clearOrganizationsForTenant(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) =>
      // Organization ids are server-allocated at activation, never tmp_*.
      Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

final class ProducerAccountSyncHandler implements EntitySyncHandler {
  const ProducerAccountSyncHandler();

  @override
  EntityType get entityType => EntityType.producerAccount;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! ProducerAccountPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final pa = payload.producerAccount;
    // The organizationId is the tenant id (producer_account_id of the AMAP admin).
    // For the sync protocol the tenantId == producerAccountId here (1:1 scoping).
    return db.upsertProducerAccount(pa.producerAccountId, pa);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) {
    final scope = SyncScope.fromKey(scopeKey);
    // Producer-scope tombstones key by the producer-account-id-as-tenant.
    // Instance-owner (or organization) tombstones: applyPayload stored the
    // row with tenantId == entityId (producer is its own tenant in the
    // local cache — see applyPayload above), so we delete with the same key.
    final tenantId = scope is ProducerAccountSyncScope
        ? scope.producerAccountId
        : entityId;
    return db.deleteProducerAccount(tenantId, entityId);
  }

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! ProducerAccountPayload) {
      return Future.value();
    }
    final producerAccount = payload.producerAccount;
    final localId = producerAccount.producerAccountId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapProducerAccountId(oldId: localId, newId: serverEntityId);
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is ProducerAccountPayload) {
        final producer = payload.producerAccount;
        if (producer.producerAccountId == oldId) {
          return mutation.copyWith(
            op: Upsert(
              payload: ProducerAccountPayload(
                producerAccount: producer.copyWith(producerAccountId: newId),
              ),
            ),
          );
        }
      }
      if (payload is OrganizationPayload) {
        final organization = payload.organization;
        final hasProducerReference = organization.producers.any(
          (producer) => producer.producerAccountId == oldId,
        );
        // NO_ACCOUNT products are no longer included in OrganizationPayload
        // mutations — ProducerAccount.products is the single source of truth.
        // Only rewrite the producers list reference.
        if (!hasProducerReference) {
          return mutation;
        }
        return mutation.copyWith(
          op: Upsert(
            payload: OrganizationPayload(
              organization: organization.copyWith(
                producers: organization.producers
                    .map(
                      (producer) => producer.producerAccountId == oldId
                          ? producer.copyWith(producerAccountId: newId)
                          : producer,
                    )
                    .toList(),
              ),
            ),
          ),
        );
      }
    }
    if (op case Delete(
      entityType: EntityType.producerAccount,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.producerAccount, entityId: newId),
      );
    }
    return mutation;
  }
}

final class MemberSyncHandler implements EntitySyncHandler {
  const MemberSyncHandler();

  @override
  EntityType get entityType => EntityType.member;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! MemberPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final m = payload.member;
    return db.upsertMember(m.organizationId, m);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteMember(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! MemberPayload) {
      return Future.value();
    }
    final member = payload.member;
    final localId = member.memberId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    return db.remapMemberId(
      organizationId: member.organizationId,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! MemberPayload) return mutation;
      final member = payload.member;
      if (member.memberId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: MemberPayload(member: member.copyWith(memberId: newId)),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.member,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.member, entityId: newId),
      );
    }
    return mutation;
  }
}

final class DeliveryTemplateSyncHandler implements EntitySyncHandler {
  const DeliveryTemplateSyncHandler();

  @override
  EntityType get entityType => EntityType.deliveryTemplate;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! DeliveryTemplatePayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final t = payload.deliveryTemplate;
    return db.upsertDeliveryTemplate(t.organizationId, t);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteDeliveryTemplate(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! DeliveryTemplatePayload) {
      return Future.value();
    }
    final t = payload.deliveryTemplate;
    final localId = t.deliveryTemplateId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    return db.remapDeliveryTemplateId(
      organizationId: t.organizationId,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! DeliveryTemplatePayload) return mutation;
      final template = payload.deliveryTemplate;
      if (template.deliveryTemplateId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: DeliveryTemplatePayload(
            deliveryTemplate: template.copyWith(deliveryTemplateId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.deliveryTemplate,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.deliveryTemplate, entityId: newId),
      );
    }
    return mutation;
  }
}

final class MemberJoinRequestSyncHandler implements EntitySyncHandler {
  const MemberJoinRequestSyncHandler();

  @override
  EntityType get entityType => EntityType.memberJoinRequest;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! MemberJoinRequestPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertMemberJoinRequest(payload.memberJoinRequest);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteMemberJoinRequest(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) => Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

final class ContractSyncHandler implements EntitySyncHandler {
  const ContractSyncHandler();

  @override
  EntityType get entityType => EntityType.contract;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! ContractPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final c = payload.contract;
    return db.upsertContract(c.organizationId, c);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteContract(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! ContractPayload) {
      return Future.value();
    }
    final contract = payload.contract;
    final localId = contract.contractId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapContractId(
      organizationId: contract.organizationId,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is ContractPayload) {
        final contract = payload.contract;
        if (contract.contractId != oldId) return mutation;
        return mutation.copyWith(
          op: Upsert(
            payload: ContractPayload(
              contract: contract.copyWith(contractId: newId),
            ),
          ),
        );
      }
      if (payload is OrganizationPayload) {
        final organization = payload.organization;
        final hasContractReference = organization.deliveries.any(
          (d) => d.contracts.any((dc) => dc.contractId == oldId),
        );
        if (!hasContractReference) return mutation;
        return mutation.copyWith(
          op: Upsert(
            payload: OrganizationPayload(
              organization: organization.copyWith(
                deliveries: organization.deliveries.map((d) {
                  final hasRef = d.contracts.any(
                    (dc) => dc.contractId == oldId,
                  );
                  if (!hasRef) return d;
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
              ),
            ),
          ),
        );
      }
      return mutation;
    }
    if (op case Delete(
      entityType: EntityType.contract,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.contract, entityId: newId),
      );
    }
    return mutation;
  }
}

final class OrganizationRequestSyncHandler implements EntitySyncHandler {
  const OrganizationRequestSyncHandler();

  @override
  EntityType get entityType => EntityType.organizationRequest;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! OrganizationRequestPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertOrganizationRequest(payload.organizationRequest);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteOrganizationRequest(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) =>
      // OrganizationRequest ids are server-allocated, never tmp_*.
      Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

final class ProducerRequestSyncHandler implements EntitySyncHandler {
  const ProducerRequestSyncHandler();

  @override
  EntityType get entityType => EntityType.producerRequest;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! ProducerRequestPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertProducerRequest(payload.producerRequest);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteProducerRequest(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) => Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

final class OwnerSyncHandler implements EntitySyncHandler {
  const OwnerSyncHandler();

  @override
  EntityType get entityType => EntityType.owner;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! OwnerPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertOwner(payload.owner);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) =>
      // The back always returns FORBIDDEN for Owner DELETE mutations, but we
      // mirror the delete locally in case a tombstone arrives (e.g. after a
      // future protocol revision or manual cleanup).
      db.deleteOwner(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! OwnerPayload) {
      return Future.value();
    }
    final owner = payload.owner;
    final localId = owner.ownerId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    // Remap: delete + re-insert with the server-allocated id.
    return db.transaction(() async {
      await db.deleteOwner(localId);
      await db.upsertOwner(owner.copyWith(ownerId: serverEntityId));
    });
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! OwnerPayload) return mutation;
      final owner = payload.owner;
      if (owner.ownerId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: OwnerPayload(owner: owner.copyWith(ownerId: newId)),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.owner,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.owner, entityId: newId),
      );
    }
    return mutation;
  }
}

final class MemberInvitationSyncHandler implements EntitySyncHandler {
  const MemberInvitationSyncHandler();

  @override
  EntityType get entityType => EntityType.memberInvitation;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! MemberInvitationPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    final invitation = payload.memberInvitation;
    return db.upsertMemberInvitation(invitation.organizationId, invitation);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteMemberInvitation(
    (SyncScope.fromKey(scopeKey) as OrganizationSyncScope).organizationId,
    entityId,
  );

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! MemberInvitationPayload) {
      return Future.value();
    }
    final invitation = payload.memberInvitation;
    final localId = invitation.invitationId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapMemberInvitationId(
      organizationId: invitation.organizationId,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! MemberInvitationPayload) return mutation;
      final invitation = payload.memberInvitation;
      if (invitation.invitationId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: MemberInvitationPayload(
            memberInvitation: invitation.copyWith(invitationId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.memberInvitation,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.memberInvitation, entityId: newId),
      );
    }
    return mutation;
  }
}

final class OwnerInvitationSyncHandler implements EntitySyncHandler {
  const OwnerInvitationSyncHandler();

  @override
  EntityType get entityType => EntityType.ownerInvitation;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! OwnerInvitationPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertOwnerInvitation(payload.ownerInvitation);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteOwnerInvitation(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! OwnerInvitationPayload) {
      return Future.value();
    }
    final invitation = payload.ownerInvitation;
    final localId = invitation.invitationId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapOwnerInvitationId(oldId: localId, newId: serverEntityId);
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! OwnerInvitationPayload) return mutation;
      final invitation = payload.ownerInvitation;
      if (invitation.invitationId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: OwnerInvitationPayload(
            ownerInvitation: invitation.copyWith(invitationId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.ownerInvitation,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.ownerInvitation, entityId: newId),
      );
    }
    return mutation;
  }
}

/// Sync handler for [BasketExchange] entities on the `organization:{id}` scope.
///
/// The back never allows applyDelete for BasketExchange — tombstones return
/// FORBIDDEN. [deleteEntity] mirrors the delete locally anyway in case a future
/// protocol revision adds tombstone support.
///
/// tmp_* id remap convention for nested requests:
/// When a client submits a request with a `tmp_*` [BasketExchangeRequest.requestId]
/// embedded in [BasketExchange.requests], the back allocates the real request id
/// server-side but returns [MutationOutcome.serverEntityId] = [BasketExchange.basketExchangeId]
/// (the outer aggregate id, not the inner request id). The handler remaps the
/// outer [basketExchangeId] only. The allocated request id is recovered by
/// re-reading the response [BasketExchange] payload returned by the next sync —
/// the back replaces the `tmp_*` request entry with the server-allocated row,
/// so [applyPayload] rewrites [requestsJson] with the authoritative list.
final class BasketExchangeSyncHandler implements EntitySyncHandler {
  const BasketExchangeSyncHandler();

  @override
  EntityType get entityType => EntityType.basketExchange;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! BasketExchangePayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertBasketExchange(payload.basketExchange);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) =>
      // The back always returns FORBIDDEN for BasketExchange DELETE mutations.
      // We mirror the tombstone locally in case of a future protocol revision.
      db.deleteBasketExchange(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! BasketExchangePayload) {
      return Future.value();
    }
    final exchange = payload.basketExchange;
    final localId = exchange.basketExchangeId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    // Remap the outer basketExchangeId. Embedded request ids are recovered by
    // applyPayload rewriting requestsJson from the authoritative server payload.
    return db.remapBasketExchangeId(oldId: localId, newId: serverEntityId);
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! BasketExchangePayload) return mutation;
      final exchange = payload.basketExchange;
      if (exchange.basketExchangeId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: BasketExchangePayload(
            basketExchange: exchange.copyWith(basketExchangeId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.basketExchange,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.basketExchange, entityId: newId),
      );
    }
    return mutation;
  }
}

/// Sync handler for `AppNotification` on the recipient's private scope
/// (`member:{id}` today — see ADR-005). Notifications are server-authoritative:
/// the client only flips `read_at` or archives, so there is no tmp_* id remap.
final class NotificationSyncHandler implements EntitySyncHandler {
  const NotificationSyncHandler();

  @override
  EntityType get entityType => EntityType.notification;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! NotificationPayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertNotification(payload.notification);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteNotification(scopeKey, entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) =>
      // Notifications are created server-side; clients never allocate tmp_* ids.
      Future.value();

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) => mutation;
}

/// Sync handler for `DeviceToken` on the recipient's private scope (ADR-005).
/// Client-authored: the app upserts a `tmp_*` id when it registers a push token,
/// and the server allocates the real id — so this handler remaps it like other
/// client-created entities.
final class DeviceTokenSyncHandler implements EntitySyncHandler {
  const DeviceTokenSyncHandler();

  @override
  EntityType get entityType => EntityType.deviceToken;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final deviceTokenPayload = _require(payload);
    return db.upsertDeviceToken(deviceTokenPayload.deviceToken);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteDeviceToken(scopeKey, entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final deviceToken = _require(payload).deviceToken;
    final localId = deviceToken.deviceTokenId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) {
      return Future.value();
    }
    if (localId == serverEntityId) {
      return Future.value();
    }
    return db.remapDeviceTokenId(
      recipientScope: deviceToken.recipientScope,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! DeviceTokenPayload) return mutation;
      final deviceToken = payload.deviceToken;
      if (deviceToken.deviceTokenId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: DeviceTokenPayload(
            deviceToken: deviceToken.copyWith(deviceTokenId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.deviceToken,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.deviceToken, entityId: newId),
      );
    }
    return mutation;
  }

  DeviceTokenPayload _require(EntityPayload payload) {
    if (payload is DeviceTokenPayload) return payload;
    throw StateError(
      'Handler for $entityType cannot process payload for ${payload.entityType}.',
    );
  }
}

/// Sync handler for [AttendanceEmailRequest] entities on the `organization:{id}` scope.
///
/// The client creates rows with `tmp_*` ids and enqueues an Upsert; the server
/// allocates the real id, sends the email, and returns the entity with [sentAt]
/// populated. This handler remaps the `tmp_*` id once the server outcome arrives.
final class AttendanceEmailRequestSyncHandler implements EntitySyncHandler {
  const AttendanceEmailRequestSyncHandler();

  @override
  EntityType get entityType => EntityType.attendanceEmailRequest;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final p = _require(payload);
    return db.upsertAttendanceEmailRequest(p.attendanceEmailRequest);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteAttendanceEmailRequest(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final p = _require(payload);
    final localId = p.attendanceEmailRequest.attendanceEmailRequestId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapAttendanceEmailRequestId(
      oldId: localId,
      newId: serverEntityId,
    );
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! AttendanceEmailRequestPayload) return mutation;
      final request = payload.attendanceEmailRequest;
      if (request.attendanceEmailRequestId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: AttendanceEmailRequestPayload(
            attendanceEmailRequest: request.copyWith(
              attendanceEmailRequestId: newId,
            ),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.attendanceEmailRequest,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(
          entityType: EntityType.attendanceEmailRequest,
          entityId: newId,
        ),
      );
    }
    return mutation;
  }

  AttendanceEmailRequestPayload _require(EntityPayload payload) {
    if (payload is AttendanceEmailRequestPayload) return payload;
    throw StateError(
      'Handler for $entityType cannot process payload for ${payload.entityType}.',
    );
  }
}

/// Sync handler for [ErrorReport] entities.
///
/// The client creates rows with `tmp_*` ids and enqueues an [Upsert]; the
/// server allocates the real id. This handler remaps the `tmp_*` id once the
/// server outcome arrives.
final class ErrorReportSyncHandler implements EntitySyncHandler {
  const ErrorReportSyncHandler();

  @override
  EntityType get entityType => EntityType.errorReport;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final p = _require(payload);
    return db.upsertErrorReport(p.errorReport);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) => db.deleteErrorReport(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final p = _require(payload);
    final localId = p.errorReport.errorReportId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    return db.remapErrorReportId(oldId: localId, newId: serverEntityId);
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! ErrorReportPayload) return mutation;
      final report = payload.errorReport;
      if (report.errorReportId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: ErrorReportPayload(
            errorReport: report.copyWith(errorReportId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.errorReport,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.errorReport, entityId: newId),
      );
    }
    return mutation;
  }

  ErrorReportPayload _require(EntityPayload payload) {
    if (payload is ErrorReportPayload) return payload;
    throw StateError(
      'Handler for $entityType cannot process payload for ${payload.entityType}.',
    );
  }
}
