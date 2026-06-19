import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/notification_copy_override.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization.freezed.dart';
part 'organization.g.dart';

enum DeliveryStatus {
  @JsonValue('PLANNED')
  planned,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
}

extension DeliveryStatusX on DeliveryStatus {
  bool get isActive =>
      this != DeliveryStatus.completed && this != DeliveryStatus.cancelled;
}

enum DeliveryContractStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('PREPARED')
  prepared,
  @JsonValue('DISTRIBUTED')
  distributed,
}

enum ActivityType {
  @JsonValue('PREPARATION')
  preparation,
  @JsonValue('RECEPTION')
  reception,
  @JsonValue('DISTRIBUTION')
  distribution,
}

enum SlotStatus {
  @JsonValue('OPEN')
  open,
  @JsonValue('CRITICAL')
  critical,
  @JsonValue('FULL')
  full,
  @JsonValue('CLOSED')
  closed,
  @JsonValue('CANCELLED')
  cancelled,
}

enum RegistrationStatus {
  @JsonValue('REGISTERED')
  registered,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('COMPLETED')
  completed,
}

/// Distinguishes standard volunteer slots from early-arrival (réception anticipée) slots.
///
/// Mirrors back's `SlotKind` enum. Wire values are uppercase (`STANDARD` / `EARLY`).
/// Defaults to [standard] — legacy slots without this field decode correctly.
enum SlotKind {
  @JsonValue('STANDARD')
  standard,
  @JsonValue('EARLY')
  early,
}

@freezed
abstract class MemberRegistration with _$MemberRegistration {
  const factory MemberRegistration({
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'member_email') required String memberEmail,
    // ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
    @JsonKey(name: 'registration_instant') required String registrationInstant,
    required RegistrationStatus status,
  }) = _MemberRegistration;

  factory MemberRegistration.fromJson(Map<String, Object?> json) =>
      _$MemberRegistrationFromJson(json);
}

@freezed
abstract class MemberSlot with _$MemberSlot {
  const factory MemberSlot({
    /// Server-allocated slot identity (nullable for legacy slots not yet
    /// backfilled). Preserved as-is on edits — never generated client-side.
    @JsonKey(name: 'slot_id') String? slotId,
    // ISO-8601 string, e.g. "2025-06-14T09:00:00"
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
    @JsonKey(name: 'activity_type') required ActivityType activityType,
    @JsonKey(name: 'required_volunteers') required int requiredVolunteers,
    @JsonKey(name: 'current_registrations') required int currentRegistrations,
    required SlotStatus status,

    /// Distinguishes standard slots from early-arrival slots.
    /// Defaults to [SlotKind.standard] so legacy JSON without this field
    /// deserializes correctly.
    @JsonKey(name: 'slot_kind') @Default(SlotKind.standard) SlotKind slotKind,
    @Default([]) List<MemberRegistration> registrations,
  }) = _MemberSlot;

  factory MemberSlot.fromJson(Map<String, Object?> json) =>
      _$MemberSlotFromJson(json);
}

@freezed
abstract class DeliveryContract with _$DeliveryContract {
  const factory DeliveryContract({
    @JsonKey(name: 'contract_id') required String contractId,
    @JsonKey(name: 'coordinators')
    @Default(<String>[])
    List<String> coordinators,
    @JsonKey(name: 'basket_quantity') required int basketQuantity,
    @JsonKey(name: 'delivery_description') required String deliveryDescription,
    @JsonKey(name: 'preparation_notes') String? preparationNotes,
    required DeliveryContractStatus status,
    @Default([]) List<MemberSlot> slots,
  }) = _DeliveryContract;

  factory DeliveryContract.fromJson(Map<String, Object?> json) =>
      _$DeliveryContractFromJson(json);
}

@freezed
abstract class DeliveryItem with _$DeliveryItem {
  const factory DeliveryItem({
    @JsonKey(name: 'item_type_id') required String itemTypeId,
    // Tiny denormalised label snapshot (historical accuracy / resilience); the heavy SVG icon is
    // resolved by itemTypeId from the org-level Organization.itemTypes catalog, never duplicated here.
    @Default('') String name,
    String? weight,
  }) = _DeliveryItem;

  factory DeliveryItem.fromJson(Map<String, Object?> json) =>
      _$DeliveryItemFromJson(json);
}

@freezed
abstract class BasketDeliveryDescription with _$BasketDeliveryDescription {
  const factory BasketDeliveryDescription({
    @JsonKey(name: 'product_type_id') required String productTypeId,
    @JsonKey(name: 'basket_size_name') required String basketSizeName,
    @Default(<DeliveryItem>[]) List<DeliveryItem> items,
  }) = _BasketDeliveryDescription;

  factory BasketDeliveryDescription.fromJson(Map<String, Object?> json) =>
      _$BasketDeliveryDescriptionFromJson(json);
}

@freezed
abstract class Delivery with _$Delivery {
  const factory Delivery({
    @JsonKey(name: 'delivery_id') required String deliveryId,
    @JsonKey(name: 'organization_id') required String organizationId,
    // ISO-8601 string, e.g. "2025-06-14T09:00:00"
    @JsonKey(name: 'scheduled_date') required String scheduledDate,
    required DeliveryStatus status,
    @JsonKey(name: 'min_volunteers_required')
    required int minVolunteersRequired,
    @JsonKey(name: 'delivery_template_id') String? deliveryTemplateId,
    // Per-delivery overrides of the template's slot times ("HH:MM"); null falls back
    // to the linked template, then to the hard-coded defaults. An early slot may be
    // defined here even without a template.
    @JsonKey(name: 'standard_end_time') String? standardEndTime,
    @JsonKey(name: 'volunteer_arrival_time') String? volunteerArrivalTime,
    @JsonKey(name: 'early_slot') EarlySlot? earlySlot,
    @Default([]) List<DeliveryContract> contracts,
    @JsonKey(name: 'basket_descriptions')
    @Default(<BasketDeliveryDescription>[])
    List<BasketDeliveryDescription> basketDescriptions,
  }) = _Delivery;

