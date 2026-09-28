import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'nav_event.freezed.dart';

@freezed
sealed class NavEvent with _$NavEvent {
  const factory NavEvent.opened() = NavOpened;
  const factory NavEvent.closed() = NavClosed;
  const factory NavEvent.roleChanged({
    required UserRole role,
    required Set<Role> memberRoles,
  }) = NavRoleChanged;
}
