# Tableau de bord unifié (MixedDashboardScreen)

## Description

Écran d'accueil unifié (*MixedDashboardScreen*) pour les membres AMAP qui cumulent un ou plusieurs rôles contextuels : **BÉNÉVOLE** (*VOLUNTEER*), **COORDINATEUR** (*COORDINATOR*) et/ou **ADMIN** (*ADMIN*).

| Attribut | Valeur |
|----------|--------|
| Route | `/dashboard` |
| Titre AppBar | **Tableau de bord** (invariant, quel que soit le nombre de rôles) |
| Acteurs | Tout membre AMAP authentifié portant au moins l'un des rôles : VOLUNTEER, COORDINATOR, ADMIN |

Les rôles plateforme OWNER et PRODUCER n'accèdent pas à cet écran — ils disposent de dashboards dédiés (`/owner/dashboard` et `/product-types`).

## Wireframe ASCII

### Variante mono-rôle (exemple : ADMIN seul)

Lorsqu'un seul rôle AMAP est détenu, aucun en-tête de section n'est affiché — le contenu de la section occupe directement l'espace disponible sous l'AppBar.

```
┌─────────────────────────────────────────────┐
│ ☰  Tableau de bord                          │
├─────────────────────────────────────────────┤
│                                             │
│  Accès rapides                              │
│  ┌──────────────────────────────────────┐   │
│  │ 👤 Utilisateurs              ›       │   │
│  ├──────────────────────────────────────┤   │
│  │ 🌾 Producteurs               ›       │   │
│  ├──────────────────────────────────────┤   │
│  │ 🔁 Templates de livraison    ›       │   │
│  ├──────────────────────────────────────┤   │
│  │ ⚙️  Préférences               ›       │   │
│  ├──────────────────────────────────────┤   │
│  │ 👤 Demandes d'adhésion       ›       │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌── Alertes ──────────────────────────┐   │
│  │  Aucune alerte en cours.            │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌── Synthèse ─────────────────────────┐   │
│  │  Membres actifs          42         │   │
│  │  Coordinateurs            3         │   │
│  │  Producteurs actifs       5         │   │
│  └──────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

### Variante multi-rôles (exemple : BÉNÉVOLE + COORDINATEUR + ADMIN)

Lorsque l'utilisateur détient au moins 2 rôles AMAP, chaque section est précédée d'un en-tête centré libellé `— Bénévole —`, `— Coordinateur —` ou `— Admin —`. Les sections s'empilent dans l'ordre VOLUNTEER → COORDINATOR → ADMIN (même ordre que le menu de navigation).

```
┌─────────────────────────────────────────────┐
│ ☰  Tableau de bord                          │
├─────────────────────────────────────────────┤
│                                             │
│              — Bénévole —                   │
│                                             │
│  Prochaines livraisons                      │
│  ┌──────────────────────────────────────┐   │
│  │  Mercredi 17 Jan                     │   │
│  │  🔴 Besoin urgent de bénévoles       │   │
│  │  👥 Coord. : 🥕 J. Morel · 🍞 —      │   │
│  ├──────────────────────────────────────┤   │
│  │  Mercredi 31 Jan                     │   │
│  │  👥 Coord. : 🥕 C. Petit · 🍞 M.O.   │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  Mon historique                             │
│  8 livraisons passées cette saison          │
│                                             │
│  [ VOIR PLANNING ]   [ MON HISTORIQUE ]     │
│                                             │
│              — Coordinateur —               │
│                                             │
│  [ ➕ NOUVEAU CRÉNEAU ]                     │
│                                             │
│  Livraisons en cours                        │
│  ┌──────────────────────────────────────┐   │
│  │  Mercredi 17 Jan • 18h00            │   │
│  │  🔴 En cours  2/5 bénévoles         │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  Prochaines livraisons                      │
│  ┌──────────────────────────────────────┐   │
│  │  Mercredi 24 Jan • 18h00            │   │
│  │  Confirmée  5/5 bénévoles           │   │
│  │  👥 Coord. : 🥕 J. Morel · 🍞 —      │   │
│  │  ⚠️ Coordinateur manquant : Pain     │   │
│  │  [ME PORTER COORDINATEUR]            │   │
│  └──────────────────────────────────────┘   │
│                                             │
│                — Admin —                    │
│                                             │
│  Accès rapides                              │
│  ┌──────────────────────────────────────┐   │
│  │ 👤 Utilisateurs              ›       │   │
│  │ …                                    │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌── Alertes ──────────────────────────┐   │
│  │  • 1 producteur suspendu            │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌── Synthèse ─────────────────────────┐   │
│  │  Membres actifs          42         │   │
│  │  Coordinateurs            3         │   │
│  │  Producteurs actifs       5         │   │
│  └──────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

