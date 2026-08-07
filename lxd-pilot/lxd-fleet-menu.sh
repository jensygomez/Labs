#!/bin/bash
# lxd-fleet-menu.sh - Menú con pasos secuenciales

SNAPSHOT_NAME="golden-base"
NETWORK_CONFIGURED=false
PACKAGES_INSTALLED=false
SNAPSHOT_CREATED=false

# Función para verificar estado de configuración
check_status() {
    # Verificar si tiene IP fija (server01 debería tener 10.45.223.101)
    IP_SERVER01=$(lxc exec server01 -- ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)
    if [[ "$IP_SERVER01" == "10.45.223.101" ]]; then
        NETWORK_CONFIGURED=true
    else
        NETWORK_CONFIGURED=false
    fi
    
    # Verificar si tiene paquetes instalados
    if lxc exec server01 -- rpm -q openssh-server &>/dev/null 2>&1; then
        PACKAGES_INSTALLED=true
    else
        PACKAGES_INSTALLED=false
    fi
    
    # Verificar si tiene snapshot
    if lxc info server01 2>/dev/null | grep -q "$SNAPSHOT_NAME"; then
        SNAPSHOT_CREATED=true
    else
        SNAPSHOT_CREATED=false
    fi
}

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
            lxc start $NAME 2>/dev/null
        fi
    done
    echo "✅ Snapshots restaurados."
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
    check_status
    
    echo "========================================="
    echo "       🖥️  LXD FLEET MANAGER  🖥️"
    echo "========================================="
    echo "Estado: Total=$TOTAL | Running=$RUNNING | Stopped=$STOPPED"
    echo "-----------------------------------------"
    lxc list 
    echo "-----------------------------------------"
    
    # Mostrar estado de configuración
    echo "📋 Estado de configuración:"
    if [ "$NETWORK_CONFIGURED" = true ]; then
        echo "   ✅ Red configurada (IPs fijas)"
    else
        echo "   ⬜ Red SIN configurar"
    fi
    if [ "$PACKAGES_INSTALLED" = true ]; then
        echo "   ✅ Paquetes instalados"
    else
        echo "   ⬜ Paquetes SIN instalar"
    fi
    if [ "$SNAPSHOT_CREATED" = true ]; then
        echo "   ✅ Snapshot creado"
    else
        echo "   ⬜ Snapshot SIN crear"
    fi
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

    elif [ "$RUNNING" -eq 0 ] && [ "$STOPPED" -gt 0 ]; then
        echo "1) ⏳ Encender todos (Start)"
        echo "2) 🗑️  Destruir todo"
        echo "3) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) lxc start --all; sleep 3 ;;
            2) destroy_all ;;
            3) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

    elif [ "$RUNNING" -gt 0 ]; then
        # Menú dinámico según estado de configuración
        echo "1) 🎭 Cargar Playbook (Ansible)"
        echo "2) 🔄 Reiniciar todos (Restart)"
        echo "3) 🛑 Parar todos (Stop)"
        
        if [ "$NETWORK_CONFIGURED" = false ]; then
            echo "4) 🌐 Configurar IPs fijas (Paso 2)"
        elif [ "$PACKAGES_INSTALLED" = false ]; then
            echo "4) 📦 Instalar paquetes base (Paso 3)"
        elif [ "$SNAPSHOT_CREATED" = false ]; then
            echo "4) 📸 Crear Golden Base Snapshot (Paso 4)"
        else
            echo "4) 🔄 Restaurar snapshot (vuelve a Golden Base)"
        fi
        
        echo "5) 🗑️  Destruir todo"
        echo "6) Refrescar"
        echo "q) Salir"
        
        read -p "Opción: " opt
        case $opt in
            1) load_playbook_menu ;;
            2) lxc restart --all; sleep 3 ;;
            3) echo "🛑 Parando servidores..."; lxc stop --all; sleep 2 ;;
            4) 
                if [ "$NETWORK_CONFIGURED" = false ]; then
                    ./setup-network.sh
                    read -p "Presiona Enter para continuar..."
                elif [ "$PACKAGES_INSTALLED" = false ]; then
                    ./install-packages.sh
                    read -p "Presiona Enter para continuar..."
                elif [ "$SNAPSHOT_CREATED" = false ]; then
                    ./create-snapshot.sh
                    read -p "Presiona Enter para continuar..."
                else
                    restore_snapshot
                    read -p "Presiona Enter para continuar..."
                fi
                ;;
            5) destroy_all ;;
            6) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    fi
done

