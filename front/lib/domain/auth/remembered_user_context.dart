import 'package:freezed_annotation/freezed_annotation.dart';

part 'remembered_user_context.freezed.dart';
part 'remembered_user_context.g.dart';

@freezed
abstract class RememberedUserContext with _$RememberedUserContext {
  const factory RememberedUserContext({
    required String email,
    required String serverId,
    required bool rememberMe,
  }) = _RememberedUserContext;

  factory RememberedUserContext.fromJson(Map<String, Object?> json) =>
      _$RememberedUserContextFromJson(json);
}

abstract class RememberedUserContextStore {
  Future<RememberedUserContext?> read({required String serverId});
  Future<void> write(RememberedUserContext context);
  Future<void> clear();
}
