#!/usr/bin/env bash
#
# Installe MkDocs Material avec les versions et les hashes de la CI : le requirements.txt de l'action
# Litote/ci setup-mkdocs, au SHA épinglé dans le workflow docs (mis à jour par Dependabot).
#
# Usage : site/install.sh (de préférence dans un environnement virtuel Python, voir site/README.md)

set -euo pipefail

cd "$(dirname "$0")/.."

sha=$(sed -n 's#.*Litote/ci/\.github/actions/setup-mkdocs@\([0-9a-f]\{40\}\).*#\1#p' .github/workflows/docs.yml | head -n 1)
if [ -z "$sha" ]; then
  echo "Pas de Litote/ci/.github/actions/setup-mkdocs@<sha> dans .github/workflows/docs.yml" >&2
  exit 1
fi

python3 -m pip install --disable-pip-version-check --only-binary ':all:' --require-hashes \
  -r "https://raw.githubusercontent.com/Litote/ci/${sha}/.github/actions/setup-mkdocs/requirements.txt"
