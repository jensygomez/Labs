#!/bin/bash
# network-engine/phases/09-services.sh

run_phase() {
  echo "[FASE 9] ejecutando Servicios"

  # Definir qué servicios iniciar (SOLUCIÓN CLAVE)
  SERVICES=("svc-web")

  for svc in "${SERVICES[@]}"; do
    ensure_service "$svc"
  done
  
  # Pequeña pausa para que el servicio arranque
  sleep 1
}