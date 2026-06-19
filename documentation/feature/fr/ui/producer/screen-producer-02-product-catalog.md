# Catalogue de types de produits

## Description

Interface principale de gestion du catalogue produits d'un compte producteur (*ProducerAccount*). Accessible uniquement aux utilisateurs avec le rôle PRODUCER.

- **Routes** : `/product-types` (liste), `/product-types/new` (création), `/product-types/:id` (édition)
- **Accès** : authentifié, rôle PRODUCER requis

## Écran liste — `/product-types`

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│  Types de produits                    [sync]│
├─────────────────────────────────────────────┤
│  Légumes Bio                                │
│  Panier hebdomadaire de légumes         3   │
│  ────────────────────────────────────────   │
│  Oeufs fermiers                             │
│  Oeufs de poules élevées en plein air   2   │
│  ────────────────────────────────────────   │
│  Pain artisanal                             │
│                                         1   │
│                                             │
│                                      [  +  ]│
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Titre AppBar : "Types de produits"
- Bouton de synchronisation manuelle dans l'AppBar (icône de rechargement ; remplacé par un spinner pendant la synchronisation).
- La liste est alimentée en temps réel par un stream drift des types de produits (*PRODUCT_TYPE*) appartenant au compte producteur connecté.
- Chaque entrée affiche : nom, description (optionnelle) et nombre de tailles de panier (*BASKET_SIZE*).
- Swipe gauche sur une entrée : suppression immédiate (offline-first) avec déclenchement de la synchronisation.
- Tap sur une entrée : ouverture du formulaire d'édition (`/product-types/:id`).
- FAB [+] : ouverture du formulaire de création (`/product-types/new`).
- Liste vide : message "Aucun type de produit."

### Bandeau d'état de synchronisation

Un bandeau s'affiche en haut de la liste selon l'état de la synchronisation :

| Situation | Contenu du bandeau |
|-----------|--------------------|
| Échec de synchronisation | "Échec de la synchronisation : [message]" + bouton [Réessayer] |
| Mutations rejetées | "[N] mutation(s) rejected" + bouton [Ignorer] |
| Synchronisation réussie | Aucun bandeau affiché |

## Formulaire création/édition

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Nouveau type de produit                   │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ Nom *                               │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Description                         │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Tailles de panier (séparées par     │    │
│  │ des virgules)                       │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [Enregistrer]                              │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Titre AppBar : "Nouveau type de produit" (création) ou "Modifier le type de produit" (édition).
- Champ "Nom" : obligatoire.
- Champ "Description" : optionnel.
- Champ "Tailles de panier" : liste de noms séparés par des virgules (ex. "Petit, Moyen, Grand").
- [← Retour] dans l'AppBar ramène à la liste.

**Création** : le bouton [Enregistrer] crée un type de produit avec un identifiant temporaire `tmp_*` dans le cache local (offline-first) puis déclenche une synchronisation. L'identifiant définitif est attribué par le serveur lors de la prochaine synchronisation réussie.

**Édition** : le bouton [Enregistrer] met à jour l'entrée depuis le cache local puis déclenche une synchronisation.

## Références

- [`../spec-ui.md`](../spec-ui.md) — conventions UI globales
- [`screen-producer-01-home.md`](screen-producer-01-home.md) — tableau de bord producteur (point d'entrée vers ce catalogue)
