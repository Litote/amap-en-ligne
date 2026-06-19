/// URL fragment captured at app startup, before go_router calls
/// `window.history.replaceState` and strips the hash from the URL.
///
/// Set once in `main()` before `usePathUrlStrategy()`. Non-null only when the
/// app was opened on web with a fragment in the URL (e.g. a GoTrue recovery
/// redirect: `http://host/reset-password#access_token=...&type=recovery`).
String? webInitialFragment;
