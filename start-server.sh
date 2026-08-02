#!/usr/bin/env bash
# Lance FXServer avec ce dossier comme server-data
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ ! -f artifacts/FXServer ]] && [[ ! -f artifacts/run.sh ]]; then
  echo "Place les artifacts FiveM dans ./artifacts/"
  echo "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
  exit 1
fi

if [[ -f artifacts/run.sh ]]; then
  exec ./artifacts/run.sh +exec server.cfg "$@"
fi
exec ./artifacts/FXServer +set serverProfile default +exec server.cfg "$@"
