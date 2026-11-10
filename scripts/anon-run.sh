#!/usr/bin/env bash
# One command: apply anon/setup.sql and anon/rules.sql, then write the
# anonymised dump to stdout. Progress goes to stderr.
# Usage: scripts/anon-run.sh > anonymised.sql
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-anonymiser-tester-anon}"
DB_USER="${DB_USER:-testuser}"
DB_NAME="${DB_NAME:-anonymiser-tester-db}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

apply() {
  echo "Applying $1" >&2
  docker exec -i "$DB_CONTAINER" \
    psql -v ON_ERROR_STOP=1 -q -U "$DB_USER" -d "$DB_NAME" < "$ROOT/anon/$1" >&2
}

apply setup.sql
apply rules.sql

echo "Dumping as masked role" >&2
"$ROOT/scripts/anon-dump.sh"
