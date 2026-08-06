#!/usr/bin/env bash
# fleet-menu.sh
#
# Menú dinámico para gestionar el estado de la flota de laboratorio.
# Lee el estado real via virsh y adapta las opciones disponibles.
#
# Uso: bash fleet-menu.sh

set -o errexit
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODES=(node01 node02 node03 node04)
WAIT_SECONDS=60

# --- Detección de estado ---------------------------------------------------

get_fleet_state() {
    local defined=0 running=0 shutoff=0

    for node in "${NODES[@]}"; do
        if sudo virsh dominfo "$node" &>/dev/null; then
            defined=$((defined + 1))
            local state
            state="$(sudo virsh domstate "$node" 2>/dev/null || echo desconocido)"
            case "$state" in
                running)   running=$((running + 1)) ;;
                "shut off") shutoff=$((shutoff + 1)) ;;
            esac
        fi
    done

    echo "$defined $running $shutoff"
}

# --- Acciones ----------------------------------------------------------------

do_deploy() {
    bash "$SCRIPT_DIR/launch-pilot-fleet.sh"
}

do_reset() {
    declare -A FLEET_IPS=(
        ["node01"]="192.168.122.11"
        ["node02"]="192.168.122.12"
        ["node03"]="192.168.122.13"
        ["node04"]="192.168.122.14"
    )
    declare -A FLEET_EXTRA=(
        ["node01"]=""
        ["node02"]=""
        ["node03"]=""
        ["node04"]="nfs-utils"
    )

    echo "==> 🔄 Reseteando toda la flota a estado original (Clean Slate)..."
    echo ""

    for node in "${NODES[@]}"; do
        ip="${FLEET_IPS[$node]}"
        extra="${FLEET_EXTRA[$node]}"

        echo "==> 🧹 Limpiando $node ($ip)..."

        sudo virsh destroy "$node" 2>/dev/null || true
        sudo virsh undefine "$node" 2>/dev/null || true

        rm -rf "$HOME/vm-images/$node"
        echo "    [✓] Archivos locales y dominio eliminados."

        bash "$SCRIPT_DIR/make-node.sh" "$node" "$ip" "$extra"
        echo ""
    done

    echo "==> ✅ Toda la flota está 100% limpia y arrancando."
    echo "==> ⏳ Esperando ${WAIT_SECONDS}s a que cloud-init aplique la config..."
    sleep "$WAIT_SECONDS"
}


do_shutdown() {
    for node in "${NODES[@]}"; do
        sudo virsh shutdown "$node" 2>/dev/null || true
    done
    echo "==> ⏳ Esperando ${WAIT_SECONDS}s para apagado graceful..."
    sleep "$WAIT_SECONDS"
}

do_start() {
    for node in "${NODES[@]}"; do
        sudo virsh start "$node" 2>/dev/null || true
    done
    echo "==> ⏳ Esperando ${WAIT_SECONDS}s a que arranquen..."
    sleep "$WAIT_SECONDS"
}

do_destroy_domains() {
    for node in "${NODES[@]}"; do
        sudo virsh destroy "$node" 2>/dev/null || true
        sudo virsh undefine "$node" 2>/dev/null || true
    done
    echo "==> Dominios eliminados (overlays en disco NO se tocaron)."
}

# --- Menú principal ----------------------------------------------------------

while true; do
    clear
    echo "==> Estado actual de la flota:"
    sudo virsh list --all
    echo ""

    read -r defined running shutoff <<< "$(get_fleet_state)"

    if [[ "$defined" -eq 0 ]]; then
        echo "No hay máquinas desplegadas."
        echo "1) Deploy máquinas (launch-pilot-fleet.sh)"
        echo "2) Refrescar menú"
        echo "3) Salir"
        read -rp "Opción: " opt
        case "$opt" in
            1) do_deploy ;;
            2) continue ;;
            3) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

    elif [[ "$running" -eq "$defined" ]]; then
        echo "Todas las máquinas están corriendo."
        echo "1) Resetear (destruir todo y recrear desde cero)"
        echo "2) Apagar VMs (shutdown graceful, sin destruir)"
        echo "3) Destruir dominios (conserva overlays en disco)"
        echo "4) Refrescar menú"
        echo "5) Salir"
        read -rp "Opción: " opt
        case "$opt" in
            1) do_reset ;;
            2) do_shutdown ;;
            3) do_destroy_domains ;;
            4) continue ;;
            5) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

    elif [[ "$shutoff" -eq "$defined" ]]; then
        echo "Todas las máquinas están apagadas."
        echo "1) Iniciar VMs (arrancar sin recrear)"
        echo "2) Resetear (destruir todo y recrear desde cero)"
        echo "3) Destruir dominios (conserva overlays en disco)"
        echo "4) Refrescar menú"
        echo "5) Salir"
        read -rp "Opción: " opt
        case "$opt" in
            1) do_start ;;
            2) do_reset ;;
            3) do_destroy_domains ;;
            4) continue ;;
            5) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

    else
        echo "Estado mixto: $running corriendo, $shutoff apagadas, de $defined definidas."
        echo "1) Resetear (normaliza todo desde cero)"
        echo "2) Apagar las que corren"
        echo "3) Destruir dominios (todas)"
        echo "4) Refrescar menú"
        echo "5) Salir"
        read -rp "Opción: " opt
        case "$opt" in
            1) do_reset ;;
            2) do_shutdown ;;
            3) do_destroy_domains ;;
            4) continue ;;
            5) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    fi
done
