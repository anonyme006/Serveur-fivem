#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB_URL="${1:-mysql -u root -p}"

echo "Import sql/init.sql"
$DB_URL < "$ROOT/sql/init.sql"

shopt -s nullglob
for f in "$ROOT/sql/vendor"/*.sql; do
  echo "Import $f"
  $DB_URL fivem_qbox < "$f" || true
done
echo "OK"
