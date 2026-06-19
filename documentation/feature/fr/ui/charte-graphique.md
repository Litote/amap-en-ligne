# Charte graphique

> Référence visuelle pour les contributeurs à l'interface d'Amap en Ligne.
> La source de vérité complète (tokens CSS, assets SVG, UI kit, aperçus HTML) se trouve dans `front/.claude/skills/amap-en-ligne-design/`.

---

## Marque

### La marque «&nbsp;Le Panier&nbsp;»

Le logo officiel est **Le Panier** : un panier tressé contenant une aubergine, une carotte et une tomate. Il est disponible en deux variantes :

| Fichier | Usage | Dimensions |
|---------|-------|------------|
| `front/assets/logo.svg` | Icône carrée seule (app icon, favicon) | 96×96 px viewBox |
| `front/assets/wordmark.svg` | Lockup horizontal — panier + logotype «&nbsp;Amap en Ligne&nbsp;» | 380×96 px viewBox |

**Règles d'usage :**
- Ne jamais utiliser le logo en dessous de 32&nbsp;px — le détail des légumes devient illisible sous 24&nbsp;px.
- Le wordmark s'utilise à la place du logo+texte séparés dans l'en-tête de l'écran d'accueil.
- Aucun autre emoji ou illustration ne doit faire office de logo (le 🥕 est supprimé).

---

## Palette de couleurs

L'application utilise le thème Material 3 généré depuis `ColorScheme.fromSeed(seedColor: Colors.green)`. Tous les écrans authentifiés s'appuient sur les rôles de couleur M3 issus de ce seed (primary, surface, error…). Les exceptions ci-dessous sont strictement limitées à l'écran d'accueil public.

### Couleurs des boutons d'action (écran d'accueil uniquement)

| Action | Couleur | Valeur hex | Rôle |
|--------|---------|-----------|------|
| SE CONNECTER | `Colors.green` | `#4CAF50` | Primaire — connexion |
| S'INSCRIRE À UNE AMAP | `Colors.blue` | `#2196F3` | Secondaire — rejoindre |
| INSCRIVEZ-VOUS | `Colors.orange` | `#FF9800` | Tertiaire — créer |

Ces constantes nommées ne doivent pas être réutilisées en dehors de l'écran d'accueil.

### Couleurs sémantiques M3

Partout ailleurs, utiliser exclusivement les rôles du `ColorScheme` fourni par le contexte :
- `colorScheme.primary` — actions principales, liens, en-têtes de section
- `colorScheme.error` — messages d'erreur, états invalides
- `colorScheme.surface` / `surfaceContainerLow` — fonds de cartes
- `colorScheme.onSurface` / `onSurfaceVariant` — texte principal / secondaire

---

## Typographie

**Police :** Roboto — police par défaut de Material 3 sur Flutter (Android, iOS, Web). Aucune police personnalisée n'est chargée via `google_fonts`.

**Échelle de type :** Défauts Material 3. Les écrans utilisent principalement :

| Rôle | Taille | Usage |
|------|--------|-------|
| `titleLarge` | 22&nbsp;px | Titres d'écran |
| `titleMedium` | 16&nbsp;px | Titres de cartes |
| `bodyMedium` | 14&nbsp;px | Corps de texte |
| `bodySmall` | 12&nbsp;px | Texte mutté, aide |
| `labelLarge` | 14&nbsp;px | Labels de boutons |

**Casse des labels de boutons :** `ALL CAPS` avec `letterSpacing` standard. Exemples : `SE CONNECTER`, `S'INSCRIRE`, `ANNULER`, `CRÉER`.

**En-têtes de section dans les formulaires :** `ALL CAPS`, couleur `colorScheme.primary`. Exemple : `INFORMATIONS ORGANISATION`, `COMPTE ADMINISTRATEUR DE L'ORGANISATION`.

---

## Composants

### Boutons

| Type | Usage | Style |
|------|-------|-------|
| `FilledButton` | Action principale | Fond coloré, forme pill (~20&nbsp;px radius), label ALL CAPS |
| `OutlinedButton` | Action secondaire | Contour, fond transparent — `ANNULER`, `RETOUR À L'ACCUEIL` |
| `TextButton` | Action tertiaire | Texte seul, couleur primary — `Mot de passe oublié ?` |

