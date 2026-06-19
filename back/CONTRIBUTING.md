# Contributing — amap-en-ligne — back

Architecture notes and domain decisions for the Kotlin backend.
For the global coding rules see [`AGENTS.md`](AGENTS.md); for root-level
commit/PR conventions see the [repository root `CONTRIBUTING.md`](../CONTRIBUTING.md).

---

## Module layout

```
back/
├── convention/                  Gradle convention plugins (shared build logic)
├── lib/                         Cross-cutting libraries (id, lambda, http, …)
├── persistence/
│   ├── model/                   Pure domain data classes (@Serializable)
│   ├── changes/                 Change records for offline-first sync (this doc)
│   ├── dao/                     Abstract persistence interfaces
│   └── dynamo/                  DynamoDB implementation of the DAOs
├── service/                     Application services (use cases)
└── deploy/lambda/               Native GraalVM Lambda entry point
```

`back/` is a single Gradle multi-project build — every module above is a subproject of `back/settings.gradle.kts` (no per-module `settings.gradle.kts` or `gradle.properties`). The only included build is `convention/`, which hosts shared build logic.

Inter-module dependencies use project paths: `api(project(":lib:id"))`, `implementation(project(":service:data"))`. Each module sets `group` to its top-level directory (`lib` / `persistence` / `service` / `deploy`) — required to disambiguate `:lib:lambda` from `:deploy:lambda`. Never introduce cyclic dependencies between modules.

---

## Authentication

`POST /v1/sync` requires a Bearer JWT in the `Authorization` header. JWT verification is hidden behind a single seam — the [`AuthenticationService`](lib/authentication/src/main/kotlin/AuthenticationService.kt) interface — with one implementation per deployment selected via Koin:

| Deployment      | Koin module                   | Implementation                                                                                                       | Provider                                                                          |
|-----------------|-------------------------------|----------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| `deploy:lambda` | `CognitoAuthenticationModule` (in `lib:authentication-cognito`) | [`CognitoAuthenticationService`](lib/authentication-cognito/src/main/kotlin/CognitoAuthenticationService.kt) | AWS Cognito User Pool — RS256 tokens, public keys fetched via JWKS                |
| `deploy:jvm`    | `GoTrueAuthenticationModule` (in `lib:authentication-gotrue`) | [`GoTrueAuthenticationService`](lib/authentication-gotrue/src/main/kotlin/GoTrueAuthenticationService.kt)   | Self-hosted Supabase Auth (GoTrue) — HS256 tokens signed with a shared secret     |

The core `lib:authentication` module exposes only the `AuthenticationService` interface and the shared model (`Authentication`, `AuthenticatedInfo`, `Role`, `Scope`, `MemberType`). It carries no JWT-library dependency. Each provider lives in its own module so a deploy never pulls the other provider's dependencies into its classpath.

Both produce the same [`AuthenticatedInfo`](lib/authentication/src/main/kotlin/AuthenticationModel.kt). Downstream code (`SyncRoute`, `DataService`, the `EntityTypeService` family) never sees the underlying provider.

### Configuration

Each implementation reads its config via [`Properties.Instance`](lib/properties/src/main/kotlin/Properties.kt), which checks JVM `-D` properties first then env vars — same pattern as the rest of the back.

| Implementation | Variable               | Required | Source                                                          |
|----------------|------------------------|----------|-----------------------------------------------------------------|
| Cognito        | `COGNITO_ISSUER_URL`   | yes      | terraform output `cognito_issuer_url`                           |
| Cognito        | `COGNITO_CLIENT_ID`    | yes      | terraform output `cognito_client_id`                            |
| GoTrue         | `GOTRUE_JWT_SECRET`    | yes      | same secret shared with the GoTrue container                    |
| GoTrue         | `GOTRUE_JWT_ISSUER`    | yes      | matches GoTrue's own `GOTRUE_JWT_ISSUER`                        |
| GoTrue         | `GOTRUE_JWT_AUDIENCE`  | no       | default `authenticated` — matches GoTrue's `GOTRUE_JWT_AUD`     |

