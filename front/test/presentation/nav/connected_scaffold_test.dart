import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onBack}) =>
      tester.pumpWidget(
        MaterialApp(
          home: ConnectedScaffold(
            title: 'Écran',
            onBack: onBack,
            body: const SizedBox(),
          ),
        ),
      );

  testWidgets('shows the menu button when no back action is given', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byKey(const Key('nav_menu_button')), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('shows a back button that runs onBack when given', (
    tester,
  ) async {
    var backs = 0;
    await pump(tester, onBack: () => backs++);

    expect(find.byKey(const Key('nav_menu_button')), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pump();

    expect(backs, 1);
  });
}
