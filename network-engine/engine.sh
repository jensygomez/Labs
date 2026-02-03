#!/bin/bash
# network-engine/engine.sh
set -Eeo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
# En engine.sh
source "$BASE_DIR/topology/lab.conf"  # 1. Primero los datos
source "$BASE_DIR/lib/guard.sh"       # 2. Luego las validaciones
source "$BASE_DIR/lib/netns.sh"       # 3. Luego las herramientas
source "$BASE_DIR/lib/idempotency.sh"

echo "🚀 Iniciando engine..." >&2

# Verificamos archivos antes de hacer source para que no muera en silencio
[[ -f "$BASE_DIR/lib/guard.sh" ]] || { echo "❌ ERROR: No existe lib/guard.sh"; exit 1; }
source "$BASE_DIR/lib/guard.sh"

[[ -f "$BASE_DIR/lib/idempotency.sh" ]] || { echo "❌ ERROR: No existe lib/idempotency.sh"; exit 1; }
source "$BASE_DIR/lib/idempotency.sh"

[[ -f "$BASE_DIR/topology/lab.conf" ]] || { echo "❌ ERROR: No existe topology/lab.conf"; exit 1; }
source "$BASE_DIR/topology/lab.conf"

# Verificamos si require_root está fallando
echo "🔍 Verificando privilegios..." >&2
require_root

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

# Ejecutar fases
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