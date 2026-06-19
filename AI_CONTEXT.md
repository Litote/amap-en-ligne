# AI Context — amap-en-ligne

> System-wide context for AI agents. Keep up-to-date after significant changes.
> Component details: [`back/AI_CONTEXT.md`](back/AI_CONTEXT.md) · [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md).

---

## System overview

Producer-side management app for French AMAP / CSA networks. Offline-first: clients keep a local cache (drift/sqlite) and reconcile with the server through a single sync endpoint.

Monorepo with three independent components:

| Path | Stack | Role |
|------|-------|------|
| `back/` | Kotlin / Gradle multi-module / Ktor / GraalVM Lambda | API server — single authenticated endpoint `POST /v1/sync` |
| `front/` | Flutter / Dart / drift / dio / BLoC | Offline-first mobile + web client |
| `infra/` | Terraform / AWS | DynamoDB, Lambda + API Gateway, Cognito, SNS push |

The root Gradle build orchestrates back and front (`gradlew check`, `acceptanceTest`, `frontTest`, `crossComponentTest`, `frontBuildAndroid`, `frontBuildWeb`, …). **Tool boundary**: Gradle owns the build (`back`/`front`/`convention` composite build); `infra/Makefile` owns deployment orchestration (Terraform + a Docker-wrapped GraalVM cross-compile that calls Gradle + AWS CLI) and is **intentionally not** part of the Gradle composite build. CI bypasses the Makefile and calls `gradlew`/`terraform`/`aws` directly. Agent profiles: `.github/agents/*.agent.md` (Copilot) mirrored in `.claude/agents/*.md` (Claude).

The wire contract between front and back is **the only coupling point** — both sides have parallel domain types kept in sync by hand, pinned by tests on both sides (`front/test/domain/sync_wire_format_test.dart`, back `DataServiceTest` + `JvmDeploymentIntegrationTest`). Documented sync stories live in `acceptance/scenarios/*.json`.

---

## API surface principle

> **Authenticated actions go through `POST /v1/sync`. Only public bootstrap endpoints live outside sync.**

Public REST endpoints (unauthenticated):

| Route | Purpose |
|-------|---------|
| `GET /.well-known/amap-en-ligne.json` | Instance discovery document |
| `GET /.well-known/apple-app-site-association`, `assetlinks.json` | iOS/Android app links |
| `GET /v1/public/organizations` | Browse visible AMAPs before login |
| `GET /v1/public/servers` | List federated peer servers |
| `POST /v1/public/member-join-requests` | Request to join an AMAP |
| `POST /v1/organization-requests` | Request to create an AMAP |
| `POST /v1/producer-requests` | Request to create a producer account |
| `POST /v1/activate` | Activate an account from an emailed token |

Authenticated REST exceptions (outside sync):

