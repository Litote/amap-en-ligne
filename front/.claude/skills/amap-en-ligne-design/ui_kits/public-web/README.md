# Public Web UI Kit — Amap en Ligne

Pixel-faithful recreation of the **public surface** of the Flutter app — the screens any visitor can reach without logging in:

| Route in Flutter | Screen in this kit |
|---|---|
| `/` | HomeScreen — carrot mark, three action cards, info section |
| `/login` | LoginScreen — email/password, server picker, helper copy |
| `/register` | OrganizationCreationScreen — segmented type, address form, terms checkbox |
| `/amap-search` | AmapSearchScreen — combo + join-request form |

Source references (in `Litote/amap-en-ligne@main`):
- `front/lib/main.dart` — theme setup
- `front/lib/presentation/home/home_screen.dart`
- `front/lib/presentation/auth/login_screen.dart`
- `front/lib/presentation/organization/organization_creation_screen.dart`
- `front/lib/presentation/amap_search/amap_search_screen.dart`

## Files

- `index.html` — interactive click-thru prototype (Home → Login / Register / Search). Stateful in-page navigation; no real backend.
- `App.jsx` — root with view state.
- `HomeScreen.jsx`, `LoginScreen.jsx`, `RegisterScreen.jsx`, `SearchScreen.jsx`
- `components.jsx` — shared Material-3-ish atoms: `FilledButton`, `OutlinedButton`, `TextButton`, `TextField`, `SectionHeader`, `AppBar`, `MobileFrame`.

The kit recreates the Flutter widgets as React; styles are inline + the central `colors_and_type.css` from the design-system root. It is intentionally cosmetic — not a real auth flow.
