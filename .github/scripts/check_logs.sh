#!/usr/bin/env bash
# Fails if a Godot log contains script/parse errors, or the autoplay game did not finish.
set -u
status=0
for log in "$@"; do
  if grep -nE "SCRIPT ERROR|Parse Error|Failed to load script|Invalid call|Invalid access" "$log"; then
    echo "::error::Errors in $log"
    status=1
  fi
done
if ! grep -q "game over" autoplay.log; then
  echo "::error::Autoplay game did not finish"
  status=1
fi
exit $status
