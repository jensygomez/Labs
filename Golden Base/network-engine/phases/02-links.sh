#!/bin/bash
source lib/links.sh
source topology/lab.conf

run_phase() {
  echo "[FASE 2] Cables"
  for c in "${CABLES[@]}"; do
    IFS=":" read -r a ia b ib <<< "$c"
    ensure_cable "$a" "$ia" "$b" "$ib"
  done
}
