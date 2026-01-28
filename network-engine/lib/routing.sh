#!/bin/bash
# network-engine/lib/routing.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"



# ------------------------------------------------------------------------------
# PRIMITIVA 4: ENSURE ROUTE
# ------------------------------------------------------------------------------
ensure_route(){
  local ns="$1"
  local dest="$2"
  local via="$3"
  if ! ns_exists "$ns"; then
    echo "❌ Namespace $ns no existe"
    return 1
  fi
  # Normalizar Destino
  local route_dest
  if [[ "$dest" == "default" ]]; then 
    route_dest="default"
  else  
    route_dest="$dest"
  fi
  # Ruta ya Existe...?
  if ip netns exec "$ns" ip route show | grep -qw "$route_dest via $via"; then
    echo  "✔ Ruta $route_dest via $via ya existe en $ns"
    return 0
  fi
  # Agregar Ruta
  ip netns exec "$ns" ip route add "$route_dest" via "$via"
  echo "+ Ruta $route_dest via $via agregada en $ns"
}
