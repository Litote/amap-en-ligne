# Dashboard Producteur

## Description
Écran d'accueil du producteur (route `/producer-dashboard`, entrée « Accueil producteur » du menu ; c'est aussi l'écran ouvert à la connexion). Il salue le producteur par son nom et résume son activité auprès des organismes partenaires : vue d'ensemble, prochaines livraisons et contrats en cours, puis les accès rapides.

> **📋 Source des données** : un producteur ne reçoit jamais le scope d'une AMAP (`organization:{id}`, qui porte les données personnelles des membres). Tout l'écran est calculé sur l'appareil à partir des projections en lecture seule planning producteur (*ProducerSchedule*) de son propre flux `producer-account:{id}` : une par AMAP rattachée, avec les livraisons portant l'un de **ses** contrats (date, statut, nom du contrat, nombre de paniers). Voir `AI_CONTEXT.md` → *Producer schedules*.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│  [☰]  Mon tableau de bord                           [⟳]    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Bonjour Ferme Bio des Collines 👋                          │
│                                                             │
│  📊 Vue d'ensemble                                          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  • 2 organismes partenaires                             │ │
│  │  • 3 contrats en cours                                  │ │
│  │  • Prochaine livraison : Mercredi 17 janv. • 18h-20h    │ │
│  │    • AMAP Les Jardins                                   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📅 Prochaines livraisons                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 17 janv. • 18h-20h • AMAP Les Jardins      │ │
│  │  Légumes bio 2026 • 45 paniers           [Planifiée]    │ │
│  │  [🧺 COMPOSITION DU PANIER]                              │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Jeudi 18 janv. • 18h-20h • Coop Bio Ville           │ │
│  │  Fruits de saison • 32 paniers           [Confirmée]    │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 24 janv. • 18h-20h • AMAP Les Jardins      │ │
│  │  Légumes bio 2026 • 45 paniers           [Planifiée]    │ │
│  └─────────────────────────────────────────────────────────┘ │
│  [VOIR TOUTES MES LIVRAISONS]                               │
│                                                             │
│  📊 Mes contrats actifs                                     │
│  • AMAP Les Jardins - Légumes bio 2026 (45 paniers/livraison)│
│  • Coop Bio Ville - Fruits de saison (32 paniers/livraison) │
│  • Coop Bio Ville - Oeufs (1 panier/livraison)              │
│                                                             │
│  Accès rapides                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ 📦 Catalogue de produits                              › │ │
│  │    Gérez vos types de produits                          │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │ 🚚 Mes livraisons                                     › │ │
│  │    Suivez vos livraisons à venir                        │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │ ⚙️ Préférences                                         › │ │
│  │    Paramètres du compte                                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Contenu

### Salutation
« Bonjour {nom du compte producteur} 👋 » — le même nom que l'en-tête du menu. Tant que le nom n'est pas connu (avant la première synchronisation), « Bonjour 👋 ».

### Vue d'ensemble
- **Organismes partenaires** : nombre d'AMAP auxquelles le producteur est rattaché (une projection par AMAP, même sans livraison à venir). Accord singulier/pluriel.
- **Contrats en cours** : nombre de contrats du producteur ayant au moins une livraison à venir (voir « Mes contrats actifs »).
- **Prochaine livraison** : date (format du planning, ex. « Jeudi 1 oct. • 18h-20h ») et AMAP de la livraison à venir la plus proche, ou « Aucune livraison à venir ».

### Prochaines livraisons
Les **3** livraisons à venir les plus proches, toutes AMAP confondues. Une carte par livraison : date • AMAP, puis une ligne par contrat du producteur lié à cette livraison (« {nom du contrat} • {N} panier(s) »), le badge de statut de la livraison (Planifiée, Confirmée, 🔴 En cours) et le bouton **[COMPOSITION DU PANIER]**, qui ouvre la [composition du panier](../common/screen-common-03-delivery-description.md) de ses produits sur cette livraison.

Le bouton **[VOIR TOUTES MES LIVRAISONS]** ouvre la liste complète (`/producer-deliveries`). Sans livraison à venir : « Aucune livraison à venir pour vos produits. » (pas de bouton).

