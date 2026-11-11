#!/usr/bin/env bash
# A zero Godot process exit code does NOT always mean that the script parsed
# and ran correctly. Capture its own log and reject hidden GDScript failures.
set -euo pipefail
if [[ $# -ne 1 || "$1" != res://tests/*.gd ]]; then
  echo "Usage: bash tests/godot_guard.sh res://tests/name.gd" >&2
  exit 2
fi
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
timeout --signal=TERM --kill-after=5s 150s \
  godot --headless --path . --script "$1" 2>&1 | tee "$log"
if grep -E 'SCRIPT ERROR:|ERROR: Failed to load script|Parse Error:|Compile Error:|Invalid call\.' "$log"; then
  echo "::error::Godot reported a hidden script failure in $1" >&2
  exit 1
fi
