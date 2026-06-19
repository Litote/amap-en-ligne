# ADR-005 — Sync-first notification system

## Status

Accepted

## Context

The product needs to notify users about events that happen on their AMAP: a basket
exchange request was accepted, a member join request was submitted, a delivery is
coming up, a producer request was approved, etc. Those notifications must reach the
user through several transports over time — in-app inbox, email, mobile push —
and the in-app inbox must work **offline**, like the rest of the client.

SMS was considered and **dropped**: it is a paid transport with no free tier, so it
is not implemented and not modelled (no `SMS` channel, no SMS preference toggle).

Two facts about the current codebase shape the decision:

1. **A vestigial `Notification` model already exists embedded inside `Member`**
   (`type`, `channel`, `content`, `sentInstant`). It is not a first-class synced
   entity and would leak a member's personal feed to every caller that syncs the
   `organization:{id}` scope (admins), besides churning the `Member` row on every
   notification.
2. **An asynchronous outbox pattern already exists** for activation emails:
   `ActivationEmailPort` → `PostgresActivationEmailAdapter` + `ActivationEmailCronJob`
   (JVM) and `SnsActivationEmailAdapter` + `ActivationEmailLambda` (Lambda). The
   ~12 other `*EmailPort` interfaces are log stubs (`LogXxxEmailAdapter`).

The offline-first contract of this app is `POST /v1/sync` with scope-keyed cursors
and optimistic client mutations. Any state a user observes or mutates offline must be
a synced entity on a scope the user is authorized for.

The requirement, scoped for the first iteration, is:

- **v1**: an in-app notification feed that works offline, plus **email** transport.
- **Designed for, but not built in v1**: mobile **push** transport, and
  notification feeds for **owners** and **producers** (which carry a different set of
  notifications than members).
- **Out of scope**: SMS (paid transport, not implemented).

## Decision

We separate three concerns that are easy to conflate:

| Concern | Mechanism | Offline? |
|---|---|---|
| In-app feed (inbox, unread badge, read/archived state) | **Synced entity** | yes — via `POST /v1/sync` |
| Notification preferences | Existing `MemberPreferences` (already synced on `Member`) | yes |
| Outbound transport (email/push) | **Dispatcher + channel-sender registry** (server side-effect) | no |

"Offline-compatible" applies to the feed and the preferences. Transport is a
post-commit server side-effect, fired in the same atomic transaction as the domain
mutation — exactly like the existing `*EmailPort` calls.

### 1. A private per-recipient scope family

A member's personal feed must not transit through `organization:{id}` (visible to
admins) nor `instance-owner` (shared by all owners). We introduce a **private
per-recipient scope**, modelled as one member of a family so owner/producer feeds can
join later without a new entity or service:

| Recipient | Feed scope | Key |
|---|---|---|
| AMAP member | `member:{sub}` | auth subject |
| Owner | `owner:{sub}` (distinct from the shared `instance-owner`) | auth subject |
| Producer | `producer-account:{id}` (already private; now also carries `Notification`) | `producerAccountId` |

`AuthorizedScopeResolver` grants the caller **their own** private feed(s) from `auth`.
`SyncScope.Member(subject)` and `SyncScope.Owner(subject)` each list only
`EntityType.Notification`; `SyncScope.ProducerAccount` lists `ProductType` + `Notification`.

