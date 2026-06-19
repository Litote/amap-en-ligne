import 'package:amap_en_ligne/data/local/database_integrity.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isDatabaseHealthy', () {
    test('returns true for a freshly opened, intact database', () async {
      final executor = NativeDatabase.memory();
      addTearDown(executor.close);

      expect(await isDatabaseHealthy(executor), isTrue);
    });

    test('returns false when quick_check reports a non-ok result', () async {
      final executor = _FakeExecutor(
        selectRows: const [
          {'quick_check': 'database disk image is malformed'},
        ],
      );

      expect(await isDatabaseHealthy(executor), isFalse);
    });

    test('returns false when the integrity query throws', () async {
      final executor = _FakeExecutor(throwOnSelect: true);

      expect(await isDatabaseHealthy(executor), isFalse);
    });

    test('returns false when quick_check yields no rows', () async {
      final executor = _FakeExecutor(selectRows: const []);

      expect(await isDatabaseHealthy(executor), isFalse);
    });
  });
}

/// Minimal [QueryExecutor] stub exercising the failure branches of
/// [isDatabaseHealthy] without a real database. Only [ensureOpen] and
/// [runSelect] are used; everything else is intentionally unimplemented.
class _FakeExecutor implements QueryExecutor {
  _FakeExecutor({this.selectRows, this.throwOnSelect = false});

  final List<Map<String, Object?>>? selectRows;
  final bool throwOnSelect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async {
    if (throwOnSelect) throw Exception('simulated corruption');
    return selectRows ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
