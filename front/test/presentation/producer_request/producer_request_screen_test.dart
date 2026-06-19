import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPublicApi extends Mock implements PublicApi {}

final _stubServerConfig = GoTrueServerConfig(
  id: 'test',
  name: 'Test',
  backendUrl: 'https://test.example',
  gotrueUrl: 'https://test.example/auth',
);

Future<void> _pump(
  WidgetTester tester,
  PublicApi api, {
  String? initialFirstName,
  String? initialLastName,
  String? initialEmail,
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PublicApi>.value(value: api),
        RepositoryProvider<ServerConfig>.value(value: _stubServerConfig),
      ],
      child: MaterialApp(
        home: ProducerRequestScreen(
          initialFirstName: initialFirstName,
          initialLastName: initialLastName,
          initialEmail: initialEmail,
        ),
      ),
    ),
  );
}

void main() {
  late _MockPublicApi api;

  setUp(() => api = _MockPublicApi());

  testWidgets('shows empty form fields when no prefill values are provided', (
    tester,
  ) async {
    await _pump(tester, api);

    expect(
      (tester
              .widget<TextFormField>(find.byKey(const Key('first_name')))
              .controller)!
          .text,
      isEmpty,
    );
    expect(
      (tester
              .widget<TextFormField>(find.byKey(const Key('last_name')))
              .controller)!
          .text,
      isEmpty,
    );
    expect(
      (tester
              .widget<TextFormField>(find.byKey(const Key('admin_email')))
              .controller)!
          .text,
      isEmpty,
    );
  });

  testWidgets('pre-fills first name, last name and email from parameters', (
    tester,
  ) async {
    await _pump(
      tester,
      api,
      initialFirstName: 'Marie',
      initialLastName: 'Curie',
      initialEmail: 'marie@example.fr',
    );

    expect(find.text('Marie'), findsOneWidget);
    expect(find.text('Curie'), findsOneWidget);
    expect(find.text('marie@example.fr'), findsOneWidget);
  });

  testWidgets('pre-fills only supplied fields and leaves others empty', (
    tester,
  ) async {
    await _pump(tester, api, initialFirstName: 'Pierre');

    expect(find.text('Pierre'), findsOneWidget);
    expect(
      (tester
              .widget<TextFormField>(find.byKey(const Key('last_name')))
              .controller)!
          .text,
      isEmpty,
    );
    expect(
      (tester
              .widget<TextFormField>(find.byKey(const Key('admin_email')))
              .controller)!
          .text,
      isEmpty,
    );
  });
}
