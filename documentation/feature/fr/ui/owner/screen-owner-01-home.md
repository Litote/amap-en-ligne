# Dashboard Owner

## Description

Interface d'accueil du rôle `OWNER` pour piloter l'instance, avec un accès prioritaire au traitement des demandes d'organisation (AMAP et Producteurs).

## Wireframe ASCII

```
┌─────────────────────────────────────────────────────────────┐
│             Administrateur Instance · Tableau de bord        │
├─────────────────────────────────────────────────────────────┤
│  Alice Martin (Admin Instance)                      [Menu]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Demandes en attente                                        │
│  5 demandes à traiter (AMAP + Producteurs)                  │
│  [VOIR LES DEMANDES]                                        │
│                                                             │
│  Vue instance                                               │
│  - Organisations actives : 12                               │
│  - Demandes ce mois : 9                                     │
│  - Demandes refusées ce mois : 2                            │
│                                                             │
│  ──────────────────────────────────────────────────────     │
│                                                             │
│  Demandes d'organisation                                    │
│  Gestion des utilisateurs                                   │
│  Nouvel Administrateur                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

| Élément | Comportement |
|---------|-------------|
| **[VOIR LES DEMANDES]** | Navigue vers `screen-owner-02-organization-requests.md`, onglet AMAP actif par défaut |
| **Demandes d'organisation** | Navigue vers `screen-owner-02-organization-requests.md`, onglet AMAP actif |
| **Gestion des utilisateurs** | Navigue vers `screen-owner-03-user-management.md` |
| **Nouvel Administrateur** | Navigue vers `screen-owner-04-invite-owner.md` (formulaire d'invitation d'un nouvel Owner) |

Le badge "Demandes en attente" affiche le nombre combiné de demandes au statut `PENDING_VALIDATION` tous types confondus (AMAP + Producteurs).

## Références

- **Écran suivant** : [`screen-owner-02-organization-requests.md`](screen-owner-02-organization-requests.md)
- **Gestion des utilisateurs de l'instance** : [`screen-owner-03-user-management.md`](screen-owner-03-user-management.md)
- **Invitation d'un nouvel Owner** : [`screen-owner-04-invite-owner.md`](screen-owner-04-invite-owner.md)
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