| Route | Purpose |
|-------|---------|
| `GET /v1/admin/producer-accounts/search?q=` | Discovery query for producers not yet visible in the caller's scope feed; returns only active `ACCOUNT_BACKED` producers valid as enrollment/link targets. |
| `GET /v1/admin/organizations/{id}/export` | ADMIN (own org) / OWNER (any). Dumps a versioned native-JSON `OrganizationExport` (the `organization:{id}` snapshot + the linked producers' `ProductType` catalogs) for backup / instance migration. |
| `POST /v1/admin/organizations/{id}/import` | ADMIN (own org) / OWNER (any). Restores an `OrganizationExport` into the target org. Trusted restore: written directly through the sync DAOs (bypasses interactive business guards). Ids are preserved; only the source `organizationId` is rewritten to the target; the target org must be **empty** (else `409`). Imported `Member`s carry PII but no auth identity (`sub` is never on the wire) — they stay inert until (re)invited. See ADR / import-export invariant below. |

Auth endpoints (login, refresh, password reset) are served by GoTrue / Cognito directly.

---

## Sync protocol — `POST /v1/sync`

Bearer-authenticated, validated on both sides.

**Request** (`SyncRequest`): `cursors: Map<scopeKey, String?>` + `mutations: List<ClientMutation>` (`Upsert` / `Delete`).
- Scope keys: `producer-account:{id}`, `organization:{id}`, `instance-owner`, plus private notification feeds `member:{sub}` / `owner:{sub}`.
- Missing/null cursor ⇒ bootstrap for that scope; non-null cursor ⇒ full incremental diff strictly after it.

**Response** (`SyncResponse`): `authorized_scopes` + `results: Map<scopeKey, ScopeSyncResult>` + `mutations: List<MutationOutcome>`.
- `authorized_scopes` is authoritative — the client discovers/persists scopes from the server; a disappeared scope means dropping its local cache and scoped pending mutations.
- Each result is `BootstrapScopeResult(items, next_cursor)` or `IncrementalScopeResult(changes, next_cursor)`. The back may answer an incremental request with a bootstrap when the diff is too large.
- `MutationOutcome.serverEntityId` carries the real id allocated for a `tmp_*` upsert; `REJECTED` outcomes carry a `MutationErrorCode`.

**Wire format**:
- snake_case multi-word fields; sealed-class discriminator key `type` with PascalCase values (`"ProductType"`, `"Upsert"`); enum constants uppercase (`"APPLIED"`, `"FORBIDDEN"`).
- `null` nullable fields are **omitted** from JSON (back `explicitNulls = false` ↔ front `include_if_null: false`).

---

## Cross-component invariants

Preserve these together on both sides:

- **`tmp_` prefix is shared** — front marks optimistic creations with it; back detects it to allocate real ids. Changing it on either side breaks creation flows.
- **Cursors are opaque** — clients compare lexicographically, never parse. Cursors attach to scopes, not entity types.
- **Adding a synced entity is a coordinated move** — closed `EntityType` enums + exhaustive switches on both sides. Step-by-step recipes in each component's `AI_CONTEXT.md`.
- **Auth is split per deployment** — `deploy:jvm` → GoTrue (HS256, self-hosted Supabase Auth); `deploy:lambda` → Cognito (RS256 via JWKS). The front implements both providers behind one `AuthService` interface, selected at runtime from a server catalog. **Cognito sends the access token, never the idToken** (back rejects `token_use != "access"`).
- **`producerAccountId == sub` by invariant** on both providers — resolved from the JWT subject, never stored as an auth-provider attribute.
- **Authorization is JWT-only, no revocation (accepted limitation)** — roles come exclusively from the token (`app_metadata.roles` / `cognito:groups`), never cross-checked against persisted `Member.roles`. An already-issued access token keeps its privileges until expiry even after an operator revokes a role, so access-token TTL must stay short (≤ 15 min recommended). `email_verified` is **not** enforced at `POST /v1/sync` (the provider already gates role issuance on verification). Enforcement points: `SyncRoute` rejects empty-roles (403) and batches over `MAX_MUTATIONS_PER_SYNC` = 500 (400); `EntityTypeService.requireAnyRole` is the shared role guard; `OrganizationService` is deny-by-default. Details in `back/AI_CONTEXT.md` → Security notes.
- **Producer management modes** — `ProducerAccount.management_mode` (`ACCOUNT_BACKED` / `NO_ACCOUNT`) is authoritative and immutable after creation. `ProducerAccount.products` is the single source of truth; for `NO_ACCOUNT` producers the back derives `Organization.products` automatically. No-account creation uses `tmp_*` ids that the front remaps in `ProducerAccount` + `Organization.producers[]` (not `Organization.products[]`).
- **Coordinators** — `DeliveryContract.coordinators: List<Id<Member>>` (the singular `coordinator_id` is gone). The front authors the delivery↔contract links: the delivery form lets the coordinator check active season `Contract`s directly (label = contract name + producer name) and derives one `DeliveryContract` per checked contract (new links start `PENDING` with empty `coordinators`; existing links are preserved as-is while their contract stays checked). The "Produits présents" list is restricted to the products referenced by the checked contracts' `product_prices` (a contract without any price entry falls back to all of its producer's products). A `CONFIRMED` delivery with any contract having empty `coordinators` is rejected with `MISSING_COORDINATOR`; `PLANNED` and post-CONFIRMED states are not checked. See ADR-004.
- **Contract lifecycle** — `Contract` carries two new wire fields: `status` (`IN_PREPARATION` | `ACTIVE` | `ENDED`, default `IN_PREPARATION`) and `delivery_template_id` (nullable). **Effectively ended** = `status == ENDED || maxDeliveryDate < today` (back `isEffectivelyEnded`, front `isContractEffectivelyEnded` / `contractStatusView`). Guards: (i) adding new `Contract.members[]` / `Member.contracts[]` entries on an effectively ended contract → `CONTRACT_ENDED`; (ii) linking an effectively ended contract to a new delivery → `CONTRACT_ENDED`; (iii) a non-privileged caller (not OWNER/ADMIN/COORDINATOR) self-subscribing to an `IN_PREPARATION` contract → `FORBIDDEN`. Removals, status edits of existing entries, and edits of already-linked past deliveries stay allowed. The front hides `IN_PREPARATION` contracts from members (visible only to coordinators), hides deliveries whose linked contracts are all `IN_PREPARATION` from plain members on the planning (coordinators/admins see them flagged "🚧 Contrat inactif" without registration actions — `isDeliveryPendingContractActivation`), and surfaces late rejections via `ContractEndedListener`. Coordinator form: status dropdown (default `IN_PREPARATION`) + optional delivery template dropdown; after creation, a dialog offers to generate weekly deliveries. Back allocates a real id for `tmp_*` contract upserts (like `ProductType`); the batch remap in `DataService` propagates the real id to `OrganizationPayload.deliveries[].contracts[].contractId` in the same sync call. Front-side remap: `ContractSyncHandler.rewriteMutationReference` and `db.remapContractId` also rewrite `Organization.deliveries[].contracts[]` references. Weekly generation is remap-safe: the front defers the post-creation sync trigger until after the dialog (contract + deliveries upserts share one batch), and on confirm re-reads the org/contracts and re-resolves the saved contract (by id, then natural key — `resolveSavedContract`) before recomputing the plan, so links never carry a dead `tmp_*` id. Generated deliveries carry `basket_descriptions` derived from the contract's `product_prices` (fallback: the producer's catalog). The delivery form drops a dangling `tmp_*` contract link (no matching cached contract) on save instead of duplicating the re-identified contract.
- **Per-delivery basket composition** — a delivery's informative basket contents live in `Delivery.basket_descriptions: List<BasketDeliveryDescription{product_type_id, basket_size_name, items: List<DeliveryItem>}>` inside the `Organization` aggregate (no DAO/migration change). A `DeliveryItem` is intentionally **lean**: `item_type_id` (reference) + optional free-text `weight?` + a tiny `name` snapshot (default `""`, for historical accuracy/resilience). **The heavy SVG icon is NOT stored per item** — it lives once in a flat, deduplicated org-level catalog `Organization.item_types: List<ItemType{id, name, image_svg?}>`, resolved by `item_type_id` at display time. This avoids multiplicative duplication: with hundreds of deliveries the SVG would otherwise be copied per item and blow DynamoDB's 400 KB `Organization`-item limit (deliveries are embedded as one JSON attribute — `OrganizationSyncDynamoDAO`). The catalog reaches members because they sync `organization:{id}` but **not** `producer-account:{id}`, where the producer's source `ProductType.item_types` lives. **Images are SVG-only** (`image_svg` = inline SVG markup, rendered via `flutter_svg` `SvgPicture.string`; nulls omitted on the wire). Flow: producer edits the source catalog at `/product-types/:id/items` (entry on the product-type form); the coordinator composes a delivery at `/coordinator/deliveries/:deliveryId/description` (button on the delivery form, existing deliveries only — editor loads from cache); on save `DeliveryDescriptionBloc` **merges** the used components' `ItemType`s (by id, latest producer definition, existing entries preserved) into `Organization.item_types` in the same org `Upsert`. Members see it read-only on the planning `DeliveryCard` (`BasketCompositionSection`, collapsible, grouped by basket size, SVG resolved from `org.item_types`). Purely informative — no back-side validation beyond standard serialization.
- **Slot lifecycle** — `MemberSlot.slot_id` is nullable, server-allocated (backfilled on first privileged write; never generated by the client). Volunteers can only register on existing slots (`VolunteerMutationValidator` forbids slot creation), so the front materialises default slots on privileged writes: weekly generation and the coordinator delivery form attach an OPEN STANDARD slot (+ EARLY when the template or the delivery override defines one) to the first contract link of any slotless delivery (`defaultVolunteerSlots` in `front/lib/domain/model/delivery_slots.dart`). **Per-delivery time overrides** — `Delivery` carries optional `standard_end_time` / `volunteer_arrival_time` (`"HH:MM"`) and `early_slot` (reuses `EarlySlot`) overriding the slot times otherwise dictated by the linked `DeliveryTemplate`; resolution is delivery override → template → hard-coded default, applied uniformly by `defaultVolunteerSlots` (front) and `checkCapacity` (back, EARLY-slot cap), so an early slot may be defined directly on a template-less delivery. Nulls are omitted on the wire and the fields ride inside the `Organization` aggregate's `deliveries` JSON (no DAO/migration change). The member planning shows the `COMPLET` state only when slot capacity exists and is exhausted — a slotless delivery offers no registration action. `SlotStatus.CANCELLED` is terminal: privileged cancel cascades registrations server-side and publishes `SLOT_CANCELLED`; reopening is `FORBIDDEN`; deleting a slot with active registrations is `CONFLICT`; reschedule keeps registrations and publishes `SLOT_RESCHEDULED`.
- **Volunteer self-registration** — a VOLUNTEER-only caller may only add/remove their own `registrations` inside `Upsert(OrganizationPayload)`; anything else is `FORBIDDEN` (back `VolunteerMutationValidator`).
- **`BasketExchange` is a reciprocal-swap aggregate** on `organization:{id}` — requests are embedded in `requests`, never a separate entity. The offerer publishes the delivery they want to swap (D1); a requester answers with a **counter-delivery** they offer in return (`BasketExchangeRequest.proposed_delivery_id` / `proposed_contract_id`, nullable on the wire, **required at submission**). The offerer **validates** one request (OPEN→ACCEPTED, atomic PENDING→REJECTED fan-out on the others) or **refuses it individually** (`PENDING→REJECTED`, offer stays OPEN — now supported, offerer-only). For a `tmp_*` request, `serverEntityId` carries the **aggregate root's** id; the front reconciles by diffing `requests` after sync. `Delete` is always `FORBIDDEN` (cancel via `Upsert(status=CANCELLED)`). **Basket double-booking guard**: a `(member, delivery)` basket can be committed in at most one active exchange (`isBasketCommitted` back / `committedDeliveryIdsFor` front); violations are `UNIQUE_VIOLATION`. A basket is committed when it is offered (OPEN/ACCEPTED) **or** has changed hands through a settled (ACCEPTED) exchange — both deliveries of an accepted swap (offered D1 + accepted counter D2) are committed for **both** parties (each side gives one basket and **receives** the other), so a basket already exchanged or received cannot be re-offered or re-proposed (enforced on both the offer-creation and request-submission paths, front and back). Notifications carry concrete delivery dates + a `deep_link` (`/basket-exchange/{id}/requests` for the offerer, `/basket-exchange` for requesters). The front surfaces ongoing exchanges on the home dashboard (`BasketExchangeDashboardCard`) and offers an all-members overview table + CSV export at `/basket-exchange/overview`.
- **Notifications live on private per-recipient scopes** (`member:{sub}` / `owner:{sub}` / `producer-account:{id}`), keyed by the JWT `sub` — never on `organization:{id}` or `instance-owner`. Server-authoritative: the client only flips `read_at` or archives. Outbound email/push is a best-effort post-commit side-effect; push targets synced `DeviceToken`s on the same feeds (SNS Mobile Push on Lambda, FCM HTTP v1 on JVM; no SMS). See ADR-005.
- **Admin-customisable alert copy** — `Organization.notification_overrides: Map<NotificationCategory, NotificationCopyOverride{title?, body?}>` lets an org ADMIN override the title/body of each org-scoped alert from `/preferences`. Resolution happens at publish sites via `Map.resolveCopy(category, defaultTitle, defaultBody)` (back, `NotificationCopy.kt`): a non-blank override wins per-part, else the hardcoded dynamic default is kept (overrides are applied **verbatim**, no interpolation). Wired in `OrganizationService` (SLOT_*), `BasketExchangeService` (BASKET_EXCHANGE_*) and `PublicService` (MEMBER_JOIN_REQUEST_SUBMITTED). **Owner/instance categories** (`ORGANIZATION_REQUEST_SUBMITTED` / `PRODUCER_REQUEST_SUBMITTED`) have no owning org and stay on defaults — out of scope. The front edits them via an admin-only "Personnalisation des alertes" card (`AlertTemplatesBloc`, `kCustomisableAlertCategories`) saving an `Organization` upsert; the map rides inside the `Organization` aggregate (Dynamo JSON attr + Postgres `notification_overrides` jsonb).
- **Invitation email copy override** — `MemberInvitation.custom_email_subject` / `custom_email_body` (nullable, omitted when null) let an admin override the invitation email's subject / intro body. `EmailTemplates.memberInvitation` uses them when non-blank but **always appends the activation-link footer + signature** (the link is never droppable). `/members` exposes a bulk "Demander la connexion" action (`UserManagementEvent.resendAllPendingRequested`) that re-sends to every `PENDING_ACTIVATION` invitation, optionally with the overridden copy; the back's resend path (`MemberInvitationService.resendInvitation`) persists and forwards the custom fields.
- **Member PII is synced data** — `Member` carries nullable `first_name`/`last_name`/`email`/`phone` + `account_status` (`ACTIVE`/`SUSPENDED`; invitation states live on `MemberInvitation.status`). RGPD delete anonymises the row (PII + sub nulled, `SUSPENDED`) and writes an `AccountDeletionLog`; rows are kept for referential integrity.
- **Organization backup / migration** — `OrganizationExport` (`persistence:wire`) is the versioned native-JSON archive of one org: `format_version` + `exported_at` + `source_instance` + `organization_id` + `scopes.{organization, product_types}` (lists of `EntityPayload`, so the wire serializers stay the single source of truth). Export = `organization:{id}` snapshot + linked producers' `ProductType`s; import = trusted DAO restore, ids preserved, source `organizationId` rewritten to target, target must be empty. Front round-trips it as a downloaded/uploaded `.json` from an admin-only `/preferences` card.
- **Shared baskets (panier partagé)** — `Contract.shared_baskets: List<SharedBasket{shared_basket_id, member_ids (ordered, ≥2), anchor_delivery_id?}>` is an **overlay** marking that several members alternate on a single physical basket (each keeps their individual `ContractMember` subscription). A coordinator authors them on `/coordinator/member-contracts`. Validation (`ContractService.validateSharedBaskets`, `INVALID_SHARED_BASKET`): ≥2 members, all members are contract members, no member in two baskets of the same contract, all members share an identical subscription. **Alternation is computed client-side, not stored**: order the contract's deliveries by `(scheduledDate, deliveryId)`, `a` = index of `anchor_delivery_id` (0 if null/unknown), `p` = index of the delivery, picker = `member_ids[((p − a) mod n + n) mod n]` — implemented **identically** in `SharedBasketAlternation.kt` (`SharedBasket.pickerFor`) and `front/lib/domain/model/shared_basket_view.dart` (`sharedBasketPickerFor`), pinned by `acceptance/scenarios/contract-shared-basket-*.json`. `shared_basket_id` is a **nested** id: a `tmp_*` one is allocated server-side but **never** echoed via `serverEntityId` (reserved for the contract root) — the front recovers it by overwriting the cached contract from the authoritative `ContractPayload` on the next sync (BasketExchange nested-id convention). **Accepted limitation**: `DeliveryContract.basket_quantity` stays a manual coordinator input — a shared basket counts as one physical basket and nothing auto-derives the count. The member sees the alternation on `/contracts` (1 distribution sur N + their pickup dates) and on each planning `DeliveryCard` (whose turn it is that week). **Interaction with `BasketExchange`**: a shared basket on a given delivery belongs to exactly one family that week, so the exchange flow resolves the *effective holder* via the alternation — `Contract.holdsBasketOn` (back) / `memberHoldsBasketOn` (front), both in the alternation helper. The back rejects (`FORBIDDEN`) an offer or counter-delivery whose `(contract, delivery)` basket is not the caller's that week (`BasketExchangeService.rejectIfNotBasketHolder`); the front hides those weeks/contracts in the propose + submit-request dialogs (fed the org `contracts`). Non-shared contracts are unaffected (holder = always the member).
- **Known limitation (accepted)** — `Organization` *edits* emit only an `organization:{id}` `Change`; an OWNER picks them up on the next `instance-owner` bootstrap (the diff-size fallback forces one periodically). Creation does fan out to `instance-owner`.

