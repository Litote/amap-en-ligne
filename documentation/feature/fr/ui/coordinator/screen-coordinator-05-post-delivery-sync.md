# Synchronisation post-livraison (Coordinateur)

## Description
Interface de synchronisation des validations papier avec les données numériques après la livraison.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│              📋 Finalisation livraison 17 Jan               │
├─────────────────────────────────────────────────────────────┤
│  [← Retour Dashboard]            Livraison terminée         │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  ✅ Synchronisation émargement bénévoles                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  👤 Jean Petit                                          │ │
│  │     ✅ Présent                                           │ │
│  │                                                         │ │
│  │  👤 Sophie Martin                                       │ │
│  │     ✅ Présente                                          │ │
│  │                                                         │ │
│  │  👤 Paul Martin                                         │ │
│  │     ✅ Présent                                           │ │
│  │                                                         │ │
│  │  👤 Lisa Klaus                                          │ │
│  │     ✅ Présente                                          │ │
│  │                                                         │ │
│  │  👤 Tom Richard                                         │ │
│  │     ❌ Absent                                            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📦 Récapitulatif récupérations                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  🥚 Paniers œufs:     ✅ 18/18 récupérés (100%)        │ │
│  │                                                         │ │
│  │  🌿 Paniers légumes:  ✅ 22/23 récupérés (96%)         │ │
│  │     ⚠️ 1 panier non récupéré: Claire Monet             │ │
│  │     📞 [CONTACTER]                                      │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📊 Statistiques finales                                    │
│  • Taux présence bénévoles: 80% (4/5)                      │
│  • Taux récupération paniers: 98% (40/41)                  │
│  • Incidents: 1 bénévole absent, 1 panier non récupéré    │
│                                                             │
│  📄 Actions de clôture                                      │
│  [📊 GÉNÉRER RAPPORT] [📧 RÉSUMÉ EMAIL] [💾 ARCHIVER]      │
│                                                             │
│  ✅ Données synchronisées • Livraison finalisée            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[← Retour Dashboard]** : Retour au dashboard coordination ([Tableau de bord](screen-coordinator-01-home.md))
- **[CONTACTER]** : Appel ou message au membre pour panier non récupéré
- **[📊 GÉNÉRER RAPPORT]** : Création du rapport final de livraison
- **[📧 RÉSUMÉ EMAIL]** : Envoi du résumé aux coordinateurs et participants
- **[💾 ARCHIVER]** : Archivage définitif des données de la livraison

### Édition des données synchronisées
- **Statut bénévole** : Bascule entre « présent » et « absent »
- **Statut panier** : Bascule entre « récupéré » et « non récupéré »

## Processus de synchronisation

### Synchronisation émargement bénévoles
- **Validation présences** : Mise à jour des présences des bénévoles en « présent » ou « absent »

### Synchronisation récupération paniers
- **Validation récupérations** : Mise à jour des paniers en « récupéré » ou « non récupéré »
- **Contact membres** : Contact direct des membres n'ayant pas récupéré leur panier

### Calculs statistiques finaux
- **Taux de présence** : Pourcentage de bénévoles présents / inscrits
- **Taux de récupération** : Pourcentage de paniers récupérés / attendus
- **Incidents** : Décompte des problèmes rencontrés

## États de finalisation

### Bénévoles
- **✅ Présent** : Participation confirmée
- **❌ Absent** : Absence constatée

### Paniers
- **✅ Récupéré** : Panier retiré
- **⚠️ Non récupéré** : Panier restant à la fin de la livraison

### Livraison globale
- **✅ Finalisée** : Toutes les données synchronisées et archivées
- **📊 Rapportée** : Rapport généré et distribué
- **💾 Archivée** : Données sauvegardées pour historique et statistiques

## Actions de clôture

### Génération de rapport
- **Rapport détaillé** : Document complet avec tous les indicateurs
- **Distribution** : Envoi aux coordinateurs et responsables

### Communication finale
- **Résumé email** : Synthèse pour tous les participants
- **Remerciements** : Message aux bénévoles présents
- **Relance paniers non récupérés** : Communication avec les membres concernés

### Archivage
- **Sauvegarde données** : Conservation des présences bénévoles et récupérations de paniers finalisées
- **Historique** : Ajout aux statistiques globales de l'association
- **Traçabilité** : Conservation pour consultation ultérieure

## Références

### Documentation liée
- **Spécifications UI** : `../spec-ui.md`
- **Suivi livraison** : [Suivi de livraison](screen-coordinator-04-delivery-tracking.md) pour les données d'entrée de la synchronisation
- **Feuilles d'émargement** : [Feuilles d'émargement](screen-coordinator-03-attendance-sheets.md) pour les documents source de synchronisation
- **Dashboard coordination** : [Tableau de bord](screen-coordinator-01-home.md) pour le retour et contextualisation
