#!/usr/bin/env bash
# The anonymous dump must keep customer rows but replace real names and emails
# with fake values (not real ones, and not NULL).
# Needs the anon container loaded with Pagila (make anon-up, scripts/load-pagila-anon.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REAL_EMAIL="MARY.SMITH@sakilacustomer.org"   # customer_id 1 in Pagila
DUMP="$(mktemp)"
trap 'rm -f "$DUMP"' EXIT

"$ROOT/scripts/anon-run.sh" > "$DUMP" 2>/dev/null

# Guard against a vacuous pass: the dump must actually contain customer data.
grep -q "COPY public.customer" "$DUMP" || { echo "FAIL: dump has no customer data"; exit 1; }

if grep -q "$REAL_EMAIL" "$DUMP"; then
  echo "FAIL: real email $REAL_EMAIL found in anonymous dump"
  exit 1
fi

# customer 1: columns are customer_id, store_id, first_name, last_name, email, ...
ROW="$(awk -F'\t' '/^COPY public.customer /{in_copy=1; next} /^\\\./{in_copy=0} in_copy && $1==1 {print $3 "\t" $4 "\t" $5}' "$DUMP")"
if [ -z "$ROW" ] || [[ "$ROW" == *'\N'* ]] || [[ "$ROW" == *MARY* ]]; then
  echo "FAIL: customer 1 name/email not replaced with fake values: '$ROW'"
  exit 1
fi

echo "PASS: customer names and emails are masked with fake values ($ROW)"
