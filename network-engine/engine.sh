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
# 3. Cargar configuraciones de firewall
# ------------------------------------------------------------------------------
load_component "topology/firewall/base.conf"
load_component "topology/firewall/core-edge.conf"
load_component "topology/firewall/core-mgmt.conf"
load_component "topology/firewall/core-svc.conf"
load_component "topology/firewall/core-adm.conf"
load_component "topology/firewall/edge-1.conf"

# ------------------------------------------------------------------------------
# 4. Carga dinámica de routing/*.conf
# ------------------------------------------------------------------------------
for routing_conf in "$BASE_DIR"/topology/routing/*.conf; do
  [[ -f "$routing_conf" ]] && load_component "${routing_conf#"$BASE_DIR"/}"
done

# ------------------------------------------------------------------------------
# 5. Cargar TODAS las librerías (primitivas del engine)
# ------------------------------------------------------------------------------
load_component "lib/guard.sh"
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
# 6. Validar privilegios
# ------------------------------------------------------------------------------
require_root
echo "🔍 Privilegios de root verificados." >&2

# ------------------------------------------------------------------------------
# 7. Ejecutor estándar de fases
# Cada fase DEBE definir run_phase()
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 8. Ejecución dinámica de fases (orden = prefijo numérico)
# ------------------------------------------------------------------------------
echo "📦 Ejecutando fases dinámicamente..." >&2

shopt -s nullglob
for phase in "$BASE_DIR"/phases/[0-9][0-9]-*.sh \
             "$BASE_DIR"/phases/[0-9][0-9][0-9]-*.sh; do
  run "$(basename "$phase")"
done
shopt -u nullglob

# ------------------------------------------------------------------------------
echo "✅ Topología convergida completamente"
