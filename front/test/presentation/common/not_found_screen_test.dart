import 'package:amap_en_ligne/presentation/common/not_found_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpUnknownLocation(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/nope',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
      ],
      errorBuilder: (_, _) => const NotFoundScreen(),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('an unknown location shows a French not-found page', (
    tester,
  ) async {
    await pumpUnknownLocation(tester);

    expect(find.text('Page introuvable'), findsOneWidget);
    expect(find.textContaining('Page Not Found'), findsNothing);
  });

  testWidgets('the home button navigates back to the home page', (
    tester,
  ) async {
    await pumpUnknownLocation(tester);

    await tester.tap(find.text("RETOUR À L'ACCUEIL"));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });
}
