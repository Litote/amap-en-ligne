---
name: acceptance-scenarios
description: Acceptance scenario format for this project. Use when adding or modifying JSON scenario files in acceptance/scenarios/. Covers the given/when/then structure, targets, step format, cursor refs, and all assertion kinds.
---

## Location

Scenario files live in `acceptance/scenarios/` at the repository root (not inside `back/`).
Each file is a `.json` document. The test runner (`AcceptanceScenariosTest`) discovers all `.json` files in that directory and executes those targeting `"server"`.

## File structure

```json
{
  "id": "my-scenario-id",
  "title": "Human-readable description of what is verified",
  "targets": ["server", "flutter"],
  "given": {
    "backendState": "empty",
    "appState": "fresh"
  },
  "when": [ /* steps */ ],
  "then": {
    "lastResponse": { /* assertions on the last step's response */ }
  }
}
```

### `targets`
- `"server"` — executed by `AcceptanceScenariosTest` against the JVM deployment
- `"flutter"` — executed by the Flutter integration test suite
- Include both unless the scenario is specific to one side

### `given`
Currently only `"backendState": "empty"` and `"appState": "fresh"` are supported. The test runner resets the DB before each scenario.

## Steps (`when` array)

Each step is a sync call:
```json
{
  "actor": "client",
  "action": "sync",
  "request": {
    "cursors": {},
    "mutations": []
  },
  "save": {
    "cursorRefs": {
      "ProductType": "myRefName"
    }
  }
}
```

- `actor` must be `"client"`, `action` must be `"sync"`
- `cursors`: map of `EntityType → cursor string` (or `{}` for bootstrap)
- `mutations`: list of `ClientMutation` objects (see below)
- `save.cursorRefs`: after the step, save the returned cursor for `EntityType` under `myRefName` for use in later steps via `"$ref:myRefName"`

### Cursor reference in a later step
```json
"cursors": {
  "ProductType": "$ref:myRefName"
}
```

## Mutations

```json
{
  "client_op_id": "op-1",
  "op": {
    "type": "Upsert",
    "payload": {
      "type": "ProductType",
      "productType": {
        "product_type_id": "tmp_my-new-entity",
        "producer_account_id": "producerAccountId",
        "name": "My Product",
        "supported_basket_sizes": [{ "name": "small" }]
      }
    }
  }
}
```

- `client_op_id`: unique string within the scenario
- `type: "Upsert"` or `type: "Delete"`
- For Upsert: `payload.type` matches `EntityType` name, payload body matches the model
- For creations, use `"tmp_"` prefix on the id — server allocates the real id and returns it in `serverEntityId`
- `"producer_account_id": "producerAccountId"` — the test harness authenticates as this fixed producer account

## Assertions (`then.lastResponse`)

```json
{
  "statusCode": 200,
  "mutationOutcomes": [
    {
      "clientOpId": "op-1",
      "status": "APPLIED",
      "serverEntityId": { "kind": "present-and-not-equal", "value": "tmp_my-new-entity" }
    }
  ],
  "snapshotByEntityType": {
    "ProductType": {
      "itemCount": 1,
      "contains": [{ "name": "My Product" }]
    }
  },
  "changesByEntityType": {
    "ProductType": 1
  },
  "containsChanges": [
    { "entityType": "ProductType", "entityId": "pt-real-id", "op": "UPSERT" }
  ]
}
```

### String expectation kinds
| kind | meaning |
|---|---|
| `"non-empty-string"` | value is present and non-blank |
| `"present-and-not-equal"` | value is present and differs from `value` field |
| `"equals"` | value equals `value` field exactly |

### `snapshotByEntityType`
Only present in the response when the corresponding cursor was `null` (bootstrap). Use `{}` (empty object) to assert that no snapshots are returned.

### `changesByEntityType`
Only present when a non-null cursor was sent. The integer is the expected count of changes in the page.

## Running scenarios locally

```bash
# From back/
./gradlew :deploy:jvm:acceptanceTest
# Or via root task:
./gradlew acceptanceTest
```

The task starts a Testcontainers Postgres, applies Flyway, starts the JVM server, and runs `AcceptanceScenariosTest`.
