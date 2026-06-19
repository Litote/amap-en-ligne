# Catalogue d'items d'un type de produit

## Description

Interface de gestion des items (*ItemType*) associés à un type de produit (*PRODUCT_TYPE*). Un item représente un composant nommé et optionnellement illustré qui peut être inclus dans la description d'une livraison. Le catalogue d'items est défini une seule fois par type de produit et réutilisé pour décrire le contenu de chaque livraison.

- **Route** : `/product-types/:productTypeId/items`
- **Accès** : authentifié, rôle PRODUCER requis

## Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Légumes Bio — Items                 [sync]│
├─────────────────────────────────────────────┤
│  Carottes                                   │
│  [img]                                      │
│  ────────────────────────────────────────   │
│  Courgettes                                 │
│                                             │
│  ────────────────────────────────────────   │
│  Poireaux                                   │
│  [img]                                      │
│                                             │
│                                      [  +  ]│
└─────────────────────────────────────────────┘
```

## Contenu et comportement

- Titre AppBar : nom du type de produit suivi de " — Items".
- Bouton [← Retour] dans l'AppBar : retour vers le catalogue de types de produits (`/product-types`).
- Bouton de synchronisation manuelle dans l'AppBar (icône de rechargement ; remplacé par un spinner pendant la synchronisation).
- La liste affiche tous les items (*ItemType*) du type de produit, dans l'ordre de saisie.
- Chaque entrée affiche : le nom de l'item et, si elle est renseignée, l'image miniature correspondante.
- Swipe gauche sur une entrée : suppression de l'item (offline-first) avec déclenchement de la synchronisation.
- Tap sur une entrée : ouverture du formulaire d'édition de l'item.
- FAB [+] : ouverture du formulaire d'ajout d'un nouvel item.
- Liste vide : message "Aucun item défini."

## Formulaire d'ajout / édition d'un item

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Nouvel item                               │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ Nom *                               │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ URL de l'image (optionnel)          │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [Enregistrer]                              │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Titre AppBar : "Nouvel item" (ajout) ou "Modifier l'item" (édition).
- Champ "Nom" : obligatoire.
- Champ "URL de l'image" : optionnel. Lorsque renseigné, l'image est affichée en miniature dans la liste.
- [Enregistrer] : enregistre l'item localement (offline-first) et déclenche une synchronisation.
- [← Retour] dans l'AppBar : annule et retourne à la liste des items sans enregistrer.

## Références

- [`../spec-ui.md`](../spec-ui.md) — conventions UI globales
- [`screen-producer-02-product-catalog.md`](screen-producer-02-product-catalog.md) — catalogue de types de produits (point d'entrée vers cet écran)
- [`../common/screen-common-03-delivery-description.md`](../common/screen-common-03-delivery-description.md) — utilisation des items dans la description d'une livraison
