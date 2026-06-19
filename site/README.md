# site/ — Site d'aide public (MkDocs Material)

Génère le site d'aide public d'Amap en ligne à partir du guide utilisateur.

## Source de vérité

Le contenu du guide reste dans **`documentation/guide/fr/`**. Il est monté ici sous
`docs/guide` via un **lien symbolique** (`docs/guide → ../../documentation/guide/fr`),
pour éviter toute duplication : on n'édite jamais le contenu dans `site/`, on édite
`documentation/guide/fr/`.

La page de garde (`docs/index.md`) et la configuration (`mkdocs.yml`) vivent ici.

## Prérequis

- Python 3.9+

## Développement local

```bash
cd site
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Prévisualisation avec rechargement à chaud
mkdocs serve
```

Le site est servi sur http://127.0.0.1:8000.

## Build

```bash
cd site
mkdocs build        # sortie dans site/_build (gitignorée)
```

## Publication

La publication sur GitHub Pages est automatisée par
`.github/workflows/docs.yml` à chaque push sur `main`.

> Pensez à ajuster `site_url` dans `mkdocs.yml` à l'URL de publication réelle.

## Notes

- Le contenu est **100 % français**, destiné aux utilisateurs finaux.
- Lorsqu'un libellé d'écran change dans l'application, mettez à jour la page
  correspondante de `documentation/guide/fr/` (le site se régénère automatiquement).
