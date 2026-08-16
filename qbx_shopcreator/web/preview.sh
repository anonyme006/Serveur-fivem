#!/usr/bin/env bash
# Preview NUI in browser without FiveM and without production build.
# Hot-reload: edit src/ → refresh automatically.
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -d node_modules ]]; then
  npm install
fi
echo ""
echo "  Preview (mocks, hot reload — no build):"
echo "    Management : http://127.0.0.1:5173/?mode=management"
echo "    Storefront : http://127.0.0.1:5173/?mode=storefront"
echo "    Admin      : http://127.0.0.1:5173/?mode=admin"
echo "    Deliveries : http://127.0.0.1:5173/?mode=deliveries"
echo ""
exec npm run dev -- --host 127.0.0.1 --port 5173
