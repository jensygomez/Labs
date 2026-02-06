#!/bin/bash
# network-engine/phases/05-forwarding.sh
run_phase(){
    echo "[FASE 5] ejecutando Forwarding & Kernel"
    for ns in "${ROUTERS[@]}";do
        ensure_forwarding "$ns"
    done
}