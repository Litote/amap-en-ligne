# Dashboard Coordinateur

## Description

Interface d'accueil du rôle `COORDINATOR` (*COORDINATOR*) pour la gestion des livraisons (*DELIVERY*) de l'AMAP. Ce tableau de bord est rendu par le composant `CoordinatorDashboardSection`, lui-même composé dans l'écran unifié ([Tableau de bord unifié](../common/screen-common-04-dashboard.md)).

Les données affichées proviennent en temps réel du flux `OrganizationRepository.watch(organizationId)`.

## Wireframe ASCII

```
┌─────────────────────────────────────────────────────────────┐
│                 Tableau de bord                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [ ➕ NOUVELLE LIVRAISON ]                                  │
│                                                             │
│  (si aucune livraison en cours ni à venir :)               │
│  Aucune livraison active.                                   │
│                                                             │
│  (sinon :)                                                  │
│  Livraisons en cours                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Mercredi 17 janvier • 18h00                        │   │
│  │  🔴 En cours                                        │   │
│  │  2/5 bénévoles                                      │   │
│  │  👥 Coordinateurs : 🥕 Jean Morel · 🍞 Claire Petit │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  Prochaines livraisons                                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Mercredi 24 janvier • 18h00                        │   │
│  │  Confirmée                                          │   │
│  │  5/5 bénévoles                                      │   │
│  │  👥 Coordinateurs : 🥕 Jean Morel · 🍞 —            │   │
│  │     ⚠️ Coordinateur manquant : Pain artisanal       │   │
│  │     [ME PORTER COORDINATEUR]                         │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  …                                                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Bouton d'action

**`[➕ NOUVELLE LIVRAISON]`** (FilledButton) — toujours affiché en premier, avant les listes de livraisons.

### État vide

Si aucune livraison n'est en cours ni prévue, la mention « Aucune livraison active. » est affichée à la place des listes.

### Livraisons en cours

Section « Livraisons en cours » : présente uniquement si au moins une livraison a le statut `inProgress` (`DELIVERY.status == inProgress`).

### Prochaines livraisons

Section « Prochaines livraisons » : les 5 prochaines livraisons futures dont le statut est actif (hors `inProgress`) et la date est postérieure à maintenant, triées par date croissante.

### Carte de livraison

Chaque carte de livraison (*DELIVERY*) affiche :

- **Titre** : date formatée en français (`EEEE d MMMM • HH'h'mm`, première lettre en majuscule), par exemple « Mercredi 17 janvier • 18h00 ».
- **Chip de statut** :
  - `🔴 En cours` (rouge) — statut `inProgress`
  - `Confirmée` (vert) — statut `confirmed`
  - `Planifiée` (bleu) — statut `planned`
  - libellé brut en gris — tout autre statut
- **Sous-titre** : « N/M bénévoles » où N est la somme des inscriptions actuelles (`currentRegistrations`) et M la somme des bénévoles requis (`requiredVolunteers`) sur l'ensemble des livraisons (*slots*) de tous les contrats (*contracts*) de la livraison lorsqu'un détail par livraison existe ; sinon, M reprend le minimum de bénévoles configuré sur la livraison.
- **Ligne Coordinateurs** : pour chaque livraison-contrat (*DELIVERY_CONTRACT*), affiche le nom du produit suivi de la liste des coordinateurs (séparés par `·`). Une livraison-contrat sans coordinateur affiche `—`.
- **Bandeau d'alerte** « ⚠️ Coordinateur manquant : <produits> » : visible si au moins une livraison-contrat a `coordinators.isEmpty()` et que la livraison est encore active.
- **Action [ME PORTER COORDINATEUR]** : visible uniquement quand la livraison est active et qu'au moins une livraison-contrat n'a pas de coordinateur. Ouvre un sélecteur permettant de choisir le contrat sur lequel se positionner. L'utilisateur connecté est ajouté à la liste `coordinators` du contrat choisi via une mutation sync (*Upsert(OrganizationPayload)*).
- **Action [Suivre]** : bouton explicite (aligné à droite, en bas de la carte) ouvrant l'écran de suivi de la distribution. Redondant avec le tap sur la carte entière, conservé pour rendre l'action visible. Cette section n'étant rendue que pour les coordinateurs (*COORDINATOR*), le bouton est par construction réservé à ce rôle.

### État de chargement

Pendant le chargement de l'organisation depuis le cache local, un `CircularProgressIndicator` est affiché à la place du contenu.

## Navigation et interactions

| Contrôle | Cible | Comportement |
|----------|-------|--------------|
| `[➕ NOUVELLE LIVRAISON]` | `/coordinator/time-slots/new` | Navigation directe vers le formulaire de création d'une livraison dans la gestion des livraisons ([Écran 2](screen-coordinator-02-time-slots.md)) |
| Carte de livraison | `/coordinator/tracking/:deliveryId` | Ouvre l'écran de suivi de livraison ([Écran 4](screen-coordinator-04-delivery-tracking.md)) |
| `[Suivre]` (carte de livraison) | `/coordinator/tracking/:deliveryId` | Bouton explicite ouvrant le même écran de suivi de livraison ([Écran 4](screen-coordinator-04-delivery-tracking.md)) |
| `[ME PORTER COORDINATEUR]` (carte de livraison) | reste sur le dashboard | Affiche un sélecteur listant les livraisons-contrats sans coordinateur, ajoute l'utilisateur connecté à `coordinators` du contrat choisi puis ferme le sélecteur |

## Références

- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
- **Écran unifié contenant cette section** : [`../common/screen-common-04-dashboard.md`](../common/screen-common-04-dashboard.md)
- **Gestion des livraisons** : [`screen-coordinator-02-time-slots.md`](screen-coordinator-02-time-slots.md)
