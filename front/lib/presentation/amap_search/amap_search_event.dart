import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'amap_search_event.freezed.dart';

@freezed
sealed class AmapSearchEvent with _$AmapSearchEvent {
  const factory AmapSearchEvent.orgsLoadRequested() = OrgsLoadRequested;

  const factory AmapSearchEvent.orgSelected(Organization org) = OrgSelected;

  const factory AmapSearchEvent.joinFormSubmitted({
    required String firstName,
    required String lastName,
    required String email,
  }) = JoinFormSubmitted;
}