## Contenu et comportement

### Règle d'affichage des en-têtes de section

L'en-tête de section (`— Bénévole —`, `— Coordinateur —`, `— Admin —`) est affiché **uniquement si l'utilisateur détient au moins 2 rôles AMAP**. En cas de rôle unique, la section s'affiche sans intitulé.

### Ordre des sections

Les sections sont toujours empilées dans l'ordre suivant, identique au menu de navigation :

1. VOLUNTEER (Bénévole)
2. COORDINATOR (Coordinateur)
3. ADMIN (Admin)

Seules les sections correspondant aux rôles effectivement détenus sont rendues.

### Section Bénévole (VOLUNTEER)

Voir la spécification complète dans [`../member/screen-member-01-home.md`](../member/screen-member-01-home.md).

Blocs principaux :

- **Prochaines livraisons** : liste des 3 prochaines livraisons actives triées par date croissante, chacune affichant la date formatée (ex. « Mercredi 17 janvier ») et, le cas échéant, un badge d'urgence calculé depuis le taux de remplissage des créneaux bénévoles :
  - `✅ Complet` — taux ≥ 100 %
  - (pas de badge) — taux compris entre 80 % et 100 %
  - `⚠️ Places limitées` — taux compris entre 50 % et 80 %
  - `🔴 Besoin urgent de bénévoles` — taux < 50 %
- **Ligne Coordinateurs** : sous le badge d'urgence, chaque carte liste les coordinateurs (*COORDINATOR*) de la livraison regroupés par contrat (*DELIVERY_CONTRACT*). Format compact `🥕 J. Morel · 🍞 —` (initiale + nom abrégé pour gagner de la place ; `—` quand la livraison-contrat n'a pas de coordinateur). Sans interaction sur cet écran : le `tel:` est exposé sur le planning (*screen-member-02*) et le suivi de livraison (*screen-coordinator-04*).
- **Mon historique** : nombre de livraisons au statut `completed` de la saison en cours, suivi de deux boutons `[VOIR PLANNING]` et `[MON HISTORIQUE]`.
- Si aucune livraison à venir n'existe, la mention « Aucune livraison à venir. » est affichée à la place de la liste.

### Section Coordinateur (COORDINATOR)

Voir la spécification complète dans [`../coordinator/screen-coordinator-01-home.md`](../coordinator/screen-coordinator-01-home.md).

Blocs principaux :

- **Bouton `[➕ NOUVEAU CRÉNEAU]`** (FilledButton) : affiché en premier, navigue vers `/coordinator/time-slots`.
- **Livraisons en cours** (`inProgress`) : cartes affichant la date, le statut et le ratio de remplissage. Cliquables vers le suivi de livraison.
- **Prochaines livraisons** (`upcoming`) : les 5 prochaines livraisons actives triées par date croissante. Cliquables vers le suivi de livraison.
- **Ligne Coordinateurs** sur chaque carte : liste les coordinateurs par livraison-contrat (`🥕 J. Morel · 🍞 —`). Une carte affichant au moins un contrat sans coordinateur expose le bandeau `⚠️ Coordinateur manquant : <contrats>` et le bouton `[ME PORTER COORDINATEUR]` (voir [Dashboard coordinateur](../coordinator/screen-coordinator-01-home.md) pour le détail du sélecteur).
- Si aucune livraison en cours ni prochaine, affiche « Aucune livraison active. ».
- Pendant le chargement de l'organisation, un indicateur de progression (`CircularProgressIndicator`) est affiché.

### Section Admin (ADMIN)

Voir la spécification complète dans [`../admin/screen-admin-01-home.md`](../admin/screen-admin-01-home.md).

Blocs principaux :

