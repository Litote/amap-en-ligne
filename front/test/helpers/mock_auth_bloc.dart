import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_event.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

/// Register fallback values needed for [AuthEvent] matchers in mock
/// expectations. Call this once in [setUpAll].
void registerAuthFallbackValues() {
  registerFallbackValue(const AuthEvent.logoutRequested());
}
