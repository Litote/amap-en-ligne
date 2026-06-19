# Validation des demandes d'organisation

## Description

Interface réservée aux administrateurs d'instance permettant de consulter les demandes de création d'organisation en attente, d'en examiner les détails et de les approuver ou refuser. Les demandes sont organisées en deux onglets selon leur type : AMAP (*organizationType* = `AMAP`) et Producteurs (*organizationType* = `PRODUCER`). Accessible uniquement aux rôles `ADMIN` et `OWNER`.

---

## Wireframe — Liste des demandes

```
┌─────────────────────────────────────────────────────────────┐
│  Admin · Demandes d'organisation                            │
├─────────────────────────────────────────────────────────────┤
│  ← Tableau de bord admin                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [ AMAP ]  [ PRODUCTEURS ]                                  │
│  ─────────                                                  │
│                                                             │
│  Filtrer par statut :  [EN ATTENTE ▼]       [Rafraîchir]   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AMAP              Admin              Soumis le    │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  En attente AMAP des Pins   Jean Dupont  12/05/2026 │   │
│  │     jean@exemple.fr                     [EXAMINER →] │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  En attente Coop Bio Est    Marie Martin 10/05/2026  │   │
│  │     marie@exemple.fr                    [EXAMINER →] │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Approuvée AMAP du Lac     Paul Bernard  03/05/2026  │   │
│  │     paul@exemple.fr   Approuvée le 05/05  [Renvoyer l'invitation] │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Refusée  Les Jardins     Sophie Petit   28/04/2026  │   │
│  │     sophie@exemple.fr             Refusée le 02/05   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  2 demandes en attente · 1 approuvée · 1 refusée           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Wireframe — Détail d'une demande

```
┌─────────────────────────────────────────────────────────────┐
│  Admin · Demande : AMAP des Pins                            │
├─────────────────────────────────────────────────────────────┤
│  ← Retour à la liste                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [ AMAP ]  [ PRODUCTEURS ]                                  │
│  ─────────                                                  │
│                                                             │
│  En attente de validation                                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ORGANISATION                                       │   │
│  │                                                     │   │
│  │  Nom              AMAP des Pins                     │   │
│  │  Type             AMAP                              │   │
│  │  Fuseau horaire   Europe/Paris                      │   │
│  │  Langue           Français                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  COMPTE ADMINISTRATEUR DEMANDÉ                      │   │
│  │                                                     │   │
│  │  Prénom           Jean                              │   │
│  │  Nom              Dupont                            │   │
│  │  Email            jean@exemple.fr                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  SOUMISSION                                         │   │
│  │                                                     │   │
│  │  Date             12/05/2026 à 14h37                │   │
│  │  Référence        REQ-2026-00042                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ─────────────────────────────────────────────────────     │
│                                                             │
│  [REFUSER]                                  [APPROUVER]    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Wireframe — Modal de refus

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ╔═════════════════════════════════════════════════════╗   │
│  ║  Refuser la demande                                 ║   │
│  ╠═════════════════════════════════════════════════════╣   │
│  ║                                                     ║   │
│  ║  Organisation : AMAP des Pins                       ║   │
│  ║                                                     ║   │
│  ║  Commentaire (optionnel)                            ║   │
│  ║  ┌─────────────────────────────────────────────┐   ║   │
│  ║  │ Ex : nom trop similaire à une organisation  │   ║   │
│  ║  │ existante, informations manquantes…         │   ║   │
│  ║  │                                             │   ║   │
│  ║  └─────────────────────────────────────────────┘   ║   │
│  ║                                                     ║   │
│  ║  Ce commentaire sera transmis au demandeur.         ║   │
│  ║                                                     ║   │
│  ║  [ANNULER]                    [CONFIRMER LE REFUS]  ║   │
│  ╚═════════════════════════════════════════════════════╝   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Navigation et interactions

### Onglets

| Action | Comportement |
|--------|-------------|
| Clic sur [AMAP] | Filtre la liste sur `organizationType = AMAP` sans rechargement de page ; onglet actif par défaut ; libellé colonne → "AMAPs" |
| Clic sur [PRODUCTEURS] | Filtre la liste sur `organizationType = PRODUCER` sans rechargement de page ; libellé colonne → "Producteurs" |

### Écran de liste

| Action | Comportement |
|--------|-------------|
| Filtre statut | Filtre la liste sans rechargement de page |
| [EXAMINER →] | Navigue vers la vue détail de la demande |
| [Renvoyer l'invitation] | Renvoie l'email d'activation pour une demande approuvée ; confirmation par message dans l'interface |
| [Rafraîchir] | Recharge la liste depuis le serveur |
| Compteur bas | Mis à jour dynamiquement après chaque action admin |

### Vue détail

| Action | Comportement |
|--------|-------------|
| [APPROUVER] | Marque la demande comme approuvée ; retour liste avec bandeau succès |
| [REFUSER] | Ouvre le modal de refus |
| ← Retour | Revient à la liste sans modifier la demande |

### Modal de refus

| Action | Comportement |
|--------|-------------|
| [CONFIRMER LE REFUS] | Marque la demande comme refusée avec commentaire optionnel ; ferme le modal et retourne à la liste |
| [ANNULER] | Ferme le modal sans action |

---

## États de l'interface

### Liste

| Statut | Indicateur | Comportement |
|--------|-----------|-------------|
| `PENDING_VALIDATION` | En attente | Ligne cliquable, bouton [EXAMINER →] actif |
| `APPROVED` | Approuvée | Ligne en lecture seule, date d'approbation affichée, bouton `[Renvoyer l'invitation]` actif |
| `REJECTED` | Refusée | Ligne en lecture seule, date de refus affichée |

### Vue détail — états du bouton [APPROUVER]

- **Actif** : statut `PENDING_VALIDATION`
- **Désactivé + message** : statut déjà `APPROVED` ou `REJECTED` (la demande a été traitée par un autre admin entre-temps)
- **Chargement** : spinner inline pendant l'appel API ; boutons désactivés

### Erreurs

- « Cette demande a déjà été traitée. »
- « Demande introuvable. Veuillez rafraîchir la liste. »
- « Une erreur s'est produite. Veuillez réessayer. »

---

## Règles métier

- Seuls les rôles `ADMIN` et `OWNER` peuvent accéder à ces écrans.
- Une demande ne peut être approuvée ou refusée qu'une seule fois.
- Le commentaire de refus est optionnel mais est affiché au demandeur dans l'email de notification.
- L'approbation active le compte administrateur de l'organisation.
- La liste affiche par défaut les demandes en attente en ordre chronologique décroissant (plus récentes en haut).
- Le filtre par onglet correspond au champ `organizationType` de la demande (`AMAP` ou `PRODUCER`).
- L'onglet actif est conservé lors de la navigation entre la liste et le détail d'une demande au sein du même écran.
- Le bouton `[Renvoyer l'invitation]` est disponible uniquement sur les demandes ayant le statut `APPROVED`. Il permet de renvoyer l'email d'activation si le destinataire ne l'a pas reçu ou si le lien a expiré.

---

## Références

- **Écran précédent** : [`screen-owner-01-home.md`](screen-owner-01-home.md)
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
