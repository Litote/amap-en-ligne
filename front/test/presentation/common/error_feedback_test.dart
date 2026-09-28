import 'package:amap_en_ligne/presentation/common/error_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'showUnexpectedErrorSnackBar shows the generic copy, never the raw error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showUnexpectedErrorSnackBar(
                  context,
                  Exception('raw detail'),
                  StackTrace.current,
                ),
                child: const Text('trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('trigger'));
      await tester.pump();

      expect(find.text(kUnexpectedErrorMessage), findsOneWidget);
      expect(find.textContaining('raw detail'), findsNothing);
    },
  );

  test(
    'recordFallbackBreadcrumb is a safe no-op when Sentry is not initialised',
    () {
      // Call sites live on build/fallback paths: the helper must never throw,
      // even without a configured Sentry SDK (the default in tests).
      expect(
        () => recordFallbackBreadcrumb('lookup failed', Exception('detail')),
        returnsNormally,
      );
    },
  );
}
