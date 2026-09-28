import 'package:amap_en_ligne/presentation/auth/password_visibility_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool obscured}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordVisibilityButton(
              obscured: obscured,
              onPressed: () {},
            ),
          ),
        ),
      );

  testWidgets('names the action for screen readers while hidden', (
    tester,
  ) async {
    await pump(tester, obscured: true);

    expect(find.byTooltip('Afficher le mot de passe'), findsOneWidget);
  });

  testWidgets('names the action for screen readers while shown', (
    tester,
  ) async {
    await pump(tester, obscured: false);

    expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
  });
}
