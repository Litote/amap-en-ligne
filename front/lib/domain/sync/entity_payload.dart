import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/attendance_email_request.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
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
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_payload.freezed.dart';

/// Polymorphic carrier for the typed body of an entity in the sync protocol.
///
/// Wire `type` discriminator matches the corresponding `EntityType` constant
/// on the back. Hand-rolled (rather than Freezed unions) because Freezed 3.x
/// does not emit the discriminator on `toJson` for single-variant unions, and
/// we still want a sealed type for exhaustive `switch`.
sealed class EntityPayload {
  const EntityPayload();

  EntityType get entityType;

  Map<String, dynamic> toJson();

  factory EntityPayload.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'ProductType' => ProductTypePayload.fromJson(json),
        'Organization' => OrganizationPayload.fromJson(json),
        'ProducerAccount' => ProducerAccountPayload.fromJson(json),
        'Member' => MemberPayload.fromJson(json),
        'MemberJoinRequest' => MemberJoinRequestPayload.fromJson(json),
        'Contract' => ContractPayload.fromJson(json),
        'DeliveryTemplate' => DeliveryTemplatePayload.fromJson(json),
        'OrganizationRequest' => OrganizationRequestPayload.fromJson(json),
        'ProducerRequest' => ProducerRequestPayload.fromJson(json),
        'Owner' => OwnerPayload.fromJson(json),
        'MemberInvitation' => MemberInvitationPayload.fromJson(json),
        'OwnerInvitation' => OwnerInvitationPayload.fromJson(json),
        'BasketExchange' => BasketExchangePayload.fromJson(json),
        'Notification' => NotificationPayload.fromJson(json),
        'DeviceToken' => DeviceTokenPayload.fromJson(json),
        'AttendanceEmailRequest' => AttendanceEmailRequestPayload.fromJson(
          json,
        ),
        'ErrorReport' => ErrorReportPayload.fromJson(json),
        final t => throw FormatException('Unknown EntityPayload type: $t'),
      };
}

