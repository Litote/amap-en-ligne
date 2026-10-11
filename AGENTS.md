# AGENTS.md — amap-en-ligne

> **Purpose**: Instructions for AI agents working on this codebase.
> For installation, configuration, and usage, see [`README.md`](README.md).
> For contributing guidelines and project architecture, see [`CONTRIBUTING.md`](CONTRIBUTING.md) — read the relevant section before changing build, CI or architecture.
> For a project analysis, see [`AI_CONTEXT.md`](AI_CONTEXT.md).

---

## Critical Rules

### NEVER Do

| Category         | Forbidden Actions                                                                |
|------------------|----------------------------------------------------------------------------------|
| **Dependencies** | Add/upgrade dependencies without explicit request, change version catalogs       |
| **Security**     | Log secrets/API keys, expose environment variables, commit credentials           |
| **Scope**        | Mass refactors, rename symbols unnecessarily, formatting-only changes            |
| **Commit**       | Commit unless the user explicitly asks for a commit or a PR                      |

### ALWAYS Do

| Category                   | Required Actions                                                                                          |
|----------------------------|-----------------------------------------------------------------------------------------------------------|
| **Dependency proposal**    | When adding or exposing a library (e.g. declaring a transitive runtime-only artifact for compilation) is the cleanest solution, **stop and ask the user explicitly** — name the library, the exact version (aligned on the existing catalog), and why — instead of silently working around the missing dependency with a hack. Implement it only after approval. |
| **Testing**                | When you try to fix a bug, start by adding the test and THEN fix the bug. Add tests for all logic changes |
| **E2E testing**            | When adding a user-facing feature that involves auth, sync, or a cross-component flow: add a cross-component E2E test. Kotlin side in `acceptance/e2e/src/test/kotlin/e2e/` (extends `E2eTestSupport`), Flutter side in `front/test/acceptance/cross_component/` (tagged `cross-component`). See `acceptance/AGENTS.md` for the Kotlin side and the `front/.claude/skills/acceptance-tests` skill for the Flutter side. |
| **Validation on both sides** | Every business/input rule enforced by a front form (required field, format, length, range, cross-field ordering such as start < end, uniqueness…) MUST also be enforced by the back (route or `EntityTypeService`, rejecting with `400 INVALID_PAYLOAD` / `MutationErrorCode.INVALID_PAYLOAD`), and every back rule a user can hit MUST be checked by the front before submitting (with a French message). The front check is UX; the back check is the source of truth — never rely on one side only. When adding or changing a rule, add a test on **both** sides. |
| **SonarCloud**             | After **every** code change (back, front, tests, build scripts), run `./gradlew allSonar` from the repo root before reporting the work as done, and fix every issue it reports — `:back:sonarCheck` fails on any unresolved issue (0 issues overall, stricter than the quality gate). Query the issues with the `sonarqube` MCP server (project `Litote_amap-en-ligne`). Never hand this check back to the user. |
| **Imports**                | Use single imports only                                                                                   |
| **Language**               | Write all code, comments, and documentation in English                                                    |
| **Visibility**             | Prefer private by default — use `_prefix` convention in Dart                                              |
| **Immutability**           | Prefer `final` over mutable fields, use immutable data structures (Freezed in Dart)                       |
| **Document**               | User-facing changes → `README.md`; contributor/architecture changes → `CONTRIBUTING.md`; agent-relevant changes → `AI_CONTEXT.md` + `AGENTS.md` |
| **Keep AI doc up-to-date** | Update `AI_CONTEXT.md` when adding/removing domain types, changing public API, or making architectural decisions. Update `AGENTS.md` when rules or workflows change. |

---

## Definition of Done

A change is complete when:

- [ ] Only relevant files are modified
- [ ] Type safety is preserved
- [ ] Architecture boundaries are respected
- [ ] Tests are added for new logic
- [ ] `./gradlew format` passes in root directory
- [ ] `./gradlew check` passes (compiles without warnings, all tests pass) in root directory — note `check` is unit-only; back acceptance scenarios run via `./gradlew allAcceptanceTests`, not `check`
- [ ] `./gradlew allAcceptanceTests` passes (back acceptance + front acceptance + cross-component E2E) — the dedicated CI `acceptance` job runs this and its coverage is folded into SonarCloud
- [ ] IDE diagnostics (Problems panel) report zero errors
- [ ] `./gradlew allSonar` passes from the repo root, run by the agent itself after every code change: SonarCloud quality gate (coverage ≥ 80%, 0 hotspots to review, 0 bugs, 0 vulnerabilities) **and** `:back:sonarCheck` (0 unresolved issues overall)
- [ ] If a new user-facing feature involves auth, sync, or a cross-component flow: a cross-component E2E test added in `acceptance/e2e/` (Kotlin) + `front/test/acceptance/cross_component/` (Flutter) and verified via `./gradlew crossComponentTest`

---

## Sub-Agent Structure

Each component has a dedicated sub-agent with a strict scope boundary. Sub-agents are optional: use them when the user asks for one; otherwise the main session works across components directly, following each component's entry context.

Copilot custom agent profiles live in `.github/agents/*.agent.md`; Claude mirrors live in `.claude/agents/*.md`. Keep names, scope boundaries, and entry-context rules aligned across both locations.

### flutter-agent
- **Scope:** `front/` exclusively
- **Entry context:** [`front/AGENTS.md`](front/AGENTS.md)
- **Stack:** Flutter / Dart
- **Must not touch:** `back/`, `infra/`

### backend-agent
- **Scope:** `back/` exclusively
- **Entry context:** [`back/AGENTS.md`](back/AGENTS.md)
- **Stack:** Kotlin / AWS Serverless / Docker
- **Must not touch:** `front/`, `infra/`

### infra-agent
- **Scope:** `infra/` exclusively
- **Entry context:** [`infra/AGENT.md`](infra/AGENT.md)
- **Stack:** Terraform / AWS
- **Must not touch:** `front/`, `back/`
- **Extra caution:** always plan before apply, never destroy without explicit confirmation

### acceptance-tests
- **Scope:** `acceptance/`, plus `front/integration_test/` and back E2E support
- **Entry context:** [`acceptance/AGENTS.md`](acceptance/AGENTS.md)
- **Stack:** Kotlin (JUnit, Testcontainers, Playwright) / Dart
- **Must not touch:** `back/` or `front/` source code

### documentation-agent
- **Scope:** `documentation/` exclusively
- **Entry context:** [`documentation/AGENT.md`](documentation/AGENT.md)
- **Stack:** Markdown (French for feature/UI specs, English for architecture docs)
- **Role:** write and maintain functional specifications, feature descriptions, UI specs, and architecture decision records
- **Must not touch:** `back/`, `front/`, `infra/`, or any root file
- **Must not:** make implementation decisions — document observable behaviour only; flag implementation/doc mismatches to the user

### Cross-component tasks
When a task spans multiple components (e.g. "add an endpoint and update the front"), start from the current contract in `AI_CONTEXT.md`, and check that the updated contract is reflected there before closing the task.

---

## Agent Behavior Guidelines

**When generating code:**
- Be minimal — change only what's necessary
- Be conservative — preserve existing patterns
- Be explicit — no hidden side effects
- Preserve type safety and determinism

**When uncertain:**
- Prefer no change over speculative change
- Favor architectural integrity over feature completion
- Explain conflicts with requirements
