#!/usr/bin/env bash
# Installe / met à jour les deps open-source (releases buildées Ox + clones Qbox)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="${ROOT}/.tmp-install/releases"
mkdir -p "$TMP"

clone_or_update() {
  local url="$1"
  local dest="$2"
  if [[ -d "$dest" && ! -d "$dest/.git" && -f "$dest/fxmanifest.lua" ]]; then
    echo "→ keep $(basename "$dest") (déjà présent)"
    return 0
  fi
  if [[ -d "$dest/.git" ]]; then
    echo "→ update $(basename "$dest")"
    git -C "$dest" pull --ff-only || true
  else
    echo "→ clone $(basename "$dest")"
    rm -rf "$dest"
    git clone --depth 1 "$url" "$dest" || echo "   FAIL $url"
    rm -rf "$dest/.git" "$dest/.github" 2>/dev/null || true
  fi
}

download_ox_release() {
  local repo="$1"
  local dest="$2"
  echo "→ release $repo"
  python3 - "$repo" "$dest" "$TMP" <<'PY'
import json, shutil, sys, urllib.request, zipfile
from pathlib import Path
repo, dest, tmp = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3])
api = f'https://api.github.com/repos/{repo}/releases/latest'
req = urllib.request.Request(api, headers={'User-Agent': 'vibe-setup'})
with urllib.request.urlopen(req, timeout=60) as r:
    data = json.load(r)
assets = data.get('assets') or []
if not assets:
    raise SystemExit(f'no assets for {repo}')
url = assets[0]['browser_download_url']
req = urllib.request.Request(url, headers={'User-Agent': 'vibe-setup'})
with urllib.request.urlopen(req, timeout=120) as r:
    content = r.read()
work = tmp / repo.replace('/', '_')
if work.exists():
    shutil.rmtree(work)
work.mkdir(parents=True)
import io
with zipfile.ZipFile(io.BytesIO(content)) as z:
    z.extractall(work)
entries = list(work.iterdir())
src = entries[0] if len(entries) == 1 and entries[0].is_dir() else work
if dest.exists():
    shutil.rmtree(dest)
shutil.copytree(src, dest)
print('   ok', dest)
PY
}

echo "==> Ox (releases buildées)"
download_ox_release overextended/oxmysql      "$ROOT/resources/[ox]/oxmysql"
download_ox_release overextended/ox_lib        "$ROOT/resources/[ox]/ox_lib"
download_ox_release overextended/ox_target      "$ROOT/resources/[ox]/ox_target"
download_ox_release overextended/ox_doorlock    "$ROOT/resources/[ox]/ox_doorlock"
download_ox_release overextended/ox_inventory   "$ROOT/resources/[ox]/ox_inventory"
download_ox_release overextended/ox_fuel        "$ROOT/resources/[ox]/ox_fuel" || true

echo "==> Voice"
clone_or_update "https://github.com/AvarianKnight/pma-voice.git" "$ROOT/resources/[voice]/pma-voice"

echo "==> Qbox"
for repo in qbx_core qbx_medical qbx_ambulancejob qbx_policejob qbx_management \
  qbx_radialmenu qbx_radio qbx_smallresources qbx_density qbx_vehicles qbx_garages \
  qbx_vehicleshop qbx_customs qbx_properties qbx_idcard qbx_seatbelt qbx_hud \
  qbx_scoreboard qbx_spawn qbx_taxijob qbx_binoculars qbx_divegear qbx_fireworks \
  qbx_helicam qbx_chat_theme; do
  clone_or_update "https://github.com/Qbox-project/${repo}.git" "$ROOT/resources/[qbx]/${repo}"
done

echo "==> Housing / admin / utils"
clone_or_update "https://github.com/Project-Sloth/ps-adminmenu.git" "$ROOT/resources/[standalone]/ps-adminmenu" || true
clone_or_update "https://github.com/Project-Sloth/ps-housing.git" "$ROOT/resources/[housing]/ps-housing" || true
clone_or_update "https://github.com/Project-Sloth/ps-realtor.git" "$ROOT/resources/[housing]/ps-realtor" || true
clone_or_update "https://github.com/Renewed-Scripts/Renewed-Banking.git" "$ROOT/resources/[standalone]/Renewed-Banking" || true
clone_or_update "https://github.com/Renewed-Scripts/Renewed-Weathersync.git" "$ROOT/resources/[standalone]/Renewed-Weathersync" || true
clone_or_update "https://github.com/Xogy/xsound.git" "$ROOT/resources/[standalone]/xsound" || true
clone_or_update "https://github.com/Bob74/bob74_ipl.git" "$ROOT/resources/[maps]/bob74_ipl"

echo "==> CFX core (si manquant)"
if [[ ! -f "$ROOT/resources/[core]/chat/fxmanifest.lua" ]]; then
  git clone --depth 1 https://github.com/citizenfx/cfx-server-data.git "$TMP/cfx-server-data"
  CORE="$ROOT/resources/[core]"
  mkdir -p "$CORE"
  cp -a "$TMP/cfx-server-data/resources/[managers]/mapmanager" "$CORE/"
  cp -a "$TMP/cfx-server-data/resources/[managers]/spawnmanager" "$CORE/"
  cp -a "$TMP/cfx-server-data/resources/[gameplay]/chat" "$CORE/"
  cp -a "$TMP/cfx-server-data/resources/[system]/sessionmanager" "$CORE/"
  cp -a "$TMP/cfx-server-data/resources/[system]/baseevents" "$CORE/"
  cp -a "$TMP/cfx-server-data/resources/[system]/hardcap" "$CORE/"
fi

# Re-merge vibe items if inventory reinstalled
if [[ -f "$ROOT/config/items_vibe.lua" && -f "$ROOT/resources/[ox]/ox_inventory/data/items.lua" ]]; then
  if ! grep -q 'VIBE CUSTOM ITEMS' "$ROOT/resources/[ox]/ox_inventory/data/items.lua"; then
    echo "==> Fusion items vibe dans ox_inventory"
    python3 - <<'PY'
from pathlib import Path
items_path = Path('resources/[ox]/ox_inventory/data/items.lua')
vibe = Path('config/items_vibe.lua').read_text()
body = vibe[vibe.find('return {')+len('return {'):].rsplit('}',1)[0].strip()
text = items_path.read_text(encoding='utf-8')
idx = text.rfind('}')
items_path.write_text(text[:idx] + "\n\t-- VIBE CUSTOM ITEMS\n" + body + "\n" + text[idx:], encoding='utf-8')
PY
  fi
fi

echo ""
echo "Installation terminée. Voir LIEN-COMPLET.md et docs/GUIDE-INSTALL.md"
