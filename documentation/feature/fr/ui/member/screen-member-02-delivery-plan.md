# Écran 3 : Planning des livraisons (vue Amapien)

## Description
Interface de consultation du planning mensuel avec possibilité d'inscription directe aux livraisons de bénévolat disponibles.

> **📋 Référence** : Structure détaillée dans `../../../../architecture/data-model.md` - Section DELIVERY, MEMBER_SLOT, CONTRACT.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                  📅 Planning des livraisons                 │
├─────────────────────────────────────────────────────────────┤
│  [← Déc 2024]        Janvier 2025         [Fév 2025 →]     │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  📋 Livraisons ce mois                                      │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 3 Janvier • 18h00-20h00                   │ │
│  │  🌿 Maraîcher Bio + 🥚 Œufs Fermiers                   │ │
│  │  ✅ TERMINÉ - Vous avez participé                       │ │
│  │  👥 Bénévoles: Marie D., Jean P., Paul M., Lisa K., Tom │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 10 Janvier • 18h00-20h00                  │ │
│  │  🌿 Maraîcher Bio + 🍞 Pain Artisanal                  │ │
│  │  ✅ Vous êtes inscrit(e) comme bénévole                │ │
│  │  👥 5/5 bénévoles ─ COMPLET                            │ │
│  │      [VOIR DÉTAILS] [SE DÉSINSCRIRE]                   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 17 Janvier • 18h00-20h00                  │ │
│  │  🌿 Maraîcher Bio + 🥚 Œufs Fermiers                   │ │
│  │  🔴 BESOIN URGENT DE BÉNÉVOLES                          │ │
│  │  👥 2/5 bénévoles ─ Manque 3 personnes                 │ │
│  │      [S'INSCRIRE MAINTENANT] 🚨                        │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 24 Janvier • 18h00-20h00                  │ │
│  │  🌿 Maraîcher Bio + 🍞 Pain Artisanal                  │ │
│  │  ⚠️ Attention - Places limitées                         │ │
│  │  👥 3/5 bénévoles ─ 2 places restantes                 │ │
│  │  👥 Coordinateurs :                                     │ │
│  │     🥕 Légumes — Jean Morel • 📞 06 12 34 56 78        │ │
│  │     🍞 Pain — Coordinateur à confirmer                  │ │
│  │      [S'INSCRIRE]                                      │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 31 Janvier • 18h00-20h00                  │ │
│  │  🌿 Maraîcher Bio + 🥕 Légumes de saison               │ │
│  │  ⏰ Créneau anticipé disponible (1 place restante)      │ │
│  │  👥 1/5 bénévoles                                      │ │
│  │                                                         │ │
│  │  Choisissez votre créneau :                             │ │
│  │  [S'inscrire • Créneau standard 18h00-20h00]           │ │
│  │                                                         │ │
│  │  [S'inscrire • Créneau anticipé 17h00-20h00]           │ │
│  │  ℹ️ Réception des légumes du maraîcher                  │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ [🏠 ACCUEIL]     [📊 MON HISTORIQUE]     [ℹ️ AIDE]         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[S'INSCRIRE MAINTENANT]** : Inscription immédiate sur une livraison critique
- **[S'INSCRIRE]** : Inscription standard pour livraisons disponibles (sans créneau anticipé, ou dont le créneau anticipé est complet)
- **[S'inscrire • Créneau standard HHhMM-HHhMM]** : Inscription sur le créneau de bénévolat habituel, pour les livraisons qui proposent un créneau anticipé avec des places encore disponibles
- **[S'inscrire • Créneau anticipé HHhMM-HHhMM]** : Inscription sur le créneau anticipé (*EARLY_SLOT*), visible uniquement si ce créneau est configuré sur la livraison et qu'il reste de la capacité. L'explication fournie par le coordinateur est affichée directement sous le bouton, sans dialog ni modal.
- **[SE DÉSINSCRIRE]** : Annulation de l'inscription avec confirmation
- **[Suivre]** : visible **uniquement pour les coordinateurs** (*COORDINATOR*) — bouton en haut de chaque carte de livraison ouvrant l'écran de suivi de la distribution ([Suivi de distribution](../coordinator/screen-coordinator-04-delivery-tracking.md)). Les amapiens simples et les admins non-coordinateurs ne voient pas ce bouton. L'édition de la livraison reste accessible depuis l'écran coordinateur dédié ([Gestion des livraisons](../coordinator/screen-coordinator-02-time-slots.md)), pas depuis le planning.
- **[VOIR DÉTAILS]** : Affichage des détails complets du créneau (participants, activités)
- **[🏠 ACCUEIL]** : Retour au tableau de bord Amapien ([Accueil membre](screen-member-01-home.md))
- **[📊 MON HISTORIQUE]** : Navigation vers l'historique personnel ([Historique](screen-member-03-history.md))
- **[ℹ️ AIDE]** : Accès à l'aide et documentation

### Navigation temporelle
- **[← Déc 2024]** : Navigation vers le mois précédent
- **[Fév 2025 →]** : Navigation vers le mois suivant
- Affichage du mois courant : **Janvier 2025**

### États des livraisons
- **✅ TERMINÉ** : Livraison passée avec participation confirmée
- **✅ COMPLET** : Toutes les places bénévoles sont prises. Cet état n'apparaît que lorsque la livraison est effectivement complète (au moins un créneau défini et toutes les places occupées) — une livraison sans créneau bénévole n'affiche ni COMPLET ni bouton d'inscription
- **🔴 BESOIN URGENT** : Moins de 50% des bénévoles requis
- **⚠️ Places limitées** : Entre 50% et 80% des places occupées
- **Vous êtes inscrit(e)** : Participation confirmée du membre connecté
- **⏰ Créneau anticipé disponible** : La livraison dispose d'un créneau anticipé avec au moins une place libre
- **🚧 Contrat inactif** : Tous les contrats (*CONTRACT*) liés à la livraison sont encore en préparation (`IN_PREPARATION`). Une telle livraison est **masquée pour les amapiens simples** ; seuls les coordinateurs et admins la voient, avec ce badge et **sans action d'inscription**

### Comportement des options d'inscription avec créneau anticipé
Lorsqu'une livraison possède un créneau anticipé (*EARLY_SLOT*) configuré et que ce créneau a encore de la capacité, l'écran affiche **deux boutons d'inscription visibles directement** dans la carte de la livraison, sans ouvrir de dialog ni de modal :
- Le premier bouton correspond au créneau standard (heure de début habituelle jusqu'à la fin).
- Le second bouton correspond au créneau anticipé (heure d'arrivée anticipée jusqu'à la fin). L'explication saisie par le coordinateur apparaît sous ce bouton.

Lorsque le créneau anticipé est complet ou absent, un unique bouton d'inscription est affiché (comportement inchangé).

### Données affichées
- Planning mensuel chronologique
- État de participation du membre pour chaque créneau
- Informations sur les producteurs présents
- Disponibilité des places bénévoles
- Actions contextuelles selon l'état du créneau
- Pour les livraisons avec créneau anticipé disponible : les deux options d'inscription et l'explication du créneau anticipé
- **Coordinateurs par livraison-contrat** (*DELIVERY_CONTRACT*) : chaque carte de livraison liste, sous la ligne des bénévoles, les coordinateurs (*COORDINATOR*) de chaque contrat (un coordinateur par ligne, regroupé par produit). Lorsque `MEMBER.phone` est renseigné, le numéro est rendu sous forme de lien `tel:<numéro>` — un tap ouvre l'application téléphone du système. En l'absence de numéro, aucun lien n'est affiché. Lorsqu'une livraison-contrat n'a pas encore de coordinateur, la mention `Coordinateur à confirmer` apparaît à la place du nom.
- **Panier partagé** (*SHARED_BASKET*) : si l'Amapien partage le panier d'un contrat avec d'autres familles (en alternance) et que ce contrat est lié à la livraison affichée, la carte indique sous les produits si **c'est son tour** de récupérer le panier cette semaine (« 🤝 Panier partagé : c'est votre tour de récupérer le panier. ») ou si c'est une autre famille (« 🤝 Panier partagé : récupéré par {famille} cette semaine. »). Information en lecture seule — le partage est mis en place par le coordinateur.

## Références

### Documentation liée
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md) - Section "Planning mensuel"
- **Dashboard** : [Accueil membre](screen-member-01-home.md)
- **Historique** : [Historique des participations](screen-member-03-history.md)
- **Templates de livraison** : [`../admin/screen-admin-05-delivery-template.md`](../admin/screen-admin-05-delivery-template.md) — configuration du créneau anticipé par l'admin de l'organisation
- **Données** : `../../../../architecture/data-model.md` - Entités DELIVERY, DELIVERY_TEMPLATE, EARLY_SLOT, MEMBER_SLOT, MEMBER
