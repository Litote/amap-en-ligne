
# Front — amap-en-ligne

> Flutter app for amap-en-ligne — offline-first sync client targeting Android, iOS and Web.
> Global rules: see [`../AGENTS.md`](../AGENTS.md) and [`../AI_CONTEXT.md`](../AI_CONTEXT.md).

---

## Commands

```bash
# Dependencies
flutter pub get

# Code generation (freezed, json_serializable) — run after model changes
dart run build_runner build --delete-conflicting-outputs

# Lint
flutter analyze

# Unit + widget tests (Linux-safe, excludes goldens and acceptance)
flutter test test/ --exclude-tags "golden || acceptance"

# Acceptance tests (cross-component E2E excluded — run via ./gradlew frontCrossComponentTest)
flutter test test/acceptance/ --tags acceptance --exclude-tags cross-component

# Golden tests — macOS only (text rendering differs on Linux)
flutter test test/golden/ --tags golden

# Regenerate golden screenshots — macOS only
flutter test test/golden/ --update-goldens --tags golden

# Build
flutter build apk --release
flutter build ios --no-codesign --simulator --debug
flutter build web --release  # builds WASM by default
```

**Web builds:** Flutter web uses **WebAssembly (WASM) by default** for better performance (4.8% smaller code size vs JS). To debug or fall back to JS, use `flutter build web --no-wasm`.

**Important:** Golden tests are generated on macOS and validated on macOS. Never run `--update-goldens` on Linux — it will produce different pixel output and break CI.

---

## Architecture

**Layer rules:**
- `domain/` has zero Flutter/external dependencies — pure Dart
- `data/` depends on `domain/` only (no presentation)
- `presentation/` depends on `domain/` only (no data — injected via BlocProvider)
- `shared/services/` are injected into the BLoC constructor (testable)

---

## State Management (BLoC)

**Key rule:** All state is immutable (Freezed sealed union types). No mutable fields outside services.

---

## Conventions

**Immutability:**
- Use `final` for all fields
- Use Freezed for all data classes, events, and states
- Use `const` constructors for stateless widgets

**Visibility:**
- Private by convention: `_prefixName` for internal fields and methods
- No explicit `public` keyword (Dart default)

**Imports:** Single imports only — no `show X, Y` patterns

**Code generation:** Every model change requires re-running `build_runner`. Generated files (`.freezed.dart`, `.g.dart`) are committed to the repo.

**Runtime config:** The app currently boots from a static server catalog and no longer requires a build-time `secrets.json` file for normal local builds.

**Comments:** In English (as per global AGENTS.md rule).

**Dependency versions:** All entries in `pubspec.yaml` must use **exact versions** (e.g. `dio: 5.7.0`), never range constraints (`^`, `>=`, `any`). The `environment: sdk:` range is the only exception. When adding or upgrading a package, pin the version resolved in `pubspec.lock`.

---

## Testing Rules

- **Per-test timeout is automatic:** `front/dart_test.yaml` sets `timeout: 60s`, picked up by every `flutter test` run (no flag needed). It turns a hung test into a named, fast failure instead of freezing the whole suite until the 10-minute default. Override per case with `timeout:` on `testWidgets`/`test` only when a slow test is genuinely required.
- **Never `pumpAndSettle()` while a `CircularProgressIndicator` (or any indefinite animation) can be on screen** — it never settles and hangs the test. Pump explicitly instead (`await tester.pump()` then `await tester.pump(const Duration(milliseconds: 50))`). For screen/widget tests, **mock the repository** (mocktail + `StreamController`) rather than driving a real `drift` `watch()` stream: a live drift stream leaves a pending timer that trips `A Timer is still pending even after the widget tree was disposed`.
- **Bug fix flow:** write a failing test first, then fix the bug
- **New logic:** always add a corresponding test
- **Mocking:** use `mocktail` (not `mockito`)
- **BLoC tests:** use `bloc_test` package (`blocTest<>` helper)
- **Repository tests:** use a drift in-memory `NativeDatabase` and a mocked `Dio`
- **Acceptance tests:** use real drift + real repositories + a scripted `SyncApi`; do not replace them with mocked repositories or device-only E2E unless the story explicitly needs UI coverage

