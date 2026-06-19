# Participations globales

## Description

Écran anonymisé de positionnement de l'Amapien dans la dynamique de participation de son AMAP sur la saison courante. Il affiche uniquement la position de l'utilisateur connecté et une répartition agrégée des membres ; les noms des autres membres ne sont jamais exposés.

L'écran est accessible depuis le bouton **[🏆 Participations globales]** du footer de l'écran [Historique des participations](screen-member-03-history.md).

## Wireframe ASCII

```
┌─────────────────────────────────────────────────────────────┐
│               🏆 Participations globales                    │
├─────────────────────────────────────────────────────────────┤
│  [← Retour]                                  Saison 2025   │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  📍 Ma position                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Vous êtes 3ème ex-aequo / 7 membres actifs             │ │
│  │  📈 Mes participations cette saison : 4                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📊 Répartition des membres actifs                          │
│  Actifs (≥5)        : ■■       (2 membres)                  │
│  Occasionnels (1-4) : ■■■      (3 membres)  ← vous          │
│  Inactifs (0)       : ■■       (2 membres)                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

| Contrôle | Cible | Comportement |
|----------|-------|--------------|
| `[← Retour]` | `/history` | Retour à l'écran Historique des participations ([Historique](screen-member-03-history.md)) |

Aucune autre action n'est disponible sur cet écran.

## Règles métier

### Périmètre de la saison courante
- La saison courante est définie de manière identique à l'écran Historique : l'année (`season_year`) la plus élevée parmi les contrats (*CONTRACT*) de statut `ACTIVE`. Le bandeau affiche « Saison \<année\> ».
- Seules les participations rattachées aux contrats de la saison courante entrent dans les calculs.

### Dénominateur et membres pris en compte
- Le dénominateur est le nombre de membres (*MEMBER*) ayant le statut `ACTIVE` au sein de l'organisation.

### Rang et ex-aequo
- Le classement utilise un **classement standard** : les membres ayant le même nombre de participations partagent le même rang.
- Affichage sans ex-aequo : « Vous êtes 3ème / 7 membres actifs »
- Affichage avec ex-aequo : « Vous êtes 3ème ex-aequo / 7 membres actifs »
- Cas où personne n'a participé : « Vous êtes 1er ex-aequo / N membres actifs »

### Paliers de la répartition
Les membres actifs (*ACTIVE*) sont répartis en trois catégories selon le nombre de participations confirmées sur la saison courante :

| Catégorie | Seuil | Libellé affiché |
|-----------|-------|-----------------|
| Actifs | ≥ 5 participations | « Actifs (≥5) » |
| Occasionnels | 1 à 4 participations | « Occasionnels (1-4) » |
| Inactifs | 0 participation | « Inactifs (0) » |

Ces paliers sont identiques à ceux utilisés pour le statut d'activité sur l'écran Historique.

### Vie privée — anonymat des autres membres
- Aucune donnée nominative d'un autre membre n'est affichée (ni nom, ni prénom, ni rang individuel).
- La flèche « ← vous » positionne l'utilisateur dans la bonne catégorie de répartition sans révéler les identités des autres.

## Références

- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
- **Historique des participations** : [`screen-member-03-history.md`](screen-member-03-history.md)
- **Données** : `../../../../architecture/data-model.md` - Entités MEMBER, MEMBER_SLOT, CONTRACT
