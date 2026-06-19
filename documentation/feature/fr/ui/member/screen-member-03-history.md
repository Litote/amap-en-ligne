# Historique des participations (vue Amapien)

## Description
Vue personnelle de l'historique des participations bénévoles avec statistiques et prochains engagements.

> **📋 Référence** : Structure détaillée dans `../../../../architecture/data-model.md` - Section DELIVERY, MEMBER_SLOT, CONTRACT.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                  📊 Mon historique bénévole                 │
├─────────────────────────────────────────────────────────────┤
│  [← Retour Accueil]                    Saison 2026-2027    │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  🎯 Mes statistiques                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📈 Total participations : 8                            │ │
│  │  📝 Inscriptions cette saison : 11                      │ │
│  │  🏆 Rang dans l'Amap : 3ème ex-aequo / 45 membres      │ │
│  │  📅 Dernière participation : 3 janvier 2027             │ │
│  │  ⭐ Statut : Membre actif                               │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📋 Historique détaillé                                     │
│                                                             │
│  ⭕ Engagements à venir                                     │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 10 Jan 2027 • 18h-20h                              │ │
│  │  ✅ Confirmé - Préparation paniers                      │ │
│  │  👤 Avec: Paul M., Lisa K., Tom R., Anna B.             │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ✅ Participations réalisées                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 3 Jan 2027 • 18h-20h                               │ │
│  │  ✅ Participation confirmée                             │ │
│  │  📝 Note: Aide réception + distribution                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 20 Déc 2026 • 18h-20h                              │ │
│  │  ✅ Participation confirmée                             │ │
│  │  📝 Note: Organisation paniers de Noël                  │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 13 Déc 2026 • 18h-20h                              │ │
│  │  ⚠️ Absence signalée (prévenue)                         │ │
│  │  📝 Remplacé(e) par Sophie M.                           │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📊 Répartition par mois                                    │
│  (saison juin 2026 – mars 2027, exemple)                   │
│                                                             │
│       3 ┤     █                   █                        │
│       2 ┤     █     █   █   █     █   █   █                │
│       1 ┤ █   █     █   █   █  █  █   █   █   █            │
│       0 ┤─┬───┬─────┬───┬───┬──┬──┬───┬───┬───┬─          │
│         Juin Juil Août Sep Oct Nov Déc Janv Févr Mars      │
│         2026                              2027             │
│                                                             │
│ [📅 PLANNING] [🏆 Participations globales]                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

| Contrôle | Cible | Comportement |
|----------|-------|--------------|
| `[← Retour Accueil]` | tableau de bord | Retour au tableau de bord Amapien ([Accueil membre](screen-member-01-home.md)) |
| `[📅 PLANNING]` | `/planning` | Navigation vers le planning des livraisons ([Planning](screen-member-02-delivery-plan.md)) |
| `[🏆 Participations globales]` | `/participations-globales` | Navigation vers l'écran Participations globales ([Participations globales](screen-member-05-participations-globales.md)) |

### Données affichées - Statistiques personnelles
- **Total participations** : Nombre de participations réalisées (COMPLETED) sur la saison courante (voir Règles métier)
- **Inscriptions cette saison** : Nombre total d'inscriptions NON ANNULÉES de l'Amapien sur la saison courante — comprend les engagements à venir et les participations réalisées (voir Règles métier)
- **Rang dans l'Amap** : Position par rapport aux autres membres actifs, avec gestion des ex-aequo (voir Règles métier)
- **Dernière participation** : Date de la dernière livraison effectuée sur la saison courante
- **Statut membre** : Niveau d'activité (Actif, Occasionnel, Inactif)

### Données affichées - Engagements à venir
- **Date et horaires** : Informations complètes du créneau
- **Statut confirmation** : ✅ Confirmé avec détails de l'activité
- **Co-équipiers** : Liste des autres bénévoles inscrits

### Données affichées - Participations réalisées
- **Historique chronologique** : Liste descendante des participations passées
- **Statut participation** : ✅ Confirmée, ⚠️ Absence signalée
- **Notes contextuelles** : Détails sur l'activité ou remplacement
- **Informations de remplacement** : En cas d'absence, qui a pris le relais

### Visualisation statistique
- **Bar chart mensuel** : Graphique en barres couvrant tous les mois de la plage de la saison courante (du mois de `min_delivery_date` au mois de `max_delivery_date` des contrats actifs), en ordre chronologique.
- La hauteur de chaque barre correspond au nombre de participations réalisées (COMPLETED) ce mois-là.
- Les mois sans participation affichent une barre vide (hauteur 0) — aucun mois de la plage n'est omis.
- Quand la plage couvre deux années civiles différentes, les libellés de mois indiquent l'année au changement d'année (voir Règles métier).

