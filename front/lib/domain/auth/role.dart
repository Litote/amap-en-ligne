import 'package:json_annotation/json_annotation.dart';

/// Unified role enum mirroring `authentication.Role` on the back.
///
/// Used in [Member.roles] (AMAP-context roles) and [Owner] (implicitly OWNER).
/// Wire values are uppercase (e.g. `"ADMIN"`) matching the back's serialization.
enum Role {
  @JsonValue('OWNER')
  owner,
  @JsonValue('ADMIN')
  admin,
  @JsonValue('PRODUCER')
  producer,
  @JsonValue('COORDINATOR')
  coordinator,
  @JsonValue('VOLUNTEER')
  volunteer,
}