The Cognito Lambda also benefits from a defense-in-depth check at API Gateway: a native JWT authorizer verifies issuer + signature + `client_id` ≡ audience before invoking the Lambda. The Lambda re-validates locally — kept on purpose so the contract holds even if the gateway is bypassed.

### Claim mapping

Both providers expose the same logical fields under different claim shapes. This is the contract:

| `AuthenticatedInfo`                 | Cognito claim                                                | GoTrue claim                                          |
|-------------------------------------|--------------------------------------------------------------|-------------------------------------------------------|
| `memberId`                          | `sub`                                                        | `sub`                                                 |
| `email` / `emailVerified`           | `email` / `email_verified`                                   | `email` / `email_verified`                            |
| `firstName` / `lastName`            | `given_name` / `family_name`                                 | `user_metadata.given_name` / `user_metadata.family_name` |
| `language`                          | `locale` (standard OIDC attribute)                           | `user_metadata.locale`                                |
| `timezone`                          | `zoneinfo` (standard OIDC attribute)                         | `user_metadata.zoneinfo`                              |
| `roles`                             | `cognito:groups` (`List<String>`)                            | `app_metadata.roles` (`List<String>`)                 |
| `scopes`                            | `scope` (space-separated, `<resource_server>/<scope>`)       | `app_metadata.scopes` (`List<String>`)                |

**`app_metadata` vs `user_metadata` (GoTrue).** GoTrue tokens carry both. `app_metadata` is admin-controlled — only modifiable via the service-role key or direct SQL on `auth.users`. `user_metadata` is user-controlled — modifiable from any authenticated session via `/user`. Security-sensitive claims (roles, scopes) therefore must live in `app_metadata`; putting them in `user_metadata` would let any authenticated user grant themselves arbitrary roles.

**Why `locale` / `zoneinfo` for Cognito.** Cognito's custom-attribute names are constrained to `^[a-zA-Z0-9_]+$` — no `:` allowed. The standard OIDC attributes `locale` and `zoneinfo` carry the same semantics and are emitted natively, so we use those rather than inventing custom attributes that would need awkward underscored names.

**Cognito scope prefix.** Cognito Resource Server scopes are emitted as `<resource_server>/<scope>` (e.g. `api/read:profile`) alongside reserved OIDC scopes (`openid`, `email`, …). `CognitoAuthenticationService` strips the resource-server prefix before mapping to the `Scope` enum; reserved scopes simply fail `Scope.fromString` and are dropped by `mapNotNull`.

**Cognito access tokens have no `aud`.** Local audience verification is intentionally skipped on the Lambda side — Cognito access tokens carry `client_id` rather than `aud`, and the API Gateway authorizer already does that match. Re-checking it would mean reading `client_id` manually, which adds duplication without changing the contract.

### Roles and scopes

Both [`Role`](lib/authentication/src/main/kotlin/AuthenticationModel.kt) and [`Scope`](lib/authentication/src/main/kotlin/AuthenticationModel.kt) are closed enums on the back. Unknown values are logged and dropped (`mapNotNull { fromString(it) }`) — extending an enum is therefore additive on the back, but it must be coordinated with whichever authorisation mapping pushes those values into the JWT.

| Provider | Where roles come from                                                       | Where scopes come from                                                                                                                                |
|----------|-----------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| Cognito  | `cognito:groups` — Terraform creates one group per `Role` in `infra/modules/cognito/main.tf`. | `scope` claim, populated by the Cognito Resource Server (`identifier = "api"`) — Terraform declares one scope per `Scope` enum value.                 |
| GoTrue   | `app_metadata.roles` — set via GoTrue's admin API or direct SQL on `auth.users`. | `app_metadata.scopes` — same channel.                                                                                                                 |

Adding a `Role` or `Scope`:

1. Extend the enum in `lib:authentication`.
2. **Cognito**: extend `var.groups` / `var.api_scopes` in `infra/modules/cognito/variables.tf` (or the explicit lists at the call site) and re-`terraform apply`.
3. **GoTrue**: assign the new value via the admin API on the relevant users (`PUT /admin/users/{id}` with `{"app_metadata": {"roles": [...]}}`).

### Local development with GoTrue

`back/deploy/jvm/docker-compose.yml` runs Postgres + Flyway + GoTrue side by side — the same topology used in production via self-hosted Supabase.

