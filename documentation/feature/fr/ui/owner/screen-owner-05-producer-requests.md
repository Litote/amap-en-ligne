# Demandes de compte producteur

## Description

Interface réservée aux propriétaires d'instance (*OWNER*) permettant de consulter les demandes de création de compte producteur (*ProducerRequest*) en attente, d'en examiner les détails et de les approuver ou refuser. Accessible uniquement au rôle `OWNER`.

---

## Wireframe — Liste des demandes

```
┌─────────────────────────────────────────────────────────────┐
│  Admin · Demandes de compte producteur                      │
├─────────────────────────────────────────────────────────────┤
│  ← Tableau de bord admin                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Filtrer par statut :  [EN ATTENTE ▼]       [Rafraîchir]   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Producteur        Admin              Soumis le    │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  En attente Ferme des Collines  Lucie Moreau  08/05/2026 │   │
│  │     lucie@exemple.fr                    [EXAMINER →] │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  En attente Maraîchage Soleil   Marc Tran   05/05/2026  │   │
│  │     marc@exemple.fr                     [EXAMINER →] │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Approuvée  Bio du Terroir      Anne Blanc  01/05/2026  │   │
│  │     anne@exemple.fr   Approuvée le 03/05  [Renvoyer l'invitation] │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Refusée    Les Serres Vertes   Hugo Petit  22/04/2026  │   │
│  │     hugo@exemple.fr             Refusée le 25/04   │   │
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
│  Admin · Demande : Ferme des Collines                       │
├─────────────────────────────────────────────────────────────┤
│  ← Retour à la liste                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  En attente de validation                                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  PRODUCTEUR                                         │   │
│  │                                                     │   │
│  │  Nom du producteur  Ferme des Collines              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  COMPTE ADMINISTRATEUR DEMANDÉ                      │   │
│  │                                                     │   │
│  │  Prénom             Lucie                           │   │
│  │  Nom                Moreau                          │   │
│  │  Email              lucie@exemple.fr                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  SOUMISSION                                         │   │
│  │                                                     │   │
│  │  Date               08/05/2026 à 10h22              │   │
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
│  ║  Producteur : Ferme des Collines                    ║   │
│  ║                                                     ║   │
│  ║  Commentaire (optionnel)                            ║   │
│  ║  ┌─────────────────────────────────────────────┐   ║   │
│  ║  │ Ex : informations insuffisantes, activité   │   ║   │
│  ║  │ non éligible…                               │   ║   │
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
| `PENDING` | En attente | Ligne cliquable, bouton [EXAMINER →] actif |
| `APPROVED` | Approuvée | Ligne en lecture seule, date d'approbation affichée, bouton `[Renvoyer l'invitation]` actif |
| `REJECTED` | Refusée | Ligne en lecture seule, date de refus affichée |

### Vue détail — états du bouton [APPROUVER]

- **Actif** : statut `PENDING`
- **Désactivé + message** : statut déjà `APPROVED` ou `REJECTED` (la demande a été traitée entre-temps)
- **Chargement** : spinner inline pendant l'appel ; boutons désactivés

### Erreurs

- « Cette demande a déjà été traitée. »
- « Demande introuvable. Veuillez rafraîchir la liste. »
- « Une erreur s'est produite. Veuillez réessayer. »

---

## Règles métier

- Seul le rôle `OWNER` peut accéder à ces écrans.
- Une demande ne peut être approuvée ou refusée qu'une seule fois.
- Le commentaire de refus est optionnel mais est transmis au demandeur dans l'email de notification.
- L'approbation déclenche la création d'un compte producteur en attente d'activation (*ActivationKind* = `PRODUCER`).
- La liste affiche par défaut les demandes en attente en ordre chronologique décroissant (plus récentes en haut).
- Le bouton `[Renvoyer l'invitation]` est disponible uniquement sur les demandes ayant le statut `APPROVED`. Il permet de renvoyer l'email d'activation si le destinataire ne l'a pas reçu ou si le lien a expiré.

---

## Références

- **Écran précédent** : [`screen-owner-01-home.md`](screen-owner-01-home.md)
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
