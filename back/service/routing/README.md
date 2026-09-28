# service:routing

HTTP layer for the back. Defines the Ktor `Application` module
`Application.dataRoutingModule(koin)` and every route the back exposes. Reused
by both deployments — `deploy:jvm` runs it on a CIO embedded server,
`deploy:lambda` runs it through the `lib:lambda-ktor` engine adapter — so
HTTP behaviour is identical across transports.

## Responsibilities

- Wire all routes into a Ktor `Application`.
- Install global plugins: JSON `ContentNegotiation`, a `StatusPages`
  exception handler that returns the project's standard `internalServerError`
  envelope.
- Compose the `Json` used by ContentNegotiation: starts from the shared
  `serialization.json` and adds any `InstanceAuthConfigSerializers`
  contributed by the active deploy's adapter (so the polymorphic
  `InstanceAuthConfig` discriminator on the discovery doc serializes
  with the right `kind`).
- Enforce the auth pre-check on authenticated routes via
  `ApplicationCall.authenticatedInfoOrRespond(...)` — single seam over
  `AuthenticationService`, responds `401` with `WRONG_SERVER` / expired /
  invalid envelopes, returns `AuthenticatedInfo` on success.

The module does not know about transport (no Lambda, no CIO), persistence,
or domain logic. Services are resolved from Koin at startup.

**CORS is not handled here.** In the Lambda deploy it is configured at the
API Gateway level (`infra/modules/api_gateway/main.tf`); in the JVM deploy
the standard Ktor `CORS` plugin is installed conditionally by `deploy:jvm`
when `CORS_ALLOW_ORIGINS` is set (see that module's `CorsConfig.kt`).

## Exposed endpoints

### Public (no auth)

| Method | Path                                            | Notes                                                                          |
|--------|-------------------------------------------------|--------------------------------------------------------------------------------|
| GET    | `/.well-known/amap-en-ligne.json`               | Instance discovery doc, `Cache-Control: max-age=3600`                          |
| GET    | `/.well-known/apple-app-site-association`       | iOS Universal Links (404 if `IOS_TEAM_ID` / `IOS_BUNDLE_ID` unset)             |
| GET    | `/.well-known/assetlinks.json`                  | Android App Links (404 if `ANDROID_PACKAGE_NAME` / `ANDROID_CERT_FINGERPRINT` unset) |
| GET    | `/v1/public/organizations`                      | Active organizations summary                                                   |
| GET    | `/v1/public/servers`                            | Known peer servers                                                             |
| POST   | `/v1/organization-requests`                     | Request to create an AMAP                                                      |
| POST   | `/v1/producer-requests`                         | Request to create a producer account                                           |
| POST   | `/v1/public/member-join-requests`               | Request to join an AMAP                                                        |
| POST   | `/v1/activate`                                  | Activate an account from an emailed token                                      |

### Authenticated

| Method | Path                                                                  | Caller                                                                   |
|--------|-----------------------------------------------------------------------|--------------------------------------------------------------------------|
| POST   | `/v1/sync`                                                            | Any caller with `producerAccountId`, `organizationId`, or `OWNER` role   |
| POST   | `/v1/coordinator/deliveries/{deliveryId}/send-attendance-email`       | Coordinator                                                              |
| GET    | `/v1/admin/producer-accounts/search?q=...`                            | ADMIN / OWNER — the only authenticated REST exception (see note below)   |
| PATCH  | `/v1/owner/me/profile`                                                | OWNER self                                                               |
| PATCH  | `/v1/producer/me/profile`                                             | PRODUCER self                                                            |

## Auth surface principle

Authenticated state-changing work funnels through `POST /v1/sync` —
clients submit `ClientMutation`s, the server replies with per-scope results
and per-mutation outcomes. The remaining authenticated REST endpoints are
deliberate exceptions:

- `GET /v1/admin/producer-accounts/search` returns producers **not yet
  visible** to the caller's sync scope, so it cannot be expressed as scope
  state today.
- `/v1/coordinator/...send-attendance-email` triggers a side-effect (email
  dispatch) on demand, not a state mutation.
- `/v1/owner/me/profile` and `/v1/producer/me/profile` mutate the caller's
  identity in the auth provider (GoTrue / Cognito), which is upstream of
  the sync layer.

See [`../../CONTRIBUTING.md`](../../CONTRIBUTING.md) — "API surface" section —
for the broader discussion.

## Module composition

`dataRoutingModule` resolves the following from Koin and wires them in:

- `DataService`, `PublicService`, `ActivationService`, `CoordinatorService`,
  `OwnerService`, `ProducerAccountService` (from `service:data`)
- `AuthenticationService` (from `lib:authentication`, implementation
  provided by `lib:authentication-gotrue` or `lib:authentication-cognito`)
- `InstanceConfig` and optional `InstanceAuthConfigSerializers` (from
  `lib:instance-config` + the active `lib:instance-config-*` adapter)
- `HttpService` (from `lib:http`) for the standard error envelopes
- `Properties` (from `lib:properties`) for the deep-link routes
- `ProducerAccountSyncDAO` (from `persistence:dao`) — the search route
  goes straight to the DAO since it is a read-only query

## Adding a new route

1. Create `XxxRoute.kt` with an `internal fun Route.xxxRoute(...)`
   extension. Take only services as parameters — never inject Koin
   directly into the route.
2. Register it inside the `routing { ... }` block of `dataRoutingModule`,
   resolving the required services from `koin.koin.get<...>()` at the
   top of the function.
3. If the route is public, add the path to
   `AuthenticationService.isUnauthenticatedPath` so the auth pre-check
   skips it. Otherwise call `call.authenticatedInfoOrRespond(...)` at
   the top of each handler.
4. Add a route test under `src/test/kotlin/`. Tests use `testApplication`
   with `dataRoutingModule(koin)` and stub Koin singletons via `module { ... }`.

For more on the wider sync/auth contract, see
[`../../CONTRIBUTING.md`](../../CONTRIBUTING.md) — "Authentication", "API
surface", and "Offline-first synchronisation" sections.
