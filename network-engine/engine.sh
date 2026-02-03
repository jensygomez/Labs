#!/bin/bash
# network-engine/engine.sh
set -Eeo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Iniciando engine..." >&2

# Función para cargar componentes con validación
load_component() {
  local file="$1"
  if [[ -f "$BASE_DIR/$file" ]]; then
    source "$BASE_DIR/$file"
  else
    echo "❌ ERROR CRÍTICO: No se encuentra $file" >&2
    exit 1
  fi
}

# 1. Cargar dependencias en orden lógico
load_component "topology/lab.conf"
load_component "lib/guard.sh"
load_component "lib/netns.sh"
load_component "lib/links.sh"       # <--- ¡ESTA FALTABA!
load_component "lib/addressing.sh"  # <--- Asegúrate de que esta también esté
load_component "lib/firewall.sh"    # <--- Y esta para la fase 08
load_component "lib/idempotency.sh"

# 2. Validar privilegios
require_root
echo "🔍 Privilegios de root verificados." >&2

# 3. Definir ejecutor de fases
run() {
  local phase="$1"
  local phase_path="$BASE_DIR/phases/$phase"
  
  echo "📦 Ejecutando fase: $phase" >&2
  
  if [[ ! -f "$phase_path" ]]; then
    echo "❌ Error: Archivo de fase $phase no encontrado." >&2
    exit 1
  fi
  
  source "$phase_path"
  
  if ! declare -F run_phase >/dev/null; then
    echo "❌ Error: $phase no define la función run_phase()" >&2
    exit 1
  fi
  
  run_phase
  unset -f run_phase
}

# 4. Ejecución secuencial
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