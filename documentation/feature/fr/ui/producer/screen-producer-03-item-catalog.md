# Catalogue de composants d'un type de produit

## Description

Interface de gestion des composants (*ItemType*) associés à un type de produit (*PRODUCT_TYPE*). Un composant est un élément nommé et optionnellement illustré qui peut être inclus dans la description d'une livraison. Le catalogue de composants est défini une seule fois par type de produit et réutilisé pour décrire le contenu de chaque livraison.

- **Route** : `/product-types/:productTypeId/items`
- **Accès** : authentifié, rôle PRODUCER requis

## Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Légumes Bio — Composants            [sync]│
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

- Titre AppBar : nom du type de produit suivi de " — Composants".
- Bouton [← Retour] dans l'AppBar : retour vers le catalogue de types de produits (`/product-types`).
- Bouton de synchronisation manuelle dans l'AppBar (icône de rechargement ; remplacé par un spinner pendant la synchronisation).
- La liste affiche tous les composants (*ItemType*) du type de produit, dans l'ordre de saisie.
- Chaque entrée affiche : le nom du composant et, si elle est renseignée, l'image miniature correspondante.
- Swipe gauche sur une entrée : suppression du composant (offline-first) avec déclenchement de la synchronisation.
- Tap sur une entrée : ouverture du formulaire d'édition du composant.
- FAB [+] : ouverture du formulaire d'ajout d'un nouveau composant.
- Liste vide : message "Aucun composant défini."

## Formulaire d'ajout / édition d'un composant

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Nouveau composant                         │
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

- Titre AppBar : "Nouveau composant" (ajout) ou "Modifier le composant" (édition).
- Champ "Nom" : obligatoire.
- Champ "URL de l'image" : optionnel. Lorsque renseigné, l'image est affichée en miniature dans la liste.
- [Enregistrer] : enregistre le composant localement (offline-first) et déclenche une synchronisation.
- [← Retour] dans l'AppBar : annule et retourne à la liste des composants sans enregistrer.

## Références

- [`../spec-ui.md`](../spec-ui.md) — conventions UI globales
- [`screen-producer-02-product-catalog.md`](screen-producer-02-product-catalog.md) — catalogue de types de produits (point d'entrée vers cet écran)
- [`../common/screen-common-03-delivery-description.md`](../common/screen-common-03-delivery-description.md) — utilisation des composants dans la description d'une livraison
