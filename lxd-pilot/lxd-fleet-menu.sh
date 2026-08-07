#!/bin/bash
# lxd-fleet-menu.sh - Menú con flujo de dos pasos

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
    files=($(ls playbook_*.yml 2>/dev/null))
    
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
        echo "1) 🚀 Paso 1: Crear flota (con DHCP)"
        echo "2) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) ./make-lxd-fleet.sh; read -p "Presiona Enter..." ;;
            2) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

    elif [ "$RUNNING" -gt 0 ]; then
        # Verificar si tienen snapshot (si no tienen, necesitan setup)
        HAS_SNAPSHOT=$(lxc info server01 2>/dev/null | grep -c "golden-base")
        
        if [ "$HAS_SNAPSHOT" -eq 0 ]; then
            echo "1) ⚙️  Paso 2: Configurar Golden Base + Snapshot"
        fi
        
        echo "2) 🎭 Cargar Playbook (Ansible)"
        echo "3) 🔄 Reiniciar todos (Restart)"
        echo "4) 🛑 Parar todos (Stop)"
        echo "5) 🔄 Restaurar snapshot (vuelve a Golden Base)"
        echo "6) 🗑️  Destruir todo"
        echo "7) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) 
                if [ "$HAS_SNAPSHOT" -eq 0 ]; then
                    ./setup-fleet.sh
                else
                    load_playbook_menu
                fi
                ;;
            2) 
                if [ "$HAS_SNAPSHOT" -eq 0 ]; then
                    load_playbook_menu
                else
                    lxc restart --all; sleep 3
                fi
                ;;
            3) echo "🛑 Parando servidores..."; lxc stop --all; sleep 2 ;;
            4) restore_snapshot ;;
            5) destroy_all ;;
            6) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    fi
done
