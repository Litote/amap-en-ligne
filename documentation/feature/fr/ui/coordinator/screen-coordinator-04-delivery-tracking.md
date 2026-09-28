# Suivi de livraison (Coordinateur)

## Description
Interface de suivi en direct des présences bénévoles et des récupérations de paniers pendant la livraison.

Cet écran n'a plus d'entrée de menu dédiée : il est désormais atteint depuis le bouton `[SUIVRE]` d'une carte de livraison sur l'écran [Gestion des livraisons](screen-coordinator-02-time-slots.md) (qui réunit gestion et suivi dans une seule liste), et toujours depuis les cartes de livraison du dashboard coordinateur.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                🔴 LIVE • Suivi livraison                    │
├─────────────────────────────────────────────────────────────┤
│  📅 17 Jan • 18h-20h                 👥 4/5 présents       │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  👥 Coordinateurs de cette livraison                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  🥕 Légumes de saison                                   │ │
│  │     Jean Morel • 📞 06 12 34 56 78                      │ │
│  │     Claire Petit • (téléphone non communiqué)           │ │
│  │  🍞 Pain artisanal                                      │ │
│  │     Marc Olivier • 📞 06 98 76 54 32                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  👥 État des bénévoles                                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  ✅ Jean Petit                             [MARQUER ABSENT]│ │
│  │  ✅ Sophie Martin                          [MARQUER ABSENT]│ │
│  │  ✅ Paul Martin                            [MARQUER ABSENT]│ │
│  │  ✅ Lisa Klaus                             [MARQUER ABSENT]│ │
│  │  🔴 Tom Richard                            [MARQUER PRÉSENT]│ │
│  │                                             [CONTACTER]   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  🥚 Récupération paniers œufs (18 contrats)                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  ✅ Marie Dupont                  1 panier               │ │
│  │  ✅ Pierre Laurent                1 panier               │ │
│  │  ✅ Anne Bernard                  2 paniers              │ │
│  │  ⏳ 15 membres restants...         [VOIR TOUT ▼]       │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  🌿 Récupération paniers légumes (23 contrats)              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  ✅ Sophie Moreau                1 grand panier         │ │
│  │  ✅ Jean Roux                    1 petit panier         │ │
│  │  ⏳ 21 membres restants...         [VOIR TOUT ▼]       │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📊 Progression temps réel                                  │
│  Bénévoles: ████████░░ 80% (4/5)                           │
│  Paniers œufs: ███░░░░░░░ 17% (3/18)                       │
│  Paniers légumes: ██░░░░░░░░ 9% (2/23)                     │
│                                                             │
│  ⚡ Actions rapides                                         │
│  [📞 CONTACTER TOM] [📧 CONTACTER CLAIRE] [📋 SYNTHÈSE]    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Section Coordinateurs
- Les coordinateurs (*COORDINATOR*) sont regroupés par livraison-contrat (*DELIVERY_CONTRACT*), pour rendre la spécialisation par produit visible (légumes, pain, fruits, etc.).
- Lorsqu'un coordinateur a un numéro de téléphone (*MEMBER.phone*), il est rendu comme lien `tel:<numéro>` — un tap sur mobile ouvre directement l'appli téléphone.
- En l'absence de numéro, l'écran affiche `(téléphone non communiqué)` sans lien.
- Si la livraison-contrat n'a aucun coordinateur, la ligne `Coordinateur à confirmer` est affichée à la place des noms.

### Actions en temps réel - Bénévoles
- **[MARQUER ABSENT]** : Bascule un bénévole présent en absent
- **[MARQUER PRÉSENT]** : Bascule un bénévole absent en présent
- **[CONTACTER]** : Ouvre l'action de contact du membre à partir de son téléphone ou de son email

### Actions en temps réel - Paniers
- **[VOIR TOUT ▼]** : Expansion de la liste complète des récupérations
- **Cases individuelles** : Marquage manuel des récupérations en « récupéré » ou « en attente » (non affiché dans ce wireframe)

### Actions rapides globales
- **[📞 CONTACTER TOM]** : Contact direct d'un bénévole absent
- **[📧 CONTACTER CLAIRE]** : Contact direct d'un membre dont le panier n'est pas encore récupéré
- **[📋 SYNTHÈSE]** : Affiche un récapitulatif de l'état courant

## États temps réel

### Bénévoles
- **✅ Présent** : Le bénévole est marqué comme présent
- **🔴 Absent** : Le bénévole est marqué comme absent
- La liste « État des bénévoles » ne recense que les bénévoles : les coordinateurs (*COORDINATOR*) de la livraison en sont exclus, même s'ils se sont inscrits sur un créneau (cohérent avec le compteur de bénévoles, qui n'inclut jamais les coordinateurs).

### Récupération paniers
- **✅ Récupéré** : Le panier est remis au membre
- **⏳ En attente** : Le panier n'est pas encore récupéré

### Indicateurs visuels
- **Barres de progression** : Visualisation immédiate des taux de réalisation
- **Compteurs** : Totaux présents/absents et récupérés/en attente
- **Codes couleur** : Vert (présent ou récupéré), Rouge (absent), Orange (en attente), Bleu (info)

## Comportement observable

- L'écran met à jour les listes et les compteurs pendant la livraison.
- Le coordinateur voit, pour chaque bénévole, s'il est présent ou absent.
- Le coordinateur voit, pour chaque contrat, si le panier est récupéré ou encore en attente. Chaque bloc « Récupération des paniers » indique le ou les produits (*PRODUCT_TYPE*) concernés par le contrat (référencés par ses tarifs, ou à défaut tous les produits de son producteur), sous le nom du contrat.
- Les actions de contact s'appuient sur les coordonnées déjà disponibles pour le membre.

## Références

### Documentation liée
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
