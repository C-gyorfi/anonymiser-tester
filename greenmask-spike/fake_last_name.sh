#!/usr/bin/env bash
# Custom Greenmask transformer (Cmd transformer, text driver).
# Greenmask sends one value per line on stdin; we reply with one line on stdout.
# This one ignores the input and returns a fake string.
trap 'exit 0' TERM

while IFS= read -r _; do
  echo "Fake-${RANDOM}"
done
