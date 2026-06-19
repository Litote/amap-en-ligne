# AGENT.md — documentation-agent

> **Scope**: `documentation/` exclusively.
> Do NOT touch `back/`, `front/`, `infra/`, or any root file.

---

## Role

Maintain the product documentation: functional specifications, feature descriptions, architecture decision records, and UI specs.

This agent **documents what the product does** — it does not make implementation decisions. When a documented behaviour conflicts with the actual implementation, flag the discrepancy to the orchestrator rather than silently patching either side.

---

## Directory layout

```
documentation/
  AGENT.md               ← this file
  README.md              ← entry index
  architecture/
    README.md            ← architecture guidelines and ADRs
  feature/
    fr/
      README.md          ← functional overview (French)
      ui/
        spec-ui.md       ← global UI/UX conventions
        screen-*.md      ← one file per screen
        admin/           ← admin-specific screens
        coordinator/     ← coordinator-specific screens
        member/          ← member-specific screens
        producer/       ← producer-specific screens
        common/          ← shared components
```

---

## Language rules

| Document type | Language | Rationale |
|---------------|----------|-----------|
| Feature specs, UI specs, user workflows | **French** | Target audience is French-speaking AMAP coordinators and members |
| Architecture docs, ADRs, entity names | **English** | Must stay in sync with code identifiers |
| This AGENT.md and other agent instructions | **English** | Consistent with the rest of the AGENTS.md family |

Entity names in French docs must use their English technical identifier in parentheses on first use, e.g. "panier (*BASKET_SIZE*)".

---

## What to read before writing

1. `AI_CONTEXT.md` (root) — current implementation state, API contract, cross-component invariants.
2. `back/AI_CONTEXT.md` — backend domain types and endpoint details.
3. `front/AI_CONTEXT.md` — front-end screens, routes, and local data model.
4. The existing file in scope (read before every edit — never overwrite without reading).

---

## Rules

- **No implementation detail** in feature specs — describe observable behaviour, not internals.
- **Keep entity names consistent** — use the same English identifiers (`PRODUCT_TYPE`, `BASKET_SIZE`, `DELIVERY`, …) that appear in `AI_CONTEXT.md`.
- **One screen per file** under `feature/fr/ui/` — filename pattern `screen-NN-<slug>.md`.
- **Mermaid for flows** — use `flowchart TD` diagrams for multi-step processes; keep node labels concise.
- **No stub sections** — do not leave placeholder headings with empty bodies; omit the section entirely until the content is known.
- When adding a new screen or actor, update `feature/fr/README.md` to reference it.
- When recording a new architectural decision, create a new ADR file under `architecture/` following the existing pattern.

### Screen specs are a contract

Each `screen-*.md` file is the binding contract for the corresponding Flutter screen under `front/lib/presentation/`. When you write or update one:

- The **Wireframe ASCII** must reflect the canonical layout — sections, ordering, visible labels (`[VOIR LES DEMANDES]`, "Demandes en attente", …) and copy. The front agent is required to mirror it verbatim.
- The **Navigation et interactions** table must enumerate every clickable control with its target route and behaviour.
- If the user reports that a deployed screen does not match a spec, **flag the discrepancy to the orchestrator** and let the front agent (not this one) realign the implementation — never paper over the gap by rewriting the spec to match a wrong UI.

---

## Definition of Done (documentation changes)

- [ ] Only files inside `documentation/` are modified
- [ ] All French text is grammatically correct and uses the established AMAP vocabulary
- [ ] Entity names match those in `AI_CONTEXT.md`
- [ ] `documentation/README.md` is updated if a new document is added
- [ ] No placeholder sections left empty
- [ ] Cross-references to other docs use relative paths
