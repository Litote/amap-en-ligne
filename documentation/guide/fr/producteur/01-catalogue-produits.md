# Gérer mon catalogue de produits

## À quoi ça sert

Décrire ce que vous proposez : vos **types de produits** (par exemple « Légumes Bio »,
« Œufs fermiers »), les **tailles de panier** associées, et la liste des **composants** qui
peuvent entrer dans chaque type de produit.

## Vos types de produits

Ouvrez l'écran **Types de produits**. Vous y voyez la liste de vos produits, chacun avec
son nom, sa description et son nombre de tailles de panier.

```
┌──────────────────────────────────────────────
│  Types de produits                        [↻]
│  Légumes Bio
│  Panier hebdomadaire de légumes           3
│  Oeufs fermiers
│  Oeufs de poules en plein air             2
│                                          [ + ]
└──────────────────────────────────────────────
```

### Créer un type de produit

1. Touchez le bouton **[ + ]**.
2. Renseignez le **Nom** (obligatoire) et, si vous le souhaitez, une **Description**.
3. Renseignez les **Tailles de panier**, séparées par des virgules (par exemple
   « Petit, Moyen, Grand »).
4. Touchez **[Enregistrer]**.

### Modifier un type de produit

Touchez la ligne du produit, ajustez les champs, puis **[Enregistrer]**.

### Supprimer un type de produit

Faites glisser la ligne vers la gauche pour la supprimer.

> Vos modifications sont enregistrées localement immédiatement, même hors connexion,
> puis synchronisées avec le serveur. Le bouton de synchronisation **[↻]** en haut
> permet de forcer une synchronisation.

## Les composants d'un type de produit

Un **composant** est un élément nommé (et éventuellement illustré) qui peut entrer dans
vos paniers — par exemple « Carottes », « Courgettes », « Poireaux ». Vous définissez
le catalogue de composants **une seule fois** par type de produit, puis vous le
réutilisez pour décrire chaque livraison.

### Gérer les composants

1. Ouvrez un type de produit existant, puis touchez la carte **Catalogue de
   composants**.
2. Touchez **[ + ]** pour ajouter un composant : renseignez son **Nom** (obligatoire)
   et, si vous le souhaitez, une **Image SVG (optionnel)**. Touchez **[Ajouter]**.
3. Pour supprimer un composant, touchez l'icône **corbeille** de sa ligne. Pour en
   changer le nom ou l'image, supprimez-le puis recréez-le.

> **L'image** est une petite icône au format **SVG** : collez directement son code
> (qui commence par `<svg`). Les autres formats (photo, adresse d'image) ne sont pas
> acceptés, et l'icône doit rester légère (10 000 caractères au maximum).

## Voir aussi

- [Décrire le contenu d'une livraison](02-contenu-des-livraisons.md)