---

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | BLoC state management |
| `go_router` | Declarative routing |
| `freezed` | Immutable data classes + sealed union types |
| `json_serializable` | JSON serialization |
| `drift` + `drift_flutter` | Local SQLite cache (offline-first) |
| `dio` | HTTP client for `POST /v1/sync` |
| `connectivity_plus` | Network-restored sync trigger |
| `flutter_svg` | SVG rendering (brand assets) |
| `bloc_test` + `mocktail` | Testing utilities |

---

## Design system

Le design system complet (tokens couleur, typographie, voix & ton, UI kit, assets SVG) est dans `.claude/skills/amap-en-ligne-design/`.

**Règle :** invoquer la skill `amap-en-ligne-design` avant tout travail sur un écran ou un composant visuel.

Assets de marque dans `assets/` :
- `logo.svg` — Le Panier, carré 96×96 viewBox (app icon, favicon)
- `wordmark.svg` — lockup horizontal 380×96 viewBox (en-tête home)

Référence doc : `documentation/feature/fr/ui/charte-graphique.md` et ADR `documentation/architecture/adr-002-design-system.md`.

---

## UI specs are the source of truth

Every screen implemented under `lib/presentation/` must mirror its specification under `documentation/feature/fr/ui/`. The spec file is the contract — the implementation may not unilaterally add, remove, reorder or rename sections, cards, buttons or copy.

**Before writing or modifying any screen widget:**

1. Locate the screen's spec at `documentation/feature/fr/ui/<role>/screen-<role>-NN-<slug>.md` (e.g. `owner/screen-owner-01-home.md`). If no file matches, ask the orchestrator before guessing.
2. Read the spec end-to-end, including the **Wireframe ASCII**, **Navigation et interactions** table, **États de l'interface**, and **Règles métier** sections.
3. Treat the ASCII wireframe as the layout source of truth: the order of sections, the visible labels (`[VOIR LES DEMANDES]`, `Demandes en attente`, …), and the user-visible counts must appear in the implementation exactly as written (in French, with the same wording).
4. Treat the **Navigation et interactions** table as the routing/behaviour contract: each named control routes to the documented target with the documented side effects.
5. Apply the design system tokens (Material 3 with `Colors.green` seed, pill buttons, 12px-radius cards, `OutlineInputBorder`, Material Symbols Outlined icons) from `.claude/skills/amap-en-ligne-design/SKILL.md`. Do not introduce custom colors, custom radii, gradients, imagery or non-Material 3 widgets.
6. Use `ConnectedScaffold` for authenticated screens — the AppBar title is the screen title from the spec.

**When the spec and the implementation disagree:**

- If the spec is missing a behaviour the user is asking for, **stop and surface the gap** to the orchestrator (per `documentation/AGENT.md`) rather than silently extending either side.
- If the spec describes data the front does not yet expose (e.g. instance-wide counts), derive the closest approximation from what is available locally and add a short comment naming the missing source — do not invent fake numbers.

**Forbidden in a screen implementation:**

- Inventing tiles, cards, or menu entries that are not in the spec wireframe.
- Replacing a documented section with a generic `ListTile` grid because it is faster to code.
- Translating documented French copy ("Demandes en attente", "VOIR LES DEMANDES", …) into different wording.
- Using `Colors.*` or hex literals outside the seeded Material 3 `ColorScheme` (the three `Colors.green/blue/orange` action accents on the public home are the only exception, documented in `AI_CONTEXT.md`).


## SonarCloud Workflow

To check the quality gate from an agent session:

1. Run `./gradlew allSonar` from the repo root (runs all checks with coverage then uploads results).
2. Use the `sonarqube` MCP server (configured in Claude Code) to query the gate status —
3. The gate passes when `new_coverage ≥ 80%`, `new_duplicated_lines_density ≤ 3%`, ratings all A, hotspots reviewed 100%.
---
