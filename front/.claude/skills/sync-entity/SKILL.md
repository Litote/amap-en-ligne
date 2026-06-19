---
name: sync-entity
description: >
  Add a new offline-first synchronised entity to the Flutter front. Covers
  the 6-file checklist: EntityType enum → Freezed model → EntityPayload →
  Drift table → EntitySyncHandler → Repository. Includes tmp_ id handling,
  buildEntitySyncHandlers wiring, and test patterns.
triggers:
  - new entity
  - sync entity
  - EntityType
  - EntitySyncHandler
  - EntityPayload
  - offline entity
  - add entity front
  - synchronisable
  - tmp_ id
---

# Adding a Synchronised Entity (Frontend)

Every entity that participates in the offline-first sync protocol requires changes in **6 places in order**. Skipping or reordering causes compile errors.

## 6-File Checklist

### 1. `domain/sync/entity_type.dart` — register the wire type

```dart
enum EntityType {
  @JsonValue('ProductType') productType,
  @JsonValue('Foo') foo,        // ← add here
}

const Map<EntityType, String> entityTypeWireNames = {
  EntityType.productType: 'ProductType',
  EntityType.foo: 'Foo',       // ← add here
};
```

The `@JsonValue` string must match the back's `EntityType` enum exactly (PascalCase).

### 2. `domain/model/foo.dart` — Freezed domain model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'foo.freezed.dart';
part 'foo.g.dart';

@freezed
abstract class Foo with _$Foo {
  const factory Foo({
    @JsonKey(name: 'foo_id') required String fooId,
    @JsonKey(name: 'producer_account_id') required String producerAccountId,
    required String name,
    String? description,
  }) = _Foo;

  factory Foo.fromJson(Map<String, Object?> json) => _$FooFromJson(json);
}
```

Run `dart run build_runner build --delete-conflicting-outputs` after creating this file.

### 3. `domain/sync/entity_payload.dart` — sealed payload variant

Add a new case to the existing `EntityPayload.fromJson` factory:

```dart
factory EntityPayload.fromJson(Map<String, dynamic> json) =>
    switch (json['type']) {
      'ProductType' => ProductTypePayload.fromJson(json),
      'Foo' => FooPayload.fromJson(json),   // ← add here
      final t => throw FormatException('Unknown EntityPayload type: $t'),
    };
```

Then add the new class in the same file. Note: `toJson` is **hand-rolled** (Freezed 3.x does not emit the discriminator field on single-variant unions):

```dart
@Freezed(toJson: false, fromJson: false)
abstract class FooPayload extends EntityPayload with _$FooPayload {
  const FooPayload._() : super();
  const factory FooPayload({required Foo foo}) = _FooPayload;

  factory FooPayload.fromJson(Map<String, dynamic> json) =>
      FooPayload(foo: Foo.fromJson(json['foo'] as Map<String, dynamic>));

  @override
  EntityType get entityType => EntityType.foo;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Foo',
    'foo': foo.toJson(),
  };
}
```

### 4. `data/local/database.dart` — Drift table + AppDatabase helpers

Add the `Table` class and register it in `@DriftDatabase`. Increment `schemaVersion` and add a migration. Then add query helpers (`watchFoos`, `upsertFoo`, `deleteFoo`, `clearFoosForTenant`, `remapFooId`). See the **drift** skill for complete patterns.

```dart
@DriftDatabase(tables: [ProductTypes, SyncCursors, PendingMutations, Foos])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2;  // was 1

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(foos);
    },
  );
  // … helpers …
}
```

### 5. `data/sync/entity_sync_handler.dart` — handler implementation

Add a new `final class` implementing `EntitySyncHandler`. Append it to `buildEntitySyncHandlers`:

```dart
final class FooSyncHandler implements EntitySyncHandler {
  const FooSyncHandler();

  @override
  EntityType get entityType => EntityType.foo;