---

## Federated instance discovery

Each instance exposes `GET /.well-known/amap-en-ligne.json` (name, `api_url`, `protocol_version`, `auth.kind` = `gotrue` | `cognito`). Wrong-server tokens (JWT `iss` mismatch) get `401 WRONG_SERVER` + `token_issuer` so the client can redirect.

The front's hardcoded preset list (`front/lib/data/server/server_presets.dart`) is a **temporary bootstrap**, not the target: the goal is instance discovery + cached per-instance config. True federation (inter-server trust, key verification) is not implemented.

---

## Deploy / backend matrix

| Component | Deployment | Persistence |
|-----------|------------|-------------|
| `back` | `deploy:jvm` (Ktor CIO) | `persistence:postgres` (self-hosted Supabase Postgres, direct JDBC) |
| `back` | `deploy:lambda` (GraalVM native) | `persistence:dynamo` (DynamoDB via Terraform) |
| `front` | Android / iOS / Web | drift on sqlite (local cache) |

---

## Tests

| Layer | Path | Pins |
|-------|------|------|
| Acceptance catalog | `acceptance/scenarios/*.json` | Documented sync stories |
| Back acceptance | `back/deploy/jvm/.../AcceptanceScenariosTest.kt` | Server-tagged stories over real HTTP |
| Back unit / DAO / deployment | `back/service/core`, `back/persistence/*`, `back/deploy/jvm` | Mutation outcomes, DAO contracts (Dynamo Local / Testcontainers), full HTTP flow |
| Front domain | `front/test/domain/sync_wire_format_test.dart` | Wire-format contract guard |
| Front data / acceptance / presentation | `front/test/**` | drift CRUD, sync orchestration, client stories, bloc transitions |
| Cross-component mobile | `acceptance/e2e/...CrossComponentUi*.kt` + `front/integration_test/` | Full UI flow on Android/iOS device |
| Cross-component web | `acceptance/e2e/...CrossComponentWebUi*.kt` | Full UI flow in headless Chromium (Playwright) |

### E2E gotchas

- **Android**: `E2eTestSupport.ensureAndroidEmulatorRunning()` auto-launches the first AVD (via `flutter emulators`) and skips the test (`assumeTrue`) when none is available.
- **Web build**: `buildFlutterWeb()` builds `--wasm` and patches `flutter_bootstrap.js` to load CanvasKit locally; `flutterServerConfigScript(...)` injects server config into localStorage before app start.
- **Flutter web inputs** use a single off-screen `<input>`; `fill()` does not work. Text fields: click → `waitForSelector` → `Control+A` → `keyboard().insertText(...)`. Password fields: click → `waitForSelector` → `Thread.sleep(500)` → `keyboard().type(...)` (Chrome blocks `insertText` on password inputs; the sleep avoids dropped leading chars).
- **OTP**: always use `ContainerSuite.getRecoveryToken(email)` (6-char numeric OTP). `extractOtpFromEmail()` returns the 56-char magic-link token, which GoTrue's `/verify` rejects with `403 otp_expired`.
