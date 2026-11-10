#!/usr/bin/env bash
# Load Pagila into the PostgreSQL Anonymizer container (make anon-up).
# Run scripts/download-pagila.sh first.
#
# The Anonymizer image has no pgvector, so everything about the
# film_embedding table is dropped (extension, table, index, trigger, FK, data).
# It holds film embeddings, not personal data, so masking tests are unaffected.
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-anonymiser-tester-anon}"
DB_USER="${DB_USER:-testuser}"
DB_NAME="${DB_NAME:-anonymiser-tester-db}"
DIR="$(cd "$(dirname "$0")/.." && pwd)/pagila"

for file in pagila-schema.sql pagila-data.sql; do
  if [ ! -f "$DIR/$file" ]; then
    echo "Missing $DIR/$file - run scripts/download-pagila.sh first" >&2
    exit 1
  fi
done

# pg_dump separates statements with blank lines, so work paragraph by paragraph
# and skip any paragraph that belongs to the vector extension or film_embedding.
drop_vector_parts() {
  awk 'BEGIN { RS = ""; ORS = "\n\n" }
       !/film_embedding|EXTENSION (IF NOT EXISTS )?vector|Name: vector|public\.vector/'
}

for file in pagila-schema.sql pagila-data.sql; do
  echo "Loading $file (without pgvector parts)"
  # Drop "OWNER TO postgres" statements: the container has no postgres role
  sed -E '/OWNER TO postgres/d' "$DIR/$file" |
    drop_vector_parts |
    docker exec -i "$DB_CONTAINER" \
      psql -v ON_ERROR_STOP=1 -q -U "$DB_USER" -d "$DB_NAME"
done

echo "Pagila loaded into $DB_NAME on $DB_CONTAINER"
