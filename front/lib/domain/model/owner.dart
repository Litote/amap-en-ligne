import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'owner.freezed.dart';
part 'owner.g.dart';

/// Account status for an instance-level owner.
enum AccountStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('SUSPENDED')
  suspended,
}

/// Instance-level owner. Presence of a row in the local cache materialises
/// the OWNER role. There is no [roles] field — the role is implicit.
///
/// Mirrors `persistence.model.Owner` on the back.
@freezed
abstract class Owner with _$Owner {
  const factory Owner({
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    required String email,
    String? phone,
    @JsonKey(name: 'account_status')
    @Default(AccountStatus.active)
    AccountStatus accountStatus,
    @JsonKey(name: 'registered_at') required String registeredAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'user_preferences') UserPreferences? userPreferences,
  }) = _Owner;

  factory Owner.fromJson(Map<String, Object?> json) => _$OwnerFromJson(json);
}
