#!/bin/bash
# network-engine/phases/05-forwarding.sh
run_phase(){
    echo "[FASE 5] Forwarding & Kernel..."
    for ns in "${ROUTERS[@]}";do
        ensure_forwarding "$ns"
    done
    echo
    echo "ejecuntando..."
    sleep 2
    echo
    echo "[FASE 5] ejecutada com sucesso"
    echo "-----------------------------------"
}