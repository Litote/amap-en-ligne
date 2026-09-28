import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/presentation/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  testWidgets('shows invalid link message when no access token in URL', (
    tester,
  ) async {
    // In tests, Uri.base.fragment is empty so _extractAccessToken returns null,
    // triggering the fallback UI.
    await tester.pumpWidget(
      RepositoryProvider<AuthService>.value(
        value: _MockAuthService(),
        child: const MaterialApp(home: ResetPasswordScreen()),
      ),
    );

    expect(find.text('Lien de réinitialisation invalide.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