- **Accès rapides** : liste de tuiles cliquables conduisant aux écrans de gestion.
- **Alertes** : carte listant les anomalies détectées (ex. producteurs suspendus). Si aucune anomalie, affiche « Aucune alerte en cours. ».
- **Synthèse** : carte présentant 3 compteurs issus du cache local — membres actifs, coordinateurs, producteurs actifs.

Les données de la section Admin sont alimentées en temps réel depuis les flux `MemberRepository.watch(organizationId)` et `OrganizationRepository.watch(organizationId)`.

### État de chargement

Pendant la synchronisation initiale, les sections Bénévole et Coordinateur affichent un `CircularProgressIndicator` jusqu'à ce que l'organisation soit disponible dans le cache local. La section Admin affiche immédiatement un état vide (0 membres, 0 producteurs) puis se met à jour à la réception des données.

### État « aucun rôle »

Si l'utilisateur ne détient aucun rôle AMAP (cas transitoire possible juste après l'activation), l'écran affiche le titre AppBar « Tableau de bord » sans aucune section de contenu.

## Navigation et interactions

| Contrôle | Section | Cible | Comportement |
|----------|---------|-------|--------------|
| `[➕ NOUVEAU CRÉNEAU]` | Coordinateur | `/coordinator/time-slots` | Navigation directe |
| Carte de livraison (coordinateur) | Coordinateur | `/coordinator/tracking/:deliveryId` | Navigation vers le suivi de livraison ([Écran 4](../coordinator/screen-coordinator-04-delivery-tracking.md)) |
| Tuile « Utilisateurs » | Admin | `/members` | Navigation vers la gestion des membres AMAP |
| Tuile « Producteurs » | Admin | `/admin/producers` | Navigation vers la gestion des producteurs |
| Tuile « Templates de livraison » | Admin | `/admin/delivery-templates` | Navigation vers les templates de livraison |
| Tuile « Préférences » | Admin | `/preferences` | Navigation vers les préférences utilisateur |
| Tuile « Demandes d'adhésion » | Admin | `/admin/membership-requests` | Navigation vers les demandes d'adhésion |
| `[VOIR PLANNING]` | Bénévole | `/planning` | Navigation vers le planning des livraisons |
| `[MON HISTORIQUE]` | Bénévole | `/history` | Navigation vers l'historique personnel |
| `[ME PORTER COORDINATEUR]` | Coordinateur | reste sur le dashboard | Affiche un sélecteur listant les livraisons-contrats sans coordinateur ; valide l'auto-affectation via mutation sync (cf. [Dashboard coordinateur](../coordinator/screen-coordinator-01-home.md)) |

## Règles métier

### Périmètre des rôles AMAP vs rôles plateforme

Cet écran est réservé aux rôles contextuels AMAP. Les rôles plateforme suivent des routes dédiées et ne passent jamais par `/dashboard` :

| Rôle | Route d'atterrissage |
|------|---------------------|
| OWNER | `/owner/dashboard` |
| PRODUCER | `/product-types` |
| VOLUNTEER, COORDINATOR, ADMIN, ou MEMBER_NO_ROLE | `/dashboard` |

### Ordre d'affichage et déduplication

L'ordre d'empilement (VOLUNTEER → COORDINATOR → ADMIN) est déterminé statiquement à partir des rôles de la session courante (`AuthBloc.state.memberRoles`). Si un rôle est détenu mais n'appartient pas à l'ensemble `{VOLUNTEER, COORDINATOR, ADMIN}` (ex. OWNER ou PRODUCER), il est ignoré sans générer de section.

### Isolation par organisation

Les sections Bénévole et Coordinateur s'appuient sur l'`organizationId` dérivé de la session (`producerAccountId`) pour filtrer les livraisons de l'AMAP courante. Un membre ne voit jamais les données d'une autre AMAP.

## Références

- [`../spec-ui.md`](../spec-ui.md) — conventions UI globales
- [`../member/screen-member-01-home.md`](../member/screen-member-01-home.md) — section Bénévole (détail complet)
- [`../coordinator/screen-coordinator-01-home.md`](../coordinator/screen-coordinator-01-home.md) — section Coordinateur (détail complet)
- [`../admin/screen-admin-01-home.md`](../admin/screen-admin-01-home.md) — section Admin (détail complet)
- [`screen-common-01-menu.md`](screen-common-01-menu.md) — libellés et ordre du menu de navigation
