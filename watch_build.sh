#!/usr/bin/env bash
cd /c/Users/HP/wlanre/build
for i in $(seq 1 60); do
  st=$(gh run view 31830720089 --repo GalToast/oneplus-guacamole-kernel --json status --jq .status 2>/dev/null)
  echo "[$(date -u +%H:%M:%S)] status=$st" >> build_watch.log
  if [ "$st" = "completed" ]; then echo "TERMINAL "$(date -u +%H:%M:%S) >> gate_watch.log; break; fi
  sleep 120
done
echo "watch ended $(date -u +%H:%M:%S)" >> build_watch.log