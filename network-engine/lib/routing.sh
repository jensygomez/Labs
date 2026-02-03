#!/bin/bash
# network-engine/lib/routing.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"


# ------------------------------------------------------------------------------
# PRIMITIVA 4: ENSURE ROUTE (Versión Corregida)
# ------------------------------------------------------------------------------
ensure_route(){
  local ns="$1"
  local dest="$2"
  local via="$3"

  if ! ns_exists "$ns"; then
    # echo "❌ Namespace $ns no existe"
    return 1
  fi

  # 1. Comprobación robusta
  # Filtramos por el destino exacto. Si el output no está vacío, la ruta existe.
  if ip netns exec "$ns" ip route show to "$dest" | grep -q "via $via"; then
    # echo "✔ Ruta $dest via $via ya existe en $ns"
    return 0
  fi

  # 2. Uso de 'replace' en lugar de 'add'
  # 'replace' es la clave de la idempotencia: si no existe la crea, 
  # si existe con otro gateway la actualiza, y nunca lanza "File exists".
  if ip netns exec "$ns" ip route replace "$dest" via "$via"; then
    # echo "+ Ruta $dest via $via agregada/actualizada en $ns"
  else
    # echo "❌ Error al configurar ruta $dest en $ns"
    return 1
  fi
}