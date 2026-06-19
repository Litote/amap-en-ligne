# ADR-003 — Authentication Session Persistence by Platform and Intent

## Status

Accepted

## Context

The Flutter client serves mobile and web from the same product surface, but the expected authentication behaviour differs by platform and by login choice:

- On mobile, users expect the app to restore their authenticated session automatically after the app is closed and reopened.
- On web, users may sign in on either personal or shared devices, so "keep me signed in" and "only for this browser session" must be distinct behaviours.
- The login form still benefits from remembering the last used server and email even when the authenticated session itself should not survive a browser relaunch.
- Protected routes, activation links, and password-reset links may all send the user through the login route before they can continue.

Before this decision, session persistence and remembered login context were not documented as separate concerns.

## Decision

### 1. Mobile keeps durable automatic session restore

Mobile continues to restore the authenticated session automatically from durable local storage after app restart.

### 2. Web supports two persistence modes

On web, the `remember me` choice controls how the authenticated session is stored:

- **Remember me checked** — the authenticated session is stored durably and survives browser relaunches.
- **Remember me unchecked** — the authenticated session is stored for the current browser session only and is not restored after the browser is closed.

### 3. Authenticated session storage is separate from remembered last-user context

The app stores two different kinds of local authentication-related state:

1. **Persisted authenticated session** — the tokens and state required to restore a signed-in session.
2. **Remembered last-user context** — non-authenticated login context used to prefill and recover the login flow.

The remembered last-user context stores at least:

- email
- server id
- remember-me choice

This context may exist even when no authenticated session is persisted.

### 4. Explicit logout clears all local auth memory

Explicit user logout clears:

- the persisted authenticated session
- the remembered last-user context
- any pending reconnect intent

This logout-clears-memory behaviour is intentional product and security behaviour, especially for shared web devices.

### 5. Login preserves and replays protected-route intent

When an unauthenticated user is redirected to login from a protected route, the intended destination is preserved through the login route using a `from` query parameter. After successful authentication, that intent is replayed and the user is returned to the requested route.

### 6. Recovery and deeplink flows reuse remembered context

Existing web activation and reset-password flows reuse the remembered last-user context so that the selected server and email are not unnecessarily lost while the user passes through those flows.

## Consequences

- Mobile and web no longer share a single persistence rule: mobile remains durably restoring, while web behaviour depends on the `remember me` choice.
- Web can support shared-device usage better: users who do not opt into durable persistence are signed out when the browser session ends.
- The login form can still be prefilled after logout or after a non-durable web session ends, but explicit logout removes that remembered context on purpose.
- Logout is a stronger action than passive session expiry or browser close on web: it clears both authentication state and remembered login context.
- Route guards and login redirects must preserve the `from` query parameter so users land back on the protected page they originally requested.
- Activation and password-reset entry points must continue to read the remembered context when available, so the user does not have to reselect the server or re-enter the email unnecessarily.

## Alternatives considered

### Single durable persistence on all platforms

Rejected because it would keep web users signed in across browser relaunches even when they did not opt into that behaviour, which is a poor fit for shared devices.

### Browser-session-only persistence on web with no remembered context

Rejected because it would discard useful login context such as server id and email, making routine sign-in, activation, and password-reset flows more fragile and repetitive.

### Keep remembered context after explicit logout

Rejected because explicit logout is intended to clear local auth memory, including login prefills and reconnect intent, as a deliberate product/security behaviour.
