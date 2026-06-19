# Description d'une livraison

## Description

Interface de consultation et de saisie du contenu d'une livraison (*DELIVERY*) pour un type de produit donné. La description précise, pour chaque taille de panier (*BASKET_SIZE*), les items (*ItemType*) inclus et, le cas échéant, leur poids.

Cet écran est accessible depuis deux perspectives :

| Perspective | Route | Acteur |
|-------------|-------|--------|
| Producteur | `/product-types/deliveries/:deliveryId/description` | PRODUCER |
| Coordinateur | `/coordinator/deliveries/:deliveryId/description` | COORDINATOR |

L'interface est identique dans les deux cas ; seul l'accès en modification est réservé au producteur.

## Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Légumes Bio — Livraison 17 Jan            │
├─────────────────────────────────────────────┤
│  Panier Petit                               │
│  ────────────────────────────────────────   │
│  [img] Carottes          500 g              │
│  [img] Courgettes        300 g              │
│        Poireaux          —                  │
│                                      [  +  ]│
│                                             │
│  Panier Moyen                               │
│  ────────────────────────────────────────   │
│  [img] Carottes          800 g              │
│  [img] Courgettes        500 g              │
│        Poireaux          200 g              │
│                                      [  +  ]│
│                                             │
│  Panier Grand                               │
│  ────────────────────────────────────────   │
│  (aucun item défini)                 [  +  ]│
└─────────────────────────────────────────────┘
```

## Contenu et comportement

- Titre AppBar : nom du type de produit suivi de la date de livraison.
- [← Retour] dans l'AppBar : retour vers l'écran précédent.
- La liste est organisée par taille de panier (*BASKET_SIZE*), dans l'ordre défini sur le type de produit.
- Pour chaque taille de panier, les items présents dans la description (`BasketDeliveryDescription`) sont listés avec :
  - l'image miniature de l'item si une URL est renseignée ;
  - le nom de l'item (*ItemType*) ;
  - le poids associé, si renseigné, ou "—" si absent.
- Si aucun item n'est défini pour une taille de panier, la mention "(aucun item défini)" est affichée.

### Perspective producteur (modification activée)

- FAB [+] sous chaque taille de panier : ajout d'un item à cette taille de panier.
- Tap sur un item existant : ouverture du formulaire d'édition du poids.
- Swipe gauche sur un item : suppression de l'item de cette taille de panier.

### Perspective coordinateur (lecture seule)

- Aucune action de modification n'est disponible.
- Le FAB [+] n'est pas affiché.

## Formulaire d'ajout / édition d'un item de livraison

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Ajouter un item — Panier Petit            │
├─────────────────────────────────────────────┤
│                                             │
│  Item *                                     │
│  ┌─────────────────────────────────────┐    │
│  │ Carottes                          ▼ │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ Poids (g, optionnel)                │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [Enregistrer]                              │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Titre AppBar : "Ajouter un item — [nom de la taille de panier]" (ajout) ou "Modifier l'item — [nom de la taille de panier]" (édition).
- Sélecteur "Item" : liste déroulante des items (*ItemType*) définis sur le type de produit ; obligatoire. Un item déjà présent dans la description pour cette taille de panier ne peut pas être sélectionné à nouveau.
- Champ "Poids (g)" : optionnel, valeur entière positive.
- [Enregistrer] : enregistre la modification.
- [← Retour] dans l'AppBar : annule et retourne à la description sans enregistrer.

## Références

- [`../spec-ui.md`](../spec-ui.md) — conventions UI globales
- [`../producer/screen-producer-03-item-catalog.md`](../producer/screen-producer-03-item-catalog.md) — définition du catalogue d'items d'un type de produit
- [`../producer/screen-producer-02-product-catalog.md`](../producer/screen-producer-02-product-catalog.md) — catalogue de types de produits (perspective producteur)
- [`../coordinator/screen-coordinator-01-home.md`](../coordinator/screen-coordinator-01-home.md) — tableau de bord coordinateur (perspective coordinateur)
