# Configuration de l'organisation

## Description

Formulaire d'édition de l'identité de l'AMAP (*Organization*). Accessible uniquement au rôle `ADMIN`, cet écran permet de modifier le nom, les coordonnées de contact et les paramètres généraux de l'organisation.

Les modifications sont soumises via un upsert standard de l'agrégat `Organization` par le mécanisme de synchronisation, sans procédure spécifique.

## Wireframe ASCII

```
┌─────────────────────────────────────────────────────────────┐
│  ←  Configuration de l'organisation             [Menu]      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Identité de l'AMAP                                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Nom de l'organisation *                             │   │
│  │  [AMAP Les Jardins du Soleil__________________]      │   │
│  │                                                      │   │
│  │  Email de contact *                                  │   │
│  │  [contact@amap-jardins.fr_____________________]      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  Paramètres régionaux                                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Fuseau horaire                                      │   │
│  │  [Europe/Paris________________________________]      │   │
│  │                                                      │   │
│  │  Langue par défaut                                   │   │
│  │  [fr__________________________________________]      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  Présence en ligne                                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Site web                                            │   │
│  │  [https://www.amap-jardins.fr_________________]      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│              [ENREGISTRER LES MODIFICATIONS]                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Les champs marqués d'un astérisque (*) sont obligatoires.

## Navigation et interactions

| Contrôle | Comportement |
|----------|-------------|
| **← (retour)** | Retour à l'écran précédent |
| **[Menu]** | Ouvre le menu de navigation |
| **Champ « Nom de l'organisation »** | Saisie texte libre, obligatoire |
| **Champ « Email de contact »** | Saisie texte libre, obligatoire, validé en tant qu'adresse email |
| **Champ « Fuseau horaire »** | Saisie texte libre, facultatif (ex. `Europe/Paris`) |
| **Champ « Langue par défaut »** | Saisie texte libre, facultatif (ex. `fr`) |
| **Champ « Site web »** | Saisie texte libre, facultatif, validé en tant qu'URL lorsque renseigné |
| **[ENREGISTRER LES MODIFICATIONS]** | Valide le formulaire et soumet un upsert de l'agrégat `Organization` (*ORGANIZATION*) via la synchronisation standard ; affiche une confirmation visuelle en cas de succès |

## États de l'interface

| État | Description |
|------|-------------|
| **Chargement initial** | Les champs sont pré-remplis avec les valeurs actuelles de l'organisation, issues du cache local. |
| **Validation en erreur** | Si le champ « Nom de l'organisation » est vide, si l'email n'est pas valide, ou si le site web renseigné n'est pas une URL valide, les champs concernés affichent un message d'erreur sous le champ ; le formulaire n'est pas soumis tant que les erreurs persistent. |
| **Enregistrement en cours** | Le bouton [ENREGISTRER LES MODIFICATIONS] est désactivé pendant la soumission. |
| **Succès** | Une confirmation est affichée : « Modifications enregistrées. » |

## Règles métier

- Seul un membre portant le rôle `ADMIN` peut accéder à cet écran.
- Le champ `name` est obligatoire ; il ne peut pas être vide ou composé uniquement d'espaces.
- Le champ `contactEmail` est obligatoire et doit respecter le format d'une adresse email valide.
- Les champs `timezone`, `defaultLanguage` et `website` sont facultatifs.
- Le champ `website`, lorsqu'il est renseigné, doit être une URL valide.
- La sauvegarde s'effectue par un upsert standard de l'agrégat `Organization` — aucun mécanisme spécifique en dehors de la synchronisation habituelle n'est employé.
- Il n'existe pas de suppression d'organisation depuis cet écran.

## Références

- **Menu de navigation** : [`../common/screen-common-01-menu.md`](../common/screen-common-01-menu.md)
- **Écran admin principal** : [`screen-admin-01-home.md`](screen-admin-01-home.md)
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
