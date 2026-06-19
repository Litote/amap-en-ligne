import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/presentation/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _MockPublicApi extends Mock implements PublicApi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockPublicApi api;

  setUp(() {
    api = _MockPublicApi();
    when(() => api.listOrganizations()).thenAnswer((_) async => []);
    PackageInfo.setMockInitialValues(
      appName: 'Amap en Ligne',
      packageName: 'org.amapenligne',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  Widget buildSubject() => RepositoryProvider<PublicApi>.value(
    value: api,
    child: const MaterialApp(home: HomeScreen()),
  );

  testWidgets('home shows an "À propos" button', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.widgetWithText(TextButton, 'À propos'), findsOneWidget);
  });

  testWidgets('tapping "À propos" shows the app version', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final aboutButton = find.widgetWithText(TextButton, 'À propos');
    await tester.ensureVisible(aboutButton);
    await tester.tap(aboutButton);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data?.contains('v1.2.3 (build 42)') == true,
      ),
      findsOneWidget,
    );
  });
}
