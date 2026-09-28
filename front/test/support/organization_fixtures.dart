import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO-8601 datetime string for tomorrow at 18:00.
String tomorrowIso() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return _formatIso(tomorrow.year, tomorrow.month, tomorrow.day);
}

/// Returns an ISO-8601 datetime string for the 15th of the current month at 18:00.
String currentMonthIso() {
  final now = DateTime.now();
  return _formatIso(now.year, now.month, 15);
}

/// Returns an ISO-8601 datetime string for the past (1 year ago) at 18:00.
String pastIso() {
  final past = DateTime.now().subtract(const Duration(days: 365));
  return _formatIso(past.year, past.month, past.day);
}

/// Returns an ISO-8601 datetime string for N days from now at 18:00.
String daysFromNowIso(int days) {
  final date = DateTime.now().add(Duration(days: days));
  return _formatIso(date.year, date.month, date.day);
}

String _formatIso(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}T18:00:00';

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

MemberRegistration buildRegistration({
  String memberId = 'member-1',
  String displayName = 'Jean Dupont',
  String memberEmail = 'jean@example.fr',
  RegistrationStatus status = RegistrationStatus.registered,
  String registrationInstant = '2026-01-15T18:00:00Z',
}) => MemberRegistration(
  memberId: memberId,
  displayName: displayName,
  memberEmail: memberEmail,
  registrationInstant: registrationInstant,
  status: status,
);

MemberSlot buildSlot({
  String startTime = '2025-06-14T18:00:00',
  String endTime = '2025-06-14T20:00:00',
  ActivityType activityType = ActivityType.preparation,
  int requiredVolunteers = 3,
  int currentRegistrations = 0,
  SlotStatus status = SlotStatus.open,
  List<MemberRegistration> registrations = const [],
}) => MemberSlot(
  startTime: startTime,
  endTime: endTime,
  activityType: activityType,
  requiredVolunteers: requiredVolunteers,
  currentRegistrations: currentRegistrations,
  status: status,
  registrations: registrations,
);

DeliveryContract buildContract({
  String contractId = 'c-1',
  List<String> coordinators = const ['member-1'],
  DeliveryContractStatus status = DeliveryContractStatus.pending,
  int basketQuantity = 10,
  String deliveryDescription = 'Panier légumes',
  List<MemberSlot> slots = const [],
}) => DeliveryContract(
  contractId: contractId,
  coordinators: coordinators,
  status: status,
  basketQuantity: basketQuantity,
  deliveryDescription: deliveryDescription,
  slots: slots,
);

Delivery buildDelivery({
  String deliveryId = 'd-1',
  String organizationId = 'org-1',
  String? scheduledDate,
  DeliveryStatus status = DeliveryStatus.planned,
  int minVolunteersRequired = 3,
  List<DeliveryContract> contracts = const [],
  List<BasketDeliveryDescription> basketDescriptions = const [],
}) => Delivery(
  deliveryId: deliveryId,
  organizationId: organizationId,
  scheduledDate: scheduledDate ?? tomorrowIso(),
  status: status,
  minVolunteersRequired: minVolunteersRequired,
  contracts: contracts,
  basketDescriptions: basketDescriptions,
);

Organization buildOrg({
  String organizationId = 'org-1',
  String name = 'AMAP Test',
  String contactEmail = 'test@amap.fr',
  List<OrganizationProducer> producers = const [],
  List<OrgProduct> products = const [],
  List<Delivery> deliveries = const [],
  List<ItemType> itemTypes = const [],
}) => Organization(
  organizationId: organizationId,
  name: name,
  contactEmail: contactEmail,
  producers: producers,
  products: products,
  deliveries: deliveries,
  itemTypes: itemTypes,
);
