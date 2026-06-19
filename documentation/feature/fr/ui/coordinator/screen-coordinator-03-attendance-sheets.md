# Génération feuilles d'émargement (Coordinateur)

## Description
Interface de génération des feuilles d'émargement pour validation des présences bénévoles et récupération des paniers.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│              📄 Génération feuilles d'émargement            │
├─────────────────────────────────────────────────────────────┤
│  [← Retour Dashboard]                     📅 17 Jan 2025   │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  🎯 Livraison: Mercredi 17 Janvier • 18h-20h               │
│  👥 5 bénévoles inscrits • 🥚 Œufs + 🌿 Légumes             │
│                                                             │
│  📋 Types de feuilles à générer                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  ✅ Feuille émargement bénévoles                       │ │
│  │     Validation présence des 5 bénévoles inscrits       │ │
│  │     ├─ Présent/Absent │ Case signature                │ │
│  │                                                         │ │
│  │  ✅ Feuille récupération paniers                       │ │
│  │     Suivi récupération par contrat et membre           │ │
│  │     ├─ Par producteur │ Quantités │ Case récupération  │ │
│  │                                                         │ │
│  │  📐 Format: A4 □ Couleur ✅ Noir & Blanc               │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  👀 Prévisualisation                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📄 Feuille bénévoles (Page 1/1)                       │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │ Amap - Émargement Bénévoles                      │   │ │
│  │  │ Livraison: 17/01/2025 - 18h-20h                │   │ │
│  │  │                                                 │   │ │
│  │  │ Jean Petit   ☐ Présent  ☐ Absent  Signature ____  │   │ │
│  │  │ Sophie M.    ☐ Présent  ☐ Absent  Signature ____  │   │ │
│  │  │ Paul Martin  ☐ Présent  ☐ Absent  Signature ____  │   │ │
│  │  │ Lisa Klaus   ☐ Présente ☐ Absent  Signature ____  │   │ │
│  │  │ Tom Richard  ☐ Présent  ☐ Absent  Signature ____  │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                         │ │
│  │     [◀ PRÉCÉDENT] [SUIVANT ▶] [ZOOMER +/-]             │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ⚡ Actions rapides                                         │
│  [📄 TÉLÉCHARGER PDF] [🖨️ IMPRIMER] [📧 ENVOYER EMAIL]     │
│                                                             │
│  📊 Statistiques                                            │
│  • Bénévoles inscrits: 5                                   │
│  • Contrats actifs: 23 (légumes) + 18 (œufs)              │
│  • Estimation durée distribution: 1h30                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[← Retour Dashboard]** : Retour au dashboard coordination ([Écran 1](screen-coordinator-01-home.md))
- **[📄 TÉLÉCHARGER PDF]** : Génération et téléchargement du PDF complet
- **[🖨️ IMPRIMER]** : Impression directe des feuilles sélectionnées
- **[📧 ENVOYER EMAIL]** : Envoi par email aux coordinateurs de terrain

### Configuration des feuilles
- **Cases à cocher Types** : Sélection des feuilles à générer
  - ✅ Feuille émargement bénévoles (validation présences)
  - ✅ Feuille récupération paniers (suivi distribution)
- **Options format** : 
  - Format A4 standard
  - □ Couleur / ✅ Noir & Blanc (économique)

### Prévisualisation interactive
- **[◀ PRÉCÉDENT]** : Page précédente dans la prévisualisation
- **[SUIVANT ▶]** : Page suivante dans la prévisualisation
- **[ZOOMER +/-]** : Ajustement du niveau de zoom pour vérification

## Types de feuilles générées

### Feuille émargement bénévoles
- **En-tête** : Date, horaires, contexte de la livraison
- **Colonnes** : 
  - Nom complet du bénévole
  - Case « Présent »
  - Case « Absent »
  - Case signature (validation présence)
- **Données** : Liste des MEMBER_SLOT confirmés pour la DELIVERY

### Feuille récupération paniers
- **Organisation par producteur** : Sections séparées pour chaque PRODUCER
- **Colonnes** : 
  - Nom du membre (MEMBER)
  - Type de contrat (CONTRACT)
  - Quantité/Format du panier
  - Récupéré par (en cas d'échange de panier confirmé)
  - Case signature ou validation de récupération
- **Données** : Liste des CONTRACT actifs pour la date de livraison
- **Paniers échangés** : lorsqu'un échange de panier (*BASKET_EXCHANGE*) est confirmé pour cette livraison, la ligne du propriétaire du panier porte la mention « 🔄 Échange — à remettre à {membre} » (et la colonne « Récupéré par » dans le PDF). Cela couvre les deux côtés du troc : la livraison offerte (le panier de l'offreur est récupéré par le demandeur retenu) et la contre-livraison (le panier du demandeur est récupéré par l'offreur).

### Statistiques d'aide
- **Bénévoles inscrits** : Nombre total de MEMBER_SLOT confirmés
- **Contrats actifs** : Décompte par PRODUCT_TYPE (légumes, œufs, etc.)
- **Estimation durée** : Calcul basé sur le nombre de paniers et l'historique

## Processus de génération

### Étapes de génération
1. **Sélection créneau** : Choix de la DELIVERY cible
2. **Configuration types** : Sélection des feuilles nécessaires
3. **Paramétrage format** : Options d'impression et de mise en page
4. **Prévisualisation** : Vérification avant génération finale
5. **Génération PDF** : Création du document final multi-pages
6. **Distribution** : Téléchargement, impression ou envoi email

### Données intégrées
- **MEMBER_SLOT** : Liste des bénévoles inscrits avec status "confirmed"
- **CONTRACT** : Contrats actifs pour la date de livraison
- **MEMBER** : Informations membres pour noms et signatures
- **PRODUCT_TYPE** : Classification des paniers par type de produit
- **DELIVERY** : Détails de la livraison (date, horaires, lieu)

## Références

### Documentation liée
- **Spécifications UI** : `../spec-ui.md`
- **Dashboard coordination** : [Écran 1](screen-coordinator-01-home.md) pour l'accès et le retour
- **Suivi livraison** : [Écran 4](screen-coordinator-04-delivery-tracking.md) pour l'utilisation des feuilles générées
