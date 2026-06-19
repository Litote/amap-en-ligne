# Contributing

Component-specific guides:

| Component                         | Guide |
|-----------------------------------|-------|
| `front/` — Flutter                | [`front/CONTRIBUTING.md`](front/CONTRIBUTING.md) |
| `back/` — Kotlin / AWS Serverless | [`back/CONTRIBUTING.md`](back/CONTRIBUTING.md) |
| `infra/` — Terraform              | _(to be created)_ |

---

## Commit signing

All commits merged into `main` **must be signed**. The repository enforces this via branch protection rules.

See [Signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)

---

## Conventional Commits

All PR titles **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Branch naming

```
<type>/<short-kebab-description>

# Examples:
feat/call-disambiguation-flow
fix/stt-locale-fallback
chore/bump-flutter-version
```

| Type | When to use |
|------|-------------|
| `feat:` | New user-facing feature |
| `fix:` | Bug fix |
| `chore:`, `docs:`, `test:`, `refactor:`, `ci:` | Internal changes |

## Version catalog naming

`gradle/libs.versions.toml` is the single source of truth for backend dependencies. All aliases (versions, libraries, plugins, bundles) MUST use **kebab-case** — lowercase words separated by dashes. No camelCase, no underscores.

Gradle maps each `-` in a TOML alias to a `.` in the Kotlin DSL accessor:

| TOML alias                | Kotlin DSL accessor                      |
|---------------------------|------------------------------------------|
| `koin-core`               | `libs.koin.core`                         |
| `aws-dynamodb-mapper`     | `libs.aws.dynamodb.mapper`               |
| `version-catalog-update`  | `libs.plugins.version.catalog.update`    |

When using the `lib("alias")` / `plugin("alias")` helpers from convention plugins (see `convention/src/main/kotlin/Catalog.kt`), pass the kebab-case alias verbatim — e.g. `lib("koin-core")`, `plugin("ktlint")`.

Keep the catalog tidy: remove entries that are no longer referenced by any `build.gradle.kts`.

## Acceptance tests

Documented sync stories live under [`acceptance/scenarios/`](acceptance/scenarios/) and are described in [`acceptance/README.md`](acceptance/README.md).

- `./gradlew acceptanceTest` runs the documented server + Flutter acceptance suites from the repository root
- `./gradlew frontAcceptanceTest` runs the Flutter acceptance suite only
- `cd back && ./gradlew acceptanceTest` runs the server acceptance runner only
- `./gradlew crossComponentTest` runs full end-to-end tests: Flutter cross-component Dart tests + Kotlin E2E suites (web + mobile). Requires Docker + `flutter` in PATH. Mobile tests automatically start an Android emulator (see [`acceptance/README.md`](acceptance/README.md) for setup).

When you change the offline-first sync behavior, update both:

1. the documented scenario catalog when the story itself changes
2. the corresponding executable acceptance test layer (server, Flutter, or both)

Current contract reminder:

- sync cursors are keyed by **scope** (`producer-account:*`, `organization:*`, `instance-owner`), not by `EntityType`
- the server returns authoritative `authorized_scopes`
- each scope result is either a bootstrap dump or an incremental diff

## CI / GitHub Actions

### Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `back-ci.yml` | push/PR on `back/**`, `acceptance/**` | `./gradlew check` (Java 25) + JaCoCo coverage + SonarCloud (if `SONAR_TOKEN` set) |
| `front-ci.yml` | push/PR on `front/**` | Flutter analyze + unit/widget tests (Ubuntu) · Android APK build · Web WASM build · iOS build + golden tests (macOS) |
| `front-update-goldens.yml` | Manual only | Regenerates golden screenshots on macOS, opens a PR with verified commit |
| `e2e.yml` | push/PR on `back/**`, `front/**`, `acceptance/**` | Cross-component API tests + Playwright web UI tests (Testcontainers + Flutter + headless Chromium). Android mobile tests are skipped in CI — run locally. |
| `deploy-lambda.yml` | push/PR on `back/**`, `infra/**` | PR: GraalVM native build + `terraform plan`. Push to `main`: native build + `terraform apply` + `aws lambda update-function-code`. |
| `docs.yml` | push on `documentation/guide/fr/**`, `site/**` | Builds and publishes the MkDocs help site to GitHub Pages |
| `zizmor.yml` | push/PR on `main` | Security scan of all workflow files |

