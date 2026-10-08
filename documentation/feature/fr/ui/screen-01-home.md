# Accueil Public

## Description
Page d'accueil non authentifiée de l'application qui présente l'applicatif et offre quatre actions principales : connexion à un compte existant, préinscription à une AMAP existante, création d'une nouvelle AMAP, ou demande d'un espace producteur.
Si l'utilisateur est déjà connecté, il est redirigé vers la home correspondant à son profil.

> **📋 Référence** : Structure détaillée dans `../../../architecture/data-model.md` - Section ORGANIZATION, MEMBER.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                    🥕  Amap en ligne                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  J'ai déjà un compte                                │   │
│  │  Connectez-vous à votre espace personnel            │   │
│  │  [SE CONNECTER] 🟢                                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Je veux rejoindre une AMAP                         │   │
│  │  Préinscrivez-vous                                  │   │
│  │                                                     │   │
│  │  ┌ Choisir une AMAP ─────────────────────────────┐  │   │
│  │  │ AMAP des Collines                           ▼ │  │   │
│  │  ├───────────────────────────────────────────────┤  │   │
│  │  │ Coopérative Bio Locale                        │  │   │
│  │  │ AMAP du Plateau                               │  │   │
│  │  │ [...]                                         │  │   │
│  │  └───────────────────────────────────────────────┘  │   │
│  │  [S'INSCRIRE À UNE AMAP] 🔵                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Je veux créer une AMAP                             │   │
│  │  [CRÉER UNE AMAP] 🟠                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Je suis producteur                                 │   │
│  │  Demandez votre espace producteur                   │   │
│  │  [CRÉER SON COMPTE PRODUCTEUR]                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ───────────────────────────────────────────────────────   │
│                                                             │
│  Qu'est-ce qu'une AMAP ?                                   │
│  Les AMAP (Association pour le Maintien d'une Agriculture  │
│  Paysanne) créent des liens directs entre producteurs et   │
│  consommateurs autour de produits locaux et de saison.     │
│                                                             │
│  Amap en Ligne est libre (AGPL), sans coût d'utilisation   │
│  et auto-hébergeable.                                      │
│  [Guide d'utilisation]   [Code source]   [À propos]        │
│  (sur une seule ligne si la largeur le permet — desktop ;  │
│   retour à la ligne sur mobile)                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Sur mobile, la même colonne est conservée : les cartes occupent toute la largeur et les liens du bas passent à la ligne.

## Navigation et interactions

### Actions principales
- **[SE CONNECTER]** : Navigation vers [Écran 2 - Login](screen-02-login.md) pour utilisateurs existants
- **[S'INSCRIRE À UNE AMAP]** : Ouvre la préinscription à une organisation existante, avec l'AMAP choisie dans la liste déroulante présélectionnée
- **[CRÉER UNE AMAP]** : Navigation vers [Écran 3 - Création Organisation](screen-03-organization-creation.md)
- **[CRÉER SON COMPTE PRODUCTEUR]** : Ouvre le formulaire de demande d'espace producteur (*PRODUCER_REQUEST*)

### Actions secondaires
- **[Guide d'utilisation]** : Ouvre dans un nouvel onglet / le navigateur le guide d'utilisation publié de l'instance (`guide_url` du document de découverte, ou du préréglage serveur). Masqué si l'instance n'en publie pas
- **[Code source]** : Ouvre dans un nouvel onglet / le navigateur le dépôt du code source (https://github.com/Litote/amap-en-ligne)
- **[À propos]** : Ouvre une boîte de dialogue affichant le nom de l'application et le numéro de version du build installé (`v<version> (build <numéro>)`) — utile pour vérifier quelle version est servie

### États de l'interface (carte « Je veux rejoindre une AMAP »)
- **Chargement** : Barre de progression à la place de la liste déroulante
- **Liste chargée** : Liste déroulante « Choisir une AMAP », la première AMAP étant présélectionnée
- **Aucune AMAP** : Pas de liste déroulante ; le bouton ouvre la préinscription sans AMAP présélectionnée
- **Erreur** : Message « Organisations indisponibles. » ; le bouton reste utilisable

## Règles métier

### Liste déroulante des AMAP
- **Source de données** : Liste publique des organisations (*ORGANIZATION*) de l'instance, chargée à l'ouverture de l'écran
- **Données exposées** : Nom de l'AMAP uniquement (aucune adresse e-mail de contact)

### Logiciel libre
- **Information transparente** : Mention de la licence (AGPL), de la gratuité d'utilisation et de la possibilité d'auto-hébergement, avec un lien vers le code source

## Références

### Documentation liée
- **Spécifications UI** : [`spec-ui.md`](spec-ui.md) - Section "Navigation publique"
- **Données** : `../../../architecture/data-model.md` - Entités ORGANIZATION, MEMBER
- **Navigation** : [Écran 2](screen-02-login.md) et [Écran 3](screen-03-organization-creation.md)

### Liens externes
- **Code source** : https://github.com/Litote/amap-en-ligne
