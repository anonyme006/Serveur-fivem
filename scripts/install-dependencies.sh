#!/usr/bin/env bash
# Installe les dépendances officielles Qbox / Ox dans resources/
# Usage: ./scripts/install-dependencies.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RES="$ROOT/resources"
TMP="$ROOT/.tmp-install"

mkdir -p "$TMP" \
  "$RES/[ox]" \
  "$RES/[qbx]" \
  "$RES/[standalone]" \
  "$RES/[voice]" \
  "$RES/[cfx-default]"

clone_or_update() {
  local url="$1" dest="$2" ref="${3:-main}"
  if [[ -d "$dest/.git" ]]; then
    echo "[update] $dest"
    git -C "$dest" fetch --depth 1 origin "$ref"
    git -C "$dest" checkout -q "$ref"
    git -C "$dest" pull --ff-only origin "$ref" || true
  else
    echo "[clone] $url -> $dest"
    rm -rf "$dest"
    git clone --depth 1 --branch "$ref" "$url" "$dest"
  fi
}

echo "==> Ox / Overextended"
clone_or_update https://github.com/overextended/oxmysql.git "$RES/[ox]/oxmysql" main
clone_or_update https://github.com/overextended/ox_lib.git "$RES/[ox]/ox_lib" master
clone_or_update https://github.com/overextended/ox_target.git "$RES/[ox]/ox_target" main
clone_or_update https://github.com/overextended/ox_inventory.git "$RES/[ox]/ox_inventory" main
clone_or_update https://github.com/overextended/ox_doorlock.git "$RES/[ox]/ox_doorlock" main
clone_or_update https://github.com/overextended/ox_fuel.git "$RES/[ox]/ox_fuel" main

echo "==> Qbox core & modules"
clone_or_update https://github.com/Qbox-project/qbx_core.git "$RES/[qbx]/qbx_core" main
clone_or_update https://github.com/Qbox-project/qbx_vehicles.git "$RES/[qbx]/qbx_vehicles" main
clone_or_update https://github.com/Qbox-project/qbx_garages.git "$RES/[qbx]/qbx_garages" main
clone_or_update https://github.com/Qbox-project/qbx_vehiclekeys.git "$RES/[qbx]/qbx_vehiclekeys" main
clone_or_update https://github.com/Qbox-project/qbx_management.git "$RES/[qbx]/qbx_management" main
clone_or_update https://github.com/Qbox-project/qbx_properties.git "$RES/[qbx]/qbx_properties" main
clone_or_update https://github.com/Qbox-project/qbx_police.git "$RES/[qbx]/qbx_police" main
clone_or_update https://github.com/Qbox-project/qbx_ambulancejob.git "$RES/[qbx]/qbx_ambulancejob" main
clone_or_update https://github.com/Qbox-project/qbx_medical.git "$RES/[qbx]/qbx_medical" main
clone_or_update https://github.com/Qbox-project/qbx_mechanicjob.git "$RES/[qbx]/qbx_mechanicjob" main
clone_or_update https://github.com/Qbox-project/qbx_taxijob.git "$RES/[qbx]/qbx_taxijob" main
clone_or_update https://github.com/Qbox-project/qbx_hud.git "$RES/[qbx]/qbx_hud" main
clone_or_update https://github.com/Qbox-project/qbx_adminmenu.git "$RES/[qbx]/qbx_adminmenu" main
clone_or_update https://github.com/Qbox-project/qbx_radialmenu.git "$RES/[qbx]/qbx_radialmenu" main
clone_or_update https://github.com/Qbox-project/qbx_smallresources.git "$RES/[qbx]/qbx_smallresources" main
clone_or_update https://github.com/Qbox-project/qbx_spawn.git "$RES/[qbx]/qbx_spawn" main
clone_or_update https://github.com/Qbox-project/qbx_cityhall.git "$RES/[qbx]/qbx_cityhall" main
clone_or_update https://github.com/Qbox-project/qbx_vehicleshop.git "$RES/[qbx]/qbx_vehicleshop" main
clone_or_update https://github.com/Qbox-project/qbx_seatbelt.git "$RES/[qbx]/qbx_seatbelt" main
clone_or_update https://github.com/Qbox-project/qbx_idcard.git "$RES/[qbx]/qbx_idcard" main 2>/dev/null || true

echo "==> Standalone essentiels"
clone_or_update https://github.com/Bob74/bob74_ipl.git "$RES/[standalone]/bob74_ipl" master
clone_or_update https://github.com/AvarianKnight/pma-voice.git "$RES/[voice]/pma-voice" main

# Renewed-Banking (release zip)
if [[ ! -d "$RES/[standalone]/Renewed-Banking" ]]; then
  echo "[download] Renewed-Banking"
  curl -sL -o "$TMP/Renewed-Banking.zip" \
    "https://github.com/Renewed-Scripts/Renewed-Banking/releases/latest/download/Renewed-Banking.zip"
  unzip -qo "$TMP/Renewed-Banking.zip" -d "$RES/[standalone]"
fi

# illenium-appearance
if [[ ! -d "$RES/[standalone]/illenium-appearance" ]]; then
  echo "[download] illenium-appearance"
  curl -sL -o "$TMP/illenium-appearance.zip" \
    "https://github.com/iLLeniumStudios/illenium-appearance/releases/latest/download/illenium-appearance.zip"
  unzip -qo "$TMP/illenium-appearance.zip" -d "$RES/[standalone]"
fi

echo "==> Build ox_lib / ox_inventory (pnpm si disponible)"
if command -v pnpm >/dev/null 2>&1; then
  (cd "$RES/[ox]/ox_lib" && pnpm i && pnpm build) || true
  (cd "$RES/[ox]/ox_inventory" && pnpm i && pnpm build) || true
else
  echo "[warn] pnpm absent — compilez ox_lib / ox_inventory sur une machine avec Node."
fi

echo ""
echo "Installation terminée."
echo "1. Configurez mysql_connection_string dans server.cfg"
echo "2. Importez sql/00_qbox_recipe.sql puis sql/01_rp_custom.sql"
echo "3. Démarrez avec: ensure order dans server.cfg"
