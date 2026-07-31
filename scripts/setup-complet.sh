#!/usr/bin/env bash
# Setup complet du serveur Vibe Qbox (open-source + vérifs)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "============================================"
echo "  Setup complet — Serveur Vibe Qbox/Ox"
echo "============================================"

if [[ ! -x "$ROOT/scripts/install-opensource.sh" ]]; then
  chmod +x "$ROOT/scripts/install-opensource.sh"
fi

"$ROOT/scripts/install-opensource.sh"

echo ""
echo "==> Vérification des ressources vibe_*"
VIBE_COUNT="$(find "$ROOT/resources/[vibe]" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
echo "    $VIBE_COUNT ressources dans resources/[vibe]"

echo ""
echo "==> Fichiers clés"
for f in server.cfg sql/init.sql config/items_vibe.lua docs/VIBE-REWRITE.md LIEN-COMPLET.md; do
  if [[ -f "$ROOT/$f" ]]; then
    echo "    OK  $f"
  else
    echo "    MANQUANT  $f"
  fi
done

cat <<EOF

============================================
Setup terminé.

Liens:
  Repo : https://github.com/anonyme006/Serveur-fivem/tree/cursor/fivem-qbox-server-scaffold-cfc5
  ZIP  : https://github.com/anonyme006/Serveur-fivem/archive/refs/heads/cursor/fivem-qbox-server-scaffold-cfc5.zip
  PR   : https://github.com/anonyme006/Serveur-fivem/pull/11

Suite:
  1) mysql -u root -p < sql/init.sql
  2) Fusionner config/items_vibe.lua -> ox_inventory/data/items.lua
  3) Éditer server.cfg (licence CFX + MySQL)
  4) Lancer FXServer: ./artifacts/run.sh +exec server.cfg
============================================
EOF