Two scripts handle the full lifecycle; run them from the **repo root**:

```bash
# First launch or after a reset: start the stack and seed one test user.
./back/deploy/jvm/dev-init.sh

# Wipe the postgres volume and stop all containers.
./back/deploy/jvm/dev-reset.sh
```

`dev-init.sh` starts the stack, waits for GoTrue to be ready, creates the user if it does not exist yet (or resets its password if it does), sets `app_metadata.producer_account_id` and `roles` via the admin API, and prints a fresh access token. Requires `curl`, `jq`, and `openssl` — no Python.

Customise via environment variables (all optional — dev defaults work out of the box):

| Variable | Default |
|---|---|
| `DEV_EMAIL` | `test@example.com` |
| `DEV_PASSWORD` | `testpwd123` |
| `DEV_PRODUCER_ACCOUNT_ID` | `producer-dev` |
| `GOTRUE_JWT_SECRET` | value from `docker-compose.yml` |

Then start the back (`.env` is auto-loaded by the `run` task):

```bash
# from back/
cp deploy/jvm/.env.example deploy/jvm/.env   # once
./gradlew :deploy:jvm:run
```

`JvmDeploymentIntegrationTest` does not depend on a running GoTrue: it mints a JWT directly with `JWT.create().sign(Algorithm.HMAC256(secret))` using the same secret it injects into the back via system properties. This is the canonical test fixture for HS256 providers — replicate the pattern when adding tests that need an authenticated request.

Documented server acceptance stories live in `../acceptance/scenarios/` and are executed by `deploy:jvm:acceptanceTest`.

```bash
# from back/
./gradlew acceptanceTest

# from repo root
./gradlew acceptanceTest
```

### Adding another provider

The interface seam is intentional: a new provider (Keycloak, Authentik, …) plugs in as a third implementation of `AuthenticationService` plus a third Koin module, with no change to `service:routing`, `service:data` or any DAO. The contract:

- `getAuthentication(token: String?): Authentication` — returns `Success` / `InvalidToken` / `ExpiredToken`. Must be safe to call on every request; cache JWKS / shared secret at construction time, not per-call.
- The returned `AuthenticatedInfo.producerAccountId` is the tenant scope used downstream by `DataService` to derive partition keys — a token without one is a member token (read-only flows). Whether to reject it is the provider's choice.

### CORS

CORS is handled differently per deployment:

- **`deploy:lambda`** — API Gateway's `cors_configuration` block (`infra/modules/api_gateway/main.tf`) intercepts OPTIONS preflights and adds the `Access-Control-*` headers on responses. The `ktor-server-cors` plugin is **not** on the Lambda classpath; `service:routing` does no CORS work. The Terraform `cors_allow_origins` variable mirrors the JVM env-var semantics: empty list (default) → no CORS block emitted at all; `["*"]` → wide open (dev only); explicit list → whitelist.
- **`deploy:jvm`** — the standard `ktor-server-cors` plugin is installed by `CorsConfig.kt` in this module, **conditionally** on the `CORS_ALLOW_ORIGINS` env var:
  - unset / empty → plugin not installed (production same-origin deploy default)
  - `*` → `anyHost()` (dev only; never in production)
  - csv of explicit origins → whitelist via `allowHost(...)` per entry