  factory Delivery.fromJson(Map<String, Object?> json) =>
      _$DeliveryFromJson(json);
}

enum OrganizationProducerStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('SUSPENDED')
  suspended,
  @JsonValue('TERMINATED')
  terminated,
}

@freezed
abstract class OrganizationProducer with _$OrganizationProducer {
  const factory OrganizationProducer({
    @JsonKey(name: 'producer_account_id') required String producerAccountId,
    // ISO-8601 instant string, e.g. "2026-05-18T22:23:25.095Z".
    @JsonKey(name: 'association_instant') required String associationInstant,
    required OrganizationProducerStatus status,
  }) = _OrganizationProducer;

  factory OrganizationProducer.fromJson(Map<String, Object?> json) =>
      _$OrganizationProducerFromJson(json);
}

@freezed
abstract class OrgProduct with _$OrgProduct {
  const factory OrgProduct({
    required String name,
    @JsonKey(name: 'product_type_id') required String productTypeId,
    @JsonKey(name: 'producer_account_id') required String producerAccountId,
    @JsonKey(name: 'supported_basket_sizes')
    @Default([])
    List<BasketSize> supportedBasketSizes,
    String? description,
  }) = _OrgProduct;

  factory OrgProduct.fromJson(Map<String, Object?> json) =>
      _$OrgProductFromJson(json);
}

@freezed
abstract class Organization with _$Organization {
  const factory Organization({
    @JsonKey(name: 'organization_id') required String organizationId,
    required String name,
    @JsonKey(name: 'contact_email') required String contactEmail,
    @JsonKey(name: 'active_status') @Default(true) bool activeStatus,
    String? timezone,
    @JsonKey(name: 'default_language') String? defaultLanguage,
    @JsonKey(name: 'default_delivery_template_id', includeIfNull: false)
    String? defaultDeliveryTemplateId,
    String? website,
    // ISO-8601 instant strings, e.g. "2026-05-18T22:23:25.095Z".
    @JsonKey(name: 'created_instant') String? createdInstant,
    @JsonKey(name: 'last_updated_instant') String? lastUpdatedInstant,
    @Default([]) List<OrganizationProducer> producers,
    @Default([]) List<OrgProduct> products,
    @Default([]) List<Delivery> deliveries,
    // Flat, deduplicated catalog of basket components (with their inline SVG icons) referenced by
    // deliveries' basketDescriptions. Stored once per component (not per delivery) and member-synced.
    @JsonKey(name: 'item_types')
    @Default(<ItemType>[])
    List<ItemType> itemTypes,
    @JsonKey(name: 'notification_overrides')
    @Default(<NotificationCategory, NotificationCopyOverride>{})
    Map<NotificationCategory, NotificationCopyOverride> notificationOverrides,
  }) = _Organization;

  factory Organization.fromJson(Map<String, Object?> json) =>
      _$OrganizationFromJson(json);
}

extension OrganizationDeliveryProductsX on Organization {
  /// Returns [Contract]s that are active (date-wise) for the given [Delivery].
  /// If [contracts] is empty or doesn't contain the contract, returns the
  /// [DeliveryContract] IDs as-is (fallback for backward compatibility).
  List<DeliveryContract> activeContractsForDelivery(
    Delivery delivery, {
    List<Contract> contracts = const [],
  }) {
    if (contracts.isEmpty) {
      return delivery.contracts;
    }

    final contractMap = {for (final c in contracts) c.contractId: c};
    return delivery.contracts.where((dc) {
      final contract = contractMap[dc.contractId];
      if (contract == null) return true;

      final deliveryDate = DateTime.parse(delivery.scheduledDate);
      final minDate = DateTime.parse(contract.minDeliveryDate);
      final maxDate = DateTime.parse(contract.maxDeliveryDate);

      return !deliveryDate.isBefore(minDate) && !deliveryDate.isAfter(maxDate);
    }).toList();
  }

  List<OrgProduct> productsForDelivery(
    Delivery delivery, {
    List<Contract> contracts = const [],
  }) {
    final selectedProductTypeIds = delivery.basketDescriptions
        .map((description) => description.productTypeId)
        .toSet();

    List<OrgProduct> visibleProducts;
    if (selectedProductTypeIds.isNotEmpty) {
      visibleProducts = products
          .where(
            (product) => selectedProductTypeIds.contains(product.productTypeId),
          )
          .toList();
    } else if (delivery.contracts.isNotEmpty && contracts.isNotEmpty) {
      final deliveryContractIds = delivery.contracts
          .map((dc) => dc.contractId)
          .toSet();
      final activeContracts = contracts.where(
        (c) => deliveryContractIds.contains(c.contractId),
      );
      final producerIds = activeContracts
          .map((c) => c.producerAccountId)
          .toSet();
      visibleProducts = products
          .where((product) => producerIds.contains(product.producerAccountId))
          .toList();
    } else {
      visibleProducts = const [];
    }

    final seenProductTypeIds = <String>{};
    return visibleProducts
        .where((product) => seenProductTypeIds.add(product.productTypeId))
        .toList();
  }

  List<String> productNamesForDelivery(
    Delivery delivery, {
    List<Contract> contracts = const [],
  }) => productsForDelivery(
    delivery,
    contracts: contracts,
  ).map((product) => product.name).toList();
}
