# ADR-001 — Role Management: Dual-Write to Database and Auth Provider

## Status

Accepted (revised 2026-05-17)

## Context

amap-en-ligne defines a single closed set of five roles. Roles must be available in two distinct contexts:

1. **Sync queries** — the user-management screens need to display and filter users by role. Fetching roles from the auth provider on every list query would introduce unnecessary latency and coupling to the auth layer.
2. **Request authorisation** — backend route guards need to verify the caller's roles on every authenticated request. Loading roles from the database on each request would add an extra query to the hot path.

### Role catalogue

The five `Role` values, their scope and their mutual-exclusion rules:

| Role | Scope | Combinable with |
|------|-------|-----------------|
| `OWNER` | Instance (no organisation) | Nothing — exclusive |
| `ADMIN` | One AMAP `Organization` (`organizationType = AMAP`) | `COORDINATOR`, `VOLUNTEER` |
| `COORDINATOR` | One AMAP `Organization` | `ADMIN`, `VOLUNTEER` |
| `VOLUNTEER` | One AMAP `Organization` | `ADMIN`, `COORDINATOR` |
| `PRODUCER` | One producer `Organization` (`organizationType = PRODUCER`) | Nothing — exclusive |

### Invariants

- **OWNER exclusivity** — a user holding `OWNER` holds no other role anywhere (no `Member` entries, no `PRODUCER` attachment).
- **PRODUCER exclusivity** — a user holding `PRODUCER` holds no other role anywhere (no `OWNER`, no `Member` entries in any AMAP).
- **AMAP roles** — within a given AMAP membership, a user holds between 1 and 3 roles drawn from `{ADMIN, COORDINATOR, VOLUNTEER}`. A user may be a member of several AMAPs simultaneously, with an independent role set per AMAP.
- **Last admin guarantee** — each `Organization` of type `AMAP` must always have at least one user with `ADMIN`. The same guarantee applies symmetrically to producer organisations and the `PRODUCER` role.
- **Last owner guarantee** — the instance must always retain at least one `OWNER`.

The auth provider varies per deployment:
- `deploy:jvm` — GoTrue (`app_metadata.roles`)
- `deploy:lambda` — Amazon Cognito (Cognito groups)

## Decision

Roles are stored in two places simultaneously (dual-write):

**1. Database — source of truth for sync**

- `OWNER` is a user-level attribute (no organisation context). It is carried by the `User` entity.
- `PRODUCER` is a user-level attribute bound to exactly one producer `Organization` (the producer the user represents). It is carried by the `User` entity together with that `organizationId`.
- `ADMIN`, `COORDINATOR`, `VOLUNTEER` live on the `Member` entity (`roles: Set<Role>`) which carries the `(userId, organizationId)` pair. A user may have several `Member` rows — one per AMAP membership.

These records are included in the sync payload and delivered to the frontend via `POST /v1/sync`. The frontend can therefore display and filter role data from its local drift cache without any additional network calls.

**2. Auth provider — source of truth for in-flight request authorisation**

When any role mutation is applied, the backend updates the auth provider (GoTrue `app_metadata.roles` / Cognito groups) as a side-effect. The JWT carries the user's effective role set — for `OWNER`/`PRODUCER` a single flat claim, for AMAP roles the per-organisation mapping needed by route guards. Guards read from the decoded JWT, avoiding an extra DB lookup on every authenticated request.

The two stores are updated within the same role-change operation but not within the same atomic transaction — the DB write is primary and committed first; the auth-provider update is a best-effort side-effect. The JWT may therefore be stale by at most one token-refresh cycle after a role change, which is acceptable given that:

- Role changes are infrequent administrative actions.
- The DB remains authoritative and the frontend receives the updated state on the next sync.
- The JWT is refreshed on the client on each new session, bounding the inconsistency window.

### Role change flow

1. Frontend sends `ClientMutation.Upsert` on the appropriate entity (`User` for `OWNER` / `PRODUCER`, `Member` for AMAP roles).
2. `RoleService` validates:
   - The caller has the required authorisation (see authorisation matrix below).
   - **Exclusivity** — granting `OWNER` is rejected if the target user already has any `Member` row or `PRODUCER` attachment; granting `PRODUCER` is rejected if the target user already has `OWNER` or any `Member` row; granting any AMAP role is rejected if the target user already has `OWNER` or `PRODUCER`.
   - **Last-admin / last-owner / last-producer** guarantees are preserved.
3. DB rows are written (primary store).
4. Auth provider is called as a side-effect to update JWT claims (eventual consistency).
5. The updated entity is included in the next sync response so the frontend cache reflects the new roles.

### Authorisation matrix

| Action | Allowed for |
|--------|-------------|
| Grant / revoke `OWNER` | `OWNER` only |
| Grant / revoke `PRODUCER` | `OWNER` only |
| Grant / revoke `ADMIN` within an AMAP | `OWNER`, or `ADMIN` of the same AMAP |
| Grant / revoke `COORDINATOR` or `VOLUNTEER` within an AMAP | `OWNER`, or `ADMIN` of the same AMAP |

Because `OWNER` and `PRODUCER` are exclusive, every promotion to one of these roles is preceded by the removal of all existing memberships of the target user — the UI presents this as a single confirmed transition.

## Consequences

- The single `Role { OWNER, ADMIN, COORDINATOR, VOLUNTEER, PRODUCER }` enum must remain aligned across three artefacts: the DB columns (user-level for `OWNER` / `PRODUCER`, member-level for AMAP roles), the JWT claims written to the auth provider, and the frontend `Role` enum. Any addition or renaming of a role value requires coordinated changes in all three locations.
- The exclusivity invariants (`OWNER` and `PRODUCER` each exclude every other role) are enforced server-side by `RoleService`. The frontend UI mirrors the same invariants so that the user is never offered a mutation that will be rejected.
- Route guards continue to use JWT claims for authorisation; they do not query the DB. This preserves low-latency request handling but means guards operate on potentially stale data during the JWT validity window after a role change.
- The frontend may display a stale role badge until the next sync completes after a role change made by another administrator. This is a known and accepted race condition.
- Promoting a user to `OWNER` or `PRODUCER` requires first removing all their existing `Member` rows (and the other exclusive role if held). The operation is presented as a single atomic transition in the UI and executed as a single server-side validation in `RoleService`.
- There is no separate platform-level `ADMIN` role. Operations previously phrased as "requires `Role.ADMIN` or `Role.OWNER`" must be re-evaluated: instance-wide administration is reserved to `OWNER`, while AMAP-scoped administration is reserved to the `ADMIN` of that specific AMAP.
- Bootstrapping a new instance still provisions exactly one user with `OWNER`. This user holds no `Member` rows and cannot acquire any without first relinquishing `OWNER`.