The intent is that a production same-origin deploy serves the web client and the API from the same domain and therefore needs no CORS at all. The plugin is opt-in for dev, federation flows (a Flutter client on instance A discovering instance B's `/.well-known/amap-en-ligne.json`), or any cross-origin deployment shape.

---

## API surface

> **Authenticated state-changing work goes through `POST /v1/sync`. Only public bootstrap endpoints and a handful of deliberate exceptions live outside sync.**

Sync is the default surface so that the offline-first contract holds for every authenticated client: any state a user produces, observes, or mutates is reconciled through sync scopes (`producer-account:{id}`, `organization:{id}`, `instance-owner`). Side-effects (email dispatch, auth-provider provisioning, anonymisation, audit logs) are orchestrated by the relevant `EntityTypeService.applyUpsert` / `applyDelete` as part of the same atomic transaction that writes the entity row and the `Change` record.

**Public REST endpoints (unauthenticated, served before login):**

| Route                                          | Purpose                                                |
|------------------------------------------------|--------------------------------------------------------|
| `GET /.well-known/amap-en-ligne.json`          | Instance discovery document                            |
| `GET /.well-known/apple-app-site-association`  | iOS Universal Links                                    |
| `GET /.well-known/assetlinks.json`             | Android App Links                                      |
| `GET /v1/public/organizations`                 | Browse visible AMAPs                                   |
| `GET /v1/public/servers`                       | List federated peer servers                            |
| `POST /v1/public/member-join-requests`         | Request to join an AMAP (no account yet)               |
| `POST /v1/organization-requests`               | Request to create an AMAP (no account yet)             |
| `POST /v1/producer-requests`                   | Request to create a producer account (no account yet)  |
| `POST /v1/activate`                            | Activate an account from a token sent by email         |

**Authenticated REST exceptions (cannot be expressed as sync state today):**

- `GET /v1/admin/producer-accounts/search?q=` — returns producers **not yet visible** to the caller's sync scope (used by the AMAP-admin enrollment flow). Decision pending whether to fold it into sync.
- `POST /v1/coordinator/deliveries/{deliveryId}/send-attendance-email` — triggers an on-demand side-effect (PDF generation + email), not a state mutation.
- `PATCH /v1/owner/me/profile`, `PATCH /v1/producer/me/profile` — mutate the caller's identity in the auth provider (GoTrue / Cognito), which is upstream of the sync layer.

Auth-provider endpoints (login, refresh, password reset) are served by GoTrue / Cognito directly and are out of scope here.

Everything else — admin lifecycle (member suspend / reactivate / delete, owner / member invitation creation / cancel / resend, organization-request approval, producer-request approval, member-join-request approval, basket exchange offers and decisions, volunteer self-registration on deliveries, …) — flows through `POST /v1/sync` as `Upsert` / `Delete` mutations on the appropriate scope.

---

## Offline-first synchronisation

The front is offline-capable and reconciles its local cache against the
server by asking for the set of changes it has not yet seen. This section
describes the server-side design that supports this.

### Goals

- The client must be able to **bootstrap from scratch** (no local data) and
  end up with the complete set of entities it owns.
- Between two synchronisations the client must receive **only the deltas**
  that apply to it, keyed by an opaque `cursor`.
- A mutation must become visible through the sync API **atomically** with
  the update to the entity itself — a client must never see an entity in the
  main table that is missing from the change feed, or vice versa.
- The sync storage footprint must stay **proportional to the number of
  live entities**, not the full mutation history.

### Data model

A [`Change`](persistence/wire/src/main/kotlin/Change.kt) is the unit of
synchronisation:

| Field                | Role                                                                   |
|----------------------|------------------------------------------------------------------------|
| `cursor`             | ULID produced at write time — lexicographically sortable by time.      |
| `entityType`         | Discriminator, e.g. `"ProductType"`.                                   |
| `entityId`           | Opaque id of the entity in its main table.                             |
| `producerAccountId`  | Tenant owner. Used as the partition scope.                             |
| `op`                 | `UPSERT` or `DELETE`.                                                  |
| `payload`            | Full serialised entity for `UPSERT`; `null` tombstone for `DELETE`.    |
| `producedAt`         | Epoch ms, debug metadata only — never used as a key.                   |

Storing the **full payload** on `UPSERT` lets the sync endpoint answer in
one round-trip: the client never has to re-read the main table to resolve a
change.

### DynamoDB layout

One table `changes`, one global secondary index:

```
Base table
  PK (HASH)  = "{entityType}#{producerAccountId}"
  SK (RANGE) = entityId
  Attributes = cursor, op, payload, producedAt

GSI "by_cursor"
  PK (HASH)  = "{entityType}#{producerAccountId}"  (same as base)
  SK (RANGE) = cursor
  Projection = ALL
```

- The **base table** guarantees a single row per live entity (the PK is
  `(entityType#tenant, entityId)`). Re-upserting the same entity overwrites
  the previous change; a delete writes a tombstone keyed by its `entityId`.
- The **GSI** is the read path for the sync API: it sorts the same items by
  `cursor` so we can answer both full-history and incremental queries with
  a single `Query` call per entity type.

No TTL. Table size is bounded by (live entities + historical tombstones).
If deletion volume ever outgrows comfort, we will either add a TTL on
`DELETE` rows with a forced-resync threshold on the client, or a background
compaction job — neither is needed at current scale.

### Write path (atomic)

Every domain mutation goes through a single `TransactWriteItems`:

```
Upsert of ProductType
  PutItem  data     (entity row)
  PutItem  changes  (op=UPSERT, payload=<serialised entity>, cursor=<new ULID>)

Delete of ProductType
  DeleteItem  data
  PutItem     changes  (op=DELETE, payload=null, cursor=<new ULID>)
```

Because both writes commit or neither does, **the sync feed can never diverge
from the main table**. Any path that mutates an entity must go through this
transactional boundary — direct writes to the `data` table are forbidden.

### Sync API

```
POST /v1/sync
{
  "cursors": {
    "ProductType":     "01HK3X5Z9QABCD…",
    "ProducerAccount": null
  }
}
```

- A `null` cursor (or absent entry) means "I have nothing, send everything".
- An empty `cursors` map is shorthand for "bootstrap every entity type I
  don't know about" and the server expands it to all known types.

The response is split per entity type between an incremental `changes`
entry and a bootstrap `data` entry:

```jsonc
{
  "changes": {
    "ProductType": {
      "changes": [
        { "cursor": "01HK3X…", "op": "UPSERT", "entity_id": "pt-42", "payload": { … } },
        { "cursor": "01HK3Y…", "op": "DELETE", "entity_id": "pt-37" }
      ],
      "next_cursor": "01HK3Y…",
      "has_more":    false
    }
  },
  "data": {
    "ProducerAccount": {
      "items":  [ { … }, { … } ],
      "cursor": "01HK3Z…"
    }
  }
}
```

- A non-null client cursor ⇒ entry under `changes`. The handler runs a GSI
  `Query` with `SK > cursor` and returns the incremental delta. Pagination
  uses DynamoDB's `LastEvaluatedKey`: when the page limit is reached the
  handler sets `has_more: true` and the client resumes with `next_cursor`.
- A null/absent client cursor ⇒ entry under `data`. The handler reads the
  current state directly from the entity table (e.g. `ProductTypeSyncDAO`) and
  returns each entity serialised in `items`. The `cursor` returned in the
  snapshot is the resumption point for subsequent incremental syncs.

### Write path (client mutations)

Clients are offline-capable and queue local mutations while disconnected.
They flush them to the server in the same `POST /v1/sync` round-trip that
fetches deltas, by attaching a `mutations` list to the request:

```jsonc
{
  "cursors": { "ProductType": "01HK3X…" },
  "mutations": [
    { "client_op_id": "op-7", "entity_type": "ProductType", "op": "UPSERT",
      "entity_id": "tmp_abc",   "payload": { … } },
    { "client_op_id": "op-8", "entity_type": "ProductType", "op": "DELETE",
      "entity_id": "pt-37" }
  ]
}
```

The server applies mutations **before** the read step, so any change emitted
by an applied mutation appears in the same response's `changes` page (its
cursor is strictly greater than the one sent by the client). Per-mutation
results are returned in the response's `mutations` field, correlated by
`client_op_id`:

```jsonc
{
  "changes": { … },
  "data":    { … },
  "mutations": [
    { "client_op_id": "op-7", "status": "APPLIED",  "server_entity_id": "9c1f…" },
    { "client_op_id": "op-8", "status": "REJECTED",
      "error": { "code": "FORBIDDEN", "message": "producer_account_id mismatch" } }
  ]
}
```

**Per-mutation atomicity.** Each mutation is its own
`TransactWriteItems` (entity row + change row, as on the write path
above). Mutations within one sync request are independent: a failure of
mutation N does not roll back mutations 0..N-1. The client retries only
the failed ones.

**Temporary ids.** A creation carries an `entity_id` prefixed with `tmp_`
(client-generated). The server allocates a real id, writes the entity and
the change row using that real id, and returns it in
`server_entity_id`. The client must rewrite its local row to use the real
id before its next sync.

**Error codes.**

| Code              | When                                                         |
|-------------------|--------------------------------------------------------------|
| `INVALID_PAYLOAD` | Missing/malformed payload, unknown entity type, DELETE on a `tmp_*` id. |
| `FORBIDDEN`       | Payload's `producer_account_id` differs from the JWT tenant. |
| `NOT_FOUND`       | (Reserved) target entity does not exist.                     |
| `UNIQUE_VIOLATION`| (Reserved) domain-level uniqueness constraint violated.      |
| `CONFLICT`        | (Reserved) optimistic-concurrency conflict.                  |

