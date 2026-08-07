#!/bin/bash
# lxd-fleet-menu.sh - Menú dinámico que detecta CUALQUIER contenedor

get_states() {
    # Cuenta TODOS los contenedores, sin filtro de nombre
    TOTAL=$(lxc list -c n --format csv 2>/dev/null | grep -v '^$' | wc -l)
    RUNNING=$(lxc list -c ns --format csv 2>/dev/null | grep "RUNNING" | wc -l)
    STOPPED=$(lxc list -c ns --format csv 2>/dev/null | grep "STOPPED" | wc -l)
}

destroy_all() {
    echo "⚠️  Esto borrará TODOS los contenedores existentes:"
    lxc list -c n --format csv
    echo ""
    read -p "¿Estás 100% seguro? (escribe 'SI' para confirmar): " confirm
    if [[ "$confirm" == "SI" ]]; then
        echo "💥 Destruyendo todo..."
        lxc list -c n --format csv | grep -v '^$' | xargs -r lxc delete --force
        echo "✅ Todo eliminado."
        sleep 2
    else
        echo "Operación cancelada."
        sleep 1
    fi
}

load_playbook_menu() {
    clear
    echo "=== 🎭 CARGAR PLAYBOOK (ANSIBLE) ==="
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
    
    # Muestra TODOS los contenedores, sin filtro
    lxc list 
    echo "-----------------------------------------"

    if [ "$TOTAL" -eq 0 ]; then
        echo "1) 🚀 Crear flota (server01 a server10)"
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
        echo "1) 🎭 Cargar Playbook (Ansible)"
        echo "2) 🔄 Reiniciar todos (Restart)"
        echo "3) 🛑 Parar todos (Stop)"
        echo "4) 🗑️  Destruir todo"
        echo "5) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) load_playbook_menu ;;
            2) lxc restart --all; sleep 3 ;;
            3) lxc stop --all; sleep 2 ;;
            4) destroy_all ;;
            5) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    fi
done
