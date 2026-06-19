import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.loaded({required List<Organization> organizations}) =
      HomeLoaded;
  const factory HomeState.error(String message) = HomeError;
}
