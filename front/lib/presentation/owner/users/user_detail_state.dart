import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_detail_state.freezed.dart';

@freezed
sealed class UserDetailState with _$UserDetailState {
  const factory UserDetailState.initial() = UserDetailInitial;

  const factory UserDetailState.loading() = UserDetailLoading;

  const factory UserDetailState.loaded({required UserRow userRow}) =
      UserDetailLoaded;

  const factory UserDetailState.notFound() = UserDetailNotFound;

  const factory UserDetailState.error(String message) = UserDetailError;
}