## Règles métier

### Périmètre de la saison courante
Les statistiques (total participations, inscriptions cette saison, rang, statut d'activité, répartition mensuelle, dernière participation) sont calculées sur la **saison courante**, définie comme suit :

- La saison est identifiée par une année (`season_year`) portée par les contrats (*CONTRACT*).
- La saison courante correspond à l'année `season_year` la plus élevée parmi tous les contrats dont le statut est `ACTIVE`.
- Seules les participations rattachées à des contrats de la saison courante entrent dans le calcul.
- Lorsqu'au moins un contrat de la saison suivante passe en statut `ACTIVE`, les statistiques basculent automatiquement sur cette nouvelle saison.

### Libellé du bandeau « Saison »
Le libellé affiché dans le bandeau en-tête est dérivé de la plage de dates des contrats (*CONTRACT*) de la saison courante :

1. Calculer `année_début` = année civile du `min_delivery_date` le plus ancien parmi tous les contrats de la saison courante.
2. Calculer `année_fin` = année civile du `max_delivery_date` le plus tardif parmi tous ces mêmes contrats.
3. Si `année_début == année_fin` → afficher **« Saison \<année_début\> »** (ex. « Saison 2026 »).
4. Si `année_début != année_fin` → afficher **« Saison \<année_début\>-\<année_fin\> »** (ex. « Saison 2026-2027 »).
5. Fallback (aucun contrat actif disponible) → afficher « Saison \<année civile courante\> ».

### Statistique « Total participations »
- Nombre de participations **réalisées** (COMPLETED) de l'Amapien sur la saison courante.
- Ne comprend pas les engagements à venir, ni les absences.

### Statistique « Inscriptions cette saison »
- Nombre total d'inscriptions **NON ANNULÉES** de l'Amapien sur la saison courante.
- Inclut : les engagements à venir (slots futurs confirmés) ET les participations réalisées (COMPLETED).
- Exclut : les inscriptions annulées.
- Cette valeur est toujours supérieure ou égale à « Total participations ».

### Rang dans l'Amap et ex-aequo
- Le classement utilise un **classement standard** : les membres ayant le même nombre de participations partagent le même rang.
- Affichage sans ex-aequo : « 3ème / 7 membres »
- Affichage avec ex-aequo : « 3ème ex-aequo / 7 membres »
- Cas particulier où personne n'a participé : tout le monde est affiché « 1er ex-aequo ».

### Statut d'activité
- **Actif** : ≥ 5 participations sur la saison courante
- **Occasionnel** : 1 à 4 participations sur la saison courante
- **Inactif** : 0 participation sur la saison courante

### Bar chart « Répartition par mois »
- L'axe des mois couvre **tous les mois** de la plage de la saison courante, du mois contenant `min_delivery_date` au mois contenant `max_delivery_date` des contrats (*CONTRACT*) actifs, en ordre chronologique strict.
- Fallback (aucun contrat) : afficher les 12 mois de l'année civile courante.
- La hauteur de chaque barre = nombre de participations réalisées (COMPLETED) rattachées à ce mois calendaire.
- Les mois sans participation affichent une barre de hauteur 0 ; ils ne sont pas masqués.
- **Libellés de mois** : abréviation française sur 3 ou 4 lettres (Juin, Juil, Août, Sep, Oct, Nov, Déc, Janv, Févr, Mars, Avr, Mai). Quand la plage couvre deux années civiles différentes, l'année est affichée sous les libellés de mois au moment du changement d'année (voir wireframe).

## États des participations

### Participations futures
- **✅ Confirmé** : Inscription validée, engagement pris
- **⏳ En attente** : Inscription en cours de validation
- **⚠️ À risque** : Créneau critique, participation incertaine

### Participations passées
- **✅ Participation confirmée** : Présence effective validée
- **⚠️ Absence signalée** : Absence prévenue avec remplacement organisé
- **❌ Absence non signalée** : Absence non prévenue (impact négatif)

## Références

### Documentation liée
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md) - Section "Historique personnel"
- **Dashboard** : [Accueil membre](screen-member-01-home.md)
- **Planning** : [Planning des livraisons](screen-member-02-delivery-plan.md)
- **Participations globales** : [Participations globales](screen-member-05-participations-globales.md)
- **Données** : `../../../../architecture/data-model.md` - Entités MEMBER_SLOT, MEMBER, DELIVERY, CONTRACT
- **Statistiques** : Calculs basés sur l'historique des MEMBER_SLOT confirmés, limités à la saison courante