Un `CircularProgressIndicator` (18×18&nbsp;px, `strokeWidth: 2`) remplace le label pendant le chargement d'un `FilledButton`.

### Cartes

`Card` Material 3 par défaut : surface `surfaceContainerLow`, rayon ~12&nbsp;px, ombre de niveau 1. Padding intérieur : `EdgeInsets.all(16)`. Les cartes de l'écran d'accueil contiennent un titre (`titleMedium`), un sous-titre (`bodyMedium`) et un `FilledButton` en bas.

### Champs de formulaire

`OutlineInputBorder` universel — contour 1&nbsp;px, rayon ~4&nbsp;px, label flottant. Les champs non-texte (listes déroulantes, sélecteurs) s'enveloppent dans `InputDecorator` pour garder le même chrome visuel.

### Espacements

Rythme 8&nbsp;pt : 4 / 8 / 12 / 16 / 24 / 32&nbsp;px.
- `SizedBox(height: 16)` entre cartes sur la page d'accueil
- `SizedBox(height: 24)` entre groupes de champs dans les formulaires
- `SizedBox(height: 12)` entre champs consécutifs
- `Padding` interne des formulaires : `EdgeInsets.all(24)`
- Largeur maximale des formulaires centrés : 400&nbsp;px (login) / 480&nbsp;px (création organisation)

---

## Voix et ton

**Langue :** Français. Toujours. Y compris les messages d'erreur et la microcopy.

**Personne grammaticale :**
- Première personne (**je**) sur les cartes d'action de l'écran d'accueil : «&nbsp;J'ai déjà un compte&nbsp;», «&nbsp;Je veux rejoindre une AMAP&nbsp;».
- **Vous** formel partout ailleurs : «&nbsp;Connectez-vous à votre espace personnel&nbsp;».

**Casse :**
- Labels de boutons → `ALL CAPS`
- En-têtes de section dans les formulaires → `ALL CAPS` + couleur primary
- Titres d'écran, corps de texte → Casse normale (première lettre en majuscule)
- Champs requis → label suivi de ` *` : «&nbsp;Email \*&nbsp;», «&nbsp;Nom de l'AMAP \*&nbsp;»

**Erreurs :** Simples, sans blâme, sans majuscule superflue, sans «&nbsp;Oops&nbsp;».
- ✅ «&nbsp;Email ou mot de passe incorrect.&nbsp;»
- ✅ «&nbsp;Erreur réseau. Vérifiez votre connexion et réessayez.&nbsp;»
- ❌ «&nbsp;Oops ! Une erreur s'est produite.&nbsp;»

**États vides :** Une phrase, sans illustration.
- «&nbsp;Aucun type de produit.&nbsp;»
- «&nbsp;Organisations indisponibles.&nbsp;»

**Ponctuation française :** espace insécable avant `?`, `!`, `:`. Guillemets «&nbsp;français&nbsp;» dans les textes longs (rarement nécessaires dans une UI).

**Emoji :** Uniquement dans le logo (Le Panier SVG). Aucun emoji dans les messages, labels ou états vides.

---

## Ce que le design n'est pas

- **Pas d'images** : aucune photo, illustration ou pattern en fond.
- **Pas de dégradés** : fonds unis, teintes surface M3 uniquement.
- **Pas d'icônes personnalisées** : `Icons.*` Flutter (Material Icons) uniquement — `sync`, `add`, `delete`, `check_circle`, `chevron_right`, `arrow_back`.
- **Pas de typographie personnalisée** : Roboto par défaut, pas d'appel à `GoogleFonts`.
- **Pas d'animations sur mesure** : transitions go_router par défaut, `LinearProgressIndicator` / `CircularProgressIndicator` M3.

---

## Ressource de référence

Le design skill complet est dans `front/.claude/skills/amap-en-ligne-design/`. Il contient :
- `README.md` — documentation complète du système
- `colors_and_type.css` — tokens CSS (source de vérité pour les prototypes HTML)
- `assets/` — SVG logo et wordmark
- `preview/` — fiches HTML consultables par concept (couleurs, boutons, typographie…)
- `ui_kits/public-web/` — recréation haute-fidélité des écrans publics en React

Invoquer la skill `amap-en-ligne-design` avant tout travail sur un écran ou un composant visuel.

---

## Décision d'architecture associée

[ADR-002 — Design System: Material 3 with Le Panier Brand](../../../architecture/adr-002-design-system.md)
