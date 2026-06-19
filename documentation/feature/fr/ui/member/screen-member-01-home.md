# Tableau de bord Membre AMAP

## Description
Interface d'accueil personnalisée pour les membres Amap, présentant les informations essentielles et les actions rapides pour l'inscription bénévole.

> **📋 Référence** : Structure détaillée dans `../../../../architecture/data-model.md` - Section DELIVERY, MEMBER_SLOT, CONTRACT.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                      🥕 Amap Livraisons                     │
├─────────────────────────────────────────────────────────────┤
│  👤 Bonjour Marie Dupont                        📱 [Menu]   │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  🎯 Ma prochaine participation                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 31 Jan • 18h-20h                          │ │
│  │  ✅ Inscrit(e) - Préparation paniers                   │ │
│  │  👥 5/5 bénévoles confirmés • [SE DÉSINSCRIRE] ❌       │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📋 Prochaines livraisons                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 17 Jan • 18h-20h                          │ │
│  │  ⚠️ Besoin urgent de bénévoles                          │ │
│  │  👥 2/5 bénévoles • [S'INSCRIRE] 🔴                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 31 Jan • 18h-20h                          │ │
│  │  ✅ Inscrit(e) - Préparation paniers                   │ │
│  │  👥 5/5 bénévoles confirmés • [SE DÉSINSCRIRE] ❌       │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📊 Mon historique                                          │
│  • 8 participations cette saison                           │
│  • Dernière participation : 3 Jan 2025                     │
│                                                             │
│ [📅 VOIR PLANNING COMPLET]    [📋 MON HISTORIQUE]          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[S'INSCRIRE]** : Inscription immédiate au créneau bénévole (action en un clic)
- **[SE DÉSINSCRIRE]** : Désinscription immédiate du créneau bénévole (action en un clic)
- **[VOIR PLANNING COMPLET]** : Navigation vers le planning des livraisons ([Planning](screen-member-02-delivery-plan.md))
- **[MON HISTORIQUE]** : Navigation vers l'historique personnel ([Historique](screen-member-03-history.md))
- **[Menu]** : Accès au menu principal de navigation

### États dynamiques
- **Engagements confirmés** : Affichage en vert avec ✅ et bouton [SE DÉSINSCRIRE]
- **Créneaux disponibles** : Bouton [S'INSCRIRE] disponible
- **Besoin urgent** : Alerte visuelle en rouge 🔴 avec bouton [S'INSCRIRE] prioritaire
- **Complet** : État validé avec information claire, pas d'action possible

### Données affichées
- Informations personnalisées du membre connecté
- Prochains engagements bénévoles avec options de désinscription
- Créneaux nécessitant des bénévoles avec inscription immédiate
- Statistiques personnelles de participation

### Notifications et préférences
- **Gestion des rappels** : Configuration dans les préférences utilisateur (`../common/screen-common-02-user-preferences.md`)
- **Types de notifications** : Rappels 24h/2h avant créneau, alertes d'urgence
- **Confirmation d'actions** : Feedback immédiat après inscription/désinscription

## Références

### Documentation liée
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md) - Section "Écran d'accueil Amapien"
- **Données** : `../../../../architecture/data-model.md` - Entités MEMBER, MEMBER_SLOT, DELIVERY
- **Navigation** : [Planning](screen-member-02-delivery-plan.md) et [Historique](screen-member-03-history.md)
- **Préférences** : [`../common/screen-common-02-user-preferences.md`](../common/screen-common-02-user-preferences.md)
