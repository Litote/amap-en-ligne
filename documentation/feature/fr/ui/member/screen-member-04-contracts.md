# Mes contrats

## Description

Écran dédié permettant à l'Amapien de consulter ses contrats membre (*MEMBER_CONTRACT*) rattachés aux contrats de saison (*CONTRACT*).

L'écran est accessible depuis l'entrée **[MES CONTRATS]** du menu principal. Il est consultatif : l'Amapien peut voir ses contrats, leur état et leurs informations principales, sans pouvoir les modifier.

## Wireframe ASCII

```
┌─────────────────────────────────────────────────────────────┐
│                     📄 Mes contrats                         │
├─────────────────────────────────────────────────────────────┤
│  👤 Marie Dupont                               📱 [Menu]    │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  Filtres : [Tous] [Actifs] [À venir] [Terminés]             │
│                                                             │
│  🟢 Contrats actifs                                          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  🌿 Maraîcher Bio • Panier légumes printemps           │ │
│  │  🟢 Actif                                               │ │
│  │  📅 Du 1 avr 2025 au 30 sept 2025                      │ │
│  │  📦 Panier moyen                                        │ │
│  │  📍 Retrait du mercredi                                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  🔵 Contrats à venir                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  🍞 Pain artisanal • Abonnement hebdomadaire           │ │
│  │  🔵 À venir                                              │ │
│  │  📅 Du 15 sept 2025 au 15 déc 2025                     │ │
│  │  📦 1 pain par livraison                                │ │
│  │  📍 Première livraison prévue le 17 sept 2025           │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ⚪ Contrats terminés                                       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  🥚 Œufs fermiers • Semestre hiver                      │ │
│  │  ⚪ Terminé                                              │ │
│  │  📅 Du 1 oct 2024 au 31 mars 2025                      │ │
│  │  📦 1 douzaine par quinzaine                            │ │
│  │  📍 Dernière livraison le 26 mars 2025                  │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  [📅 PLANNING DES LIVRAISONS]    [📊 MON HISTORIQUE]        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

| Contrôle | Cible | Comportement |
|----------|-------|--------------|
| `[Menu]` | menu principal | Ouvre le menu partagé ([Menu principal](../common/screen-common-01-menu.md)) |
| `[Tous]` | `/contracts` | Affiche tous les contrats du membre |
| `[Actifs]` | `/contracts?status=active` | Affiche uniquement les contrats en cours |
| `[À venir]` | `/contracts?status=upcoming` | Affiche uniquement les contrats à venir |
| `[Terminés]` | `/contracts?status=ended` | Affiche uniquement les contrats terminés |
| `[📅 PLANNING DES LIVRAISONS]` | `/planning` | Navigation vers le planning des livraisons ([Planning](screen-member-02-delivery-plan.md)) |
| `[📊 MON HISTORIQUE]` | `/history` | Navigation vers l'historique personnel ([Historique](screen-member-03-history.md)) |

### Règles d'affichage
- Les contrats sont regroupés par état, avec l'ordre suivant : **Actifs**, **À venir**, **Terminés**
- Le filtre sélectionné n'affiche que les cartes correspondant à l'état choisi
- Les contrats actifs restent affichés en premier lorsque plusieurs états sont visibles en même temps
- Aucun bouton de modification n'est affiché sur cet écran
- **Les contrats avec le statut *En préparation* (`IN_PREPARATION`) ne sont pas visibles pour les Amapiens.** Ils n'apparaissent ni dans la liste ni dans les filtres de cet écran. Seuls les contrats *Actifs*, *À venir* et *Terminés* (au sens de l'état visible calculé) sont affichés.

### Informations affichées sur chaque contrat
- Intitulé du contrat
- Producteur associé
- État du contrat
- Période couverte
- Information principale utile au retrait ou à la préparation (ex. taille de panier, fréquence, première ou dernière livraison)
- **Souscriptions** (produits et tailles sélectionnées) : affichées en lecture seule avec l'icône 📦 et les labels des produits, ex. « 📦 Légumes de saison — Petit panier • Fruits de saison »
- **Panier partagé (*SHARED_BASKET*)** : si le contrat est partagé avec d'autres familles (en alternance), une ligne 🤝 indique « Panier partagé entre N familles : vous récupérez 1 distribution sur N. » suivie de la liste des dates où c'est au tour de l'Amapien de récupérer le panier (« Vos distributions : … »). Information en lecture seule — le partage est mis en place par le coordinateur (voir [Contrat par Amapien](../coordinator/screen-coordinator-08-member-contracts.md)).

## États vides et messages

### Aucun contrat
Si l'Amapien n'a aucun contrat, l'écran affiche le message :

> « Aucun contrat ne vous est actuellement attribué. Contactez votre coordinateur si nécessaire. »

### Aucun résultat pour le filtre
Si le filtre sélectionné ne renvoie aucun contrat, l'écran affiche le message :

> « Aucun contrat dans cet état. »

## Statuts visibles

Les statuts affichés sur cet écran correspondent aux seuls états qu'un Amapien peut voir. Les contrats *En préparation* (`IN_PREPARATION`) sont exclus de cet écran et ne sont jamais présentés à l'Amapien.

- **🟢 Actif** : le contrat est en cours
- **🔵 À venir** : le contrat est attribué mais sa période n'a pas encore commencé
- **⚪ Terminé** : le contrat a été manuellement passé à *Terminé* (`ENDED`) OU la période du contrat est passée

## Références

- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
- **Menu principal** : [`../common/screen-common-01-menu.md`](../common/screen-common-01-menu.md)
- **Planning** : [`screen-member-02-delivery-plan.md`](screen-member-02-delivery-plan.md)
- **Historique** : [`screen-member-03-history.md`](screen-member-03-history.md)
