import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/notification_copy_override.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Read/write API for `Organization` entities.
///
/// Writes apply optimistically to the local cache and enqueue a
/// `ClientMutation` in the pending queue. The actual flush to the server
/// happens on the next `SyncRepository.sync()` call.
class OrganizationRepository {
  OrganizationRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  /// Reactive stream of all [Organization] rows in the local cache.
  /// Used by instance-wide views (OWNER role).
  Stream<List<Organization>> watchAll() => _db.watchAllOrganizations();

  Stream<Organization?> watch(String organizationId) =>
      _db.watchOrganizationForTenant(organizationId);

  /// Enrolls a new producer into the organization.
  ///
  /// Updates the organization's producer list and products optimistically, then
  /// enqueues an Upsert mutation for the server.
  Future<void> enrollProducer({
    required Organization currentOrg,
    required String producerAccountId,
    required List<OrgProduct> products,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final newProducer = OrganizationProducer(
      producerAccountId: producerAccountId,
      associationInstant: now,
      status: OrganizationProducerStatus.active,
    );
    final updatedOrg = currentOrg.copyWith(
      producers: [...currentOrg.producers, newProducer],
      products: [...currentOrg.products, ...products],
    );
    return _submitOrgMutation(updatedOrg);
  }

  /// Updates the status of a producer in the organization (suspend, reactivate,
  /// or terminate).
  Future<void> updateProducerStatus({
    required Organization currentOrg,
    required String producerAccountId,
    required OrganizationProducerStatus newStatus,
  }) {
    final updatedOrg = currentOrg.copyWith(
      producers: currentOrg.producers
          .map(
            (p) => p.producerAccountId == producerAccountId
                ? p.copyWith(status: newStatus)
                : p,
          )
          .toList(),
    );
    return _submitOrgMutation(updatedOrg);
  }

  /// Updates the list of products assigned to a specific producer in the
  /// organization.
  Future<void> updateProducerProducts({
    required Organization currentOrg,
    required String producerAccountId,
    required List<OrgProduct> products,
  }) {
    final otherProducts = currentOrg.products
        .where((p) => p.producerAccountId != producerAccountId)
        .toList();
    final updatedOrg = currentOrg.copyWith(
      products: [...otherProducts, ...products],
    );
    return _submitOrgMutation(updatedOrg);
  }

  Future<ProducerAccount> createNoAccountProducer({
    required Organization currentOrg,
    required String name,
    String? contactEmail,
    String? address,
    String? website,
    required List<ProducerProduct> products,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final producerAccountId = _idGen.nextTmpId();
    final producer = ProducerAccount(
      producerAccountId: producerAccountId,
      name: name,
      contactEmail: _normalizeOptional(contactEmail),
      address: _normalizeOptional(address),
      website: _normalizeOptional(website),
      managementMode: ProducerManagementMode.noAccount,
      // Both instant fields are required by the back-end contract
      // (MissingFieldException when absent). Stamp them at creation time so the
      // ProducerAccountPayload carries non-null values when syncing.
      createdInstant: now,
      lastUpdatedInstant: now,
      products: products,
      organizations: [
        ProducerOrganization(
          organizationId: currentOrg.organizationId,
          associationInstant: now,
          status: OrganizationProducerStatus.active,
        ),
      ],
    );
    final updatedOrg = currentOrg.copyWith(
      producers: [
        ...currentOrg.producers,
        OrganizationProducer(
          producerAccountId: producerAccountId,
          associationInstant: now,
          status: OrganizationProducerStatus.active,
        ),
      ],
      products: [
        ...currentOrg.products,
        ...products.map(
          (product) => OrgProduct(
            name: product.name,
            productTypeId: product.productTypeId,
            producerAccountId: producerAccountId,
            supportedBasketSizes: product.supportedBasketSizes,
            description: product.description,
          ),
        ),
      ],
    );
    await _db.transaction(() async {
      await _db.upsertProducerAccount(producerAccountId, producer);
      await _db.upsertOrganization(updatedOrg);
      final scopeKey = organizationScopeKey(currentOrg.organizationId);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(
            payload: ProducerAccountPayload(producerAccount: producer),
          ),
        ),
        scopeKey: scopeKey,
      );
      // The Org mutation carries only the updated producers list — NOT the new
      // NO_ACCOUNT products. ProducerAccount.products is the single source of
      // truth for NO_ACCOUNT products, so the back derives them from the PA
      // payload. The org cache is still updated with full products above for
      // responsive UI.
      final orgForPayload = updatedOrg.copyWith(products: currentOrg.products);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(payload: OrganizationPayload(organization: orgForPayload)),
        ),
        scopeKey: scopeKey,
      );
    });
    return producer;
  }

  Future<void> updateNoAccountProducerProducts({
    required Organization currentOrg,
    required ProducerAccount producerAccount,
    required List<ProducerProduct> products,
  }) async {
    final updatedProducer = producerAccount.copyWith(products: products);
    final updatedOrg = currentOrg.copyWith(
      products: [
        ...currentOrg.products.where(
          (product) =>
              product.producerAccountId != producerAccount.producerAccountId,
        ),
        ...products.map(
          (product) => OrgProduct(
            name: product.name,
            productTypeId: product.productTypeId,
            producerAccountId: producerAccount.producerAccountId,
            supportedBasketSizes: product.supportedBasketSizes,
            description: product.description,
          ),
        ),
      ],
    );
    await _db.transaction(() async {
      await _db.upsertProducerAccount(
        updatedProducer.producerAccountId,
        updatedProducer,
      );
      // Keep org cache updated for responsive UI even though we only send the
      // ProducerAccountPayload to the network. PA.products is the single source
      // of truth for NO_ACCOUNT products — no OrganizationPayload mutation needed.
      await _db.upsertOrganization(updatedOrg);
      final scopeKey = organizationScopeKey(currentOrg.organizationId);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(
            payload: ProducerAccountPayload(producerAccount: updatedProducer),
          ),
        ),
        scopeKey: scopeKey,
      );
    });
  }

  Future<void> linkNoAccountProducer({
    required Organization currentOrg,
    required ProducerAccount noAccountProducer,
    required ProducerAccount linkedProducer,
  }) async {
    final updatedNoAccountProducer = noAccountProducer.copyWith(
      linkedProducerAccount: LinkedProducerAccount(
        producerAccountId: linkedProducer.producerAccountId,
        name: linkedProducer.name,
      ),
    );
    final updatedOrg = currentOrg.copyWith(
      producers: currentOrg.producers
          .map(
            (producer) =>
                producer.producerAccountId ==
                    noAccountProducer.producerAccountId
                ? producer.copyWith(
                    producerAccountId: linkedProducer.producerAccountId,
                  )
                : producer,
          )
          .toList(),
      products: currentOrg.products
          .map(
            (product) =>
                product.producerAccountId == noAccountProducer.producerAccountId
                ? product.copyWith(
                    producerAccountId: linkedProducer.producerAccountId,
                  )
                : product,
          )
          .toList(),
    );
    await _db.transaction(() async {
      await _db.upsertProducerAccount(
        updatedNoAccountProducer.producerAccountId,
        updatedNoAccountProducer,
      );
      await _db.upsertOrganization(updatedOrg);
      final scopeKey = organizationScopeKey(currentOrg.organizationId);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(
            payload: ProducerAccountPayload(
              producerAccount: updatedNoAccountProducer,
            ),
          ),
        ),
        scopeKey: scopeKey,
      );
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(payload: OrganizationPayload(organization: updatedOrg)),
        ),
        scopeKey: scopeKey,
      );
    });
  }

  /// Updates the default delivery template reference for the organization.
  Future<void> updateDefaultDeliveryTemplateId({
    required Organization currentOrg,
    required String? defaultDeliveryTemplateId,
  }) {
    final updatedOrg = currentOrg.copyWith(
      defaultDeliveryTemplateId: defaultDeliveryTemplateId,
    );
    return _submitOrgMutation(updatedOrg);
  }

  /// Replaces the organization's per-category notification copy overrides
  /// (title/body) and flushes the updated [Organization] as a mutation.
  /// Entries with both title and body blank are dropped so the back falls back
  /// to the default copy for that category.
  Future<void> updateNotificationOverrides({
    required Organization currentOrg,
    required Map<NotificationCategory, NotificationCopyOverride> overrides,
  }) {
    final cleaned = <NotificationCategory, NotificationCopyOverride>{};
    overrides.forEach((category, override) {
      final title = _normalizeOptional(override.title);
      final body = _normalizeOptional(override.body);
      if (title != null || body != null) {
        cleaned[category] = NotificationCopyOverride(title: title, body: body);
      }
    });
    final updatedOrg = currentOrg.copyWith(notificationOverrides: cleaned);
    return _submitOrgMutation(updatedOrg);
  }

  /// Updates the [RegistrationStatus] of a specific member registration within
  /// a delivery slot, then flushes the updated [Organization] as a mutation.
  Future<void> updateRegistrationStatus({
    required Organization currentOrg,
    required String deliveryId,
    required String contractId,
    required String memberId,
    required RegistrationStatus newStatus,
  }) {
    final updatedOrg = currentOrg.copyWith(
      deliveries: currentOrg.deliveries.map((d) {
        if (d.deliveryId != deliveryId) return d;
        return d.copyWith(
          contracts: d.contracts.map((c) {
            if (c.contractId != contractId) return c;
            return c.copyWith(
              slots: c.slots.map((s) {
                return s.copyWith(
                  registrations: s.registrations.map((r) {
                    if (r.memberId != memberId) return r;
                    return r.copyWith(status: newStatus);
                  }).toList(),
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
    return _submitOrgMutation(updatedOrg);
  }

  /// Registers [me] to the slot identified by ([deliveryId], [contractId],
  /// [slotKind]) within [currentOrg].
  ///
  /// Idempotent: if [me] is already registered in that slot, returns without
  /// writing anything. Otherwise adds a new [MemberRegistration] with status
  /// [RegistrationStatus.registered] and enqueues an [Upsert] mutation.
  Future<void> registerToSlot({
    required Organization currentOrg,
    required String deliveryId,
    required String contractId,
    required SlotKind slotKind,
    required Member me,
  }) {
    bool changed = false;

    final updatedDeliveries = currentOrg.deliveries.map((d) {
      if (d.deliveryId != deliveryId) return d;
      return d.copyWith(
        contracts: d.contracts.map((c) {
          if (c.contractId != contractId) return c;
          return c.copyWith(
            slots: c.slots.map((s) {
              if (s.slotKind != slotKind) return s;
              // Idempotency guard: already registered.
              if (s.registrations.any((r) => r.memberId == me.memberId)) {
                return s;
              }
              changed = true;
              final displayName = '${me.firstName ?? ''} ${me.lastName ?? ''}'
                  .trim();
              final registration = MemberRegistration(
                memberId: me.memberId,
                displayName: displayName,
                memberEmail: me.email ?? '',
                registrationInstant: DateTime.now().toUtc().toIso8601String(),
                status: RegistrationStatus.registered,
              );
              return s.copyWith(
                registrations: [...s.registrations, registration],
                currentRegistrations: s.currentRegistrations + 1,
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList();

    if (!changed) return Future.value();

    final updatedOrg = currentOrg.copyWith(deliveries: updatedDeliveries);
    return _submitOrgMutation(updatedOrg);
  }

  /// Removes the registration of [memberId] from the slot identified by
  /// ([deliveryId], [contractId], [slotKind]) within [currentOrg].
  ///
  /// Idempotent: if no registration for [memberId] exists in that slot,
  /// returns without writing anything.
  Future<void> unregisterFromSlot({
    required Organization currentOrg,
    required String deliveryId,
    required String contractId,
    required SlotKind slotKind,
    required String memberId,
  }) {
    bool changed = false;

    final updatedDeliveries = currentOrg.deliveries.map((d) {
      if (d.deliveryId != deliveryId) return d;
      return d.copyWith(
        contracts: d.contracts.map((c) {
          if (c.contractId != contractId) return c;
          return c.copyWith(
            slots: c.slots.map((s) {
              if (s.slotKind != slotKind) return s;
              final filtered = s.registrations
                  .where((r) => r.memberId != memberId)
                  .toList();
              if (filtered.length == s.registrations.length) return s;
              changed = true;
              return s.copyWith(
                registrations: filtered,
                currentRegistrations: (s.currentRegistrations - 1).clamp(
                  0,
                  s.currentRegistrations,
                ),
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList();

    if (!changed) return Future.value();

    final updatedOrg = currentOrg.copyWith(deliveries: updatedDeliveries);
    return _submitOrgMutation(updatedOrg);
  }

  /// Adds [memberId] to the [DeliveryContract.coordinators] list of the
  /// contract identified by ([deliveryId], [contractId]) within [currentOrg].
  ///
  /// Idempotent: if [memberId] is already in the coordinators list, returns
  /// without writing anything. If the delivery or contract does not exist,
  /// also returns without writing anything.
  Future<void> assignCoordinator({
    required Organization currentOrg,
    required String deliveryId,
    required String contractId,
    required String memberId,
  }) {
    bool changed = false;

    final updatedDeliveries = currentOrg.deliveries.map((d) {
      if (d.deliveryId != deliveryId) return d;
      return d.copyWith(
        contracts: d.contracts.map((c) {
          if (c.contractId != contractId) return c;
          if (c.coordinators.contains(memberId)) return c;
          changed = true;
          return c.copyWith(coordinators: [...c.coordinators, memberId]);
        }).toList(),
      );
    }).toList();

    if (!changed) return Future.value();

    final updatedOrg = currentOrg.copyWith(deliveries: updatedDeliveries);
    return _submitOrgMutation(updatedOrg);
  }

  /// Removes [memberId] from the [DeliveryContract.coordinators] list of the
  /// contract identified by ([deliveryId], [contractId]) within [currentOrg].
  ///
  /// Idempotent: if [memberId] is not in the coordinators list, returns without
  /// writing anything. If the delivery or contract does not exist, also returns
  /// without writing anything.
  Future<void> unassignCoordinator({
    required Organization currentOrg,
    required String deliveryId,
    required String contractId,
    required String memberId,
  }) {
    bool changed = false;

    final updatedDeliveries = currentOrg.deliveries.map((d) {
      if (d.deliveryId != deliveryId) return d;
      return d.copyWith(
        contracts: d.contracts.map((c) {
          if (c.contractId != contractId) return c;
          final filtered = c.coordinators
              .where((id) => id != memberId)
              .toList();
          if (filtered.length == c.coordinators.length) return c;
          changed = true;
          return c.copyWith(coordinators: filtered);
        }).toList(),
      );
    }).toList();

    if (!changed) return Future.value();

    final updatedOrg = currentOrg.copyWith(deliveries: updatedDeliveries);
    return _submitOrgMutation(updatedOrg);
  }

  /// Updates the [DeliveryContractStatus] of a specific contract within a
  /// delivery, writes it optimistically, and enqueues an [Upsert] mutation.
  Future<void> updateDeliveryContractStatus({
    required Organization currentOrg,
    required String deliveryId,
    required String contractId,
    required DeliveryContractStatus newStatus,
  }) {
    final updatedOrg = currentOrg.copyWith(
      deliveries: currentOrg.deliveries.map((d) {
        if (d.deliveryId != deliveryId) return d;
        return d.copyWith(
          contracts: d.contracts.map((c) {
            if (c.contractId != contractId) return c;
            return c.copyWith(status: newStatus);
          }).toList(),
        );
      }).toList(),
    );
    return _submitOrgMutation(updatedOrg);
  }

  /// Adds a new [Delivery] to the organization's delivery list, writes it
  /// optimistically, and enqueues an [Upsert] mutation.
  Future<void> addDelivery({
    required Organization currentOrg,
    required Delivery delivery,
  }) {
    final updatedOrg = currentOrg.copyWith(
      deliveries: [...currentOrg.deliveries, delivery],
    );
    return _submitOrgMutation(updatedOrg);
  }

  /// Replaces an existing [Delivery] (matched by [Delivery.deliveryId]) with
  /// the provided [delivery], writes it optimistically, and enqueues an
  /// [Upsert] mutation.
  Future<void> updateDelivery({
    required Organization currentOrg,
    required Delivery delivery,
  }) {
    final updatedOrg = currentOrg.copyWith(
      deliveries: currentOrg.deliveries
          .map((d) => d.deliveryId == delivery.deliveryId ? delivery : d)
          .toList(),
    );
    return _submitOrgMutation(updatedOrg);
  }

  /// Replaces the entire deliveries list for [currentOrg], writes it
  /// optimistically, and enqueues a single atomic [Upsert] mutation.
  ///
  /// Typical use: applying a [WeeklyDeliveryPlan] result after contract
  /// creation so new/linked deliveries are flushed to the server in one batch.
  Future<void> updateDeliveries({
    required Organization currentOrg,
    required List<Delivery> deliveries,
  }) {
    final updatedOrg = currentOrg.copyWith(deliveries: deliveries);
    return _submitOrgMutation(updatedOrg);
  }

  /// Removes the delivery identified by [deliveryId] from the organization's
  /// delivery list, writes it optimistically, and enqueues an [Upsert]
  /// mutation.
  Future<void> deleteDelivery({
    required Organization currentOrg,
    required String deliveryId,
  }) {
    final updatedOrg = currentOrg.copyWith(
      deliveries: currentOrg.deliveries
          .where((d) => d.deliveryId != deliveryId)
          .toList(),
    );
    return _submitOrgMutation(updatedOrg);
  }

  /// Updates the [BasketDeliveryDescription] list of the delivery identified by
  /// [deliveryId] and the org-level component catalog ([Organization.itemTypes],
  /// where the heavy SVG icons live once), writes both optimistically, and
  /// enqueues a single [Upsert] mutation.
  Future<void> updateDeliveryDescription({
    required Organization currentOrg,
    required String deliveryId,
    required List<BasketDeliveryDescription> basketDescriptions,
    required List<ItemType> itemTypes,
  }) {
    final updatedDelivery = currentOrg.deliveries
        .firstWhere((d) => d.deliveryId == deliveryId)
        .copyWith(basketDescriptions: basketDescriptions);
    final updatedOrg = currentOrg.copyWith(
      itemTypes: itemTypes,
      deliveries: currentOrg.deliveries
          .map((d) => d.deliveryId == deliveryId ? updatedDelivery : d)
          .toList(),
    );
    return _submitOrgMutation(updatedOrg);
  }

  Future<void> _submitOrgMutation(Organization org) =>
      _db.transaction(() async {
        await _db.upsertOrganization(org);
        await _db.enqueuePendingMutation(
          ClientMutation(
            clientOpId: _idGen.next(),
            op: Upsert(payload: OrganizationPayload(organization: org)),
          ),
          scopeKey: organizationScopeKey(org.organizationId),
        );
      });

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
