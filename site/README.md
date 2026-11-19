# site/ — Site d'aide public (MkDocs Material)

Génère le site d'aide public d'Amap en ligne à partir du guide utilisateur.

## Source de vérité

Le contenu du guide reste dans **`documentation/guide/fr/`**. Il est monté ici sous
`docs/guide` via un **lien symbolique** (`docs/guide → ../../documentation/guide/fr`),
pour éviter toute duplication : on n'édite jamais le contenu dans `site/`, on édite
`documentation/guide/fr/`.

La page de garde (`docs/index.md`) et la configuration (`mkdocs.yml`) vivent ici.

## Prérequis

- Python 3.11+

## Développement local

```bash
cd site
python3 -m venv .venv
source .venv/bin/activate
./install.sh   # versions et hashes de la CI (action Litote/ci setup-mkdocs)

# Prévisualisation avec rechargement à chaud
mkdocs serve
```

Le site est servi sur http://127.0.0.1:8000.

## Build

```bash
cd site
mkdocs build --strict   # sortie dans site/_build (gitignorée), échoue sur un lien cassé
```

## Publication

La publication sur GitHub Pages est automatisée par
`.github/workflows/docs.yml` à chaque push sur `main`. Le site est aussi construit
(`mkdocs build --strict`) sur les pull requests, sans publication.

MkDocs Material est installé par l'action `Litote/ci/.github/actions/setup-mkdocs`,
qui porte les versions épinglées avec leurs hashes : Dependabot les met à jour dans
Litote/ci, puis le projet les reçoit avec la montée de version de Litote/ci.

> Pensez à ajuster `site_url` dans `mkdocs.yml` à l'URL de publication réelle.

## Notes

- Le contenu est **100 % français**, destiné aux utilisateurs finaux.
- Lorsqu'un libellé d'écran change dans l'application, mettez à jour la page
  correspondante de `documentation/guide/fr/` (le site se régénère automatiquement).
