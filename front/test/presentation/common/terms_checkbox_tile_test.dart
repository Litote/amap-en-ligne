import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/common/terms_checkbox_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = GoTrueServerConfig(
  id: 'local',
  name: 'Local',
  backendUrl: 'https://api.example/v1',
  gotrueUrl: 'https://auth.example',
);

void main() {
  testWidgets('exposes a named checkbox and a separate terms link to screen '
      'readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      RepositoryProvider<ServerConfig>.value(
        value: _config,
        child: MaterialApp(
          home: Scaffold(
            body: TermsCheckboxTile(value: false, onChanged: (_) {}),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(Checkbox)),
      matchesSemantics(
        label: "J'accepte les conditions d'utilisation du service",
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    final link = tester.getSemantics(
      find.bySemanticsLabel("Lire les conditions d'utilisation"),
    );
    // A real link on the web (an <a href>), not plain text.
    expect(link.flagsCollection.isLink, isTrue);
    expect(link.linkUrl, Uri.parse('https://api.example/cgu.html'));
    handle.dispose();
  });

  group('resolveTermsUrl', () {
    test('prefers the configured terms URL', () {
      expect(
        resolveTermsUrl(
          termsUrl: 'https://legal.example/cgu',
          isWeb: true,
          pageUrl: Uri.parse('https://app.example/register'),
          backendUrl: 'https://api.example/v1',
        ),
        'https://legal.example/cgu',
      );
    });

    test('web: the bundled file at the site root, whatever the page depth', () {
      for (final page in [
        'https://app.example/register',
        'https://app.example/register/producer',
        'https://app.example/register/producer?x=1#y',
      ]) {
        expect(
          resolveTermsUrl(
            isWeb: true,
            pageUrl: Uri.parse(page),
            backendUrl: 'https://api.example/v1',
          ),
          'https://app.example/cgu.html',
          reason: page,
        );
      }
    });

    test('mobile: next to the backend', () {
      expect(
        resolveTermsUrl(
          isWeb: false,
          pageUrl: Uri.parse('file:///'),
          backendUrl: 'https://api.example/v1',
        ),
        'https://api.example/cgu.html',
      );
    });
  });
}
