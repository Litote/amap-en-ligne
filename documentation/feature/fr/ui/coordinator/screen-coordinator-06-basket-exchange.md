# Échanges de paniers

## Description
Interface permettant aux membres d'échanger leurs paniers entre eux. L'échange est un **troc réciproque à validation mutuelle** : un membre absent propose sa livraison ; un autre membre répond en proposant **l'une de ses propres livraisons en retour** ; le membre à l'origine de l'échange valide (ou refuse) cette proposition. L'écran sert aussi à consulter les échanges disponibles et l'historique.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                   🔄 Échanges de paniers                   │
├─────────────────────────────────────────────────────────────┤
│  👤 Marie Dupont                               📱 [Menu]    │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  💝 Mes propositions en cours                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 31 Jan • Légumes Bio                      │ │
│  │  💬 "Déplacement professionnel"                        │ │
│  │  🟡 En attente • 2 demandes reçues                     │ │
│  │  [VOIR LES DEMANDES]      [ANNULER]                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  [PROPOSER UN ÉCHANGE]                                      │
│                                                             │
│  🛍️ Échanges disponibles                                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 17 Jan • Fruits & Légumes                 │ │
│  │  👤 Jean Martin • Propose son panier                   │ │
│  │  💬 "Absence pour congés"                              │ │
│  │  [DEMANDER ÉCHANGE]                                     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📊 Mon historique                                          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  ✅ Échanges réussis cette année : 3                   │ │
│  │  ✅ 31 Jan ↔ 14 Fév · Jean Martin                     │ │
│  │  [VOIR HISTORIQUE COMPLET]                             │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ [🔄 ACTUALISER]              [VUE D'ENSEMBLE]              │
│ [📋 HISTORIQUE DÉTAILLÉ]                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[PROPOSER UN ÉCHANGE]** : ouvre la modal de création d'une proposition (sélection de la livraison à céder + motif/disponibilités).
- **[DEMANDER ÉCHANGE]** : ouvre la modal de demande sur un échange disponible — le demandeur y choisit **la livraison qu'il propose en retour**.
- **[VOIR LES DEMANDES]** : écran des demandes reçues pour une proposition, avec le panier proposé en retour par chaque demandeur.
- **[ANNULER]** : annule une proposition en cours (les demandes en attente sont automatiquement refusées).
- **[VOIR HISTORIQUE COMPLET]** / **[HISTORIQUE DÉTAILLÉ]** : navigation vers l'historique détaillé (`/basket-exchange/history`).
- **[VUE D'ENSEMBLE]** : tableau récapitulatif de tous les échanges en cours de l'AMAP, ouvert à tous les membres (`/basket-exchange/overview`).

### États dynamiques des échanges
- **🟡 En attente** : proposition active, en attente de demandes / de validation.
- **✅ Confirmé** : échange validé par le proposant (réciproque finalisé).
- **❌ Refusé / non retenu** : proposition déclinée, ou supplantée par une autre demande validée.
- **⏸️ Annulé** : proposition annulée par le proposant.

### Processus de proposition d'échange

#### Modal "Proposer un échange"
```
┌─────────────────────────────────────────────────────────────┐
│                  ➕ Proposer un échange                     │
├─────────────────────────────────────────────────────────────┤
│  📅 Sélectionner la livraison :                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ▼ Mercredi 31 Jan • Légumes Bio                        │ │
│  └─────────────────────────────────────────────────────────┘ │
│  📝 Motif de l'échange (optionnel) :                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Déplacement professionnel — dispo les 14 et 21 Fév     │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ⚠️ Règles d'échange :                                       │
│  • Une seule proposition ouverte par livraison.             │
│  • Le membre intéressé vous proposera une livraison en      │
│    échange.                                                  │
│  • Précisez vos disponibilités dans le motif.               │
│              [ANNULER]    [PROPOSER]                         │
└─────────────────────────────────────────────────────────────┘
```

### Processus de demande (avec contre-livraison)

#### Modal "Demander cet échange"
```
┌─────────────────────────────────────────────────────────────┐
│                  🔄 Demander cet échange                    │
├─────────────────────────────────────────────────────────────┤
│  📅 Fruits & Légumes — proposé par Jean Martin             │
│  💬 "Absence pour congés"                                   │
│                                                             │
│  🔄 Votre panier proposé en échange :                       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ▼ Mercredi 14 Fév • Fruits & Légumes                   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  Jean Martin recevra votre proposition et choisira de la    │
│  valider ou non. Si une autre proposition est validée, la   │
│  vôtre sera automatiquement refusée.                        │
│              [ANNULER]    [ENVOYER]                          │
└─────────────────────────────────────────────────────────────┘
```

### Gestion des demandes reçues

#### Écran "Demandes pour mon échange"
```
┌─────────────────────────────────────────────────────────────┐
│              👁️ Demandes pour mon échange                   │
├─────────────────────────────────────────────────────────────┤
│  📋 Demandes reçues (2)                                     │
│  📅 Votre panier du 31 Jan                                 │
│  💬 Motif : "Déplacement professionnel"                    │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  👤 Sophie Durand                                      │ │
│  │  🔄 Propose son panier du 14 Fév                       │ │
│  │  ⏰ Demande reçue il y a 2h                            │ │
│  │  [VALIDER]      [REFUSER]                              │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  👤 Pierre Leroy                                       │ │
│  │  🔄 Propose son panier du 21 Fév                       │ │
│  │  ⏰ Demande reçue il y a 4h                            │ │
│  │  [VALIDER]      [REFUSER]                              │ │
│  └─────────────────────────────────────────────────────────┘ │
│                    [RETOUR]                                 │
└─────────────────────────────────────────────────────────────┘
```

- **[VALIDER]** : confirme l'échange réciproque (le proposant cède son panier et récupère celui du demandeur). Les autres demandes en attente sont automatiquement refusées.
- **[REFUSER]** : refuse cette demande individuellement ; la proposition reste **ouverte** pour les autres membres. Le demandeur est notifié.

### Vue d'ensemble (tous les membres)

Écran `/basket-exchange/overview` accessible à tous les membres : tableau récapitulatif des échanges **en cours** (ouverts ou confirmés) de l'AMAP — offreur, panier offert (date), demandeur retenu, panier en retour (date), nombre de demandes en attente, statut. Un bouton d'**export CSV** (« comme un fichier Excel ») télécharge le tableau.

### Présence sur le tableau de bord

La page d'accueil affiche une carte « 🔄 Échanges de paniers » dès qu'un échange concerne le membre : nombre de propositions **à valider**, de demandes **en attente de validation**, et d'échanges **confirmés**. Elle renvoie vers `/basket-exchange`.

### Notifications et alertes
- **Nouvelle demande d'échange** (au proposant) : « *X* propose son panier du *{date}* en échange du vôtre du *{date}* ». Cliquable vers l'écran des demandes reçues.
- **Échange confirmé** (au demandeur retenu) : « Votre échange est confirmé : vous récupérez le panier du *{date}*, vous cédez le vôtre du *{date}* ».
- **Proposition non retenue / refusée** (aux autres demandeurs) : avec la date du panier concerné.
- **Échange annulé** : envoyé aux demandeurs en attente lorsque le proposant annule.

Toutes ces notifications apparaissent dans la boîte de réception (`/notifications`) et, selon les préférences du membre, par email et/ou push. Les textes sont personnalisables par un administrateur via « Personnalisation des alertes ».

### Règles métier intégrées
- **Pas de double engagement** : un même panier (livraison d'un membre) ne peut être engagé que dans un seul échange actif à la fois — qu'il soit offert ou proposé en contrepartie d'un échange validé.
- **Contre-livraison obligatoire** : une demande doit toujours indiquer la livraison proposée en retour (distincte de celle offerte, et active).
- **Validation mutuelle** : c'est le proposant qui valide la demande retenue ; la validation refuse automatiquement les autres demandes en attente.

### Données affichées
- Liste des propositions personnelles avec leur statut et le nombre de demandes reçues.
- Échanges disponibles proposés par d'autres membres.
- Historique personnel des échanges (avec les deux livraisons échangées D1 ↔ D2).

## Références

- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
- **Tableau de bord** : [`screen-coordinator-01-home.md`](screen-coordinator-01-home.md)
- **Notifications** : [`../../../../architecture/adr-005-notifications.md`](../../../../architecture/adr-005-notifications.md)
