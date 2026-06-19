import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_list_event.freezed.dart';

@freezed
sealed class UserListEvent with _$UserListEvent {
  /// Triggers the initial load — subscribe to all data streams.
  const factory UserListEvent.loaded() = UserListLoadRequested;

  /// The free-text search field changed.
  const factory UserListEvent.searchQueryChanged(String query) =
      UserListSearchQueryChanged;

  /// The AMAP filter changed; null means "Toutes".
  const factory UserListEvent.amapFilterChanged(String? organizationId) =
      UserListAmapFilterChanged;

  /// The producer filter changed; null means "Tous".
  const factory UserListEvent.producerFilterChanged(String? organizationId) =
      UserListProducerFilterChanged;

  /// The role filter changed; null means "Tous".
  const factory UserListEvent.roleFilterChanged(UserListRoleFilter? filter) =
      UserListRoleFilterChanged;

  /// The status filter changed; null means "Tous".
  const factory UserListEvent.statusFilterChanged(UserDisplayStatus? status) =
      UserListStatusFilterChanged;

  /// Navigate to the given page index (1-based).
  const factory UserListEvent.pageChanged(int page) = UserListPageChanged;
}
