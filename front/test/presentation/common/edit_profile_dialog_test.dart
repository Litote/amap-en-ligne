import 'package:amap_en_ligne/presentation/common/edit_profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<Map<String, String?>>> pump(
    WidgetTester tester,
    Widget Function(ValueChanged<Map<String, String?>>) build,
  ) async {
    final submissions = <Map<String, String?>>[];
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: build(submissions.add))),
    );
    return submissions;
  }

  testWidgets('owner profile rejects a malformed email', (tester) async {
    final submissions = await pump(
      tester,
      (onSubmit) => EditProfileDialog.forOwner(
        firstName: 'Alice',
        lastName: 'Martin',
        email: 'alice@example.com',
        onSubmit: onSubmit,
      ),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'bad');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(find.text('Adresse email invalide.'), findsOneWidget);
    expect(submissions, isEmpty);
  });

  testWidgets(
    'producer profile rejects a malformed contact email and website',
    (tester) async {
      final submissions = await pump(
        tester,
        (onSubmit) =>
            EditProfileDialog.forProducer(name: 'Ferme', onSubmit: onSubmit),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email de contact (optionnel)'),
        'ferme@nowhere',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Site web (optionnel)'),
        'www.ferme.example',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();

      expect(find.text('Adresse email invalide.'), findsOneWidget);
      expect(
        find.text("L'URL n'est pas valide (ex. https://…)."),
        findsOneWidget,
      );
      expect(submissions, isEmpty);
    },
  );
}
