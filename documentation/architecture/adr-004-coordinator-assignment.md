# ADR-004 — Coordinator assignment by delivery contract

## Status

Accepted

## Context

AMAP coordinators specialise by product category — there are typically several vegetable coordinators, one or two bread coordinators, etc. The product domain captures this via the season `CONTRACT` entity, which already carries a `coordinators: List<Id<Member>>` list of referent coordinators.

At delivery time, the operational granularity is the `DELIVERY_CONTRACT` (one product contract embedded in a `DELIVERY`). Today the model exposes two parallel fields:

- `DELIVERY.coordinator_id: Id<Member>?` — a single optional coordinator at the delivery level.
- `DELIVERY_CONTRACT.coordinator_id: Id<Member>` — a single **required** coordinator at the delivery-contract level.

This shape has two limitations:

1. **Single coordinator per delivery contract** — real distributions often need a pair of coordinators (one to receive, one to distribute). The single field cannot represent it.
2. **Two parallel fields** — `DELIVERY.coordinator_id` and `DELIVERY_CONTRACT.coordinator_id` overlap. Members and admins cannot tell which one is authoritative.

The product requirement is:

- Multi-coordinator assignment per delivery contract.
- Empty assignment is allowed at delivery creation; "at least one coordinator per delivery contract" must hold before the delivery can transition to `CONFIRMED`.
- Coordinators self-assign on any active delivery they want to help with — not restricted to the season-contract referent list.
- AMAP admins can override at any time and assign any coordinator of the AMAP.
- The coordinators of an upcoming delivery must be visible everywhere the delivery is shown (member planning, dashboards, tracking), with a clickable `tel:` link when the coordinator has a phone number on file.

## Decision

### Data model

- Replace `DELIVERY_CONTRACT.coordinator_id: Id<Member>` with `coordinators: List<Id<Member>>` (default `emptyList()`).
- Remove `DELIVERY.coordinator_id` entirely. The set of coordinators visible on a `DELIVERY` is the union of `coordinators` across its `DELIVERY_CONTRACT` entries.
- `CONTRACT.coordinators` remains unchanged — it is the **reference list of specialists** for the contract over the season, surfaced informationally on the contract-definition screen. It is **not** auto-copied onto each new `DELIVERY_CONTRACT`.

### Assignment workflow

`DELIVERY_CONTRACT.coordinators` is mutated through `POST /v1/sync` as a `Upsert(OrganizationPayload(...))` on the `organization:{id}` scope.

`OrganizationService` already treats `COORDINATOR` as a privileged caller alongside `OWNER` and `ADMIN` — coordinators can already create and update deliveries, slots, basket descriptions, etc. The introduction of `coordinators: List<Id<Member>>` does not narrow that scope. Self-assign and admin-override therefore both reuse the existing privileged path: a coordinator submits `Upsert(OrganizationPayload(...))` with their own `memberId` added to `deliveries[].contracts[].coordinators`, and an admin submits the same shape with any coordinator's `memberId`.

`VOLUNTEER`-only callers continue to be filtered by `VolunteerMutationValidator`, whose existing structural check (`areNonRegistrationContractFieldsEqual`) compares every `DELIVERY_CONTRACT` field except `slots`. The new `coordinators` field is included in that comparison, so any attempt by a volunteer to add or remove a coordinator is rejected with `FORBIDDEN` — without any new validator.

### Confirmation guard

`OrganizationService.applyUpsert` rejects any payload that contains a `DELIVERY` with `status == CONFIRMED` while at least one of its `DELIVERY_CONTRACT` entries has `coordinators.isEmpty()`. A new `MutationErrorCode.MISSING_COORDINATOR` is added so the front can surface a specific message (listing the contracts that still need a coordinator) instead of a generic `INVALID_PAYLOAD`.

The guard fires on the structural condition (`status == CONFIRMED` plus an empty `coordinators`), not on a transition diff. Concretely this means:

- `PLANNED` deliveries with empty coordinators are accepted (creation and edits remain free).
- `CONFIRMED` deliveries created or kept must have a coordinator on every contract.
- `IN_PROGRESS`, `COMPLETED`, `CANCELLED` are never re-checked — admins can clean up coordinators after the fact if needed.

If an admin attempts to remove the last coordinator from a still-`CONFIRMED` delivery, the guard rejects the change; the admin can either reassign another coordinator first, or move the delivery back to `PLANNED`.

The guard applies to all callers (admins, coordinators, volunteers) — it sits above the role-specific validators in `OrganizationService.applyUpsert`. Volunteers will hit the structural check in `VolunteerMutationValidator` first (they cannot mutate `status` or `coordinators`), so the guard mostly affects privileged callers in practice.

### Display

Wherever a `DELIVERY` is presented to a member, admin or coordinator, the screen displays the coordinators grouped by `DELIVERY_CONTRACT` (so the specialisation is visible: who runs the vegetables, who runs the bread, …). Each coordinator entry shows the member's display name plus a `tel:` link when `MEMBER.phone` is non-null. Missing phone numbers are rendered as plain text without a link — no synthetic placeholder.

When a `DELIVERY_CONTRACT` has no coordinator yet, the cell reads `Coordinateur à confirmer` for members, and exposes a `[ME PORTER COORDINATEUR]` action on coordinator-facing screens.

## Consequences

- **Wire-format break** — both back and front must ship the new shape coordinatedly. There is no backward-compatibility shim; the next release synchronises the change across `back/`, `front/` and the `acceptance/` cross-component tests.
- **Migration** — existing `DELIVERY_CONTRACT` rows with a singular `coordinator_id` are migrated by lifting the value into a one-element `coordinators` list. Existing `DELIVERY.coordinator_id` values are dropped (the same person should already appear via `DELIVERY_CONTRACT.coordinator_id`; if not, the value is lost and the admin can re-assign).
- **Self-assign is broader than referent list** — a coordinator who is not in `CONTRACT.coordinators` can still self-assign on a one-off delivery. Operationally this matches reality: substitutions are common when the referent is unavailable. The `CONTRACT.coordinators` list keeps its informational role on the contract-definition screen.
- **No auto-prefill** — each new `DELIVERY_CONTRACT` starts empty. This trades initial setup overhead for a cleaner workflow: with 5 vegetable referents on a contract, prefilling 5 names on every delivery would mean unchecking 4 of them most of the time. Coordinators opt in via `[ME PORTER COORDINATEUR]` instead.
- **`MISSING_COORDINATOR` is added to `MutationErrorCode`** — both back and front must enumerate it exhaustively. The front surfaces it as a dedicated snackbar listing the contracts in question; the validator-level rejection is per-mutation, not transaction-wide.
- **Phone display** — `MEMBER.phone` is already PII synced on `organization:{id}`, so no new sync scope is introduced. Members of the same AMAP can already see each other's phone numbers; this decision only exposes them via a `tel:` link on delivery cards.
