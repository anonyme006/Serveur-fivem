#!/usr/bin/env bash
# Installe les ressources open-source de base (Qbox + Ox + voice + ipl)
# Prérequis: git, curl. À lancer depuis la racine du dépôt.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="${ROOT}/.tmp-install"
mkdir -p "$TMP"

clone_or_update() {
  local url="$1"
  local dest="$2"
  if [[ -d "$dest/.git" ]]; then
    echo "→ update $(basename "$dest")"
    git -C "$dest" pull --ff-only || true
  else
    echo "→ clone $(basename "$dest")"
    git clone --depth 1 "$url" "$dest"
  fi
}

echo "==> Ox / database"
clone_or_update "https://github.com/overextended/oxmysql.git"      "$ROOT/resources/[ox]/oxmysql"
clone_or_update "https://github.com/overextended/ox_lib.git"        "$ROOT/resources/[ox]/ox_lib"
clone_or_update "https://github.com/overextended/ox_target.git"      "$ROOT/resources/[ox]/ox_target"
clone_or_update "https://github.com/overextended/ox_doorlock.git"    "$ROOT/resources/[ox]/ox_doorlock"
clone_or_update "https://github.com/overextended/ox_inventory.git"   "$ROOT/resources/[ox]/ox_inventory"

echo "==> Voice"
clone_or_update "https://github.com/AvarianKnight/pma-voice.git"    "$ROOT/resources/[voice]/pma-voice"

echo "==> Qbox core recipe pieces"
# qbx_core + community modules (ajuster selon la recipe officielle Qbox)
clone_or_update "https://github.com/Qbox-project/qbx_core.git"              "$ROOT/resources/[qbx]/qbx_core"
clone_or_update "https://github.com/Qbox-project/qbx_management.git"        "$ROOT/resources/[qbx]/qbx_management"
clone_or_update "https://github.com/Qbox-project/qbx_radialmenu.git"        "$ROOT/resources/[qbx]/qbx_radialmenu"
clone_or_update "https://github.com/Qbox-project/qbx_radio.git"             "$ROOT/resources/[qbx]/qbx_radio"
clone_or_update "https://github.com/Qbox-project/qbx_smallresources.git"    "$ROOT/resources/[qbx]/qbx_smallresources"
clone_or_update "https://github.com/Qbox-project/qbx_density.git"           "$ROOT/resources/[qbx]/qbx_density"
clone_or_update "https://github.com/Qbox-project/qbx_vehicles.git"          "$ROOT/resources/[qbx]/qbx_vehicles"
clone_or_update "https://github.com/Qbox-project/qbx_customs.git"           "$ROOT/resources/[qbx]/qbx_customs"
clone_or_update "https://github.com/Qbox-project/qbx_taxijob.git"           "$ROOT/resources/[qbx]/qbx_taxijob"
clone_or_update "https://github.com/Qbox-project/qbx_binoculars.git"        "$ROOT/resources/[qbx]/qbx_binoculars"
clone_or_update "https://github.com/Qbox-project/qbx_divegear.git"          "$ROOT/resources/[qbx]/qbx_divegear"
clone_or_update "https://github.com/Qbox-project/qbx_fireworks.git"         "$ROOT/resources/[qbx]/qbx_fireworks"
clone_or_update "https://github.com/Qbox-project/qbx_helicam.git"           "$ROOT/resources/[qbx]/qbx_helicam"
clone_or_update "https://github.com/Qbox-project/qbx_chat_theme.git"        "$ROOT/resources/[qbx]/qbx_chat_theme"
clone_or_update "https://github.com/Qbox-project/qbx_weaponworkshop.git"    "$ROOT/resources/[qbx]/qbx_weaponworkshop"

echo "==> Housing / admin (Project Sloth — si dispo)"
clone_or_update "https://github.com/Project-Sloth/ps-adminmenu.git"  "$ROOT/resources/[standalone]/ps-adminmenu" || true
clone_or_update "https://github.com/Project-Sloth/ps-housing.git"    "$ROOT/resources/[housing]/ps-housing" || true
clone_or_update "https://github.com/Project-Sloth/ps-realtor.git"    "$ROOT/resources/[housing]/ps-realtor" || true

echo "==> Maps utilitaires"
clone_or_update "https://github.com/Bob74/bob74_ipl.git"             "$ROOT/resources/[maps]/bob74_ipl"

echo "==> Divers utiles"
clone_or_update "https://github.com/Xogy/xsound.git"                 "$ROOT/resources/[standalone]/xsound" || true

# Nettoyage éventuel
rm -rf "$TMP"

cat <<'EOF'

Installation open-source terminée.

Prochaines étapes:
  1. Installer les artifacts FXServer (https://runtime.fivem.net/artifacts/fivem/)
  2. Créer la base MariaDB et importer sql/init.sql
  3. Renseigner sv_licenseKey + mysql_connection_string dans server.cfg
  4. Acheter légalement lb-phone, jg-*, rcore_*, MLOs, véhicules
  5. Étendre les stubs resources/[vibe]/*

Documentation: docs/ANALYSE-SERVEUR.md
EOF
