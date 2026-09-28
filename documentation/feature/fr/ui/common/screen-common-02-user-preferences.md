# Préférences utilisateur

## Description
Interface de configuration des préférences personnelles de l'utilisateur, notamment pour la gestion des notifications liées aux inscriptions bénévoles et aux alertes du système.

> **📋 Référence** : Structure détaillée dans `../../../../architecture/data-model.md` - Section MEMBER, USER_PREFERENCES.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                    ⚙️ Mes préférences                      │
├─────────────────────────────────────────────────────────────┤
│  ← Retour                                        📱 [Menu]   │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  👤 Profil utilisateur                                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Nom : Marie Dupont                                     │ │
│  │  Email : marie.dupont@example.com                       │ │
│  │  Téléphone : 06 12 34 56 78                            │ │
│  │  [MODIFIER MES INFORMATIONS]                            │ │
│  │  [EXPORTER MES DONNÉES]                                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📱 Notifications bénévolat                                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  🔔 Rappels d'inscription                               │ │
│  │  ✅ Rappel 24h avant la livraison                      │ │
│  │  ✅ Rappel 2h avant la livraison                       │ │
│  │  □ Rappel 30min avant la livraison                     │ │
│  │                                                         │ │
│  │  🚨 Alertes d'urgence                                   │ │
│  │  ✅ Notifier si besoin urgent de bénévoles             │ │
│  │  □ Rappels manque de volontaire(s) sur la livraison    │ │
│  │  ✅ Modifications de planning                           │ │
│  │                                                         │ │
│  │  📧 Canaux de notification                              │ │
│  │  ✅ Notifications push                                  │ │
│  │  ✅ Email                                               │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ✏️ Personnalisation des alertes   (Admin uniquement)       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Laissez un champ vide pour le message par défaut.      │ │
│  │                                                         │ │
│  │  Créneau annulé                                         │ │
│  │  Titre   [____________________________________]         │ │
│  │  Corps   [____________________________________]         │ │
│  │  Horaire de créneau modifié                             │ │
│  │  Titre   [____________________________________]         │ │
│  │  Corps   [____________________________________]         │ │
│  │  … (une entrée par type d'alerte)                       │ │
│  │                                                         │ │
│  │             [ENREGISTRER LES ALERTES]                   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  💾 Sauvegarde & migration   (Admin uniquement)             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Exportez les données de votre AMAP dans un fichier,    │ │
│  │  ou restaurez une sauvegarde dans une AMAP vide.        │ │
│  │  [EXPORTER L'AMAP]                                      │ │
│  │  [IMPORTER UNE SAUVEGARDE]   (web uniquement)           │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│               [ENREGISTRER LES MODIFICATIONS]               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Sections principales

#### 👤 **Profil utilisateur**
- **Informations personnelles** : Nom, email, téléphone
- **[MODIFIER MES INFORMATIONS]** : Edition des données de base
- **[EXPORTER MES DONNÉES]** : Export du cache SQLite local de l'utilisateur au format ZIP
- **Validation** : Vérification email/téléphone pour certaines notifications

#### 📱 **Notifications bénévolat**
- **Rappels d'inscription** : Configuration des alertes avant livraisons
  - Rappel 24h avant (recommandé)
  - Rappel 2h avant (recommandé)
  - Rappel 30min avant (optionnel)
- **Alertes d'urgence** : Notifications pour livraisons critiques
  - Besoin urgent de bénévoles
  - Manque de volontaire(s) sur la livraison (relances)
  - Modifications du planning
- **Canaux de notification** : Choix des moyens de contact
  - Notifications push (mobile)
  - Email (toujours disponible)

#### ✏️ **Personnalisation des alertes** (Admin uniquement)

Visible uniquement pour les membres ayant le rôle **Admin**. Permet de personnaliser le **titre** et le **corps** du message envoyé pour chaque type d'alerte de l'AMAP (créneau annulé, horaire de créneau modifié, rappel de livraison, demandes d'échange de panier reçues/acceptées/refusées, nouvelle demande d'adhésion).

- Chaque type d'alerte propose deux champs **facultatifs** : un titre et un corps. Laissés vides, le message par défaut du système est utilisé pour la partie concernée.
- Le texte saisi remplace **tel quel** le message par défaut (aucune variable n'est interprétée).
- La configuration s'applique à **toute l'AMAP** (elle est portée par l'organisation, pas par l'utilisateur) et concerne aussi bien la notification dans l'application que l'e-mail et la notification push correspondants.
- Le bouton **[ENREGISTRER LES ALERTES]** sauvegarde uniquement cette section, indépendamment du bouton principal [ENREGISTRER LES MODIFICATIONS].

> Les alertes destinées aux administrateurs d'instance (demande de création d'AMAP ou de compte producteur) ne sont pas personnalisables ici : elles ne dépendent d'aucune AMAP.

#### 💾 **Sauvegarde & migration** (Admin uniquement)

Visible uniquement pour les membres ayant le rôle **Admin**. Permet de sauvegarder les données de l'AMAP (*organization* (*ORGANIZATION*) : adhérents, producteurs, contrats, livraisons, modèles de créneaux…) dans un fichier `.json`, et de restaurer une sauvegarde dans une autre AMAP — pour un archivage ou une migration d'instance.

- **[EXPORTER L'AMAP]** : télécharge un fichier `.json` contenant l'ensemble des données de l'AMAP. Disponible sur toutes les plateformes.
- **[IMPORTER UNE SAUVEGARDE]** : restaure un fichier de sauvegarde dans l'AMAP courante. **Web uniquement** dans cette version (le bouton est masqué sur mobile). L'AMAP cible doit être **vide** ; sinon l'import est refusé.
- Les adhérents (*member* (*MEMBER*)) importés conservent leurs informations mais **pas leur compte de connexion** : ils doivent être (ré)invités via le flux d'activation habituel pour pouvoir se connecter.

### Actions disponibles

#### Modification des préférences
- **Cases à cocher** : Activation/désactivation immédiate
- **Sélection multiple** : Livraisons et activités préférées
- **Validation globale** : Bouton [ENREGISTRER LES MODIFICATIONS]

#### Navigation
- **← Retour** : Retour à l'écran précédent
- **[Menu]** : Accès au menu principal
- **[MODIFIER MES INFORMATIONS]** : Edition du profil
- **[EXPORTER MES DONNÉES]** : Télécharge un fichier `.zip` contenant `amap_en_ligne.sqlite`

## Logique applicative

### Sauvegarde des préférences
```
Modifications → Validation → Mise à jour base → Confirmation utilisateur
```

### Export des données locales
```
Clic sur [EXPORTER MES DONNÉES] → Lecture de la base SQLite locale → Création d'une archive ZIP → Téléchargement / enregistrement du fichier → Confirmation utilisateur
```

### Sauvegarde & migration de l'AMAP (Admin)
```
[EXPORTER L'AMAP] → Téléchargement de l'archive JSON de l'AMAP → Confirmation
[IMPORTER UNE SAUVEGARDE] (web) → Choix d'un fichier JSON → Envoi au serveur → Restauration si l'AMAP cible est vide → Rafraîchissement des données → Confirmation (ou message d'erreur si l'AMAP n'est pas vide / fichier invalide)
```

### Application automatique
- **Inscriptions futures** : Utilisation des préférences sauvegardées
- **Suggestions personnalisées** : Livraisons recommandées selon préférences
- **Notifications ciblées** : Uniquement selon les canaux activés

### Validation des canaux
- **Email** : Toujours disponible (obligatoire pour le compte)
- **Push** : Activation selon autorisation mobile

> Le SMS n'est pas un canal disponible (transport payant — voir ADR-005).

## États et contraintes

### Contraintes techniques
- **Email obligatoire** : Au moins un canal doit rester actif
- **Cohérence temporelle** : Rappels dans l'ordre chronologique logique

### États d'activation
- **✅ Activé** : Fonction opérationnelle
- **□ Désactivé** : Fonction inactive
- **🔒 Bloqué** : Fonction nécessitant une action (ex: vérification téléphone)

### Feedback utilisateur
```
┌─────────────────────────────────────────────────────────────┐
│  ✅ Préférences enregistrées avec succès !                 │
│  📱 Vos notifications sont maintenant configurées          │
└─────────────────────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────────────────────┐
│  ✅ Export ZIP enregistré / téléchargé                     │
│  🗄️ Archive contenant la base locale de l'utilisateur      │
└─────────────────────────────────────────────────────────────┘
```

## Impact sur le système

### Inscription automatique
Lors d'une inscription via [S'INSCRIRE] :
1. **Application des préférences** : Rappels selon configuration
2. **Programmation automatique** : Notifications selon timing choisi
3. **Canaux utilisés** : Uniquement ceux activés dans les préférences


## Références

### Documentation liée
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md) - Section "Gestion des notifications"
- **Données** : `../../../../architecture/data-model.md` - Entités MEMBER, USER_PREFERENCES
- **Navigation** : Accessible depuis menu principal et profil utilisateur
- **Écrans liés** : Retour vers l'écran précédent après sauvegarde
- **Système notifications** : Configuration centralisée pour toute l'application

### Intégration système
- **Persistance** : Sauvegarde en base de données des préférences
- **Application temps réel** : Mise à jour immédiate des notifications programmées
- **Synchronisation** : Cohérence entre préférences et comportement applicatif
- **Export local** : Lecture de la base Drift/SQLite courante puis empaquetage dans une archive ZIP
