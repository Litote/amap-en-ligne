# Création d'Organisation

## Description
Interface permettant à un utilisateur de créer une nouvelle organisation (AMAP, coopérative, etc.) qui doit être soumise aux administrateurs pour validation avant d'être effective. Inclut la création du premier compte utilisateur coordinateur lié à cette organisation.

> **📋 Référence** : Structure détaillée dans `../../../architecture/data-model.md` - Section ORGANIZATION, MEMBER.

## Wireframe ASCII

État avec « AMAP » sélectionné :
```
┌─────────────────────────────────────────────────────────────┐
│                    🥕 Nouvelle Organisation                 │
├─────────────────────────────────────────────────────────────┤
│  ← Retour à l'accueil                          📱 [Menu]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📝 Créer une nouvelle organisation                         │
│                                                             │
│  ℹ️  Votre demande sera examinée par notre équipe.          │
│      Vous recevrez une confirmation par email               │
│      sous 3 jours ouvrés.                                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🏢 INFORMATIONS ORGANISATION                       │   │
│  │                                                     │   │
│  │  Type d'organisation *                              │   │
│  │  (●) AMAP  ( ) Producteur                          │   │
│  │                                                     │   │
│  │  Nom de l'AMAP *                                    │   │
│  │  [________________________________]                │   │
│  │                                                     │   │
│  │  Fuseau horaire *                                   │   │
│  │  [Europe/Paris ▼]                                   │   │
│  │                                                     │   │
│  │  Langue par défaut *                                │   │
│  │  [Français ▼]                                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  👤 COMPTE ADMINISTRATEUR DE L'ORGANISATION         │   │
│  │                                                     │   │
│  │  Prénom *                                           │   │
│  │  [________________________________]                │   │
│  │                                                     │   │
│  │  Nom *                                              │   │
│  │  [________________________________]                │   │
│  │                                                     │   │
│  │  Email *                                            │   │
│  │  [________________________________]                │   │
│  │                                                     │   │
│  │  ℹ️  Le mot de passe sera défini via le lien       │   │
│  │      d'activation envoyé par email.                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ☑️ J'accepte les conditions d'utilisation du service      │
│                                                             │
│  [ANNULER]                     [CRÉER] 🟢       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

État avec « Producteur » sélectionné (seul le libellé du champ nom change) :
```
│  │  Type d'organisation *                              │   │
│  │  ( ) AMAP  (●) Producteur                          │   │
│  │                                                     │   │
│  │  Nom du producteur *                                │   │
│  │  [________________________________]                │   │
```

## Navigation et interactions

### Actions principales
- **[CRÉER]** : Validation et envoi de la demande de création d'organisation
- **[ANNULER]** : Retour à l'écran de connexion ou d'accueil
- **← Retour à l'accueil** : Navigation vers l'écran de connexion

### Validation des données
- **Champs obligatoires** : Marqués d'un astérisque (*) — dont le type d'organisation (*OrganizationType*) — validation côté client et serveur
- **Type d'organisation** : Sélection obligatoire entre « AMAP » (association de consommateurs) et « Producteur » (`PRODUCER` — exploitation agricole)
- **Format email** : Vérification de la validité des adresses email
- **Unicité** : Vérification que le nom d'organisation et l'email coordinateur n'existent pas déjà

### États de l'interface
- **Formulaire vide** : État initial avec bouton [CRÉER] désactivé
- **Saisie en cours** : Validation temps réel des champs obligatoires
- **Validation** : Indicateur de traitement et vérifications serveur
- **Succès** : Confirmation de soumission avec message d'information
- **Erreur** : Affichage des erreurs de validation avec corrections suggérées

### Processus de validation administrative
- **Soumission** : Création d'une demande avec statut "PENDING_VALIDATION"
- **Notification admin** : Email automatique aux administrateurs
- **Examen** : Vérification manuelle des informations par l'équipe administrative
- **Décision** : Validation ou refus avec commentaires
- **Notification utilisateur** : Email de confirmation ou de refus avec explications

### Feedback utilisateur
- **Messages d'aide** : Tooltips explicatifs sur les champs complexes
- **Indicateurs de progression** : Barre de progression du formulaire
- **Validation temps réel** : Affichage immédiat des erreurs de saisie
- **Confirmation** : Modal de récapitulatif avant soumission définitive

## États post-soumission

### Écran de confirmation
```
┌─────────────────────────────────────────────────────────────┐
│                    🥕 Demande Envoyée                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ✅ Demande de création d'organisation soumise             │
│                                                             │
│  📧 Un email de confirmation a été envoyé à :              │
│     contact@votre-organisation.fr                          │
│                                                             │
│  ⏱️  Délai de traitement habituel : moins de 3 jours ouvrés │
│                                                             │
│  📋 Référence de votre demande : ORG-2025-001234           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  📝 Prochaines étapes :                             │   │
│  │                                                     │   │
│  │  1. Examen de votre demande par notre équipe       │   │
│  │  2. Définition de votre mot de passe par email     │   │
│  │  3. Accès à votre espace d'administration          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [RETOUR À L'ACCUEIL]                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Notification par email
- **Email de confirmation** : Récapitulatif de la demande et référence
- **Email de validation** : Lien d'activation permettant de définir le mot de passe et d'accéder pour la première fois à l'espace d'administration
- **Email de refus** : Explications et possibilité de correction/resoumission

## Références

### Documentation liée
- **Spécifications UI** : [`spec-ui.md`](spec-ui.md) - Section "Gestion des organisations"
- **Données** : `../../../architecture/data-model.md` - Entités ORGANIZATION, MEMBER
- **Navigation** : [Écran 2 - Login](screen-02-login.md) et [Gestion des utilisateurs](admin/screen-admin-03-user-management.md)
- **Processus** : `../regles-metier.md` - Validation et activation des organisations
