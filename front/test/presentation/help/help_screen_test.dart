import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/help/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Amap en Ligne',
      packageName: 'org.amapenligne',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  Widget buildSubject({String? guideUrl}) =>
      RepositoryProvider<ServerConfig>.value(
        value: GoTrueServerConfig(
          id: 'test-server',
          name: 'Test',
          backendUrl: 'http://localhost:8080',
          gotrueUrl: 'http://localhost:9999',
          guideUrl: guideUrl,
        ),
        child: const MaterialApp(home: HelpScreen()),
      );

  testWidgets('shows the screen title and the guide/contact cards', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Aide'), findsWidgets);
    expect(find.text("Consulter le guide d'utilisation"), findsOneWidget);
    expect(find.text("Besoin d'aide ?"), findsOneWidget);
  });

  testWidgets('shows the guide link button when guideUrl is configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(guideUrl: 'https://example.org/guide/'),
    );
    await tester.pump();

    expect(find.text('OUVRIR LE GUIDE'), findsOneWidget);
  });

  testWidgets('shows informational text only when guideUrl is absent', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('OUVRIR LE GUIDE'), findsNothing);
    expect(
      find.textContaining('Votre coordinateur ou administrateur'),
      findsOneWidget,
    );
  });

  testWidgets('shows all five FAQ questions', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(
      find.text("Je n'ai pas reçu l'e-mail d'activation ou d'invitation"),
      findsOneWidget,
    );
    expect(find.text("J'ai oublié mon mot de passe"), findsOneWidget);
    expect(
      find.text('L\'application affiche « Serveur injoignable »'),
      findsOneWidget,
    );
    expect(
      find.text('Je ne vois aucun contrat dans « Mes contrats »'),
      findsOneWidget,
    );
    expect(
      find.textContaining("Il n'y a pas de bouton pour m'inscrire"),
      findsOneWidget,
    );
  });

  testWidgets('tapping a FAQ question reveals its answer', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text("J'ai oublié mon mot de passe"));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Un code à 6 chiffres valable 1 heure'),
      findsOneWidget,
    );
  });

  testWidgets('shows the installed app version under "À propos"', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('À propos'), findsOneWidget);
    expect(find.text('Version v1.2.3 (build 42)'), findsOneWidget);
  });
}
