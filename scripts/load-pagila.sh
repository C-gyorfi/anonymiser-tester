#!/usr/bin/env bash
# Load the Pagila schema and data into the Postgres container.
# Run scripts/download-pagila.sh first.
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-anonymiser-tester}"
DB_USER="${DB_USER:-testuser}"
DB_NAME="${DB_NAME:-anonymiser-tester-db}"
DIR="$(cd "$(dirname "$0")/.." && pwd)/pagila"

for file in pagila-schema.sql pagila-data.sql; do
  if [ ! -f "$DIR/$file" ]; then
    echo "Missing $DIR/$file - run scripts/download-pagila.sh first" >&2
    exit 1
  fi
done

for file in pagila-schema.sql pagila-data.sql; do
  echo "Loading $file"
  # Drop "OWNER TO postgres" statements: the container has no postgres role
  sed -E '/OWNER TO postgres/d' "$DIR/$file" |
    docker exec -i "$DB_CONTAINER" \
      psql -v ON_ERROR_STOP=1 -q -U "$DB_USER" -d "$DB_NAME"
done

echo "Pagila loaded into $DB_NAME"
