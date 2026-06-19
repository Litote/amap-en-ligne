# AI Context — back

> Back-specific context for AI agents. System-wide contract, wire format, and cross-component invariants: [`../AI_CONTEXT.md`](../AI_CONTEXT.md).

---

## Architecture

Single Gradle multi-module build. Module groups: `lib:*`, `persistence:*`, `service:*`, `deploy:*`.

- **Single authenticated endpoint** `POST /v1/sync`; routing lives in `service:routing`, shared by both deployments:
  - `deploy:jvm` — Ktor CIO server, wired to `persistence:postgres` (self-hosted Supabase Postgres, direct JDBC).
  - `deploy:lambda` — GraalVM native on AWS Lambda via `lib:lambda-ktor` (maps API Gateway V2 events onto the Ktor pipeline), wired to `persistence:dynamo`.
- **Pluggable persistence**: `service:core` depends only on DAO interfaces (`persistence:dao` + `persistence:wire`); each deployment composes its backend module. Adding a synced entity requires **two DAO impls** (Dynamo + Postgres) plus a shared contract test in `persistence:dao` testFixtures.
- **Module layering around `service:core`**: `service:core` is the shared sync/auth kernel — it holds the `EntityTypeService` base, `RoleService`, `AuthorizedScopeResolver` and the auth/role provisioning ports (`UserProvisioningPort`, `MemberRoleProvisioningPort`, `OwnerRoleProvisioningPort`). The provider-specific impls of those ports live in dedicated service modules above `core` — `service:provisioning-gotrue` (JVM, GoTrue admin HTTP) and `service:provisioning-cognito` (Lambda, Cognito SDK) — each with its own Koin module included by the matching deployment bootstrap. The cross-cutting REST aggregators (`AdminService`, `PublicService`) backing the public/onboarding endpoints live in their own `service:onboarding` module (depends only on `persistence:*` + `service:email`/`service:notification-publisher`, **not** on the kernel; its `OnboardingModule` is `includes`d by `service:sync`'s `SyncModule`). Two **low-level capability modules sit *below* `core`** (it `api`-depends on both, so every domain gets them transitively; no cycle because they never depend on `core`):
  - `service:email` — `EmailTemplates`/`EmailContent`/`amapEmailSubject` + every `*EmailPort` interface (+ co-located payloads `AccountLifecycleTarget`/`AccountLifecycleRole`/`OwnersBroadcastEvent`/`MemberSummary`). Pure interfaces + object, **no Koin module**.
  - `service:email-delivery` — the **deployment-agnostic `*EmailPort` adapters** (`EmailDeliveryModule` `@ComponentScan`), each rendering an `EmailTemplates` message and handing it to the `EmailGateway` interface (`activationUrl` + `deliver`). Both deployments include this module and provide the concrete `EmailGateway` (`JvmEmailGateway` SMTP / `LambdaEmailGateway` SNS→SES). Only `ActivationEmailPort` stays per-deployment (cron-backed on JVM, SNS on Lambda). Depends on `service:email` + `service:notification-publisher`.
  - `service:notification-publisher` — `NotificationPublisher`/`NotificationDispatcher` (`@Single`, in `NotificationPublisherModule`, which `CoreModule` `includes`) + `NotificationChannelSender`/`NotificationContact` + `NotificationCopy`/`resolveCopy`. The channel senders (Email/Sns/Fcm) are implemented in `deploy:*` and collected as `List<NotificationChannelSender>`.
  - Each concrete `EntityTypeService` lives in its **own** `service:<name>` module *above* `core` (`organization`, `contract`, `delivery-template`, `producer-account`, `producer`, `product-type`, `member`, `member-join-request`, `member-invitation`, `organization-request`, `producer-request`, `attendance`, `exchange`, `notification` [Notification + DeviceToken entity sync], `error-report`, `owner`) that `api(project(":service:core"))`. `ActivationService` lives in `service:activation`. Every such module declares `@Module(includes = [CoreModule::class]) @ComponentScan` in its own package; `service:sync`'s `SyncModule` `includes` them all, so Koin collects every `EntityTypeService` into the `List<EntityTypeService<*>>` injected into `DataService`. Adding a synced entity = a new `service:<name>` module wired into `SyncModule` (+ `settings.gradle.kts` + `service:sync` `api` dep).
- **Atomicity**: every mutation writes the entity row(s) + the scope-keyed `Change` record(s) in one primitive — `TransactWriteItems` on Dynamo, one transaction on Postgres.
- **Auth split**: `lib:authentication` (core interface) + `lib:authentication-gotrue` (JVM, HS256 vs `GOTRUE_JWT_SECRET`) / `lib:authentication-cognito` (Lambda, RS256 via JWKS; rejects `token_use != "access"`). Same split for `lib:instance-config[-gotrue|-cognito]` (polymorphic `InstanceAuthConfig` subtypes registered via `InstanceAuthConfigSerializers`). Wrong-issuer tokens return `Authentication.WrongServer` → `401 WRONG_SERVER` + `token_issuer`.

## Persistence layout (`persistence:*`)

Four conceptual layers, each its own module. Read it as **what is stored → how it travels → how it's stored → adapters**:

| Module | Depends on | Holds | Role |
|--------|-----------|-------|------|
| `persistence:model` | `lib:authentication/id/i18n` | Domain entities + the closed `EntityType` enum. Also carries a few **transport DTOs** (`ActivateRequest/Response`, `EmailMessage`, `PublicOrganizationSummary`) that are not persisted aggregates — left here on purpose (no dedicated module). | what is stored |
| `persistence:wire` | `model` | **The whole sync wire protocol**: `Change`/`ChangeOp` (change-feed record), `EntityPayload` (polymorphic carrier), `ClientMutation`/`MutationOp`, `SyncRequest`/`SyncResponse`, `MutationOutcome`/`MutationErrorCode`, `SyncScope`, `Cursor`, `OrganizationExport`. (Formerly named `persistence:changes` — renamed because <¼ of it is about the change feed.) | how it travels |
| `persistence:dao` | `model` + `wire` | **Every DAO interface** (incl. `ChangeDAO`) + the shared contract tests in `testFixtures`. | how it's stored |
| `persistence:dynamo` / `persistence:postgres` | `dao` | DAO implementations + tests (Dynamo Local / Testcontainers). | adapters |

**DAO naming convention** — a DAO whose writes emit a `Change` (i.e. it participates in the sync feed) is named `*SyncDAO`, with mirrored impls `*SyncDynamoDAO` / `*SyncPostgresDAO`. A plain `*DAO` (no suffix) coexists **only** when the entity also has a non-sync access path (public/REST/bootstrap): e.g. `Organization` has `OrganizationSyncDAO` (feed `put(entity, change)` + snapshots) **and** `OrganizationDAO` (`listActive`/`create` for public REST). Same for `OrganizationRequest`, `ProducerRequest`, `MemberJoinRequest`. Entities with a single access pattern have one DAO carrying the right suffix.

**Parallel hierarchy (3 maintenance points per entity)** — every synced entity is declared in three places: the domain type (`model`), the `EntityType` constant (`model`), and an `EntityPayload` subclass wrapping it (`wire`). This is intrinsic to the polymorphic, `@SerialName`-discriminated wire contract — the boilerplate is the cost of compile-time exhaustiveness. Each `EntityPayload` wraps its model type under a camelCase field (`productType`, `errorReport`, …) — never inline its fields (front decodes `json['<field>']`).

## Sync resolution (`DataService`)

`AuthorizedScopeResolver` resolves the caller's scopes from auth: `producer-account:{id}` (PRODUCER; `producerAccountId = sub` by invariant), `organization:{id}`, `instance-owner` (OWNER only), plus private notification feeds `member:{sub}` / `owner:{sub}`. Mutations are applied first, then one result per scope:

- missing/null cursor ⇒ bootstrap snapshot
- non-null cursor, small diff ⇒ incremental `changes`
- diff above `DEFAULT_INCREMENTAL_LIMIT` (`ChangeDAO.countSince`) ⇒ deterministic fallback to bootstrap

**OWNER feed fan-out**: `Member` writes emit an extra `instance-owner` `Change`; `Owner`, `OrganizationRequest`, `ProducerRequest`, `OwnerInvitation` write natively on `instance-owner`; `ProducerAccount` fans out to every linked org scope + `instance-owner`. **Accepted limitation**: `Organization` *edits* emit only `organization:{id}` — OWNER picks them up on the next `instance-owner` bootstrap (deliberate: full-aggregate fan-out would flood the feed).

## Entity services (`service:<entity>` modules over the `service:core` kernel)

One `EntityTypeService<P>` per `EntityType`, each in its own `service:<name>` module (see Architecture → Per-entity service modules); side-effects (email, auth provisioning, anonymisation) run inside `applyUpsert`/`applyDelete`. Closed `EntityType` enum + exhaustive switches ⇒ adding a variant fails compilation until all branches are updated.

| Entity (scope) | Service — key rules |
|---|---|
| `ProductType` (`producer-account:{id}`) | `ProductTypeService` — `tmp_*` id allocation. |
| `Organization` (`organization:{id}`; OWNER snapshot = all orgs) | `OrganizationService` — rejects duplicate `deliveries[].scheduledDate.date` (`UNIQUE_VIOLATION`); `MISSING_COORDINATOR` guard on CONFIRMED deliveries; `CONTRACT_ENDED` guard on newly linked ended contracts (privileged path; existing links stay editable); delegates VOLUNTEER-only callers to `VolunteerMutationValidator` and privileged slot writes to `SlotLifecycleNormalizer`. |
| `ProducerAccount` (org scopes + `instance-owner`) | `ProducerAccountService` — ADMIN may create/update `NO_ACCOUNT` producers (mode immutable; single org auto-normalised; derives `Organization.products` from `ProducerAccount.products`); OWNER lifecycle: suspend/reactivate (`active_status` flip) and delete (auth users deleted, row kept inactive, `AccountDeletionLog` per sub). |
| `Member` (org + `instance-owner` fan-out) | `MemberService` — OWNER lifecycle by `sub` across all membership rows: suspend/reactivate (`SELF_ACTION_FORBIDDEN`, `LAST_ADMIN` guards), delete = anonymise PII + `AccountDeletionLog`; best-effort `UserProvisioningPort` + email side-effects. Non-privileged callers (neither OWNER nor ADMIN) may only upsert their own member row (`memberId == auth.memberId`); editing another member's profile is `FORBIDDEN`. Defense-in-depth `CONTRACT_ENDED` guard on newly added `Member.contracts[]` entries referencing ended contracts. |
| `Contract` (org) | `ContractService` — OWNER/ADMIN/COORDINATOR only for upsert and delete; org-match validation; `INVALID_SUBSCRIPTION` guard: each `ContractMember` must have ≥ 1 subscription matching a `ProductPrice` (product type + basket size); `CONTRACT_ENDED` guard: `isEffectivelyEnded(today)` = `status == ENDED || maxDeliveryDate < today` (org-timezone) — may not add new `members[]` entries; removals and status edits stay allowed; `tmp_*` creation with past dates is allowed (history import). `IN_PREPARATION` guard: `MemberService` rejects non-privileged self-subscription on `IN_PREPARATION` contracts with `FORBIDDEN`. `tmp_*` upsert allocates a real id (like `ProductTypeService`); the `DataService` batch remap propagates it to any subsequent `OrganizationPayload.deliveries[].contracts[].contractId` in the same sync call. **Shared baskets** (`Contract.sharedBaskets`): `validateSharedBaskets` guards `INVALID_SHARED_BASKET` (≥2 members, all are contract members, no member in two baskets, members share an identical subscription); a `tmp_*` `shared_basket_id` is allocated server-side (`generateId<SharedBasket>()`) but **not** echoed via `serverEntityId` (root-only) — the client recovers it from the authoritative payload (BasketExchange nested-id convention). Alternation picker is computed by the pure `SharedBasket.pickerFor` (`SharedBasketAlternation.kt`), mirrored in the front and pinned by `acceptance/scenarios/contract-shared-basket-*.json`. |
| `DeliveryTemplate` (org) | `DeliveryTemplateService` — OWNER/ADMIN/COORDINATOR only for upsert and delete; carries `desired_volunteer_count`, nullable `early_slot`. |
| `OrganizationRequest` (`instance-owner`) | `OrganizationRequestService` — OWNER review, `PENDING_VALIDATION → APPROVED` (creates `Organization` + `ActivationToken` + email) / `REJECTED` (email). Delete `FORBIDDEN`. |
| `ProducerRequest` (`instance-owner`) | `ProducerRequestService` — same pattern; APPROVED creates `ProducerAccount(ACCOUNT_BACKED)` + `ActivationToken(PRODUCER)`. |
| `MemberJoinRequest` (org) | `MemberJoinRequestService` — ADMIN/OWNER review, `PENDING → APPROVED` (creates `MemberInvitation` + token + email — **no `Member` row until activation**) / `REJECTED`. Public submission writes through the sync DAO so it appears in the org feed immediately. |
| `MemberInvitation` (org) / `OwnerInvitation` (`instance-owner`) | `MemberInvitationService` / `OwnerInvitationService` — `tmp_*` upsert creates invitation + token + email; upsert with strictly newer `resend_requested_at` invalidates old tokens and resends (idempotency cursor); `Delete` cancels (`status=CANCELLED`, tokens invalidated). `MemberInvitation` carries optional `custom_email_subject` / `custom_email_body` (persisted, forwarded to `EmailTemplates.memberInvitation`); resend persists the incoming values (the resend contract only pins identity fields, so the custom copy may change). |
| `Owner` (`instance-owner`) | `OwnerTypeService` → `OwnerService` — promotion (`tmp_*`: `OWNER_EXCLUSIVE` + `LAST_ADMIN` checks, atomic `promoteToOwner`), suspend/reactivate/delete (`LAST_OWNER`, `SELF_ACTION_FORBIDDEN`; delete bans+logs). |
| `BasketExchange` (org) | `BasketExchangeService` — reciprocal-swap aggregate with embedded `requests`. Create (caller=offerer, OPEN, no requests, active delivery, basket not already committed via `isBasketCommitted` ⇒ `UNIQUE_VIOLATION`). AddRequest (caller=requester≠offerer, exchange OPEN, no duplicate PENDING; **`proposed_delivery_id` required** — active delivery ≠ D1, requester's counter-basket not already committed; `serverEntityId` = root id). `isBasketCommitted` covers offered (OPEN/ACCEPTED) **and** both deliveries of a settled (ACCEPTED) swap for both parties (given away **or** received). **Shared-basket alternation guard** (`rejectIfNotBasketHolder`): for a contract using an alternating shared basket, only the family whose turn it is may offer (create) or counter-offer (addRequest) that delivery's basket — resolved via `Contract.holdsBasketOn` (`SharedBasketAlternation.kt`); `FORBIDDEN` otherwise. No-op for non-shared contracts. Withdraw (caller=requester, PENDING→WITHDRAWN). **Refuse** (offerer-only, single PENDING→REJECTED, offer stays OPEN — `detectSingleRequestTransition`). Cancel/Accept (offerer-only, atomic PENDING→REJECTED fan-out, `CONFLICT` if not OPEN). Notifications (`notifyMember`) carry concrete delivery dates + `deep_link`. Delete always `FORBIDDEN`. |
| `Notification` (private feeds) | `NotificationService` — recipient-agnostic (ownership vs caller's resolved private feeds); client may only flip `read_at` or archive; anything else `FORBIDDEN`. Created server-side via `NotificationPublisher` (atomic row + Change, then best-effort dispatch). Title/body resolved through `Map<NotificationCategory, NotificationCopyOverride>.resolveCopy(...)` (`NotificationCopy.kt`) against `Organization.notificationOverrides` at each org-scoped publish site; owner-targeted categories keep hardcoded defaults. |
| `DeviceToken` (private feeds) | `DeviceTokenService` — client-authored; dedup by `(recipientScope, token)`; delete on logout. |
| `AttendanceEmailRequest` (org) | `AttendanceEmailRequestService` — COORDINATOR/ADMIN/OWNER only; sets `sent_at`, best-effort `AttendanceEmailPort`. Delete `FORBIDDEN`. |
| `ErrorReport` (`instance-owner`) | `ErrorReportService` — any caller may create with `tmp_*` id; immutable; delete `FORBIDDEN`. |

`MutationErrorCode`: `NOT_FOUND`, `FORBIDDEN`, `INVALID_PAYLOAD`, `UNIQUE_VIOLATION`, `CONFLICT`, `OWNER_EXCLUSIVE`, `PRODUCER_EXCLUSIVE`, `MIXED_ROLES`, `LAST_ADMIN`, `LAST_OWNER`, `LAST_PRODUCER`, `SELF_ACTION_FORBIDDEN`, `MISSING_COORDINATOR`, `CONTRACT_ENDED`, `INVALID_SUBSCRIPTION`, `INVALID_SHARED_BASKET`.

`RoleService` centralises role-exclusivity validation (`validateGrantOwner`, `validateLastAdmin`, `validateLastOwner`, `validateMixedRoles`, `validateProducerExclusive`); producer checks resolve through `UserProvisioningPort.findProducerAccountIdByEmail`.

### Validators co-located in `OrganizationService.kt`

- **`VolunteerMutationValidator`** — VOLUNTEER-only callers: the diff must be limited to `deliveries[].contracts[].slots[].registrations`, each touched registration must be the caller's own, target delivery must be active, capacity caps apply (`requiredVolunteers` for STANDARD; for EARLY the cap resolves `Delivery.earlySlot.maxVolunteers` first, then the linked `DeliveryTemplate.earlySlot.maxVolunteers` — neither set ⇒ `FORBIDDEN`, so a template-less delivery may still offer an early slot via its own override). No registration changes on a CANCELLED slot.
- **`SlotLifecycleNormalizer`** — privileged upserts: backfills missing `slot_id`s (diff matching: by id, then natural key), rejects deleting a slot with active registrations (`CONFLICT`), rejects reopening CANCELLED (`FORBIDDEN`), normalizes the cancellation cascade (registrations → CANCELLED, counter reset), emits `SlotEvent`s consumed post-commit → `NotificationPublisher` (`SLOT_CANCELLED` / `SLOT_RESCHEDULED`, type ALERT, `member:{sub}` feeds).

## REST surface

- `/.well-known/*` — instance discovery (`DiscoveryRoute`, env: `INSTANCE_NAME`, `INSTANCE_API_URL`, optional `INSTANCE_VISIBLE`) + app links (`DeepLinkRoute`, 404 unless `IOS_TEAM_ID`/`IOS_BUNDLE_ID` resp. `ANDROID_PACKAGE_NAME`/`ANDROID_CERT_FINGERPRINT` set).
- `GET /v1/public/organizations`, `GET /v1/public/servers` (`PublicRoute` → `PublicService`).
- `POST /v1/organization-requests`, `POST /v1/producer-requests`, `POST /v1/public/member-join-requests` — public submissions; duplicate checks return `409 {"field": ...}`; no password stored at submission.
- `POST /v1/activate` (`ActivationService`, dispatches on `ActivationToken.kind`):
  - `ORGANIZATION_ADMIN` — creates admin auth user + initial `ProducerAccount` (`createInitial`, no Change).
  - `PRODUCER` — creates producer auth user (`sub` = producerAccountId).
  - `OWNER` — creates owner auth user + `Owner` row, marks `OwnerInvitation` ACTIVATED.
  - `MEMBER` — creates member auth user + `Member` row (org + `instance-owner` Changes), marks `MemberInvitation` ACTIVATED.
  - Errors: `404` unknown/invalidated, `410` expired, `409` already activated. Email link base: `INSTANCE_WEB_URL` (defaults to `INSTANCE_API_URL`).
- `GET /v1/admin/producer-accounts/search?q=` — authenticated REST exception (ADMIN/OWNER; `ProducerAccountSyncDAO.search`; full-table scan, acceptable at current volume). Returns only active `ACCOUNT_BACKED` producers not already linked/chosen by the caller org.
- `GET /v1/admin/organizations/{id}/export` + `POST /v1/admin/organizations/{id}/import` (`OrganizationBackupRoute` → `ExportService` / `ImportService` in `service:sync`; wired via `getOrNull` so manual-module route tests stay green). Native-JSON backup / migration of one org. **Export** reuses `DataService.snapshotScope(auth, organization:{id})` + `ProductTypeSyncDAO` for the linked producers' catalogs, returning a versioned `OrganizationExport` (`persistence:wire`). **Import** is a *trusted restore*: entities are written directly through the sync DAOs (bypassing the interactive `EntityTypeService` guards — role exclusivity, ACCOUNT_BACKED creation, coordinator/contract/capacity checks) with a fresh `Change` per entity on `organization:{id}` (ProductTypes on `producer-account:{id}`). Ids are **preserved**; only the source `organizationId` is rewritten to the target. Target must be **empty** (else `ImportOutcome.Conflict` → `409`); unknown version → `400`; bad role/org → `403`. Members import carries PII but no auth `sub` (re-invite to activate). Auth in both services: OWNER any org, else ADMIN of that org.

All public paths are whitelisted in `AuthenticationService.isUnauthenticatedPath`. CORS allows GET/POST/OPTIONS.

## DynamoDB single-table key schema

One table (`DYNAMO_TABLE`, default `data`), `pk`/`sk` Strings, three sparse GSIs: `by_cursor` (PK=`change_pk`, SK=`cursor`, ALL — Change items only), `by_organization_name` / `by_admin_email` (KEYS_ONLY — OrganizationRequest only).

| Entity | pk | sk |
|---|---|---|
| ProductType | `PT#${producerAccountId}` | productTypeId |
| Change | `CHANGE#${entityType}#${scopeId}` | entityId |
| Organization | `ORGANIZATION` | orgId |
| ProducerAccount | `PA#${organizationId}` (denormalised per org link) | producerAccountId |
| Member | `MEMBER#${organizationId}` | memberId |
| Contract | `CONTRACT#${organizationId}` | contractId |
| DeliveryTemplate | `DLVTMPL#${organizationId}` | deliveryTemplateId |
| Server | `SERVER` | serverId |
| OrganizationRequest | `ORGREQ` | requestId |
| MemberJoinRequest | `MJREQ#${organizationId}` | requestId |
| Owner / OwnerInvitation | `OWNER` / `OWNERINV` | id |
| BasketExchange | `BSKEX#${organizationId}` | basketExchangeId |
| Notification / DeviceToken | `NOTIF#${recipientScope}` / `DEVTOK#${recipientScope}` | id |
| AttendanceEmailRequest | `ATTENDREQ#${organizationId}` | requestId |
| ErrorReport | `ERRRPT` | errorReportId |
| ActivationToken | `ACTIVATION_TOKEN` | tokenId |

Aggregates embed their lists as JSON string attributes (e.g. Organization `producers`/`products`/`deliveries`/`item_types`, BasketExchange `requests_json`, Contract `members_json`/`product_prices_json`). Denormalised entities (ProducerAccount, Member) update every row sharing the sk in one `TransactWriteItems`. Postgres mirrors everything with Flyway-migrated tables and per-transaction equivalents.

## Email pipeline

Transactional emails are rendered from shared pure French templates (`EmailTemplates` in `service:email` → `EmailContent(subject, body)`), so both deployments emit identical copy. **Subject branding is two-tiered:** AMAP-scoped emails are prefixed `[Org name] …` at the **template/service** layer via `amapEmailSubject(organizationName, subject)` — the org name is resolved in the domain service (via `OrganizationSyncDAO`) and threaded through the email port to the template (member invitation/resend, member join request submitted/rejected, basket-exchange request received/accepted/rejected) and, for notification emails, carried on `NotificationContact.organizationName` and applied in `EmailNotificationChannelSender` (slot cancelled/rescheduled, basket exchange). The **deployment gateway** then prefixes `[AmapEnLigne]` (and appends an `AmapEnLigne: <instanceUrl>` body footer) **only when the subject is not already `[…]`-prefixed** — via the shared `EmailMessage.withInstanceBranding(instanceUrl)` helper (`service:email-delivery`, applied in `JvmEmailGateway.deliver` / `LambdaEmailGateway.deliver`; the SMTP/SES transports stay dumb) — so instance-level emails get `[AmapEnLigne]` while AMAP emails keep their single `[Org name]` prefix (no double-branding). Delivery is **best-effort post-commit** (failure logged, never rolls back the sync mutation):

The port adapters themselves are deployment-agnostic and live in `service:email-delivery`; each deployment supplies only the concrete `EmailGateway` implementation (`@Single(binds = [EmailGateway::class])`) whose `deliver` carries the transport + branding:

- `deploy:lambda` → `LambdaEmailGateway.deliver` publishes `EmailMessage` on SNS (`ACTIVATION_EMAIL_SNS_TOPIC_ARN`); `ActivationEmailLambda` consumes and sends via SES v2.
- `deploy:jvm` → `JvmEmailGateway.deliver` over SMTP (`EmailSender`).

All email ports are real on both deployments (invitations, activations, rejections, account lifecycle, basket exchange, attendance sheets, EMAIL notification channel). Fan-out ports resolve recipients from DAOs (org admins via `MemberSyncDAO`, owner broadcast — PII-free — via `OwnerSyncDAO`). Push: `SnsPushNotificationChannelSender` on Lambda (`SNS_PLATFORM_APP_ARN_ANDROID`/`_IOS`), `FcmPushNotificationChannelSender` on JVM (`FCM_CREDENTIALS_FILE` / `GOOGLE_APPLICATION_CREDENTIALS`, self-disables when unset).

## Security notes

### JWT token staleness (accepted limitation)

Authorization roles are resolved exclusively from the JWT claims (`app_metadata.roles` on GoTrue, `cognito:groups` on Cognito). They are **never** cross-checked against the persisted `Member.roles` in the database. A token already emitted therefore retains its privileges until it expires, even if the operator revokes a role in the database.

Consequence: keep access token TTL short (recommendation: ≤ 15 minutes). Refresh tokens are unaffected — they only obtain a new access token and go through the auth provider's own revocation logic.

### Role enforcement at route and service layers

- `SyncRoute` rejects callers with no roles at all (`roles.isEmpty()`) with HTTP 403 before touching `DataService`.
- `SyncRoute` rejects batches exceeding `MAX_MUTATIONS_PER_SYNC` (500) with HTTP 400 before any persistence.
- Each `EntityTypeService` guards its own mutations; `EntityTypeService.requireAnyRole` is the shared helper — every service that restricts writes to a specific set of roles must use it so the check cannot be accidentally omitted.
- `OrganizationService.applyUpsert` is deny-by-default: only OWNER/ADMIN/COORDINATOR (privileged) or VOLUNTEER callers are accepted; any other role combination returns `FORBIDDEN` before any DAO call.

### email_verified (deliberate non-enforcement)

`email_verified` is extracted from the JWT and stored in `AuthenticatedInfo.emailVerified` but is **not** enforced as a gate on `POST /v1/sync`. Both GoTrue and Cognito require email verification before issuing tokens with `app_metadata.roles`, so any caller reaching the sync endpoint with valid roles already passed the provider's own verification step. Enforcing `email_verified` at the backend layer would add no security but would risk breaking callers during provider configuration changes. This is a deliberate decision; revisit if the provider configuration changes to issue tokens without verification.

## Adding a synced entity (recipe)

1. Extend `EntityType` (`persistence:model`) + add an `EntityPayload` subclass wrapping the entity (`persistence:wire`).
2. Add the domain type (`persistence:model`) and the `*SyncDAO` interface (`persistence:dao`) — `put(entity, change)` must be atomic.
3. Implement the DAO in **both** `persistence:dynamo` and `persistence:postgres` (Flyway migration), and wire the shared contract test from `persistence:dao` testFixtures in both modules.
4. Add an `EntityTypeService` subclass in a dedicated `service:<name>` module (`api(project(":service:core"))`, own `@Module(includes = [CoreModule::class]) @ComponentScan`; declares its scope + snapshot), then register the module in `settings.gradle.kts`, `service:sync`'s `SyncModule` `includes`, and `service:sync`'s `build.gradle.kts` `api` deps so Koin discovers it. (Reuse the `service:core` kernel for `RoleService`, ports, and the notification publisher.)
5. Extend the front contract (see `front/AI_CONTEXT.md` recipe) and the wire-format tests on both sides.

Notes: `MutationOp.Upsert` carries the entity id **inside** the payload (server detects `tmp_*` there); `Change.payload` is null for delete tombstones; `persistence:wire` deliberately depends on `persistence:model`.
