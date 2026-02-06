#!/bin/bash
# network-engine/phases/03-addressing.sh
run_phase() {
  echo "[FASE 3] ejecutando IPs"
  for i in "${IPS[@]}"; do
    IFS=":" read -r ns ifc ip <<< "$i"
    ensure_ip "$ns" "$ifc" "$ip"
  done
}
