import 'package:amap_en_ligne/data/local/database_recovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('openDatabaseWithRecovery', () {
    test(
      'opens directly and never recovers when the database is healthy',
      () async {
        final calls = <String>[];

        final result = await openDatabaseWithRecovery<String>(
          isHealthy: () async {
            calls.add('check');
            return true;
          },
          open: () async {
            calls.add('open');
            return 'db';
          },
          onCorruption: () async => calls.add('recover'),
        );

        expect(result, 'db');
        // Healthy path: one open, no recovery.
        expect(calls, ['check', 'open']);
      },
    );

    test('recovers before re-opening when the database is corrupt', () async {
      final calls = <String>[];

      final result = await openDatabaseWithRecovery<String>(
        isHealthy: () async {
          calls.add('check');
          return false;
        },
        open: () async {
          calls.add('open');
          return 'fresh-db';
        },
        onCorruption: () async => calls.add('recover'),
      );

      expect(result, 'fresh-db');
      // Corrupt path: recovery runs once, strictly before the single re-open.
      expect(calls, ['check', 'recover', 'open']);
    });
  });
}
