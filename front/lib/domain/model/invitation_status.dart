import 'package:json_annotation/json_annotation.dart';

/// Lifecycle status shared by invitation entities.
enum InvitationStatus {
  @JsonValue('PENDING_ACTIVATION')
  pendingActivation,
  @JsonValue('ACTIVATED')
  activated,
  @JsonValue('CANCELLED')
  cancelled,
}
