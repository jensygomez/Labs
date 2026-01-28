#!/bin/bash
set -Eeuo pipefail

ensure_forwarding(){
    local ns="$1"
    ip netns exec "$ns" sysctl -w net.ipv4.ip_forward=1 >/dev/null

    ip netns exec "$ns" sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
    ip netns exec "$ns" sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null

    echo "✔ Forwarding habilitado en $ns"

}