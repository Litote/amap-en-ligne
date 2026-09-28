import 'package:amap_en_ligne/presentation/admin/producers/producer_ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a basket size differing only by case is not added twice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showManagedProducerProductDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final sizeField = find.widgetWithText(TextFormField, 'Ajouter une taille');
    await tester.enterText(sizeField, 'Petit');
    await tester.tap(find.byTooltip('Ajouter'));
    await tester.pump();
    await tester.enterText(sizeField, ' petit ');
    await tester.tap(find.byTooltip('Ajouter'));
    await tester.pump();

    expect(find.widgetWithText(Chip, 'Petit'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
    // The refusal is explained instead of silently ignoring the click.
    expect(
      find.text('La taille « petit » est présente deux fois.'),
      findsOneWidget,
    );
  });

  testWidgets('adding a basket size clears the field and any previous error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showManagedProducerProductDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final sizeField = find.widgetWithText(TextFormField, 'Ajouter une taille');
    await tester.enterText(sizeField, 'Petit');
    await tester.tap(find.byTooltip('Ajouter'));
    await tester.pump();
    await tester.enterText(sizeField, 'petit');
    await tester.tap(find.byTooltip('Ajouter'));
    await tester.pump();
    await tester.enterText(sizeField, 'Grand');
    await tester.tap(find.byTooltip('Ajouter'));
    await tester.pump();

    expect(find.byType(Chip), findsNWidgets(2));
    expect(tester.widget<TextFormField>(sizeField).controller!.text, isEmpty);
    expect(find.textContaining('présente deux fois'), findsNothing);
  });
}