Dependabot runs every Monday and opens PRs for GitHub Actions, Gradle (`/back`), and pub (`/front`) dependency updates.

### Required secrets and variables

Configure these in the repository settings before the relevant workflows will pass.

**Secrets:**

| Name | Used by | Purpose |
|------|---------|---------|
| `GRADLE_ENCRYPTION_KEY` | `back-ci`, `e2e`, `deploy-lambda` | Encrypts the Gradle remote build cache |
| `SONAR_TOKEN` | `back-ci` | SonarCloud analysis (optional — steps are skipped when absent) |
| `GH_PAT` | `front-update-goldens` | PAT with `workflow:write` — triggers `front-ci.yml` on the golden PR branch (the built-in `GITHUB_TOKEN` cannot trigger other workflow runs) |
| `AWS_ROLE_ARN` | `deploy-lambda` | IAM role assumed via OIDC for Terraform + Lambda deploy |
| `TF_VAR_COGNITO_CLIENT_ID` | `deploy-lambda` | Terraform variable for the Cognito client id |

**Variables** (non-secret, set in repository vars):

| Name | Used by | Example |
|------|---------|---------|
| `AWS_REGION` | `deploy-lambda` | `eu-west-3` |
| `AWS_LAMBDA_FUNCTION_NAME` | `deploy-lambda` | `amap-en-ligne-api` |

### Notes

**GraalVM native build** — `deploy-lambda` compiles a GraalVM CE 25 native image. This takes up to 60 minutes on a cold runner; Gradle cache warm-up reduces subsequent runs significantly.

**E2E Android tests** — `CrossComponentUiAuthTest` and `CrossComponentUiPasswordResetTest` require an Android emulator. They are skipped in CI (`E2E_SKIP_IF_NO_ANDROID_DEVICE=true`). Run them locally:

```bash
flutter emulators --launch <avd-id>
./gradlew crossComponentTest
```

**AWS OIDC setup** — the deploy workflow uses GitHub's OIDC provider instead of long-lived AWS credentials. Configure the trust policy on the IAM role to allow `token.actions.githubusercontent.com` for this repository.

