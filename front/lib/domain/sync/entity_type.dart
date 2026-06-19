import 'package:json_annotation/json_annotation.dart';

/// Closed enumeration of domain entity types eligible to the offline-first sync
/// protocol. Mirrors `persistence.model.EntityType` on the back.
enum EntityType {
  @JsonValue('ProductType')
  productType,
  @JsonValue('Organization')
  organization,
  @JsonValue('ProducerAccount')
  producerAccount,
  @JsonValue('Member')
  member,
  @JsonValue('MemberJoinRequest')
  memberJoinRequest,
  @JsonValue('Contract')
  contract,
  @JsonValue('DeliveryTemplate')
  deliveryTemplate,
  @JsonValue('OrganizationRequest')
  organizationRequest,
  @JsonValue('ProducerRequest')
  producerRequest,
  @JsonValue('Owner')
  owner,
  @JsonValue('MemberInvitation')
  memberInvitation,
  @JsonValue('OwnerInvitation')
  ownerInvitation,
  @JsonValue('BasketExchange')
  basketExchange,
  @JsonValue('Notification')
  notification,
  @JsonValue('DeviceToken')
  deviceToken,
  @JsonValue('AttendanceEmailRequest')
  attendanceEmailRequest,
  @JsonValue('ErrorReport')
  errorReport,
}

/// Wire-format mapping kept in sync with the `@JsonValue` annotations above.
/// Used by hand-rolled `MutationOp.Delete` JSON encoding (json_serializable's
/// generated map is private per file).
const Map<EntityType, String> entityTypeWireNames = {
  EntityType.productType: 'ProductType',
  EntityType.organization: 'Organization',
  EntityType.producerAccount: 'ProducerAccount',
  EntityType.member: 'Member',
  EntityType.memberJoinRequest: 'MemberJoinRequest',
  EntityType.contract: 'Contract',
  EntityType.deliveryTemplate: 'DeliveryTemplate',
  EntityType.organizationRequest: 'OrganizationRequest',
  EntityType.producerRequest: 'ProducerRequest',
  EntityType.owner: 'Owner',
  EntityType.memberInvitation: 'MemberInvitation',
  EntityType.ownerInvitation: 'OwnerInvitation',
  EntityType.basketExchange: 'BasketExchange',
  EntityType.notification: 'Notification',
  EntityType.deviceToken: 'DeviceToken',
  EntityType.attendanceEmailRequest: 'AttendanceEmailRequest',
  EntityType.errorReport: 'ErrorReport',
};

EntityType entityTypeFromWire(String value) => entityTypeWireNames.entries
    .firstWhere(
      (e) => e.value == value,
      orElse: () => throw FormatException('Unknown EntityType: $value'),
    )
    .key;