**Idempotency on retry.** Not implemented in v1. If the network drops just
after the server commits a mutation, a retry will re-execute it: a new
`tmp_*` creation will allocate a *second* real id, an UPSERT will be
applied twice (idempotent at the entity level), a DELETE will be applied
twice (also idempotent). The client surfaces the duplicate creation on the
next sync via the change feed and reconciles. The clean fix — persisting
`client_op_id` on the `Change` row plus a GSI for lookup — is deferred
until we observe a real incident.

**Cross-mutation `tmp_*` references.** Not supported in v1. A mutation
cannot reference a `tmp_*` id allocated by another mutation in the same
batch. Clients that need to create A and then create B referencing A do
so in two sync round-trips.

---

### Bootstrap semantics

A first-install client has no cursor. It sends `{"cursors": {}}` (or an
explicit `null` per type) and the server returns an `EntitySnapshot` per
entity type under `data`. The client seeds its cache from `items` and
stores `cursor` for subsequent incremental syncs.

Reading the entity table rather than replaying the change feed keeps
bootstrap cost proportional to the number of live entities, independent of
how many historical overwrites or deletes preceded them.

**Race-freedom.** The bootstrap cursor is generated *before* the entity
table read. A mutation landing between the two lands either in the
snapshot `items` (if the read sees it) or — since its change cursor will
be strictly greater than the snapshot cursor — in the next
`since(cursor)` response. Upserts being idempotent, the client converges
either way. Inverting this order would risk a silent miss.

### Cursors

ULIDs, generated server-side at write time. Within a single writer process,
monotonicity is guaranteed; across processes in the same millisecond the
ordering is still total but not strictly "wall-clock monotonic" — this is
fine because the client only needs a total order, not causality.

Clients must treat the cursor as **opaque**: do not parse it, do not
derive timestamps from it, do not compare it to anything other than another
cursor from the same endpoint.

### Authorisation and multi-tenancy

The `producerAccountId` is included in the partition key. A given
authenticated caller can only query the partitions that match its own
`producerAccountId`; the handler builds the PK from the JWT claim, never
from client-supplied input. There is no global (cross-tenant) partition.

### Ordering, concurrency, idempotence

- Last-write-wins at the main entity table; the corresponding change row
  reflects that last state. Clients applying changes in cursor order
  converge to the server state.
- A client can replay a change it has already seen (e.g. because it crashed
  before persisting its cursor) and remain correct — applying the same
  `UPSERT` twice is idempotent.
- No version vectors, no CRDTs. If conflict resolution becomes a product
  requirement it will be handled one level up.

### Lambda topology

The sync route lives inside the existing `DataLambda` rather than in a
dedicated function. The native cold start is sub-second, code is shared,
and operationally a second Lambda would mean a second binary, a second
Terraform module and a second log group for no measurable benefit.

If one day we need to scale or isolate the sync route independently, a
second GraalVM binary (mirroring the `tracing` binary pattern in
`deploy/lambda/build.gradle.kts`) plus a second `module "lambda"` in
Terraform is the clean split.

### Open points

- Tombstone retention. Currently unbounded; revisit if delete volume grows.
- Per-entity limits in one sync response (default proposal: 200). Needs
  empirical tuning once the front is wired.
- Cross-entity transactional boundaries. Today each mutation maps 1:1 to a
  single change row. If a future use case requires grouping several entity
  mutations into one atomic delta, we will need a composite-change scheme
  or a higher-level `TransactWriteItems` envelope.

---

## DAO contract tests

Each DAO interface in `persistence:dao` has two implementations
(`persistence:dynamo` and `persistence:postgres`). Their correctness is
verified by a shared set of **contract tests** that run against both
backends without duplication.

