# Amap en Ligne — Design System

> Producer-side management app for French AMAP / CSA (Community-Supported Agriculture) networks.
> Offline-first Flutter client (Android, iOS, Web) + Kotlin/Ktor backend.

---

## What is Amap en Ligne?

**Amap en Ligne** ("AMAP online" in French) is an open-source, self-hostable platform for managing AMAPs — *Associations pour le Maintien d'une Agriculture Paysanne*, France's flagship form of CSA. Producers and AMAP coordinators run their catalog, deliveries, member subscriptions and contract bookkeeping from a single app that works **offline first** and syncs whenever the device gets a connection.

The product audience is overwhelmingly French — copy is written in French, the dominant tone is friendly-utilitarian. Users are farmers, small producers, and the volunteer coordinators who keep AMAPs running on a budget of zero. The app is deliberately positioned as *free, open-source and self-hostable*, with a planned federated model where each region runs its own server.

### The two surfaces

| Surface | Description |
|---|---|
| **Public web/mobile** | Anonymous home page, login, search "find an AMAP near me", create-organization request, account activation. Built into the same Flutter binary; reachable at `/`, `/login`, `/register`, `/amap-search`, `/activate`. |
| **Authenticated app** | Producer + admin + coordinator views: product catalog, basket sizes, member management, delivery templates & calendars, producer enrollment, member-join requests, organization-creation request validation. |

Both run from the **same Flutter codebase** — there is no separate marketing website. The "landing page" is just the public home screen of the app.

---

## Sources used to build this design system