### Mes contrats actifs
Une ligne par couple (AMAP, contrat) ayant au moins une livraison à venir : « • {AMAP} - {contrat} ({N} panier(s)/livraison) », où N est le nombre de paniers de la **prochaine** livraison du contrat. Triée par AMAP puis par nom de contrat. Sans contrat : « Aucun contrat en cours. ».

> Le planning producteur ne transporte pas le statut du contrat : un contrat encore « En préparation » mais déjà lié à des livraisons apparaît ici (avec le nombre de paniers saisi par le coordinateur, éventuellement 0).

### Accès rapides
Trois tuiles, dans cet ordre :

| Tuile | Route |
|-------|-------|
| Catalogue de produits — « Gérez vos types de produits » | `/product-types` |
| Mes livraisons — « Suivez vos livraisons à venir » | `/producer-deliveries` |
| Préférences — « Paramètres du compte » | `/preferences` |

## Règles de calcul
- **Livraison à venir** : livraison dont la date est aujourd'hui ou plus tard (la journée entière d'aujourd'hui compte) et dont le statut n'est ni terminé (*COMPLETED*) ni annulé (*CANCELLED*).
- Le producteur ne modifie ici ni les livraisons ni les contrats (ils sont gérés par les coordinateurs de chaque AMAP) ; il peut seulement composer le panier de ses produits (bouton [COMPOSITION DU PANIER]).
- L'écran se met à jour à chaque synchronisation (bouton ⟳ ou synchronisation automatique).

## Navigation et interactions

| Contrôle | Action |
|----------|--------|
| [☰] | Ouvre le menu producteur (Accueil producteur, Notifications, Préférences, Aide, Se déconnecter) |
| [⟳] | Synchronise (appui long : synchronisation complète) |
| [VOIR TOUTES MES LIVRAISONS] | `/producer-deliveries` |
| [COMPOSITION DU PANIER] (carte de livraison) | `/producer-deliveries/:organizationId/:deliveryId/composition` — [composition du panier](../common/screen-common-03-delivery-description.md) |
| Tuiles « Accès rapides » | Route de la tuile |

## États de l'interface
- **Chargement** : la lecture du cache local est quasi instantanée ; tant qu'elle n'a pas répondu, seuls la salutation et les accès rapides sont affichés (pas d'indicateur de progression).
- **Première synchronisation** : tant qu'une synchronisation est en cours et qu'aucun planning n'est en cache (juste après la connexion), « 🔄 Synchronisation en cours… » remplace la vue d'ensemble (texte seul, pas d'animation).
- **Aucune AMAP rattachée / aucune livraison** : « 0 organisme partenaire », « 0 contrat en cours », « Aucune livraison à venir » et les messages vides des deux sections.

## Hors périmètre (évolutions envisagées, non implémentées)
Les éléments suivants de la maquette d'origine ne sont **pas** disponibles : ils demandent de nouvelles données côté serveur (statut de préparation par livraison et par producteur, échéances, historique) et des règles métier encore à définir.
- Bloc « Livraisons urgentes » (échéance de préparation, alerte 24h avant).
- Action **[✅ MARQUER PRÊT]** et statuts de préparation (⏳ en attente, ✅ prêt, 🚚 en livraison).
- Détail d'une livraison (au-delà de la composition du panier), notes de préparation, contact direct du coordinateur, signalement de problème, report ou annulation.
- Écrans **[📋 GÉRER PRODUCTION]** et **[📊 RAPPORTS]** (volume hebdomadaire, taux de ponctualité, satisfaction, évolution saisonnière).

## Références
- **Liste des livraisons** : `/producer-deliveries` (même source de données, liste complète).
- **Catalogue** : [screen-producer-02-product-catalog.md](screen-producer-02-product-catalog.md).
- **Données** : `../../../../architecture/data-model.md` — entités PRODUCER_ACCOUNT, CONTRACT, DELIVERY ; projection *ProducerSchedule* décrite dans `AI_CONTEXT.md`.
