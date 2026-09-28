# Gestion des templates de livraison (Admin)

## Description
Interface de création et de gestion des modèles réutilisables de livraison (*DELIVERY_TEMPLATE*). L'admin de l'organisation définit les templates utilisés par les coordinateurs lors de la création de livraisons. Un template définit les paramètres par défaut d'une livraison : horaires standard, nombre de bénévoles souhaité pour la création de la livraison, et optionnellement un créneau anticipé (*EARLY_SLOT*) permettant à certains bénévoles d'arriver plus tôt pour réceptionner les produits avant l'heure habituelle. Un template peut aussi être marqué comme template par défaut de l'organisation : il sera alors sélectionné automatiquement lors de la création d'une nouvelle livraison par un coordinateur. Ces templates peuvent être associés à des livraisons (*DELIVERY*) concrètes pour pré-remplir leurs paramètres, tout en permettant une surcharge ponctuelle au niveau de la livraison.

## Wireframe ASCII

```
┌─────────────────────────────────────────────────────────────┐
│              ⚙️ Templates de livraison                      │
├─────────────────────────────────────────────────────────────┤
│  [← Retour Dashboard Admin]               [💾 Sauvegarder]  │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  ➕ Nouveau template                                         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📝 Nom du template:                                    │ │
│  │     [________________________________]                  │ │
│  │                                                         │ │
│  │  🕐 Horaires standard:                                  │ │
│  │     Début: [18:00 ▼]  Fin: [20:00 ▼]                  │ │
│  │                                                         │ │
│  │  👥 Nombre de bénévoles souhaité:                       │ │
│  │     [5 ▼]                                               │ │
│  │                                                         │ │
│  │  [ ] Définir comme template par défaut                  │ │
│  │                                                         │ │
│  │  ┄┄┄┄┄ Créneau anticipé (optionnel) ┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │ │
│  │  [ ] Activer un créneau anticipé                        │ │
│  │                                                         │ │
│  │  [Si activé]                                            │ │
│  │  🕐 Heure d'arrivée anticipée:                          │ │
│  │     [17:00 ▼]                                           │ │
│  │                                                         │ │
│  │  💬 Explication (affichée aux Amapiens):                │ │
│  │     ┌─────────────────────────────────────────────────┐ │ │
│  │     │ Ex : Réception des légumes du producteur avant  │ │ │
│  │     │ l'arrivée des membres...                        │ │ │
│  │     └─────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  │  👥 Nombre max de volontaires pour ce créneau:          │ │
│  │     [3 ▼]                                               │ │
│  │                                                         │ │
│  │     [CRÉER TEMPLATE]                                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📋 Templates existants                                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📄 Livraison standard                                  │ │
│  │     🕐 18h00-20h00 • Pas de créneau anticipé           │ │
│  │     👥 5 bénévoles souhaités                            │ │
│  │     ⭐ Template par défaut de l'organisation            │ │
│  │     🔗 Associé à 8 livraisons                          │ │
│  │     [MODIFIER] [SUPPRIMER] [VOIR LIVRAISONS]            │ │
│  │                                                         │ │
│  │  📄 Livraison avec réception anticipée                  │ │
│  │     🕐 18h00-20h00 • Créneau anticipé : 17h00          │ │
│  │     👥 6 bénévoles souhaités                            │ │
│  │     💬 "Réception des légumes du maraîcher"            │ │
│  │     👥 Max 2 volontaires anticipés                     │ │
│  │     🔗 Associé à 3 livraisons                          │ │
│  │     [MODIFIER] [SUPPRIMER] [VOIR LIVRAISONS]            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ [← Retour Dashboard Admin]                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales — Nouveau template
- **[Nom du template]** : Saisie libre du nom identifiant le template
- **[Horaires dropdown]** : Configuration des heures de début et de fin du créneau standard
- **[Nombre de bénévoles souhaité]** : Valeur utilisée pour préremplir le minimum de bénévoles lors de la création d'une livraison à partir de ce template
- **[Définir comme template par défaut]** : Marque ce template comme sélection par défaut de l'organisation pour les nouvelles livraisons créées par les coordinateurs
- **[Activer un créneau anticipé]** : Case à cocher qui déploie les champs du créneau anticipé
- **[Heure d'arrivée anticipée]** : Heure de début du créneau anticipé (antérieure à l'heure standard)
- **[Zone texte Explication]** : Message visible par les Amapiens expliquant la raison du créneau anticipé
- **[Nombre max de volontaires]** : Limite supérieure du nombre de bénévoles pouvant s'inscrire sur le créneau anticipé
- **[CRÉER TEMPLATE]** : Validation et enregistrement du nouveau template

### Actions principales — Gestion des templates existants
- **[MODIFIER]** : Édition d'un template existant ; les modifications ne s'appliquent pas rétroactivement aux livraisons déjà créées avec ce template
- **[SUPPRIMER]** : Suppression du template avec confirmation ; uniquement possible si aucune livraison future n'y est associée
- **[VOIR LIVRAISONS]** : Accès à la liste des livraisons utilisant ce template

### Actions globales
- **[← Retour Dashboard Admin]** : Retour au tableau de bord admin ([Écran admin 1](screen-admin-01-home.md))
- **[💾 Sauvegarder]** : Sauvegarde des modifications en cours sur un template en édition

### Comportement du créneau anticipé dans la liste
Lorsqu'un créneau anticipé est configuré, la ligne du template affiche :
- L'heure d'arrivée anticipée
- L'explication (tronquée si trop longue)
- Le nombre maximum de volontaires autorisés sur ce créneau

## Formulaire de création

### Champs obligatoires
- **Nom du template** : Identifiant lisible, unique au sein de l'organisation
- **Heure de début standard** : Heure d'ouverture du créneau de bénévolat habituel
- **Heure de fin standard** : Heure de fermeture du créneau de bénévolat
- **Nombre de bénévoles souhaité** : Entier supérieur ou égal à 1, utilisé pour préremplir le minimum de bénévoles d'une nouvelle livraison

### Comportement du template par défaut
- Un seul template peut être marqué comme template par défaut pour une organisation à un instant donné
- Le template par défaut est sélectionné automatiquement lors de la création d'une nouvelle livraison par un coordinateur
- Ce choix ne modifie pas rétroactivement les livraisons déjà créées

### Champs optionnels — Créneau anticipé
Ces champs n'apparaissent que si la case « Activer un créneau anticipé » est cochée. Ils sont tous obligatoires dès lors que la case est cochée.

- **Heure d'arrivée anticipée** : Doit être strictement antérieure à l'heure de début standard
- **Explication** : Texte court affiché aux Amapiens pour justifier le créneau anticipé (ex. : « Réception des produits du maraîcher »)
- **Nombre max de volontaires pour le créneau anticipé** : Entier supérieur ou égal à 1

### Validation des données
- **Cohérence horaires** : L'heure de fin standard est postérieure à l'heure de début standard
- **Cohérence créneau anticipé** : L'heure d'arrivée anticipée est strictement antérieure à l'heure de début standard
- **Unicité du nom** : Pas de doublon au sein de la même organisation
- **Explication non vide** : Si le créneau anticipé est activé, l'explication doit être renseignée

### Association à une livraison
Un template est associé à une livraison depuis le formulaire de création ou de modification de la livraison par le coordinateur ([Écran coordinateur 2](../coordinator/screen-coordinator-02-time-slots.md)). L'association préremplie les horaires, le minimum de bénévoles et le créneau anticipé de la livraison, qui peuvent ensuite être surchargés sans modifier le template. Si un template par défaut est défini au niveau de l'organisation, il est proposé automatiquement lors de la création d'une nouvelle livraison.

## Références

### Documentation liée
- **Gestion des livraisons** : [`../coordinator/screen-coordinator-02-time-slots.md`](../coordinator/screen-coordinator-02-time-slots.md) — sélection d'un template et surcharge du créneau anticipé lors de la création d'une livraison
- **Planning Amapien** : [`../member/screen-member-02-delivery-plan.md`](../member/screen-member-02-delivery-plan.md) — présentation du créneau anticipé à l'Amapien lors de l'inscription
- **Dashboard admin** : [Écran admin 1](screen-admin-01-home.md) — point d'entrée principal
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