- **GitHub repo:** [`Litote/amap-en-ligne`](https://github.com/Litote/amap-en-ligne) — Flutter (Dart) front, Kotlin/Ktor back, Terraform infra. The visual system below is reverse-engineered from `front/lib/main.dart` (theme) and the screens under `front/lib/presentation/**`.
- **In-repo design notes:** `AI_CONTEXT.md`, `front/AI_CONTEXT.md`. There is **no dedicated design-system file** in the upstream repo — the design surface is whatever Flutter Material 3 produces from a `ColorScheme.fromSeed(seedColor: Colors.green)` plus the per-screen widget choices.

> **Reader:** If you have access to the GitHub repo above, you can explore further to produce more pixel-faithful designs. The Flutter source under `front/lib/presentation/` is the canonical reference for component appearance and copy tone.

---

## CONTENT FUNDAMENTALS

**Language:** French. Always. Even error messages, button labels, and microcopy. English is supported as a default-language option for organizations but the *app chrome itself* is French.

**Voice:** Direct, warm, slightly informal but never cute. Sentences are short. Punctuation is full French: spaces before `:`, `?`, `!`, French quotation marks "« »" in long-form copy (less common in UI).

**Person:** Mixed — formal **vous** in instructions ("Connectez-vous à votre espace personnel"), first-person **je** in user-facing action cards ("J'ai déjà un compte", "Je veux rejoindre une AMAP", "Je veux créer une nouvelle organisation"). The first-person framing is a deliberate hook on the home screen: the user identifies which sentence describes *them* and taps that card.

**Casing:**
- Section headers in forms are **ALL CAPS** with the primary color: `INFORMATIONS ORGANISATION`, `COMPTE ADMINISTRATEUR DE L'ORGANISATION`.
- Primary action button labels are **ALL CAPS**: `SE CONNECTER`, `S'INSCRIRE À UNE AMAP`, `INSCRIVEZ-VOUS`, `CRÉER`, `ANNULER`, `RETOUR À L'ACCUEIL`.
- Card titles, body copy, and screen titles use sentence case: "Connexion à votre compte", "Nouvelle Organisation", "Types de produits".
- Field labels are sentence case with a trailing ` *` for required fields: "Nom de l'AMAP *", "Email *".

**Tone examples (verbatim from the codebase):**
- > "Les AMAP (Association pour le Maintien d'une Agriculture Paysanne) créent des liens directs entre producteurs et consommateurs autour de produits locaux et de saison."
- > "Amap en Ligne est gratuit, open-source et auto-hébergeable."
- > "Première connexion ? Vous devez avoir reçu une invitation par email de votre coordinateur."
- > "C'est totalement gratuit !" (the *only* exclamation point — used once, on the create-organization card, to signal warmth)

**Emoji:** Sparingly. The upstream codebase still has a 🥕 emoji at 48px on the home screen as a placeholder; **this design system replaces it with the official `Le Panier` logo** (`assets/logo.svg`) — please plumb that swap into the Flutter code (`front/lib/presentation/home/home_screen.dart`). No other emoji appear in the UI.

**Numbers, dates, currency:** French locale. Use `intl` formats — `Europe/Paris` is the default timezone, `fr` is the default language. Currency is EUR.

**Errors:** Plain, non-blaming. "Email ou mot de passe incorrect." "Erreur réseau. Vérifiez votre connexion et réessayez." Never apologize, never use exclamation points, never anthropomorphize ("Oops!" — no).

**Empty states:** Single sentence, no illustration. "Aucun type de produit." "Organisations indisponibles."

---

## VISUAL FOUNDATIONS

The app is **Material 3 Flutter with `ColorScheme.fromSeed(seedColor: Colors.green)` and `useMaterial3: true`**. That single line in `main.dart` is the entire theme. Everything else — typography, shape, elevation, motion — falls back to Material 3 defaults. This design system documents both the seed-derived tokens *and* the per-screen overrides the codebase actually uses (e.g. raw `Colors.blue` / `Colors.orange` on the home-screen buttons).

**Palette:**
- **Primary:** `Colors.green` (Material `#4CAF50`, seed) — used for primary buttons, links, section headers in caps, the success check icon, the "SE CONNECTER" home card.
- **Accent blue:** `Colors.blue` (`#2196F3`) — used for the "S'INSCRIRE À UNE AMAP" (join an AMAP) button. Acts as a secondary action color.
- **Accent orange:** `Colors.orange` (`#FF9800`) — used for the "INSCRIVEZ-VOUS" (create-organization) button. Acts as an encouragement / "new" color.
- **Neutrals:** Material 3 surface tones derived from the green seed — slightly warm off-white surfaces, neutral grey body text. `Colors.grey` is used for one-off muted helper text.
- **Error:** Material 3 default error (`#B3261E`-family).

**Typography:** Roboto (Material 3 default on Flutter Android/iOS/Web). `google_fonts` is in `pubspec.yaml` but the app does *not* call `GoogleFonts.xxx` to override the default — it ships with Roboto. We mirror that here using Roboto via Google Fonts CDN, with a substitution note: **the upstream app does not load a custom typeface**; if you ship a designed asset, it can use anything but a brand decision is pending.

**Type scale:** Material 3 defaults — `displayLarge` 57px → `bodySmall` 12px. The screens lean heavily on `titleLarge` (22px, screen titles), `titleMedium` (16px, card titles), `bodyMedium` (14px, body), `labelLarge` (14px, buttons), and `bodySmall` (12px, muted).

**Spacing rhythm:** Tight, 8/12/16/24/32 px multiples. `Padding(16)` is the standard inside cards; sections inside scrollable forms separate with `SizedBox(height: 24)` between groups and `SizedBox(height: 12)` between fields. The home screen uses `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32)` and `SizedBox(height: 16)` between action cards.

**Backgrounds:** Plain surface color. No photography, no full-bleed imagery, no patterns, no textures, no gradients. The app reads as a workmanlike tool — like the Material 3 demos. Section dividers are plain `Divider()`s (1px hairlines).

**Cards:** Default Material 3 `Card` — surface color, ~12px corner radius, no border, very subtle elevation (level 1). Padding inside cards is `EdgeInsets.all(16)`. Cards on the home screen contain a title (titleMedium), a one-line subtitle (bodyMedium), and a FilledButton at the bottom.

**Corner radii:** Material 3 defaults — 12px for cards, 20px for FilledButtons (full Material 3 pill), 4px for `OutlineInputBorder` text fields, 8px for `SegmentedButton`.

**Buttons:**
- **FilledButton** — primary action. Pill-shape (~20px radius), filled with the color passed via `FilledButton.styleFrom(backgroundColor: ...)`. Label ALL CAPS. Spinner inside when loading.
- **OutlinedButton** — secondary action ("ANNULER", "RETOUR À L'ACCUEIL"). 1px outline in primary color, transparent fill.
- **TextButton** — tertiary inline action ("Mot de passe oublié ?"). No fill, no border, primary color text.

**Form inputs:** `OutlineInputBorder` is the universal field style — 1px outline, ~4px radius, label floats up on focus. `InputDecorator` wraps non-text inputs (dropdowns, server picker) in the same chrome so the form reads as visually uniform.

**SegmentedButton:** Used for binary choices like "AMAP / Producteur" organization type. Material 3 default styling — connected pill of 8px-radius segments, selected segment fills with primary container color.

**Hover / focus / press states:** Material 3 defaults — overlay tint on hover (8% primary), focus ring on focus, splash + slightly darker overlay on press. There is no custom motion or color treatment.

**Animation:** Material defaults. `LinearProgressIndicator` for "loading orgs"; `CircularProgressIndicator` for inline button spinners. Page transitions are go_router defaults (platform-adaptive — fade on Web, push on iOS, fade-through on Android). No custom easing, no bouncy springs.

**Elevation / shadow:** Material 3 surface tint replaces traditional shadows on most components. Cards use `surfaceContainerLow` (subtle ~1dp tint), `AppBar` is flat against the surface, `FloatingActionButton` (used on `ProductTypesScreen`) carries the only real shadow.

**Transparency / blur:** None. The UI is opaque, flat, surface-on-surface.

**Iconography:** **Material Icons** font, via Flutter's bundled set (`Icons.sync`, `Icons.add`, `Icons.delete`, `Icons.check_circle`, `Icons.chevron_right`). No custom icon set. On the web mirror we substitute **Material Symbols** (the same set, recently updated naming) loaded from Google Fonts CDN. See `ICONOGRAPHY` below.

**Layout rules:** Forms are centered with `maxWidth: 400` for login or `maxWidth: 480` for organization creation, then padded `EdgeInsets.all(24)`. On wide viewports the form sits as a column at the top of the page; on narrow viewports it fills the width. There are no sidebar nav or split-pane layouts on the public surface; the authenticated app uses a `ConnectedScaffold` with AppBar + optional FAB.

**Imagery:** None bundled. If imagery is needed for marketing/slides, the brand vibe calls for **warm, natural, daylight photography of vegetables, baskets, farms, hands**. Not stylized. Not blue-cool. Not stock-clipart. Use placeholders until real photography is sourced.

---

## ICONOGRAPHY

**Source:** The codebase uses Flutter's built-in **Material Icons** (`package:flutter/material.dart` exports `Icons.*`). There is no custom icon font, no SVG sprite, no PNG icon set in the repository — `front/web/icons/` contains only the default Flutter PWA app-icon placeholders (the Flutter logo), which we do **not** treat as brand assets.

**On the web (this design system):** We use **Material Symbols Outlined** loaded from Google Fonts CDN — it is the maintained successor to Material Icons and includes every glyph the Flutter code references. Same names, same metaphors.

```html
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0" rel="stylesheet">

<span class="material-symbols-outlined">sync</span>
<span class="material-symbols-outlined">add</span>
<span class="material-symbols-outlined">delete</span>
```

**Icons in active use** (verbatim from `front/lib/presentation/**`): `sync`, `add`, `delete`, `check_circle`, `chevron_right`, `arrow_back` (auto via `BackButton`).

**Emoji as icons:** Only one — 🥕 at 48px on the home screen, functioning as the de-facto logo / brand mark.

**Unicode chars as icons:** None in code.

**SVG / PNG icons:** None in code. If you need a brand mark for slides or marketing, use the 🥕 emoji glyph or commission a real logo — do not generate one in this system without designer sign-off.

**Flag for the user:** The official mark is **Le Panier** at `assets/logo.svg` (woven basket containing an eggplant, a carrot, and a tomato). The Flutter codebase still ships the 🥕 emoji as a placeholder on the home screen — plumb the SVG through to replace it.

---

## File index (manifest)

| File / folder | What's in it |
|---|---|
| `README.md` | This document. Project context, content/visual/iconography rules. |
| `SKILL.md` | Cross-compatible Agent Skill manifest. Read this first when invoking the skill. |
| `colors_and_type.css` | Single source of truth for color & type CSS custom properties. Import in any HTML you produce. |
| `assets/` | Brand mark (carrot SVG fallback). No logos or photography in upstream repo. |
| `preview/` | Card files registered into the Design System tab — colors, type, components, etc. |
| `ui_kits/public-web/` | High-fidelity recreation of the public-facing surface (home, login, register, search). One UI kit only — same Flutter binary powers everything, and the authenticated/admin views are out of scope for visual prototyping until requested. |

### UI kits

- **`ui_kits/public-web/`** — Public surface (`/`, `/login`, `/register`, `/amap-search`). Includes `index.html` (interactive prototype) plus a React component file per screen.

There is intentionally **no** authenticated-app kit yet. Producer/admin/coordinator screens are dense and procedural; a separate kit can be built on request once we have visual direction beyond Material 3 defaults.

---

## Caveats

- **No designed typeface.** Roboto is the Material 3 default; the codebase ships it as-is. If a custom face is desired, this is a brand decision pending.
- **No bundled imagery.** Any marketing photography is the user's to supply.
- **Material 3 defaults dominate.** Most of the "design system" is whatever Flutter Material 3 produces from a green seed. Strong custom direction (a real brand) would require designer input.
- **Logo not yet in upstream code.** The `Le Panier` SVG lives in this design system at `assets/logo.svg`; the Flutter app still references the 🥕 emoji.
