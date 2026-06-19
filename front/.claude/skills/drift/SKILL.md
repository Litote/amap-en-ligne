---
name: drift
description: >
  Add or modify Drift (SQLite ORM) tables in AppDatabase. Covers Table
  definitions, composite PKs, TypeConverter, multiplatform _open(),
  CRUD query helpers, transaction pattern, and NativeDatabase.memory() tests.
triggers:
  - Drift
  - AppDatabase
  - drift table
  - TypeConverter
  - NativeDatabase
  - sqlite flutter
  - offline database
  - local storage
  - schemaVersion
---

# Drift (SQLite) in amap-en-ligne/front

Single database: `lib/data/local/database.dart`.

## Anatomy

```
@DriftDatabase(tables: [ProductTypes, SyncCursors, PendingMutations, YourNewTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 2;  // increment when adding/changing tables

  static QueryExecutor _open() => driftDatabase(
    name: 'amap_en_ligne',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
```

`_open()` is the production opener; tests pass `NativeDatabase.memory()` directly.

## Defining a Table

```dart
@DataClassName('FooRow')   // controls the generated row class name
class Foos extends Table {
  TextColumn get producerAccountId => text()();
  TextColumn get fooId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get tags => text().map(const _StringListConverter())();

  @override
  Set<Column<Object>> get primaryKey => {producerAccountId, fooId};
}
```

**Column type methods:**
| Dart type | Column builder |
|-----------|---------------|
| `String` | `text()` |
| `int` | `integer()` |
| `bool` | `boolean()` |
| `double` | `real()` |
| `DateTime` | `dateTime()` |
| Custom type | `text().map(const MyConverter())` |

`.nullable()` makes the column `TEXT NULL`. `.withDefault(const Constant(''))` sets a default.

## TypeConverter

For JSON-encoded fields (lists, nested objects):

```dart
class _StringListConverter extends TypeConverter<List<String>, String> {
  const _StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    try {
      final list = jsonDecode(fromDb) as List<dynamic>;
      return list.cast<String>();
    } on Object {
      return [];
    }
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
```

Always handle malformed SQL values gracefully in `fromSql` — return a safe default.

## Composite Primary Key

Always use a `Set<Column>` override. Never add `.autoIncrement()` on a composite PK:

```dart
@override
Set<Column<Object>> get primaryKey => {tenantId, entityId};
```

## CRUD Helpers on AppDatabase

Add query helpers as methods on `AppDatabase`, not as standalone DAOs.

### Watch (reactive)

```dart
Stream<List<Foo>> watchFoos(String producerAccountId) =>
    (select(foos)
          ..where((t) => t.producerAccountId.equals(producerAccountId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(_toFoo).toList());
```

### Upsert

```dart
Future<void> upsertFoo(Foo foo) =>
    into(foos).insertOnConflictUpdate(_toFooRow(foo));
```

### Delete

```dart
Future<void> deleteFoo({
  required String producerAccountId,
  required String fooId,
}) =>
    (delete(foos)..where(
          (t) =>
              t.producerAccountId.equals(producerAccountId) &
              t.fooId.equals(fooId),
        ))
        .go();
```

### Remap tmp_ id (after server confirmation)

```dart
Future<void> remapFooId({
  required String producerAccountId,
  required String oldId,
  required String newId,
}) => transaction(() async {
  final existing = await (select(foos)
      ..where((t) => t.producerAccountId.equals(producerAccountId) & t.fooId.equals(oldId)))
      .getSingleOrNull();
  if (existing == null) return;
  await (delete(foos)
      ..where((t) => t.producerAccountId.equals(producerAccountId) & t.fooId.equals(oldId)))
      .go();
  await into(foos).insertOnConflictUpdate(existing.copyWith(fooId: newId));
});
```

### Clear for bootstrap

```dart
Future<void> clearFoosForTenant(String producerAccountId) =>
    (delete(foos)..where((t) => t.producerAccountId.equals(producerAccountId))).go();
```

## Mapping: Domain ↔ Row

Place `_toFoo` and `_toFooRow` at file scope (outside the class):

```dart
Foo _toFoo(FooRow row) => Foo(
  fooId: row.fooId,
  producerAccountId: row.producerAccountId,
  name: row.name,
);

FoosCompanion _toFooRow(Foo foo) => FoosCompanion.insert(
  producerAccountId: foo.producerAccountId,
  fooId: foo.fooId,
  name: foo.name,
  description: Value(foo.description),  // Value() wraps nullable fields
);
```

Use `Value(x)` for nullable or optional columns in `Companion`. Required columns pass the value directly.

## Code Generation

After changing `database.dart`, always regenerate:

```bash
cd front/
dart run build_runner build --delete-conflicting-outputs
```

The generated file is `database.g.dart` — commit it.

## Tests

```dart
late AppDatabase db;

setUp(() {
  db = AppDatabase(NativeDatabase.memory());
});

tearDown(() async {
  await db.close();
});

test('upsert round-trip preserves all fields', () async {
  final foo = Foo(fooId: 'f-1', producerAccountId: 'p-1', name: 'Test');
  await db.upsertFoo(foo);
  final rows = await db.watchFoos('p-1').first;
  expect(rows, [foo]);
});

test('producer isolation', () async {
  await db.upsertFoo(Foo(fooId: 'f-1', producerAccountId: 'p-1', name: 'A'));
  await db.upsertFoo(Foo(fooId: 'f-1', producerAccountId: 'p-2', name: 'B'));
  // p-1 only sees their row
  expect((await db.watchFoos('p-1').first).single.name, 'A');
});
```

Tests for Drift are in `test/data/local/database_test.dart`. Use `test/support/<entity>_fixtures.dart` for reusable builders.

## Schema Migrations

When adding a table or column, increment `schemaVersion` and implement `MigrationStrategy`:

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (migrator, from, to) async {
    if (from < 2) {
      await migrator.createTable(foos);
    }
  },
);
```

The production SQLite file persists across app updates — never change an existing column type without a migration.
