---
name: amap-en-ligne-design
description: Use this skill to generate well-branded interfaces and assets for Amap en Ligne — a French open-source AMAP / CSA (Community-Supported Agriculture) management app — either for production or throwaway prototypes/mocks. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping. Use whenever building any visual artifact for Amap en Ligne (slides, mockups, prototypes, marketing pages, in-product UI).
user-invocable: true
---

Read the `README.md` file within this skill, and explore the other available files.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. The single source of truth for color and type tokens is `colors_and_type.css` — import it into any HTML you write rather than duplicating values.

If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand. The upstream codebase is Flutter (Dart) with Material 3, so production work generally means **mirroring Material 3 defaults with a `Colors.green` seed and Roboto** rather than diverging into custom widgets.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

## Quick reference

- **Language:** French. UI chrome, errors, microcopy — all French.
- **Voice:** Direct, warm, short sentences. First-person on the home screen ("J'ai déjà un compte"), formal **vous** elsewhere.
- **Brand mark:** **Le Panier** — a woven basket containing an eggplant, a carrot, and a tomato. SVG at `assets/logo.svg` (square, 96×96 viewBox) and `assets/wordmark.svg` (horizontal lockup with the wordmark in Roboto). Use the logo at 32px or larger; below 24px the produce inside the basket loses legibility.
- **Type:** Roboto (Material 3 default). 400 / 500 / 700.
- **Action colors:**
  - Primary green `#4CAF50` — login / confirm
  - Secondary blue `#2196F3` — "join an AMAP"
  - Tertiary orange `#FF9800` — "create an organization"
- **Buttons:** Pill-shape (`border-radius: 9999px`), ALL-CAPS labels with `letter-spacing: 0.5`.
- **Cards:** White surface, 12px radius, subtle elevation, 16px inner padding.
- **Form fields:** `OutlineInputBorder` style — 4px radius, floating labels.
- **Iconography:** Material Symbols Outlined (Material Icons in Flutter). No custom icon set.
- **No imagery, no gradients, no patterns.** The look is workmanlike Material 3.

## What's in this skill

- `README.md` — full design system documentation
- `colors_and_type.css` — CSS custom properties for color + type tokens. Import this.
- `assets/` — `logo.svg` (Le Panier mark) and `wordmark.svg` (horizontal lockup with the wordmark in Roboto)
- `preview/` — design-system cards (one HTML per concept; useful as reference)
- `ui_kits/public-web/` — high-fidelity React recreation of the public surface (home / login / register / search) — use as starting point for any prototype targeting public-facing screens
