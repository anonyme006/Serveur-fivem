#!/usr/bin/env bash
# Setup complet du serveur Reroll Qbox (open-source + vérifs)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "============================================"
echo "  Setup complet — Serveur Reroll Qbox/Ox"
echo "============================================"

if [[ ! -x "$ROOT/scripts/install-opensource.sh" ]]; then
  chmod +x "$ROOT/scripts/install-opensource.sh"
fi

"$ROOT/scripts/install-opensource.sh"

echo ""
echo "==> Vérification des ressources rr_*"
RR_COUNT="$(find "$ROOT/resources/[reroll]" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
echo "    $RR_COUNT ressources dans resources/[reroll]"

echo ""
echo "==> Fichiers clés"
for f in server.cfg sql/init.sql config/items_reroll.lua docs/REROLL-REWRITE.md LIEN-COMPLET.md; do
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
  Repo : https://github.com/anonyme006/Serveur-fivem/tree/cursor/qbox-reroll-server-f159
  ZIP  : https://github.com/anonyme006/Serveur-fivem/archive/refs/heads/cursor/qbox-reroll-server-f159.zip

Suite:
  1) mysql -u root -p < sql/init.sql
  2) Fusionner config/items_reroll.lua -> ox_inventory/data/items.lua
  3) Éditer server.cfg (licence CFX + MySQL)
  4) Lancer FXServer: ./artifacts/run.sh +exec server.cfg
============================================
EOF
