#!/usr/bin/env bash
# The public OnePlus sm8150 source tree is sanitized: it lacks some
# OnePlus-specific directories (e.g. drivers/input/oneplus_touchscreen) that the
# device's /proc/config.gz references. Those Kconfigs are pulled in via
# `source "..."` lines; if the target file is absent, `make olddefconfig` aborts.
# This script comments out any `source` line whose target file does not exist,
# so the missing options simply become undefined (dropped to 'n') instead of
# breaking the config step. Run from the repo root (expects ./kernel).
set -e
cd "$(dirname "$0")"
KSRC="${1:-kernel}"
cd "$KSRC" || { echo "fix_kconfig: no dir $KSRC"; exit 1; }
echo "fix_kconfig: scanning Kconfig files in $KSRC..."
count=0
find . -name Kconfig | while read -r f; do
  dir=$(dirname "$f")
  # extract lines like:  source "path/to/Kconfig"
  grep -nE '^[[:space:]]*source[[:space:]]+"' "$f" | while IFS= read -r raw; do
    lnum=$(echo "$raw" | cut -d: -f1)
    path=$(echo "$raw" | sed -E 's/.*source[[:space:]]+"([^"]+)".*/\1/')
    if [ -e "$path" ] || [ -e "$dir/$path" ]; then
      continue
    fi
    echo "  commenting out missing source: $f:$lnum -> $path"
    sed -i "${lnum}s|^|# SANITIZED-MISSING: |" "$f"
    count=$((count+1))
  done
done
echo "fix_kconfig: done."
