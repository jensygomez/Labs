#!/bin/bash
# lxd-fleet-menu.sh

get_states() {
    TOTAL=$(lxc list -c n --format csv 2>/dev/null | grep -c "server")
    RUNNING=$(lxc list -c ns --format csv 2>/dev/null | grep "server" | grep -c "RUNNING")
    STOPPED=$(lxc list -c ns --format csv 2>/dev/null | grep "server" | grep -c "STOPPED")
}

destroy_fleet() {
    echo "🗑️  Destruyendo flota 'serverXX'..."
    for i in {1..10}; do
        NAME=$(printf "server%02d" $i)
        lxc delete $NAME --force 2>/dev/null
    done
    echo "✅ Flota eliminada."
    sleep 2
}

load_playbook_menu() {
    clear
    echo "=== 🎭 CARGAR PLAYBOOK (ANSIBLE) ==="
    # Busca en la raíz y en la carpeta roles/
    files=($(ls playbook_*.yml roles/playbook_*.yml 2>/dev/null))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "⚠️  No hay playbooks (playbook_*.yml) disponibles."
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
        ansible-playbook -i inventory.ini "$SELECTED_FILE"
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
        echo "1) Iniciar VMs (Crear flota base server01-10)"
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
        echo "1) Encender todos (Start)"
        echo "2) Destruir flota"
        echo "3) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) lxc start --all; sleep 3 ;;
            2) destroy_fleet ;;
            3) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    elif [ "$RUNNING" -gt 0 ]; then
        echo "1) Cargar Playbook (Ansible)"
        echo "2) Reiniciar todos (Restart)"
        echo "3) Parar todos (Stop)"
        echo "4) Destruir flota"
        echo "5) Refrescar"
        echo "0) 💥 LIMPIEZA NUCLEAR (Borrar TODO lxc)"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) load_playbook_menu ;;
            2) lxc restart --all; sleep 3 ;;
            3) lxc stop --all; sleep 2 ;;
            4) destroy_fleet ;;
            5) continue ;;
            0) 
                read -p "¿Estás 100% seguro? (escribe 'SI'): " confirm
                [[ "$confirm" == "SI" ]] && lxc list -c n --format csv | xargs -r lxc delete --force
                ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    fi
done
