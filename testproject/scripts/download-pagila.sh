#!/usr/bin/env bash
# Download the Pagila sample database (schema + data) into ./pagila
set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/devrimgunduz/pagila/master"
DEST="$(cd "$(dirname "$0")/.." && pwd)/pagila"

mkdir -p "$DEST"

for file in pagila-schema.sql pagila-data.sql; do
  echo "Downloading $file"
  curl -fsSL -o "$DEST/$file" "$BASE_URL/$file"
done

echo "Saved to $DEST"
