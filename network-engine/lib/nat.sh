#!/bin/bash
# network-engine/lib/nat.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/idempotency.sh"

ensure_nat(){
    local ns="$1"
    local out_if="$2"
    #Validaciones
    if ! ns_exists "$ns"; then
        # echo "❌ Namespace $ns no existe"
        return 1
    fi
    if ! ip netns exec "$ns" ip link show "$out_if" &>/dev/null; then
        # echo "❌ Interfaz $out_if no existe en $ns"
        return 1
    fi
    # Idempotencia NAT
    if ip netns exec "$ns" iptables -t nat -C POSTROUTING -o "$out_if" -j MASQUERADE 2>/dev/null; then
        # echo "✔ NAT ya activo en $ns ($out_if)"
        return 0
    else
        # Aplicar NAT
        ip netns exec "$ns" iptables -t nat -A POSTROUTING -o "$out_if" -j MASQUERADE
        # echo "🔥 NAT habilitado en $ns ($out_if)" 
    fi
}