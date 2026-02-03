#!/bin/bash
# network-engine/engine.sh
set -Eeuo pipefail

# Debug handling mejorado
[[ "${DEBUG:-0}" == "1" ]] && set -x

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cargar dependencias CRÍTICAS primero
source "$BASE_DIR/lib/guard.sh"
source "$BASE_DIR/lib/idempotency.sh"
source "$BASE_DIR/topology/lab.conf"           # ← FIX PRINCIPAL

require_root

echo "🚀 Iniciando engine - DEBUG=$DEBUG" >&2

run() {
  local phase="$1"
  echo "📦 Ejecutando fase: $phase" >&2
  
  [[ -f "$BASE_DIR/phases/$phase" ]] || {
    echo "❌ Fase $phase no existe" >&2
    exit 1
  }
  
  source "$BASE_DIR/phases/$phase"
  
  declare -F run_phase >/dev/null || {
    echo "❌ $phase no define run_phase()" >&2
    exit 1
  }
  
  run_phase
  unset -f run_phase
}

# Ejecutar fases secuencialmente
run 01-netns.sh
run 02-links.sh
run 03-addressing.sh
run 04-routing.sh
run 05-forwarding.sh
run 06-nat.sh
run 07-vlan.sh
run 08-firewall.sh
run 100-trace-test.sh

echo "✅ Topología convergida completamente"
