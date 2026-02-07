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

# 1. Cargar la configuración (Los datos)
load_component "topology/lab.conf"

# 2. DECLARAR ARRAYS ASOCIATIVOS PRIMERO (IMPORTANTE)
declare -A FW_ZONES
declare -A FW_POLICIES
declare -A FW_RULES
FW_NAMESPACES=()

# 3. Cargar configuraciones de firewall ANTES que las funciones
load_component "topology/firewall/base.conf"
load_component "topology/firewall/core-edge.conf"
load_component "topology/firewall/core-mgmt.conf"
load_component "topology/firewall/core-svc.conf"
load_component "topology/firewall/core-adm.conf"
load_component "topology/firewall/edge-1.conf"  

# 🔄 NUEVO: Carga DINÁMICA de TODOS routing/*.conf
for routing_conf in "$BASE_DIR"/topology/routing/*.conf; do
    [[ -f "$routing_conf" ]] && load_component "${routing_conf#"$BASE_DIR"/}"
done

# 4. Cargar TODAS las librerías (Las funciones/herramientas)
load_component "lib/guard.sh"
load_component "lib/netns.sh"
load_component "lib/links.sh"
load_component "lib/addressing.sh"
load_component "lib/routing.sh"
load_component "lib/forwarding.sh"
load_component "lib/nat.sh"        
load_component "lib/vlan.sh"        
load_component "lib/firewall.sh"    # AHORA ya tiene las variables definidas
load_component "lib/idempotency.sh"

# 5. Validar privilegios
require_root
echo "🔍 Privilegios de root verificados." >&2

# 6. Definir ejecutor de fases
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

# 7. Ejecución secuencial
run 01-netns.sh
run 02-links.sh
run 03-addressing.sh
run 04-routing.sh
run 05-forwarding.sh
run 06-nat.sh
run 07-vlan.sh
run 08-firewall.sh
run 09-services.sh
run 100-trace-test.sh

echo "✅ Topología convergida completamente"