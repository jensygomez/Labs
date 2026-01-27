#!/bin/bash
source lib/addressing.sh
source topology/lab.conf

run_phase() {
  echo "[FASE 3] IPs"
  for i in "${IPS[@]}"; do
    IFS=":" read -r ns ifc ip <<< "$i"
    ensure_ip "$ns" "$ifc" "$ip"
  done
}
