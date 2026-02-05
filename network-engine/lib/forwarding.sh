#!/bin/bash
# network-engine/lib/forwarding.sh
ensure_forwarding(){
    local ns="$1"

    local current
    current=$(ip netns exec "$ns" sysctl -n net.ipv4.ip_forward)

    if [[ "$current" != "1" ]]; then
        ip netns exec "$ns" sysctl -w net.ipv4.ip_forward=1 >/dev/null
    fi

    ip netns exec "$ns" sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
    ip netns exec "$ns" sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null

    #echo "✔ Forwarding OK en $ns"
}