**SonarCloud** — the `sonar` Gradle task requires the `org.sonarqube` plugin to be applied in `back/build.gradle.kts`. Until then the step is silently skipped (guarded by `SONAR_TOKEN != ''`). See [SonarCloud (local)](#sonarcloud-local) for the local setup.

---

## Federated instance direction

The project target is **federated instances**, not a single centrally configured backend fleet. Keep these rules in mind when changing auth/bootstrap/config flows:

- Do not hardwire the product around a permanent in-binary list of servers.
- Prefer **per-instance discovery** over a central registry. The target shape is a public discovery document served by each instance (for example `/.well-known/amap-en-ligne.json`) containing non-secret bootstrap settings.
- Treat the selected server/instance as part of the user's effective identity and session scope.
- A central directory can help users find instances, but it must stay optional; the instance's own discovery document is the source of truth.
- When evolving the front bootstrap flow, optimize for:
  1. cached last-known-good instance config
  2. explicit recovery when an instance disappears or changes auth provider
  3. compatibility checks between client protocol version and instance capabilities

Until this is implemented, the current hardcoded preset list is only a temporary bootstrap strategy.

## Adding or changing a business entity

Business entities are cross-component work in this repository. Even a "small" entity change usually touches the sync contract, both back persistence implementations, the front local cache, and test fixtures. Use the checklist below as the root workflow, then follow the component-specific guides for the file-level details.

### 1. Decide the change shape

Classify the change first:

- **New synced entity** — a new `EntityType` and payload flowing through `POST /v1/sync`
- **Entity schema change** — add/remove/rename a field, change nullability, enum values, or validation rules
- **Behavior-only change** — same wire shape, but different business rules, authorization, sync semantics, or UI rendering

If the change affects the wire contract, treat it as a coordinated back + front move from the start.

### 2. Update the shared contract

1. Define or update the entity's wire shape (`EntityType`, payload discriminator, snake_case field names, null handling, enum casing).
2. Re-check the cross-component invariants in [`AI_CONTEXT.md`](AI_CONTEXT.md), especially:
   - `tmp_*` creation flow
   - cursor semantics
   - tenant scoping via `producerAccountId`
3. Update the root architecture docs when the public contract or the architectural recipe changes:
   - [`AI_CONTEXT.md`](AI_CONTEXT.md)
   - this file if the workflow itself changes

### 3. Update the backend

At minimum, review all of these surfaces in `back/`:

1. **Domain / contract**
   - `persistence:model`
   - `persistence:wire` (`EntityType`, payloads, sync request/response types if needed)
2. **Service layer**
   - DAO interface in `persistence:dao`
   - `EntityTypeService` implementation in `service:data`
   - authorization / tenant checks if the entity introduces new rules
3. **Persistence implementations**
   - `persistence:dynamo`
   - `persistence:postgres`
   - make sure both keep the same semantics
4. **Deployments**
   - ensure both `deploy:jvm` and `deploy:lambda` still compose correctly if new modules/config are involved

### 4. Update the Flutter app

At minimum, review all of these surfaces in `front/`:

1. **Domain**
   - entity model
   - `EntityType`
   - `EntityPayload`
2. **Local persistence**
   - drift table/schema
   - CRUD helpers and snapshot eviction logic
3. **Sync integration**
   - add/update the entity's `EntitySyncHandler`
   - verify optimistic write / `tmp_*` remap behavior if applicable
4. **Feature layer**
   - repository
   - screens/routes/BLoCs if the entity is user-visible

### 5. Update tests

Cover the change at the right levels:

1. **Contract / wire**
   - front wire-format tests
   - back sync/integration tests
2. **Persistence**
   - Postgres DAO tests
   - Dynamo DAO tests
   - front drift tests
3. **Sync behavior**
   - bootstrap snapshot
   - incremental changes
   - mutation outcomes (`APPLIED` / `REJECTED`)
   - `tmp_*` id remap when relevant
4. **Acceptance**
   - update documented scenarios in `acceptance/scenarios/` if the story changes
   - update the corresponding executable server and/or Flutter acceptance tests

### 6. Final documentation pass

Before closing the change, update the docs that became stale:

- **Root architecture / contract** → [`AI_CONTEXT.md`](AI_CONTEXT.md)
- **Contributor workflow** → [`CONTRIBUTING.md`](CONTRIBUTING.md)
- **Back details** → [`back/AI_CONTEXT.md`](back/AI_CONTEXT.md) and/or [`back/CONTRIBUTING.md`](back/CONTRIBUTING.md)
- **Front details** → [`front/AI_CONTEXT.md`](front/AI_CONTEXT.md) and/or [`front/CONTRIBUTING.md`](front/CONTRIBUTING.md)
- **User-facing setup/usage** → [`README.md`](README.md) when relevant

When in doubt, prefer documenting the entity recipe once at the root and linking to component-specific details, rather than letting front/back workflows drift apart silently.

## SonarCloud (local)

Run SonarCloud analysis locally **after every change** before opening a PR. This is the authoritative quality gate (coverage ≥ 80%, 0 bugs, 0 vulnerabilities, 0 hotspots).

**One-time setup** — add your token to `~/.gradle/gradle.properties`:

```properties
systemProp.sonar.token=<your-sonarcloud-token>
```

Get your token at [sonarcloud.io](https://sonarcloud.io) → My Account → Security → Generate Token.

**Run analysis** (from the repo root, with `flutter` on your `PATH`):

```bash
./gradlew allSonar
```

This generates coverage for **both** components — back Kotlin (`jacocoAggregatedReport`) and front
Dart/Flutter (`frontTest --coverage` → `front/coverage/lcov.info`) — uploads a single combined analysis to
the `Litote_amap-en-ligne` SonarCloud project, then enforces the quality gate (`sonarCheck` fails the build
when the gate ≠ OK or any issue / unreviewed hotspot remains).
