# Dashboard Admin

## Description

Interface d'accueil du rôle `ADMIN` (*ADMIN*) pour accéder aux fonctions de gestion de l'AMAP (*organization*). Ce tableau de bord est rendu par le composant `AdminDashboardSection`, lui-même composé dans l'écran unifié ([Tableau de bord unifié](../common/screen-common-04-dashboard.md)).

Les données affichées (membres, organisation) proviennent en temps réel des flux locaux `MemberRepository.watch(organizationId)` et `OrganizationRepository.watch(organizationId)`.

## Wireframe ASCII

```
┌─────────────────────────────────────────────────────────────┐
│                 Tableau de bord                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Accès rapides                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ 👤 Utilisateurs                              ›       │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ 🌾 Producteurs                               ›       │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ 🔁 Templates de livraison                    ›       │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ ⚙️  Préférences                               ›       │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ 👤 Demandes d'adhésion                       ›       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌── Alertes ──────────────────────────────────────────┐   │
│  │  • 1 producteur(s) suspendu(s)                      │   │
│  │  (ou : "Aucune alerte en cours.")                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌── Synthèse ─────────────────────────────────────────┐   │
│  │  Membres actifs                42                   │   │
│  │  Coordinateurs                  3                   │   │
│  │  Producteurs actifs             5                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Bloc Accès rapides

Cinq tuiles `ListTile` (icône + libellé + chevron), dans cet ordre :

| Ordre | Libellé | Route |
|-------|---------|-------|
| 1 | Utilisateurs | `/members` |
| 2 | Producteurs | `/admin/producers` |
| 3 | Templates de livraison | `/admin/delivery-templates` |
| 4 | Préférences | `/preferences` |
| 5 | Demandes d'adhésion | `/admin/membership-requests` |

### Bloc Alertes

Carte affichant les anomalies détectées. Une seule anomalie est aujourd'hui détectée :

- **Producteurs suspendus** : « N producteur(s) suspendu(s) » si N > 0 (avec accord singulier/pluriel).

Si aucune anomalie, la carte affiche uniquement la mention « Aucune alerte en cours. ».

### Bloc Synthèse

Carte affichant trois compteurs issus du cache local :

- **Membres actifs** : nombre de membres dont `activeStatus = true`.
- **Coordinateurs** : nombre de membres actifs portant le rôle `COORDINATOR`.
- **Producteurs actifs** : nombre de producteurs de l'organisation au statut `active` (`OrganizationProducer.status == active`).

## Navigation et interactions

| Contrôle | Route cible | Écran cible |
|----------|-------------|-------------|
| Tuile « Utilisateurs » | `/members` | [Gestion des membres](screen-admin-03-user-management.md) |
| Tuile « Producteurs » | `/admin/producers` | [Gestion des producteurs](screen-admin-04-producer-management.md) |
| Tuile « Templates de livraison » | `/admin/delivery-templates` | [Templates de livraison](screen-admin-05-delivery-template.md) |
| Tuile « Préférences » | `/preferences` | [Préférences utilisateur](../common/screen-common-02-user-preferences.md) |
| Tuile « Demandes d'adhésion » | `/admin/membership-requests` | [Gestion des demandes d'adhésion](screen-admin-03-user-management.md) |

## Références

- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
- **Écran unifié contenant cette section** : [`../common/screen-common-04-dashboard.md`](../common/screen-common-04-dashboard.md)
