import 'package:amap_en_ligne/presentation/common/date_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  Future<void> pumpField(
    WidgetTester tester, {
    required TextEditingController controller,
    DateTime? Function()? initialDateFallback,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: DatePickerField(
            controller: controller,
            labelText: 'Date de dernière livraison *',
            enabled: true,
            onChanged: () {},
            initialDateFallback: initialDateFallback,
          ),
        ),
      ),
    );
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty field opens the picker on the fallback date', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(
      tester,
      controller: controller,
      initialDateFallback: () => DateTime(2031, 10, 2),
    );

    await openPicker(tester);

    expect(find.textContaining('octobre 2031'), findsOneWidget);
  });

  testWidgets('a filled field opens the picker on its own date', (
    tester,
  ) async {
    final controller = TextEditingController(text: '2032-03-04');
    addTearDown(controller.dispose);
    await pumpField(
      tester,
      controller: controller,
      initialDateFallback: () => DateTime(2031, 10, 2),
    );

    await openPicker(tester);

    expect(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.textContaining('mars 2032'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses a short header title that is not truncated', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(921, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller);

    await openPicker(tester);

    expect(find.text('Choisir une date'), findsOneWidget);
    expect(find.text('Sélectionner une date'), findsNothing);
  });

  testWidgets('shows the date in French while keeping the ISO value', (
    tester,
  ) async {
    final controller = TextEditingController(text: '2026-10-01');
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller);

    expect(find.text('1er oct. 2026'), findsOneWidget);
    expect(find.text('2026-10-01'), findsNothing);

    await openPicker(tester);
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(controller.text, '2026-10-15');
    expect(find.text('15 oct. 2026'), findsOneWidget);
  });

  testWidgets('a value set programmatically is shown formatted', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller);

    controller.text = '2026-12-17';
    await tester.pump();

    expect(find.text('17 déc. 2026'), findsOneWidget);
  });

  testWidgets('tapping the field itself opens the picker', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller);

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    expect(find.text('Choisir une date'), findsOneWidget);
  });

  testWidgets('the calendar button has an accessible label', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller);

    expect(
      find.byTooltip('Choisir la date de dernière livraison'),
      findsOneWidget,
    );
  });

  group('rules', () {
    Future<GlobalKey<FormState>> pump(
      WidgetTester tester, {
      required TextEditingController controller,
      String? Function()? extraValidator,
      DateTime? Function()? firstDate,
    }) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: DatePickerField(
                controller: controller,
                labelText: 'Date de dernière livraison *',
                enabled: true,
                onChanged: () {},
                extraValidator: extraValidator,
                firstDate: firstDate,
              ),
            ),
          ),
        ),
      );
      return formKey;
    }

    testWidgets('shows the extra rule under the field (e.g. date order)', (
      tester,
    ) async {
      final formKey = await pump(
        tester,
        controller: TextEditingController(text: '2026-10-01'),
        extraValidator: () =>
            'La date de première livraison doit précéder la '
            'date de dernière livraison.',
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(
        find.textContaining('doit précéder la date de dernière'),
        findsOneWidget,
      );
    });

    testWidgets('the picker does not offer dates before firstDate', (
      tester,
    ) async {
      await pump(
        tester,
        controller: TextEditingController(),
        firstDate: () => DateTime(2026, 12, 17),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(picker.firstDate, DateTime(2026, 12, 17));
      expect(picker.initialDate, DateTime(2026, 12, 17));
    });
  });
}
