#!/bin/bash
# network-engine/engine.sh
set -Eeo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "🚀 Iniciando engine..." >&2

# ------------------------------------------------------------------------------
# Loader genérico con validación
# ------------------------------------------------------------------------------
load_component() {
  local file="$1"
  if [[ -f "$BASE_DIR/$file" ]]; then
    source "$BASE_DIR/$file"
  else
    echo "❌ ERROR CRÍTICO: No se encuentra $file" >&2
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# 1. Cargar configuración base (datos declarativos)
# ------------------------------------------------------------------------------
load_component "topology/lab.conf"

# ------------------------------------------------------------------------------
# 2. Declarar estructuras globales ANTES de los .conf
# ------------------------------------------------------------------------------
declare -A FW_ZONES
declare -A FW_POLICIES
declare -A FW_RULES
FW_NAMESPACES=()

# ------------------------------------------------------------------------------
# 3. Cargar configuraciones de firewall DINÁMICAMENTE
# ------------------------------------------------------------------------------
# Primero cargar base.conf si existe
[[ -f "$BASE_DIR/topology/firewall/base.conf" ]] && load_component "topology/firewall/base.conf"

# Luego cargar todos los demás .conf en firewall/ (excepto base.conf)
for fw_conf in "$BASE_DIR"/topology/firewall/*.conf; do
  [[ -f "$fw_conf" ]] || continue
  [[ "$(basename "$fw_conf")" == "base.conf" ]] && continue
  load_component "${fw_conf#"$BASE_DIR"/}"
done

# ------------------------------------------------------------------------------
# 4. Carga dinámica de routing/*.conf
# ------------------------------------------------------------------------------
for routing_conf in "$BASE_DIR"/topology/routing/*.conf; do
  [[ -f "$routing_conf" ]] && load_component "${routing_conf#"$BASE_DIR"/}"
done

# ------------------------------------------------------------------------------
# 5. Guardia de root
# ------------------------------------------------------------------------------
load_component "lib/guard.sh"
require_root

# ------------------------------------------------------------------------------
# 6. Librerías de funciones
# ------------------------------------------------------------------------------
load_component "lib/netns.sh"
load_component "lib/links.sh"
load_component "lib/addressing.sh"
load_component "lib/routing.sh"
load_component "lib/forwarding.sh"
load_component "lib/nat.sh"
load_component "lib/vlan.sh"
load_component "lib/firewall.sh"
load_component "lib/services.sh"
load_component "lib/idempotency.sh"

# ------------------------------------------------------------------------------
# 7. Control de idempotencia
# ------------------------------------------------------------------------------
echo "🔍 Privilegios de root verificados."

# ------------------------------------------------------------------------------
# 8. Ejecutar fases dinámicamente
# ------------------------------------------------------------------------------
echo "📦 Ejecutando fases dinámicamente..."

for phase in "$BASE_DIR"/phases/*.sh; do
  [[ -f "$phase" ]] || continue
  echo "📦 Ejecutando fase: $(basename "$phase")"
  source "$phase"
  run_phase || {
    echo "❌ ERROR en fase $(basename "$phase")" >&2
    exit 1
  }
done

echo "✅ Topología convergida completamente"