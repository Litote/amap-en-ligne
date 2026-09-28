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
│  │  🌿 Maraîcher Bio + 🥚 Œufs Fermiers                   │ │
│  │  👥 5/5 bénévoles confirmés                            │ │
│  │  🧺 Composition du panier ▼                            │ │
│  │  ✅ Inscrit(e) - Préparation paniers                   │ │
│  │  [SE DÉSINSCRIRE] ❌                                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📋 Prochaines livraisons                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 17 Jan • 18h-20h                          │ │
│  │  🌿 Maraîcher Bio + 🥕 Légumes de saison               │ │
│  │  ⚠️ Besoin urgent de bénévoles                          │ │
│  │  👥 2/5 bénévoles                                      │ │
│  │  🧺 Composition du panier ▼                            │ │
│  │  [S'INSCRIRE] 🔴                                       │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 31 Jan • 18h-20h                          │ │
│  │  🌿 Maraîcher Bio + 🍞 Pain Artisanal                  │ │
│  │  👥 5/5 bénévoles confirmés                            │ │
│  │  🧺 Composition du panier ▼                            │ │
│  │  ✅ Inscrit(e) - Préparation paniers                   │ │
│  │  [SE DÉSINSCRIRE] ❌                                    │ │
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
- **[SE DÉSINSCRIRE]** : Désinscription immédiate du créneau bénévole (action en un clic) ; le message « Vous êtes désinscrit(e). » propose **[ANNULER]** pour se réinscrire aussitôt sur le même créneau en cas d'erreur
- **[Suivre]** : visible **uniquement pour les coordinateurs** (*COORDINATOR*) — bouton en haut de chaque carte de livraison ouvrant l'écran de suivi de la distribution ([Suivi de distribution](../coordinator/screen-coordinator-04-delivery-tracking.md)). Absent pour les amapiens simples.
- **[VOIR PLANNING COMPLET]** : Navigation vers le planning des livraisons ([Planning](screen-member-02-delivery-plan.md))
- **[MON HISTORIQUE]** : Navigation vers l'historique personnel ([Historique](screen-member-03-history.md))
- **[Menu]** : Accès au menu principal de navigation

### États dynamiques
- **Engagements confirmés** : Affichage en vert avec ✅ et bouton [SE DÉSINSCRIRE] — « ✅ Inscrit(e) comme coordinateur » lorsque le membre est coordinateur d'un contrat de la livraison (il n'est pas compté parmi les bénévoles)
- **Créneaux disponibles** : Bouton [S'INSCRIRE] disponible
- **Bénévoles recherchés** : 🙋 moins de 50 % des bénévoles inscrits, livraison dans plus de 3 jours
- **Besoin urgent** : Alerte visuelle en rouge 🔴 avec bouton [S'INSCRIRE] prioritaire — moins de 50 % des bénévoles inscrits et livraison dans 3 jours ou moins
- **Complet** : État validé avec information claire, pas d'action possible

### Données affichées
- Informations personnalisées du membre connecté
- Prochains engagements bénévoles avec options de désinscription
- Créneaux nécessitant des bénévoles avec inscription immédiate
- **Produits de la livraison** : Énumération des types de produits disponibles (🌿 Maraîcher Bio, 🥚 Œufs Fermiers, etc.)
- **Composition du panier** : Section collapsible affichant les détails de chaque article du panier (panier large, panier petit, etc.) avec images et poids
- Statistiques personnelles de participation
- **Contrats en préparation** : comme sur le planning, un amapien simple ne voit ni les livraisons dont tous les contrats sont encore en préparation (`IN_PREPARATION`), ni ces contrats (coordinateurs, produits, composition) sur les autres livraisons ; coordinateurs et admins les voient

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
