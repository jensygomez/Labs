#!/bin/bash
# network-engine/phases/09-services.sh

run_phase() {
  echo "[FASE 9] ejecutando Servicios"

  for svc in "${SERVICES[@]}"; do
    ensure_service "$svc"
  done
}
