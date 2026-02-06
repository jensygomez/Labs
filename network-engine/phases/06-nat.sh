#!/bin/bash
# network-engine/phases/06-nat.sh
run_phase(){
    echo "[FASE 6] ejecutando Nat & Egress"
    for nat in "${NAT_ROUTERS[@]}"; do
        IFS=":" read -r ns iface <<< "$nat"
        # echo "  Configurando NAT para $ns en interfaz $iface"
        ensure_nat "$ns" "$iface"
    done
}