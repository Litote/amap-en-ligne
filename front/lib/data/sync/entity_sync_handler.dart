import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/handlers/attendance_email_request_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/basket_exchange_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/contract_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/delivery_template_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/device_token_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/error_report_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/member_invitation_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/member_join_request_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/member_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/notification_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/organization_request_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/organization_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/owner_invitation_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/owner_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/producer_account_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/producer_request_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/handlers/product_type_sync_handler.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';

export 'package:amap_en_ligne/data/sync/handlers/attendance_email_request_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/basket_exchange_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/contract_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/delivery_template_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/device_token_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/error_report_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/member_invitation_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/member_join_request_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/member_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/notification_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/organization_request_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/organization_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/owner_invitation_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/owner_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/producer_account_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/producer_request_sync_handler.dart';
export 'package:amap_en_ligne/data/sync/handlers/product_type_sync_handler.dart';

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
