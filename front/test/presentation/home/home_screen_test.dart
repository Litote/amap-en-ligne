import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
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

  Widget buildSubject({String? guideUrl}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<PublicApi>.value(value: api),
      RepositoryProvider<ServerConfig>.value(
        value: GoTrueServerConfig(
          id: 'test',
          name: 'Test',
          backendUrl: 'http://localhost:8080',
          gotrueUrl: 'http://localhost:9999',
          guideUrl: guideUrl,
        ),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );

  testWidgets('home shows a guide link when the server exposes one', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(guideUrl: 'https://litote.github.io/amap-en-ligne/'),
    );
    await tester.pump();

    expect(
      find.widgetWithText(TextButton, "Guide d'utilisation"),
      findsOneWidget,
    );
  });

  testWidgets('home hides the guide link when the server has no guide', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(
      find.widgetWithText(TextButton, "Guide d'utilisation"),
      findsNothing,
    );
  });

  testWidgets('home offers to create an AMAP without a subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Je veux créer une AMAP'), findsOneWidget);
    expect(find.text('Je veux créer une nouvelle organisation'), findsNothing);
    expect(find.textContaining('totalement gratuit'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'CRÉER UNE AMAP'), findsOneWidget);
  });

  testWidgets('home offers to create a producer account', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(
      find.widgetWithText(FilledButton, 'CRÉER SON COMPTE PRODUCTEUR'),
      findsOneWidget,
    );
    expect(find.text('DEVENIR PRODUCTEUR'), findsNothing);
  });

  testWidgets('home no longer shows the national AMAP search', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.textContaining('Trouver une AMAP'), findsNothing);
    expect(find.textContaining('reseau-amap.org'), findsNothing);
  });

  testWidgets('home shows a "Code source" link', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.widgetWithText(TextButton, 'Code source'), findsOneWidget);
  });

  testWidgets('license, guide, source and about share one line on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      buildSubject(guideUrl: 'https://litote.github.io/amap-en-ligne/'),
    );
    await tester.pump();

    final license = tester.getCenter(
      find.text(
        "Amap en Ligne est libre (AGPL), sans coût d'utilisation et auto-hébergeable.",
      ),
    );
    final guide = tester.getCenter(
      find.widgetWithText(TextButton, "Guide d'utilisation"),
    );
    final source = tester.getCenter(
      find.widgetWithText(TextButton, 'Code source'),
    );
    final about = tester.getCenter(find.widgetWithText(TextButton, 'À propos'));
    expect(source.dy, moreOrLessEquals(license.dy, epsilon: 1));
    expect(guide.dy, moreOrLessEquals(license.dy, epsilon: 1));
    expect(about.dy, moreOrLessEquals(license.dy, epsilon: 1));
    expect(license.dx, lessThan(guide.dx));
    expect(guide.dx, lessThan(source.dx));
    expect(source.dx, lessThan(about.dx));
  });

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
