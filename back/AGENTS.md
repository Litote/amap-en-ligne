# AGENTS.md - amap-en-ligne - back

> **Purpose**: Instructions for AI agents working on this codebase.
> For installation, configuration, and usage, see [`README.md`](README.md).
> For contributing guidelines and project architecture, see (MANDATORY!) [`CONTRIBUTING.md`](CONTRIBUTING.md).
> For a project analysis, see (MANDATORY!) [`AI_CONTEXT.md`](AI_CONTEXT.md).
---

## Critical Rules

### NEVER Do

| Category         | Forbidden Actions                                                                |
|------------------|----------------------------------------------------------------------------------|
| **Code**         | Use `!!`, `println`, `runBlocking`, `GlobalScope`                                |
| **Architecture** | Move classes across modules, introduce circular dependencies, create new modules *(unless explicitly requested/approved)* |
| **Build**        | Remove the `group = "..."` line from any module's `build.gradle.kts` (see Build layout) |
| **Dependencies** | Add/upgrade dependencies without explicit request, change version catalogs       |
| **Security**     | Log secrets/API keys, expose environment variables, commit credentials           |
| **Scope**        | Mass refactors, rename symbols unnecessarily, formatting-only changes            |
| **Commit**       | Commit unless the user explicitly asks for a commit or a PR                      |

### ALWAYS Do

| Category                   | Required Actions                                                                                                                                                     |
|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Validation**             | Run `./gradlew formatKotlin && ./gradlew check` after every iteration                                                                                                |
| **Testing**                | When you try to fix a bug, start by adding the test and THEN fix the bug. Add tests for all logic changes                                                            |
| **Imports**                | Use single imports only                                                                                                                                              |
| **Language**               | Write all code, comments, and documentation in English                                                                                                               |
| **Visibility**             | Prefer `internal` visibility by default                                                                                                                              |
| **Immutability**           | Prefer `val` over `var`, use immutable data structures : for exemple prefer List,Set,Map over MutableList,MutableSet,MutableMap                                      |
| **Document**               | User-facing changes → `README.md`; contributor/architecture changes → `CONTRIBUTING.md`; agent-relevant changes → `AI_CONTEXT.md` + `AGENTS.md`                      |
| **Persistence**            | Adding a synced entity = implement the DAO in **both** `persistence:dynamo` and `persistence:postgres`. `service:core` only depends on the DAO interfaces.           |
| **Keep AI doc up-to-date** | Update `AI_CONTEXT.md` when adding/removing domain types, changing public API, or making architectural decisions. Update `AGENTS.md` when rules or workflows change. |
---

## Build layout

`back/` is a single Gradle multi-project build (root: `back/settings.gradle.kts`). Every module under `back/lib/`, `back/persistence/`, `back/service/`, `back/deploy/` is a subproject — no per-module `settings.gradle.kts` or `gradle.properties`. The only included build is `convention/` (build-logic).

Inter-module dependencies use project paths:

```kotlin
api(project(":lib:id"))
implementation(project(":service:core"))
```

Each module declares `group = "lib"` / `"persistence"` / `"service"` / `"deploy"` matching its top-level directory. **Do not remove these.** Two modules share the short name `lambda` (`:lib:lambda` and `:deploy:lambda`); without distinct groups they collide on Maven coordinates `<root-group>:lambda` and Gradle reports a circular `compileKotlin → jar` cycle when resolving `project(":lib:lambda")` from `:deploy:lambda`.

The `version-catalog-update` plugin must only be applied at the back root (`back/build.gradle.kts`), never on a subproject.

---

## Code Style

### Kotlin Conventions

- Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- 4-space indentation
- Avoid nullable types unless required
- Use sealed classes for finite state models
- Prefer functional programming patterns
- `@SerialName` only when the wire name differs from the Kotlin identifier (e.g. `@SerialName("product_type_id") val productTypeId` is needed; `@SerialName("status") val status` or `@SerialName("ACTIVE") ACTIVE` are redundant and must be omitted)

### Logging (KotlinLogging)

```kotlin
private companion object {
    private val logger = KotlinLogging.logger {}
}

// Usage:
logger.debug { "Processing: $fileName" }
logger.warn { "Unexpected: $value" }
logger.error(exception) { "Failed: $item" }
```

### Test Naming

```kotlin
@Test
fun `GIVEN precondition WHEN action THEN expected result`() { 
    //...
    }
```

---

## Testing Requirements

**Test Characteristics:** deterministic, fast, isolated.

---

## Definition of Done

A change is complete when:

- [ ] `back/gradlew format` passes
- [ ] `back/gradlew check` passes (compiles without warnings, all tests pass)
- [ ] No public API is broken
- [ ] Only relevant files are modified
- [ ] Type safety is preserved
- [ ] Architecture boundaries are respected
- [ ] Tests are added for new logic

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

## Debugging

```bash
# Verbose build output
./gradlew build --info

```
