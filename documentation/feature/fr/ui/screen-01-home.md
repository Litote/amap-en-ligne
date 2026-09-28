# Accueil Public

## Description
Page d'accueil non authentifiée de l'application qui présente l'applicatif, ses fonctionnalités et offre trois actions principales : connexion à un compte existant, préinscription à une AMAP existante, ou création d'une nouvelle organisation.
Si l'utilisateur est déjà connecté, il est redirigé vers la home correspondant à son profil.

> **📋 Référence** : Structure détaillée dans `../../../architecture/data-model.md` - Section ORGANIZATION, MEMBER.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                    🥕  Amap en ligne                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  👤 J'ai déjà un compte                            │   │
│  │     Connectez-vous à votre espace personnel         │   │
│  │     [SE CONNECTER] 🟢                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🔍 Je veux rejoindre une AMAP                      │   │
│  │     Préinscrivez-vous                               │   │
│  │     [S'INSCRIRE À UNE AMAP] 🔵                      │   │
│  │                                                     │   │
│  │     Choisir une AMAP :                              │   │
│  │     ┌───────────────────────────────────────────┐   │   │
│  │     │ AMAP des Collines - Ville-sur-Colline    │ ▼ │   │
│  │     ├───────────────────────────────────────────┤   │   │
│  │     │ Coopérative Bio Locale - Bourg-en-Vallée │   │   │
│  │     │ AMAP du Plateau - Lyon 3ème              │   │   │
│  │     │ Les Paniers Solidaires - Marseille       │   │   │
│  │     │ [...]                                    │   │   │
│  │     └───────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🏢 Je veux créer une nouvelle organisation          │   │
│  │     (AMAP ou producteur)                            │   │
│  │     [INSCRIVEZ-VOUS] 🟠                             │   │
│  │     C'est totalement gratuit !                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ───────────────────────────────────────────────────────   │
│                                                             │
│  📖 Qu'est-ce qu'une AMAP ?                               │
│  Les AMAP (Association pour le Maintien d'une Agriculture  │
│  Paysanne) créent des liens directs entre producteurs et   │
│  consommateurs autour de produits locaux et de saison.     │
│                                                             │
│  Trouver une AMAP près de chez vous :                      │
│     - Dans toutes les régions :                            │
│       https://www.reseau-amap.org/recherche-amap.php       │
│                                                             │
│  ℹ️  Amap en Ligne est gratuit, open-source et             │
│      auto-hébergeable                                      │
│  🌐 [En savoir plus] | 🔗 [GitHub]                        │
│                                                             │
│  [À propos]                                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[SE CONNECTER]** : Navigation vers [Écran 2 - Login](screen-02-login.md) pour utilisateurs existants
- **[S'INSCRIRE À UNE AMAP]** : Ouvre la préinscription à une organisation existante
- **[INSCRIVEZ-VOUS]** : Navigation vers [Écran 3 - Création Organisation](screen-03-organization-creation.md)

### Actions secondaires
- **[En savoir plus]** : Redirection vers page d'information détaillée
- **[GitHub]** : Lien vers le repository open-source
- **[À propos]** : Ouvre une boîte de dialogue affichant le nom de l'application et le numéro de version du build installé (`v<version> (build <numéro>)`) — utile pour vérifier quelle version est servie
- **Liens AMAP** : Redirection vers les sites de recherche d'AMAP externes

### États de l'interface
- **Chargement initial** : Animation de bienvenue avec logo
- **Navigation fluide** : Transitions douces entre sections
- **Responsive** : Adaptation automatique mobile/desktop

### Fonctionnalité combo box
- **Liste déroulante** : Affichage des AMAP déjà inscrites
- **Recherche intégrée** : Filtrage en temps réel des organisations
- **Sélection directe** : Accès rapide à la préinscription pour une AMAP spécifique
- **Fallback** : Redirection vers la recherche complète si aucune sélection

## Présentation de l'application

### Section informative
- **Mission** : Faciliter la gestion des livraisons dans les organisations alimentaires locales
- **Public cible** : AMAP, coopératives, groupements d'achats
- **Valeurs** : Open-source, gratuit, local, solidaire, auto-hébergeable

### Fonctionnalités mises en avant
- **Pour les Amapiens** : Inscription simple, rappels automatiques, suivi personnel
- **Pour les coordinateurs** : Gestion des livraisons, alertes, statistiques, communication
- **Pour l'organisation** : Autonomie, transparence, efficacité

### Liens vers l'écosystème AMAP
- **Réseau AMAP national** : Recherche dans toutes les régions de France

## Optimisation mobile

### Adaptation responsive
```
┌─────────────────────────────┐
│        🥕 Amap en ligne     │
├─────────────────────────────┤
│                             │
│  [SE CONNECTER] 🟢         │
│                             │
│  [S'INSCRIRE AMAP] 🔵      │
│                             │
│  [INSCRIVEZ-VOUS] 🟠       │
│                             │
│  ℹ️ Qu'est-ce qu'une AMAP ? │
│                             │
│  [Liens utiles...]         │
│                             │
└─────────────────────────────┘
```

### Navigation mobile optimisée
- **Actions prioritaires** visibles sans scroll
- **Boutons touch-friendly** avec espacement suffisant
- **Combo box adaptée** pour interfaces tactiles
- **Liens externes** optimisés pour mobile

## SEO et référencement

### Métadonnées optimisées
- **Title** : "Amap en Ligne - Gestion simplifiée de vos livraisons AMAP"
- **Description** : "Outil gratuit et open-source pour faciliter la gestion bénévole dans votre AMAP. Inscriptions, planning, suivi temps réel."
- **Mots-clés** : AMAP, livraisons, bénévolat, agriculture paysanne, local, open-source

### Structure sémantique
- **H1** unique avec nom de l'application
- **H2** pour chaque section principale
- **Schema.org** pour les organisations locales
- **Liens externes** vers l'écosystème AMAP français

## Règles métier

### Combo box des AMAP inscrites
- **Source de données** : Liste des organisations actives dans Amap en ligne
- **Visibilité publique** : Seules les AMAP ayant accepté d'être visibles
- **Mise à jour** : Synchronisation hebdomadaire
- **Performance** : Chargement lazy si plus de 50 organisations

### Auto-hébergement
- **Information transparente** : Mention claire de la possibilité d'auto-hébergement
- **Documentation** : Liens vers les guides d'installation
- **Support** : Communauté d'entraide pour l'auto-hébergement

### Intégration écosystème AMAP
- **Complémentarité** : Amap en ligne ne remplace pas les annuaires existants
- **Orientation** : Redirection vers les ressources appropriées

## Références

### Documentation liée
- **Spécifications UI** : [`spec-ui.md`](spec-ui.md) - Section "Navigation publique"
- **Données** : `../../../architecture/data-model.md` - Entités ORGANIZATION, MEMBER
- **Navigation** : [Écran 2](screen-02-login.md) et [Écran 3](screen-03-organization-creation.md)
- **Processus** : `../regles-metier.md` - Préinscription et validation
- **Architecture** : `../../../architecture/security.md` - Données publiques et consentements

### Liens externes
- **Réseau AMAP** : https://www.reseau-amap.org/recherche-amap.php
- **Documentation Amap en Ligne** : Lien vers documentation complète
- **Repository GitHub** : Code source et guides d'installation
