import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// Session-level authentication state. Two variants only — UI submitting /
/// failure indicators live in the auth bloc, not here.
///
/// `accessToken` is what the dio interceptor attaches to `POST /v1/sync` as
/// `Authorization: Bearer <token>`. `producerId` is the JWT `sub` claim — the
/// user's identity from the auth provider (`app_metadata.producer_account_id`
/// for GoTrue, `custom:producer_account_id` for Cognito). For PRODUCER-role
/// users, `producerId == producerAccountId` from the database by invariant.
/// For non-producer users, the database producerAccountId is resolved later.
/// It replaces the previous hardcoded `_kTenantId` constant and scopes the
/// local drift queries on the same key the back uses on its DAO side.
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = Unauthenticated;

  const factory AuthState.authenticated({
    required String producerId,
    required String accessToken,
    @Default([]) List<String> roles,
  }) = Authenticated;
}
