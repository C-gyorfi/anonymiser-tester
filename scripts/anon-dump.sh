#!/usr/bin/env bash
# Write an anonymised plain-SQL dump to stdout: pg_dump run as the masked role
# anon_dumper, so it only ever reads masked values.
# Usage: scripts/anon-dump.sh > anonymised.sql
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-anonymiser-tester-anon}"
DB_NAME="${DB_NAME:-anonymiser-tester-db}"

# --no-security-labels keeps the masking rules out of the dump;
# --exclude-extension=anon keeps the extension out (needs pg_dump 17+).
docker exec "$DB_CONTAINER" \
  pg_dump -U anon_dumper -d "$DB_NAME" \
    --no-owner --no-privileges --no-security-labels --exclude-extension=anon