**Member/owner feeds are keyed by the auth subject (`sub`), not by the entity row id.**
`auth.memberId` is the JWT subject on both auth providers, whereas `Member.memberId` /
`Owner.ownerId` are separate generated ids. The feed key must be computable identically
when the server *grants* the scope (from the JWT) and when a server-side producer
*addresses* a recipient (from the recipient's `sub`) — so the stable subject is the only
correct key. Producers are the exception: their tenant id (`producerAccountId`, from a JWT
claim) is already that stable key. A recipient whose `sub` is not yet linked (e.g. a
pending-invitation member) simply cannot be addressed until activation.

`NotificationService` is **recipient-agnostic**: it accepts a notification on any of the
caller's authorized private feeds (ownership resolved via `AuthorizedScopeResolver`), so
member/owner/producer share one service with no per-recipient branching.

### 2. `Notification` becomes a first-class synced entity

The embedded `Notification` is lifted out of `Member` and promoted to
`EntityType.Notification`, written on the recipient's private scope. There is a single
`NotificationService : EntityTypeService<NotificationPayload>` regardless of recipient
type — the difference between member/owner/producer feeds is carried by **data**
(`recipientScope` + `category`), not by the type system.

```
Notification {
  notificationId, recipientScope,            // "member:42", "owner:7", ...
  type,                                       // ALERT / REMINDER / INFO / URGENT (reuses existing NotificationType)
  category,                                   // BASKET_EXCHANGE_ACCEPTED, JOIN_REQUEST_SUBMITTED, ...
  title, body, deepLink?, relatedEntityId?,
  createdAt, readAt?
}
```

- **Creation** is server-authoritative: a domain mutation's side-effect creates the
  `Notification` row + its scope `Change` in the same atomic primitive
  (`TransactWriteItems` / `BEGIN-COMMIT`). The client never fabricates a notification.
- **Read / archive** is a normal client mutation: `Upsert(NotificationPayload(readAt=…))`
  marks read, `Delete(Notification, id)` archives. Both are optimistic, queued offline
  in `pending_mutations`, flushed on reconnect — the existing client write path.
- The legacy `Notification` / `NotificationType` / `NotificationChannel` fields embedded
  in `Member` are removed (`Member.notifications` drops); `NotificationType` is reused by
  the new entity, `NotificationChannel` moves to the transport layer.

### 3. Extensible transport, one channel wired in v1

A `NotificationDispatcher` resolves the target channels for a `(recipient, category)`
pair against the recipient's preferences, then fans out to a registry of
`ChannelSender`:

```
NotificationDispatcher
  └─ resolveChannels(recipient, category, preferences)   // EMAIL, PUSH
  └─ for each channel → NotificationChannelSender registry
        ├─ EmailChannelSender   (v1 — reuses the existing EmailSender)
        └─ PushChannelSender    (per deployment, see below)
```

`NotificationChannel` has exactly two members — `EMAIL` and `PUSH`. There is no SMS.

**Push transport is deployment-specific** (native AWS on Lambda, no AWS on JVM):

| Deployment | Push sender | Mechanism |
|---|---|---|
| `deploy:lambda` | `SnsPushNotificationChannelSender` | AWS SNS Mobile Push — `CreatePlatformEndpoint` per device token on the FCM/APNs Platform Application, then `Publish` |
| `deploy:jvm` | `FcmPushNotificationChannelSender` | FCM HTTP v1 called directly (service-account OAuth2), no AWS dependency |

Both resolve the recipient's registered **`DeviceToken`s** by scope before sending. A
device token is a first-class synced entity (`EntityType.DeviceToken`) on the same
private per-recipient scopes as `Notification`; the client registers one when it
obtains/refreshes a push registration token and deletes it on logout. The server
deduplicates by `(recipientScope, token)`.

Transport stays best-effort and post-commit: a failed send never rolls back the domain
mutation. Email (JVM) and push (both deployments) are wired as real transports; the Lambda
email path remains a log stub. Each push sender disables itself cleanly when its credentials
/ platform-application ARNs are not configured. Adding a transport later is adding one
`NotificationChannelSender` plus its dependency — no structural change.

## Consequences

- **Coordinated wire change** — adding `EntityType.Notification` follows the standard
  "add a synced entity" procedure on both sides (closed enum + exhaustive switches fail
  to compile until every branch is handled): back extends `EntityType`,
  `EntityPayload`, `NotificationSyncDAO` (implemented in **both** `persistence:dynamo`
  and `persistence:postgres`), `NotificationService`; front extends its `EntityType`,
  model, drift schema, `SyncRepository` switches, repository, screens. Guarded by
  `sync_wire_format_test.dart`, `DataServiceTest`, and an `acceptance/scenarios/`
  story.
- **New scopes `member:{sub}` and `owner:{sub}`** — `SyncScope` gains `Member` and `Owner`
  variants (keyed by subject), and `ProducerAccount` gains `Notification` in its entity
  list. `AuthorizedScopeResolver` grants them from `auth`. The front persists cursors only
  for server-returned `authorized_scopes`, so it picks up the new scopes without a client
  guess; `SyncScope.fromKey` and the front `clearScopeData` eviction handle all three feeds.
- **`Member.notifications` is removed** — a wire-format break absorbed in the same
  coordinated release; no migration shim. Notification preferences stay on
  `MemberPreferences`, so offline preference editing is unaffected.
- **Transport stays best-effort and post-commit** — a failed send never rolls back the
  domain mutation; the outbox retries. This matches the current `*EmailPort` contract.
- **Adding a recipient type later is additive** — a new private scope
  (`owner:{id}`) plus new event producers; it touches neither
  `EntityType.Notification` nor `NotificationService`.
- **Dynamo key schema** — `Notification` items are keyed `pk=NOTIF#{recipientScope}`,
  `sk=${notificationId}`. Postgres adds a `notification` table via Flyway with a
  `recipient_scope` index.
