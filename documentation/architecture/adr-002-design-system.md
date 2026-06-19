# ADR-002 — Design System: Material 3 with Le Panier Brand

## Status

Accepted

## Context

The Flutter client ships as a single binary targeting Android, iOS and Web. There is no dedicated design team. The app's visual surface is whatever Flutter's Material 3 system produces from a seed colour, and prior to this decision two gaps existed:

1. **No canonical brand mark** — the home screen used a 🥕 emoji (48 px) as a placeholder logo.
2. **No documented visual conventions** — contributors improvised per-screen styling, producing gradual inconsistency across screens and making future visual work hard to brief.

The target audience is French AMAP coordinators and producers, for whom an accessible, low-friction tool matters more than a distinctive visual identity. A workmanlike Material 3 look is therefore intentional, not a gap.

## Decision

### 1. Theme

`ColorScheme.fromSeed(seedColor: Colors.green) + useMaterial3: true` is the single theme for the entire app (wired in `front/lib/main.dart`). No additional `ThemeData` overrides. This produces a coherent warm-green M3 token set — primary tones, surface tones, error colours — without manual maintenance.

### 2. Home-screen action button colours

Three named Material constants are used on `HomeScreen` action cards, intentionally overriding the seeded primary to distinguish the three entry paths visually:

| Path | Label | Color |
|------|-------|-------|
| Login | SE CONNECTER | `Colors.green` (`#4CAF50`) |
| Join an AMAP | S'INSCRIRE À UNE AMAP | `Colors.blue` (`#2196F3`) |
| Create organisation | INSCRIVEZ-VOUS | `Colors.orange` (`#FF9800`) |

These raw `Colors.*` overrides are scoped exclusively to the home screen. They must not propagate to other screens, which rely on the M3 seed roles.

### 3. Brand mark — Le Panier

The official brand mark is **Le Panier**: a woven basket containing an eggplant, a carrot and a tomato. SVG assets live in `front/assets/`:

- `logo.svg` — square mark, 96×96 viewBox.
- `wordmark.svg` — horizontal lockup: Le Panier mark + "Amap en Ligne" logotype, 380×96 viewBox.

The home screen header displays the wordmark SVG (replacing the 🥕 placeholder). SVG rendering requires the `flutter_svg` production dependency. Both assets are declared in `pubspec.yaml` under `flutter.assets`.

### 4. Design skill

The full design reference — colour tokens, type scale, component rules, brand voice, HTML preview files, and a UI kit for the public surface — lives in:

```
front/.claude/skills/amap-en-ligne-design/
```

Any agent or contributor modifying a screen must read `SKILL.md` before starting. The visual charter for contributors is documented in French at `documentation/feature/fr/ui/charte-graphique.md`.

## Consequences

- `flutter_svg` is added as a production dependency.
- App icons (Android mipmap, iOS `AppIcon.appiconset`, Web `icons/`) are replaced with rasterised exports from `logo.svg`.
- Golden screenshots are regenerated on macOS whenever the home screen header changes.
- The 🥕 emoji is removed from the codebase.
- No custom fonts, gradients, full-bleed imagery or non-Material animations are introduced — M3 defaults cover everything else.

## References

- Design skill: `front/.claude/skills/amap-en-ligne-design/README.md`
- Visual charter: `documentation/feature/fr/ui/charte-graphique.md`
- Flutter theme: `front/lib/main.dart` (`_AmapEnLigneAppState.build`)
- Home screen header: `front/lib/presentation/home/home_screen.dart` (`_Header`)
