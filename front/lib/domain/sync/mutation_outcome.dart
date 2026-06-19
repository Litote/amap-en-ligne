import 'package:freezed_annotation/freezed_annotation.dart';

part 'mutation_outcome.freezed.dart';
part 'mutation_outcome.g.dart';

@freezed
abstract class MutationOutcome with _$MutationOutcome {
  const factory MutationOutcome({
    @JsonKey(name: 'client_op_id') required String clientOpId,
    required MutationStatus status,
    @JsonKey(name: 'server_entity_id') String? serverEntityId,
    MutationError? error,
  }) = _MutationOutcome;

  factory MutationOutcome.fromJson(Map<String, Object?> json) =>
      _$MutationOutcomeFromJson(json);
}

enum MutationStatus {
  @JsonValue('APPLIED')
  applied,
  @JsonValue('REJECTED')
  rejected,
}

@freezed
abstract class MutationError with _$MutationError {
  const factory MutationError({
    required MutationErrorCode code,
    required String message,
  }) = _MutationError;

  factory MutationError.fromJson(Map<String, Object?> json) =>
      _$MutationErrorFromJson(json);
}

enum MutationErrorCode {
  @JsonValue('NOT_FOUND')
  notFound,
  @JsonValue('FORBIDDEN')
  forbidden,
  @JsonValue('INVALID_PAYLOAD')
  invalidPayload,
  @JsonValue('UNIQUE_VIOLATION')
  uniqueViolation,
  @JsonValue('CONFLICT')
  conflict,

  /// Granting OWNER role blocked because the target user already has a
  /// Member or Producer row.
  @JsonValue('OWNER_EXCLUSIVE')
  ownerExclusive,

  /// Granting PRODUCER role blocked because the target user already has a
  /// Member row or is OWNER.
  @JsonValue('PRODUCER_EXCLUSIVE')
  producerExclusive,

  /// Granting an AMAP role (ADMIN/COORDINATOR/VOLUNTEER) blocked because the
  /// target user is currently OWNER or PRODUCER.
  @JsonValue('MIXED_ROLES')
  mixedRoles,

  /// Removing ADMIN from the last admin of an organization is not allowed.
  @JsonValue('LAST_ADMIN')
  lastAdmin,

  /// Revoking the last OWNER of the instance is not allowed.
  @JsonValue('LAST_OWNER')
  lastOwner,

  /// Removing the last user with PRODUCER role from a producer organisation
  /// is not allowed.
  @JsonValue('LAST_PRODUCER')
  lastProducer,

  /// The caller targeted their own account for a destructive lifecycle
  /// action (suspend / reactivate / delete). Self-action is forbidden.
  @JsonValue('SELF_ACTION_FORBIDDEN')
  selfActionForbidden,

  /// A delivery cannot transition to CONFIRMED while at least one of its
  /// delivery contracts has no coordinator.
  @JsonValue('MISSING_COORDINATOR')
  missingCoordinator,

  /// A new member subscription or delivery link was rejected because the
  /// target contract's season has already ended (maxDeliveryDate < today).
  @JsonValue('CONTRACT_ENDED')
  contractEnded,

  /// A contract member subscription is empty or does not match any contract product price.
  @JsonValue('INVALID_SUBSCRIPTION')
  invalidSubscription,

  /// A contract shared basket is invalid: fewer than two members, a member that is not a
  /// contract member, a member appearing in two shared baskets, or members whose subscriptions
  /// are not identical.
  @JsonValue('INVALID_SHARED_BASKET')
  invalidSharedBasket,
}
