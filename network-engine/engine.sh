#!/bin/bash
# network-engine/engine.sh
set -Eeo pipefail  # Quitamos la -u para que no sea tan sensible con las variables

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cargar dependencias CRÍTICAS
source "$BASE_DIR/lib/guard.sh"
source "$BASE_DIR/lib/idempotency.sh"
source "$BASE_DIR/topology/lab.conf"

require_root

echo "🚀 Iniciando engine..." >&2

run() {
  local phase="$1"
  echo "📦 Ejecutando fase: $phase" >&2
  
  if [[ ! -f "$BASE_DIR/phases/$phase" ]]; then
    echo "❌ Fase $phase no existe" >&2
    exit 1
  fi
  
  source "$BASE_DIR/phases/$phase"
  
  if ! declare -F run_phase >/dev/null; then
    echo "❌ $phase no define run_phase()" >&2
    exit 1
  fi
  
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