### Mechanism

`persistence:dao` exposes a `testFixtures` source set
(`java-test-fixtures` Gradle plugin). It contains one abstract base class
per DAO:

| Abstract class | DAO under test |
|---|---|
| `ProductTypeSyncDAOContractTest` | `ProductTypeSyncDAO` + `ChangeDAO` (atomic pair) |
| `OrganizationDAOContractTest` | `OrganizationDAO` |
| `ServerDAOContractTest` | `ServerDAO` |
| `OrganizationRequestDAOContractTest` | `OrganizationRequestDAO` |

Each abstract class declares the DAO properties as `abstract val` and,
where test isolation requires a clean slate between tests, an abstract
`clearAll()` called from `@BeforeEach`.

Concrete subclasses live in `persistence:dynamo` and `persistence:postgres`
and only provide infrastructure wiring — no `@Test` methods of their own.

```
// in persistence:dynamo
class ProductTypeSyncDynamoDAOTest : ProductTypeSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val productTypeDao: ProductTypeSyncDAO = ProductTypeSyncDynamoDAO(dynamoClient)
    override val changeDao:      ChangeDAO       = ChangeDynamoDAO(dynamoClient)

    @BeforeAll fun setUp()    { DynamoTestInfra.ensureStarted(); DynamoTestInfra.createTable(dynamoClient) }
    @AfterAll  fun tearDown() { DynamoTestInfra.deleteTable(dynamoClient) }
}

// in persistence:postgres
class ProductTypeSyncPostgresDAOTest : ProductTypeSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val productTypeDao: ProductTypeSyncDAO by lazy { ProductTypeSyncPostgresDAO(postgresClient) }
    override val changeDao:      ChangeDAO       by lazy { ChangePostgresDAO(postgresClient) }

    @BeforeAll fun setUp()    { container.start(); postgresClient = PostgresClient(…) }
    @AfterAll  fun tearDown() { container.stop() }
}
```

The `by lazy` pattern on the Postgres side defers DAO construction until
the first test method runs, guaranteeing that `postgresClient` is
initialized by `@BeforeAll` before any DAO is accessed.

### DynamoDB test infrastructure

`DynamoTestInfra` (in `persistence:dynamo/src/test/kotlin/`) centralises
container management and table lifecycle:

- **One client per class, unique table name** — `DynamoTestInfra.newClient()`
  returns a `DynamoClient` configured with `DYNAMO_TABLE=data-test-<UUID>`.
  Each test class therefore writes to its own isolated table, so test
  classes can run concurrently without interfering.
- **Single container start** — `ensureStarted()` is `synchronized` on the
  singleton object. The first thread starts the container; subsequent
  threads find it already running. `maxParallelForks = 1` in
  `persistence:dynamo/build.gradle.kts` further restricts to one JVM
  process, making the synchronized guard sufficient.
- **Port 8001** — the docker-compose maps `8001:8000` so that the
  DynamoDB Local container does not conflict with other local services.
  `DynamoTestInfra.newClient()` sets `DYNAMO_LOCAL_ENDPOINT=http://127.0.0.1:8001`.
- **Retry on createTable** — `createTable()` retries up to 10 times with
  a 500 ms back-off to tolerate the brief window between TCP readiness and
  full API readiness after container start.

### Adding tests for a new DAO

When you add a new DAO interface (see the step-by-step in `AI_CONTEXT.md`):

1. Add an abstract contract class in
   `persistence/dao/src/testFixtures/kotlin/NewEntityDAOContractTest.kt`.
   Declare `abstract val dao: NewEntityDAO`. Add `@Test` methods that cover
   the full interface. If tests require a clean table, add
   `abstract fun clearAll()` and annotate the calling method `@BeforeEach`.
2. Add a concrete subclass in `persistence:dynamo` that extends the
   contract and provides `insertX` / `clearAll` helpers via
   `CoroutineScope(Dispatchers.IO).async { … }.asCompletableFuture().get()`.
3. Add a concrete subclass in `persistence:postgres` that extends the
   contract and provides helpers via plain JDBC on `postgresClient.dataSource`.
