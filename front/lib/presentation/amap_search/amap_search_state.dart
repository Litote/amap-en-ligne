import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'amap_search_state.freezed.dart';

@freezed
sealed class AmapSearchState with _$AmapSearchState {
  const factory AmapSearchState.initial() = AmapSearchInitial;

  const factory AmapSearchState.loadingOrgs() = AmapSearchLoadingOrgs;

  const factory AmapSearchState.orgsLoaded({
    required List<Organization> orgs,
    Organization? selectedOrg,
    @Default('') String searchQuery,
  }) = AmapSearchOrgsLoaded;

  const factory AmapSearchState.submitting({required Organization org}) =
      AmapSearchSubmitting;

  const factory AmapSearchState.success({
    required String requestId,
    required String organizationName,
  }) = AmapSearchSuccess;

  const factory AmapSearchState.error({
    required String message,
    Organization? selectedOrg,
  }) = AmapSearchError;
}
