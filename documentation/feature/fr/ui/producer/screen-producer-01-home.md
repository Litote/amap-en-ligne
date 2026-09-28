# Dashboard Producteur

## Description
Interface d'accueil dédiée aux producteurs, présentant les informations essentielles sur leurs livraisons, contrats actifs, et gestion de production pour les organismes partenaires.

> **📋 Référence** : Structure détaillée dans `../../../../architecture/data-model.md` - Section PRODUCER_ACCOUNT, PRODUCER, CONTRACT, DELIVERY.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                      🥕 Producteurs                    │
├─────────────────────────────────────────────────────────────┤
│  🏭 Ferme Bio des Collines - Pierre Martin    📱 [Menu]     │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  📊 Vue d'ensemble                                          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📈 Saison 2025                                        │ │
│  │  • 3 contrats actifs • 127 paniers/semaine             │ │
│  │  • 2 organismes partenaires                            │ │
│  │  • Prochaine livraison : Mercredi 17 Jan               │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  🎯 Livraisons urgentes                                     │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  ⚠️ URGENT - Mercredi 17 Jan • AMAP Les Jardins        │ │
│  │  🥬 Paniers légumes bio • 45 paniers MEDIUM            │ │
│  │  📅 Préparation requise avant 12h                      │ │
│  │  [📋 DÉTAILS] [✅ MARQUER PRÊT]                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📅 Prochaines livraisons                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Mercredi 31 Jan • AMAP Les Jardins                 │ │
│  │  🥬 Paniers légumes bio • 45 MEDIUM                    │ │
│  │  ✅ Préparation confirmée • [📋 DÉTAILS]                │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Jeudi 1 Fév • Coop Bio Ville                      │ │
│  │  🍎 Fruits de saison • 32 SMALL + 15 LARGE            │ │
│  │  ⏳ En attente de préparation • [📋 DÉTAILS]            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📊 Mes contrats actifs                                     │
│  • AMAP Les Jardins - Légumes bio (45 paniers/semaine)     │
│  • Coop Bio Ville - Fruits (47 paniers/semaine)           │
│  • AMAP Centre - Légumes (35 paniers/semaine)              │
│                                                             │
│ [📋 GÉRER PRODUCTION]    [📊 RAPPORTS]    [⚙️ PARAMÈTRES]   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[📋 DÉTAILS]** : Navigation vers le détail de la livraison spécifique
- **[✅ MARQUER PRÊT]** : Confirmation que la production est prête pour livraison
- **[📋 GÉRER PRODUCTION]** : Navigation vers l'interface de gestion des produits et planification
- **[📊 RAPPORTS]** : Navigation vers les statistiques et rapports de production
- **[⚙️ PARAMÈTRES]** : Navigation vers les préférences producteur
- **[Menu]** : Accès au menu principal de navigation producteur

### États dynamiques
- **Livraisons urgentes** : Affichage en rouge ⚠️ avec deadline claire
- **Préparation confirmée** : État validé avec ✅ et accès aux détails
- **En attente** : État neutre ⏳ avec possibilité d'action
- **Vue d'ensemble** : Métriques actualisées en temps réel

### Données affichées
- Informations du compte producteur connecté
- Statistiques de la saison en cours
- Livraisons prioritaires nécessitant une action
- Planning des prochaines livraisons avec statuts
- Liste des contrats actifs avec volumes

### Notifications et alertes
- **Deadline approchant** : Alerte visuelle 24h avant échéance
- **Livraison urgente** : Notification push et mise en avant rouge
- **Confirmation requise** : Rappel pour validation de préparation
- **Nouveaux contrats** : Notification des nouvelles opportunités

## Gestion des statuts livraison

### États possibles
- **⚠️ URGENT** : Deadline dans moins de 24h, action requise
- **✅ PRÊT** : Production confirmée et prête pour livraison
- **⏳ EN ATTENTE** : Préparation pas encore démarrée
- **🚚 EN LIVRAISON** : Livraison en cours chez le partenaire
- **✅ LIVRÉE** : Livraison terminée et confirmée

### Actions disponibles
- **[✅ MARQUER PRÊT]** : Confirmer que la production est terminée
- **[📝 AJOUTER NOTES]** : Ajouter des notes de préparation ou alertes
- **[📞 CONTACTER]** : Contact direct avec le coordinateur du contrat
- **[📋 DÉTAILS]** : Accès aux spécifications détaillées de la commande

## Métriques producteur

### Indicateurs clés
- **Contrats actifs** : Nombre de contrats en cours
- **Volume hebdomadaire** : Total de paniers à produire par semaine
- **Organismes partenaires** : Nombre d'AMAP/coopératives desservies
- **Taux de ponctualité** : Pourcentage de livraisons à l'heure
- **Satisfaction clients** : Note moyenne des organismes partenaires

### Suivi de performance
- **Livraisons réussies** : Historique des livraisons terminées
- **Retards** : Suivi des retards et causes identifiées
- **Qualité** : Feedback des coordinateurs sur la qualité
- **Évolution saisonnière** : Comparaison avec les saisons précédentes

## Intégration organismes

### Flux de communication
- **Réception commandes** : Intégration automatique des besoins
- **Confirmation production** : Validation de la capacité de production
- **Mise à jour statuts** : Communication temps réel avec les coordinateurs
- **Alertes partagées** : Notification mutuelle en cas de problème

### Données partagées
- **Planning livraisons** : Synchronisation avec les organismes
- **Spécifications produits** : Détails des produits et conditionnement
- **Quantités** : Volumes exacts par taille de panier
- **Contact urgence** : Coordination directe en cas d'imprévu

## États d'urgence

### Gestion des priorités
- **Deadline < 24h** : Alerte rouge automatique
- **Production en retard** : Escalade vers les coordinateurs
- **Problème qualité** : Système d'alerte et de replacement
- **Météo défavorable** : Notification préventive aux partenaires

### Actions d'urgence
- **[🚨 SIGNALER PROBLÈME]** : Notification immédiate aux coordinateurs
- **[📞 URGENCE]** : Contact direct avec tous les partenaires concernés
- **[🔄 REPORTER]** : Demande de report avec proposition alternative
- **[⚠️ ANNULER]** : Annulation exceptionnelle avec justification

## Références

### Documentation liée
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md) - Section "Dashboard producteur"
- **Données** : `../../../../architecture/data-model.md` - Entités PRODUCER_ACCOUNT, PRODUCER, CONTRACT, DELIVERY_CONTRACT
- **Navigation** : menu principal version producteur
- **Règles métier** : `../../regles-metier.md` - Gestion de production et responsabilités
- **Intégration** : Voir écrans 3, 7 pour les interactions coordinateur-producteur

### Actions connexes
- **Gestion production** : Interface de planification et suivi des cultures
- **Rapports** : Statistiques et analyses de performance
- **Paramètres** : Configuration des préférences et notifications producteur
- **Support** : Contact et assistance technique dédiée
