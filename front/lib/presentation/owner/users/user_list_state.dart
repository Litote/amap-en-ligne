import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_list_state.freezed.dart';

@freezed
sealed class UserListState with _$UserListState {
  const factory UserListState.initial() = UserListInitial;

  const factory UserListState.loading() = UserListLoading;

  const factory UserListState.loaded({
    /// All organisations available for the AMAP filter dropdown.
    required List<Organization> allOrganizations,

    /// All producer accounts available for the Producteur filter dropdown.
    required List<ProducerAccount> allProducerAccounts,

    /// Rows visible on the current page (after filtering + pagination).
    required List<UserRow> visibleRows,

    /// Total number of rows matching the current filters (before pagination).
    required int totalCount,

    /// Current 1-based page number.
    required int currentPage,

    /// Total number of pages (50 rows per page).
    required int totalPages,

    // --- active filter state ---
    @Default('') String searchQuery,
    String? amapIdFilter,
    String? producerIdFilter,
    UserListRoleFilter? roleFilter,
    UserDisplayStatus? statusFilter,
  }) = UserListLoaded;

  const factory UserListState.error(String message) = UserListError;
}
