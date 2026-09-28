# Composition du panier d'une livraison

## Description

Écran de saisie du contenu d'une livraison (*DELIVERY*) : pour chaque produit présent et chaque taille de panier (*BASKET_SIZE*), les composants (*ItemType*) inclus et, le cas échéant, leur poids. Le contenu est purement informatif : les amapiens le consultent en lecture seule sur leurs cartes de livraison (section « Composition du panier »).

Le coordinateur **et** le producteur peuvent composer le panier :

| Acteur | Accès | Route | Produits proposés |
|--------|-------|-------|-------------------|
| Coordinateur (*COORDINATOR*) | Bouton « Composition du panier » du formulaire de livraison (livraison existante) | `/coordinator/deliveries/:deliveryId/description` | Tous les produits présents dans la livraison, de tous les producteurs |
| Producteur avec compte (*PRODUCER*) | Bouton **[COMPOSITION DU PANIER]** de « Mes livraisons » et des prochaines livraisons de son tableau de bord | `/producer-deliveries/:organizationId/:deliveryId/composition` | Uniquement **ses** produits présents dans la livraison, avec les tailles de panier de la livraison |

L'écran est le même dans les deux cas.

## Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ←  Composition du jeudi 1 octobre  ENREGISTRER│
├─────────────────────────────────────────────┤
│  ▼ Fromages                                 │
│    Petit                                    │
│    [img] Brie              [ 200 g   ] (−)  │
│    [+ Ajouter]                              │
│    Grand                                    │
│    [+ Ajouter]                              │
│  ▶ Oeufs                                    │
└─────────────────────────────────────────────┘
```

## Contenu et comportement

- Titre AppBar : « Composition du {jour date mois} » (ex. « Composition du jeudi 1 octobre ») ; bouton **Enregistrer** dans l'AppBar.
- Un bloc repliable par produit présent dans la livraison (les produits cochés dans « Produits présents » du formulaire de livraison) ; une livraison ancienne sans aucun produit renseigné propose tous les produits.
- Dans chaque bloc, une section par taille de panier, alignée à gauche, avec les composants choisis : icône (si le composant en a une), nom, champ **Poids** (texte libre, optionnel) et bouton de retrait.
- **[+ Ajouter]** :
  - si le producteur du produit a un catalogue de composants : liste à cocher des composants de son catalogue ;
  - sinon (ex. producteur sans compte) : formulaire de saisie libre « Ajouter un composant » (nom obligatoire, poids optionnel).
- **Enregistrer** : enregistre (hors ligne possible, synchronisation automatique), affiche « Description enregistrée » et revient à l'écran précédent.

## Règles métier

- **Validation (front et serveur)** : un nouveau composant doit avoir un nom (≤ 200 caractères) ; le poids fait au plus 200 caractères.
- **Producteur** : il ne peut composer que ses propres produits, sur les livraisons portant l'un de ses contrats, ni terminées ni annulées ; la composition des autres producteurs n'est jamais modifiée. Les icônes de ses composants sont reprises de son catalogue pour que les amapiens les voient.
- **Coordinateur** : il ne peut ajouter un composant qu'à un produit dont le producteur a un contrat lié à la livraison.
- **Deux auteurs, la dernière modification l'emporte** : chaque composition (produit × taille de panier) mémorise le moment de sa dernière modification. Un enregistrement fait depuis une copie plus ancienne (par exemple un coordinateur qui modifie un créneau de la livraison sans avoir encore reçu la composition saisie par le producteur) ne l'écrase pas.

## Références

- [`../spec-ui.md`](../spec-ui.md) — conventions UI globales
- [`../producer/screen-producer-03-item-catalog.md`](../producer/screen-producer-03-item-catalog.md) — catalogue de composants d'un type de produit
- [`../producer/screen-producer-01-home.md`](../producer/screen-producer-01-home.md) — tableau de bord producteur
- [`../coordinator/screen-coordinator-02-time-slots.md`](../coordinator/screen-coordinator-02-time-slots.md) — gestion des livraisons (formulaire de livraison)
