#!/bin/bash
# lxd-fleet-menu.sh - Menú con soporte de snapshot

SNAPSHOT_NAME="golden-base"

get_states() {
    TOTAL=$(lxc list -c n --format csv 2>/dev/null | grep "server" | wc -l)
    RUNNING=$(lxc list -c ns --format csv 2>/dev/null | grep "server" | grep -c "RUNNING")
    STOPPED=$(lxc list -c ns --format csv 2>/dev/null | grep "server" | grep -c "STOPPED")
}

destroy_all() {
    echo "⚠️  Esto borrará TODOS los servidores y snapshots:"
    lxc list -c n | grep "server"
    echo ""
    read -p "¿Estás 100% seguro? (escribe 'SI' para confirmar): " confirm
    if [[ "$confirm" == "SI" ]]; then
        echo "💥 Destruyendo todo..."
        lxc list -c n --format csv | grep "server" | xargs -r lxc delete --force
        echo "✅ Todo eliminado."
        sleep 2
    else
        echo "Operación cancelada."
        sleep 1
    fi
}

restore_snapshot() {
    echo "🔄 Restaurando snapshot '$SNAPSHOT_NAME' en todos los servidores..."
    echo "   (Esto reiniciará los servidores al estado Golden Base)"
    for i in $(seq -w 1 10); do
        NAME="server${i}"
        if lxc info $NAME &>/dev/null; then
            lxc stop $NAME --force 2>/dev/null
            lxc restore $NAME $SNAPSHOT_NAME 2>/dev/null && echo "   ✅ $NAME restaurado" || echo "   ❌ $NAME no tiene snapshot"
        fi
    done
    echo "✅ Snapshots restaurados. Encendiendo servidores..."
    lxc start --all 2>/dev/null
    sleep 3
}

load_playbook_menu() {
    clear
    echo "=== 🎭 CARGAR PLAYBOOK (ANSIBLE) ==="
    files=($(ls playbook_*.yml roles/playbook_*.yml 2>/dev/null))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "⚠️  No hay playbooks disponibles."
        read -p "Presiona Enter para volver..."
        return
    fi

    for i in "${!files[@]}"; do
        echo "  $((i+1))) $(basename ${files[$i]})"
    done
    echo "  b) Volver al menú principal"
    
    read -p "Opción: " role_opt
    if [[ "$role_opt" =~ ^[0-9]+$ ]] && [ "$role_opt" -ge 1 ] && [ "$role_opt" -le "${#files[@]}" ]; then
        SELECTED_FILE="${files[$((role_opt-1))]}"
        echo "🚀 Ejecutando: ansible-playbook -i inventory.ini $SELECTED_FILE"
        echo "---------------------------------------------------------"
        ansible-playbook -i inventory.ini "$SELECTED_FILE"
        echo "---------------------------------------------------------"
        read -p "Presiona Enter para continuar..."
    fi
}

while true; do
    clear
    get_states
    
    echo "========================================="
    echo "       🖥️  LXD FLEET MANAGER  🖥️"
    echo "========================================="
    echo "Estado: Total=$TOTAL | Running=$RUNNING | Stopped=$STOPPED"
    echo "-----------------------------------------"
    lxc list 
    echo "-----------------------------------------"

    if [ "$TOTAL" -eq 0 ]; then
        echo "1) 🚀 Crear flota con Golden Base + Snapshot"
        echo "2) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) ./make-lxd-fleet.sh; read -p "Presiona Enter..." ;;
            2) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

    elif [ "$RUNNING" -eq 0 ] && [ "$STOPPED" -gt 0 ]; then
        echo "1) ⏳ Encender todos (Start)"
        echo "2) 🔄 Restaurar snapshot y encender"
        echo "3) 🗑️  Destruir todo"
        echo "4) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) lxc start --all; sleep 3 ;;
            2) restore_snapshot ;;
            3) destroy_all ;;
            4) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

    elif [ "$RUNNING" -gt 0 ]; then
        echo "1) 🎭 Cargar Playbook (Ansible)"
        echo "2) 🔄 Reiniciar todos (Restart)"
        echo "3) 🛑 Parar todos (Stop - mantiene configuración)"
        echo "4) 🔄 Restaurar snapshot (vuelve a Golden Base)"
        echo "5) 🗑️  Destruir todo"
        echo "6) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) load_playbook_menu ;;
            2) lxc restart --all; sleep 3 ;;
            3) echo "🛑 Parando servidores..."; lxc stop --all; sleep 2 ;;
            4) restore_snapshot ;;
            5) destroy_all ;;
            6) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    fi
done
