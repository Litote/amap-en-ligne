# AGENTS.md — amap-en-ligne

> **Purpose**: Instructions for AI agents working on this codebase.
> For installation, configuration, and usage, see [`README.md`](README.md).
> For contributing guidelines and project architecture, see (MANDATORY!) [`CONTRIBUTING.md`](CONTRIBUTING.md).
> For a project analysis, see (MANDATORY!) [`AI_CONTEXT.md`](AI_CONTEXT.md).

---

## Critical Rules

### NEVER Do

| Category         | Forbidden Actions                                                                |
|------------------|----------------------------------------------------------------------------------|
| **Dependencies** | Add/upgrade dependencies without explicit request, change version catalogs       |
| **Security**     | Log secrets/API keys, expose environment variables, commit credentials           |
| **Scope**        | Mass refactors, rename symbols unnecessarily, formatting-only changes            |
| **Commit**       | NEVER commit changes if you are not in a Pull Request Context                    |

### ALWAYS Do

| Category                   | Required Actions                                                                                          |
|----------------------------|-----------------------------------------------------------------------------------------------------------|
| **Testing**                | When you try to fix a bug, start by adding the test and THEN fix the bug. Add tests for all logic changes |
| **E2E testing**            | When adding a user-facing feature that involves auth, sync, or a cross-component flow: add a cross-component E2E test. Kotlin side in `acceptance/e2e/src/test/kotlin/e2e/` (extends `E2eTestSupport`), Flutter side in `front/test/acceptance/cross_component/` (tagged `cross-component`). Use the `acceptance-tests` skill for guidance. |
| **Imports**                | Use single imports only                                                                                   |
| **Language**               | Write all code, comments, and documentation in English                                                    |
| **Visibility**             | Prefer private by default — use `_prefix` convention in Dart                                              |
| **Immutability**           | Prefer `final` over mutable fields, use immutable data structures (Freezed in Dart)                       |
| **Document**               | User-facing changes → `README.md`; contributor/architecture changes → `CONTRIBUTING.md`; agent-relevant changes → `AI_CONTEXT.md` + `AGENTS.md` |
| **Keep AI doc up-to-date** | Update `AI_CONTEXT.md` when adding/removing domain types, changing public API, or making architectural decisions. Update `AGENTS.md` when rules or workflows change. |

---

## Definition of Done

A change is complete when:
-
- [ ] Only relevant files are modified
- [ ] Type safety is preserved
- [ ] Architecture boundaries are respected
- [ ] Tests are added for new logic
- [ ] `./gradlew format` passes in root directory
- [ ] `./gradlew check` passes (compiles without warnings, all tests pass) in root directory — note `check` is unit-only; back acceptance scenarios run via `./gradlew allAcceptanceTests`, not `check`
- [ ] `./gradlew allAcceptanceTests` passes (back acceptance + front acceptance + cross-component E2E) — the dedicated CI `acceptance` job runs this and its coverage is folded into SonarCloud
- [ ] IDE diagnostics (Problems panel) report zero errors
- [ ] SonarCloud quality gate passes (coverage ≥ 80%, 0 hotspots to review, 0 bugs, 0 vulnerabilities) — run `./gradlew allSonar` from the repo root
- [ ] If any widget, theme, text, layout, or state rendering changed: golden screenshots regenerated locally on macOS (`flutter test test/golden/ --update-goldens --tags golden` in `front/`) and the updated `.png` files committed
- [ ] If a new user-facing feature involves auth, sync, or a cross-component flow: a cross-component E2E test added in `acceptance/e2e/` (Kotlin) + `front/test/acceptance/cross_component/` (Flutter) and verified via `./gradlew crossComponentTest`

---

 ## Sub-Agent Structure
 
 Each component has a dedicated agent with a strict scope boundary. An orchestrator coordinates cross-component work without writing component code directly.

Copilot custom agent profiles live in `.github/agents/*.agent.md`; Claude mirrors live in `.claude/agents/*.md`. Keep names, scope boundaries, and entry-context rules aligned across both locations.

### orchestrator
- **Scope:** root files only (`README.md`, `AI_CONTEXT.md`, `AGENTS.md`, `CONTRIBUTING.md`)
- **Role:** decompose cross-component tasks, delegate to sub-agents, verify contracts between components
- **Must not:** write code inside `front/`, `agent/`, or `infra/`

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

### documentation-agent
- **Scope:** `documentation/` exclusively
- **Entry context:** [`documentation/AGENT.md`](documentation/AGENT.md)
- **Stack:** Markdown (French for feature/UI specs, English for architecture docs)
- **Role:** write and maintain functional specifications, feature descriptions, UI specs, and architecture decision records
- **Must not touch:** `back/`, `front/`, `infra/`, or any root file
- **Must not:** make implementation decisions — document observable behaviour only; flag implementation/doc mismatches to the orchestrator

### Cross-component tasks
When a task spans multiple components (e.g. "add an endpoint and update the front"):
1. **orchestrator** reads `AI_CONTEXT.md` to understand the current contract
2. Delegates each component change to the relevant sub-agent independently
3. Verifies that the updated contract is reflected in `AI_CONTEXT.md` before closing the task

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
