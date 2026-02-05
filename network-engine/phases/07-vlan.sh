#!/bin/bash
# network-engine/phases/07-core-svc.sh
run_phase(){
    echo "[FASE 7] Configurando Core Services (Vlan Trunking)"

    for vlan_entry in "${VLANS[@]}";do
        IFS=':' read -r ns parent_if vlan_id ip_cidr <<< "$vlan_entry"
        # Usamos la funcion de la Lib
        ensure_vlan "$ns" "$parent_if" "$vlan_id" "$ip_cidr"
    done
    sleep 2
    echo "[FASE 7] ejecutada com sucesso"
    echo "-----------------------------------"
}