  @override
  Future<void> clearSnapshotForTenant(AppDatabase db, String tenantId) =>
      db.clearFoosForTenant(tenantId);

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    final p = _requireFooPayload(payload);
    return db.upsertFoo(p.foo);
  }

  @override
  Future<void> deleteEntity(AppDatabase db, {
    required String entityId,
    required String producerAccountId,
  }) => db.deleteFoo(producerAccountId: producerAccountId, fooId: entityId);

  @override
  Future<void> remapTmpId(AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    final p = _requireFooPayload(payload);
    final localId = p.foo.fooId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix)) return Future.value();
    if (localId == serverEntityId) return Future.value();
    return db.remapFooId(
      producerAccountId: p.foo.producerAccountId,
      oldId: localId,
      newId: serverEntityId,
    );
  }

  FooPayload _requireFooPayload(EntityPayload payload) {
    if (payload is FooPayload) return payload;
    throw StateError('Handler for $entityType cannot process ${payload.entityType}.');
  }
}

Map<EntityType, EntitySyncHandler> buildEntitySyncHandlers([
  Iterable<EntitySyncHandler> handlers = const [
    ProductTypeSyncHandler(),
    FooSyncHandler(),   // ← add here
  ],
]) { /* … existing body unchanged … */ }
```

`buildEntitySyncHandlers` throws `StateError` at startup if any `EntityType` is missing a handler — this is intentional.

### 6. `data/repositories/foo_repository.dart` — write-side repository

```dart
class FooRepository {
  FooRepository({required AppDatabase db, required IdGenerator idGenerator})
    : _db = db, _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<Foo>> watch(String tenantId) => _db.watchFoos(tenantId);

  Future<Foo> create({required String tenantId, required String name}) async {
    final foo = Foo(
      fooId: _idGen.nextTmpId(),
      producerAccountId: tenantId,
      name: name,
    );
    await _db.transaction(() async {
      await _db.upsertFoo(foo);
      await _db.enqueuePendingMutation(ClientMutation(
        clientOpId: _idGen.next(),
        op: Upsert(payload: FooPayload(foo: foo)),
      ));
    });
    return foo;
  }

  Future<void> update(Foo foo) => _db.transaction(() async {
    await _db.upsertFoo(foo);
    await _db.enqueuePendingMutation(ClientMutation(
      clientOpId: _idGen.next(),
      op: Upsert(payload: FooPayload(foo: foo)),
    ));
  });

  Future<void> delete({required String tenantId, required String fooId}) =>
      _db.transaction(() async {
        await _db.deleteFoo(producerAccountId: tenantId, fooId: fooId);
        await _db.enqueuePendingMutation(ClientMutation(
          clientOpId: _idGen.next(),
          op: Delete(entityType: EntityType.foo, entityId: fooId),
        ));
      });
}
```

`IdGenerator.nextTmpId()` generates `tmp_<uuid>`. The `SyncRepository` remaps the local row once the server confirms `MutationStatus.applied`.

## tmp_ id Lifecycle

1. `create()` stores `tmp_abc` in Drift and enqueues an `Upsert` mutation.
2. Next sync: `SyncRepository` sends the mutation, receives `MutationOutcome(serverEntityId: 'foo-1', status: applied)`.
3. `SyncRepository._reconcileMutations()` calls `handler.remapTmpId()` → `db.remapFooId()`.
4. The local row now has `fooId: 'foo-1'`; the pending mutation is drained.

## Code Generation

After all 6 files are in place:

```bash
cd front/
dart run build_runner build --delete-conflicting-outputs
```

This generates `foo.freezed.dart`, `foo.g.dart`, `entity_payload.freezed.dart`, and `database.g.dart`.

## Tests to Add

- `test/data/local/database_test.dart` — CRUD + producer isolation + `remapFooId`
- `test/data/repositories/foo_repository_test.dart` — create/update/delete + optimistic write + mutation enqueue
- `test/acceptance/sync_acceptance_test.dart` — add test cases for bootstrap and incremental sync of the new entity, using `_ScriptedSyncApi` (see **acceptance-tests** skill)

## Run Commands

```bash
# Unit tests for data layer
flutter test test/data/

# All tests excluding cross-component
flutter test --exclude-tags cross-component
```