@Freezed(toJson: false, fromJson: false)
abstract class ProductTypePayload extends EntityPayload
    with _$ProductTypePayload {
  const ProductTypePayload._() : super();
  const factory ProductTypePayload({required ProductType productType}) =
      _ProductTypePayload;

  factory ProductTypePayload.fromJson(Map<String, dynamic> json) =>
      ProductTypePayload(
        productType: ProductType.fromJson(
          json['productType'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.productType;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ProductType',
    'productType': productType.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class OrganizationPayload extends EntityPayload
    with _$OrganizationPayload {
  const OrganizationPayload._() : super();
  const factory OrganizationPayload({required Organization organization}) =
      _OrganizationPayload;

  factory OrganizationPayload.fromJson(Map<String, dynamic> json) =>
      OrganizationPayload(
        organization: Organization.fromJson(
          json['organization'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.organization;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Organization',
    'organization': organization.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class ProducerAccountPayload extends EntityPayload
    with _$ProducerAccountPayload {
  const ProducerAccountPayload._() : super();
  const factory ProducerAccountPayload({
    required ProducerAccount producerAccount,
  }) = _ProducerAccountPayload;

  factory ProducerAccountPayload.fromJson(Map<String, dynamic> json) =>
      ProducerAccountPayload(
        producerAccount: ProducerAccount.fromJson(
          json['producerAccount'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.producerAccount;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ProducerAccount',
    'producerAccount': producerAccount.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class MemberPayload extends EntityPayload with _$MemberPayload {
  const MemberPayload._() : super();
  const factory MemberPayload({required Member member}) = _MemberPayload;

  factory MemberPayload.fromJson(Map<String, dynamic> json) => MemberPayload(
    member: Member.fromJson(json['member'] as Map<String, dynamic>),
  );

  @override
  EntityType get entityType => EntityType.member;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Member',
    'member': member.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class MemberJoinRequestPayload extends EntityPayload
    with _$MemberJoinRequestPayload {
  const MemberJoinRequestPayload._() : super();
  const factory MemberJoinRequestPayload({
    required AdminMemberJoinRequest memberJoinRequest,
  }) = _MemberJoinRequestPayload;

  factory MemberJoinRequestPayload.fromJson(Map<String, dynamic> json) =>
      MemberJoinRequestPayload(
        memberJoinRequest: AdminMemberJoinRequest.fromJson(
          json['memberJoinRequest'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.memberJoinRequest;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'MemberJoinRequest',
    'memberJoinRequest': memberJoinRequest.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class ContractPayload extends EntityPayload with _$ContractPayload {
  const ContractPayload._() : super();
  const factory ContractPayload({required Contract contract}) =
      _ContractPayload;

  factory ContractPayload.fromJson(Map<String, dynamic> json) =>
      ContractPayload(
        contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
      );

  @override
  EntityType get entityType => EntityType.contract;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Contract',
    'contract': contract.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class DeliveryTemplatePayload extends EntityPayload
    with _$DeliveryTemplatePayload {
  const DeliveryTemplatePayload._() : super();
  const factory DeliveryTemplatePayload({
    required DeliveryTemplate deliveryTemplate,
  }) = _DeliveryTemplatePayload;

  factory DeliveryTemplatePayload.fromJson(Map<String, dynamic> json) =>
      DeliveryTemplatePayload(
        deliveryTemplate: DeliveryTemplate.fromJson(
          json['deliveryTemplate'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.deliveryTemplate;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'DeliveryTemplate',
    'deliveryTemplate': deliveryTemplate.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class OrganizationRequestPayload extends EntityPayload
    with _$OrganizationRequestPayload {
  const OrganizationRequestPayload._() : super();
  const factory OrganizationRequestPayload({
    required AdminOrganizationRequest organizationRequest,
  }) = _OrganizationRequestPayload;

  factory OrganizationRequestPayload.fromJson(Map<String, dynamic> json) =>
      OrganizationRequestPayload(
        organizationRequest: AdminOrganizationRequest.fromJson(
          json['organizationRequest'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.organizationRequest;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'OrganizationRequest',
    'organizationRequest': organizationRequest.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class ProducerRequestPayload extends EntityPayload
    with _$ProducerRequestPayload {
  const ProducerRequestPayload._() : super();
  const factory ProducerRequestPayload({
    required AdminProducerRequest producerRequest,
  }) = _ProducerRequestPayload;

  factory ProducerRequestPayload.fromJson(Map<String, dynamic> json) =>
      ProducerRequestPayload(
        producerRequest: AdminProducerRequest.fromJson(
          json['producerRequest'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.producerRequest;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ProducerRequest',
    'producerRequest': producerRequest.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class OwnerPayload extends EntityPayload with _$OwnerPayload {
  const OwnerPayload._() : super();
  const factory OwnerPayload({required Owner owner}) = _OwnerPayload;

  factory OwnerPayload.fromJson(Map<String, dynamic> json) => OwnerPayload(
    owner: Owner.fromJson(json['owner'] as Map<String, dynamic>),
  );

  @override
  EntityType get entityType => EntityType.owner;

  @override
  Map<String, dynamic> toJson() => {'type': 'Owner', 'owner': owner.toJson()};
}

@Freezed(toJson: false, fromJson: false)
abstract class MemberInvitationPayload extends EntityPayload
    with _$MemberInvitationPayload {
  const MemberInvitationPayload._() : super();
  const factory MemberInvitationPayload({
    required MemberInvitation memberInvitation,
  }) = _MemberInvitationPayload;

  factory MemberInvitationPayload.fromJson(Map<String, dynamic> json) =>
      MemberInvitationPayload(
        memberInvitation: MemberInvitation.fromJson(
          json['memberInvitation'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.memberInvitation;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'MemberInvitation',
    'memberInvitation': memberInvitation.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class OwnerInvitationPayload extends EntityPayload
    with _$OwnerInvitationPayload {
  const OwnerInvitationPayload._() : super();
  const factory OwnerInvitationPayload({
    required OwnerInvitation ownerInvitation,
  }) = _OwnerInvitationPayload;

  factory OwnerInvitationPayload.fromJson(Map<String, dynamic> json) =>
      OwnerInvitationPayload(
        ownerInvitation: OwnerInvitation.fromJson(
          json['ownerInvitation'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.ownerInvitation;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'OwnerInvitation',
    'ownerInvitation': ownerInvitation.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class BasketExchangePayload extends EntityPayload
    with _$BasketExchangePayload {
  const BasketExchangePayload._() : super();
  const factory BasketExchangePayload({
    required BasketExchange basketExchange,
  }) = _BasketExchangePayload;

  factory BasketExchangePayload.fromJson(Map<String, dynamic> json) =>
      BasketExchangePayload(
        basketExchange: BasketExchange.fromJson(
          json['basketExchange'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.basketExchange;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'BasketExchange',
    'basketExchange': basketExchange.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class NotificationPayload extends EntityPayload
    with _$NotificationPayload {
  const NotificationPayload._() : super();
  const factory NotificationPayload({required AppNotification notification}) =
      _NotificationPayload;

  factory NotificationPayload.fromJson(Map<String, dynamic> json) =>
      NotificationPayload(
        notification: AppNotification.fromJson(
          json['notification'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.notification;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Notification',
    'notification': notification.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class DeviceTokenPayload extends EntityPayload
    with _$DeviceTokenPayload {
  const DeviceTokenPayload._() : super();
  const factory DeviceTokenPayload({required DeviceToken deviceToken}) =
      _DeviceTokenPayload;

  factory DeviceTokenPayload.fromJson(Map<String, dynamic> json) =>
      DeviceTokenPayload(
        deviceToken: DeviceToken.fromJson(
          json['deviceToken'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.deviceToken;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'DeviceToken',
    'deviceToken': deviceToken.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class AttendanceEmailRequestPayload extends EntityPayload
    with _$AttendanceEmailRequestPayload {
  const AttendanceEmailRequestPayload._() : super();
  const factory AttendanceEmailRequestPayload({
    required AttendanceEmailRequest attendanceEmailRequest,
  }) = _AttendanceEmailRequestPayload;

  factory AttendanceEmailRequestPayload.fromJson(Map<String, dynamic> json) =>
      AttendanceEmailRequestPayload(
        attendanceEmailRequest: AttendanceEmailRequest.fromJson(
          json['attendanceEmailRequest'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.attendanceEmailRequest;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'AttendanceEmailRequest',
    'attendanceEmailRequest': attendanceEmailRequest.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class ErrorReportPayload extends EntityPayload
    with _$ErrorReportPayload {
  const ErrorReportPayload._() : super();
  const factory ErrorReportPayload({required ErrorReport errorReport}) =
      _ErrorReportPayload;

  factory ErrorReportPayload.fromJson(Map<String, dynamic> json) =>
      ErrorReportPayload(
        errorReport: ErrorReport.fromJson(
          json['errorReport'] as Map<String, dynamic>,
        ),
      );

  @override
  EntityType get entityType => EntityType.errorReport;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ErrorReport',
    'errorReport': errorReport.toJson(),
  };
}
