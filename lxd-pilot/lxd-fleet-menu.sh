#!/usr/bin/env bash
set -o errexit
set -o pipefail

NODES=(lb01 lb02 app01 app02 app03 app04 storage01 backup01 infra01 bastion01)

get_fleet_state() {
    local defined=0 running=0 stopped=0

    for node in "${NODES[@]}"; do
        if lxc info "$node" &>/dev/null; then
            defined=$((defined + 1))
            local state
            state="$(lxc info "$node" | grep -i "Status:" | awk '{print $2}')"
            case "$state" in
                RUNNING|Running) running=$((running + 1)) ;;
                STOPPED|Stopped) stopped=$((stopped + 1)) ;;
            esac
        fi
    done

    echo "$defined $running $stopped"
}

do_deploy() {
    bash make-lxd-fleet.sh
}

do_reset() {
    echo "==> 🔄 Destruyendo y recreando la Flota Corporativa..."
    for node in "${NODES[@]}"; do
        echo "    Destruyendo $node..."
        lxc delete "$node" --force 2>/dev/null || true
    done
    bash make-lxd-fleet.sh
}

do_shutdown() {
    echo "==> 🛑 Apagando la flota..."
    for node in "${NODES[@]}"; do
        lxc stop "$node" 2>/dev/null || true
    done
}

do_start() {
    echo "==> 🚀 Arrancando la flota..."
    for node in "${NODES[@]}"; do
        lxc start "$node" 2>/dev/null || true
    done
}

while true; do
    clear
    echo "========================================================="
    echo "       GESTOR DE FLOTA CORPORATIVA LXD (10 NODOS)        "
    echo "========================================================="
    lxc list
    echo ""

    read -r defined running stopped <<< "$(get_fleet_state)"

    if [[ "$defined" -eq 0 ]]; then
        echo "Estado: No hay contenedores desplegados."
        echo "1) Desplegar Flota (make-lxd-fleet.sh)"
        echo "2) Refrescar"
        echo "3) Salir"
        read -rp "Opción: " opt
        case "$opt" in
            1) do_deploy ;;
            2) continue ;;
            3) exit 0 ;;
            *) echo "Inválido"; sleep 1 ;;
        esac
    elif [[ "$running" -eq "$defined" ]]; then
        echo "Estado: Toda la flota ($running nodos) está RUNNING."
        echo "1) Resetear (Clean Slate / Recrear desde cero)"
        echo "2) Apagar todos los nodos"
        echo "3) Refrescar"
        echo "4) Salir"
        read -rp "Opción: " opt
        case "$opt" in
            1) do_reset ;;
            2) do_shutdown ;;
            3) continue ;;
            4) exit 0 ;;
            *) echo "Inválido"; sleep 1 ;;
        esac
    else
        echo "Estado: $running corriendo, $stopped apagados de $defined definidos."
        echo "1) Iniciar nodos apagados"
        echo "2) Resetear todo (Clean Slate)"
        echo "3) Apagar todos"
        echo "4) Refrescar"
        echo "5) Salir"
        read -rp "Opción: " opt
        case "$opt" in
            1) do_start ;;
            2) do_reset ;;
            3) do_shutdown ;;
            4) continue ;;
            5) exit 0 ;;
            *) echo "Inválido"; sleep 1 ;;
        esac
    fi
done
