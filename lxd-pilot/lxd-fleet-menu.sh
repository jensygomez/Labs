#!/bin/bash
# lxd-fleet-menu.sh

# Función para contar estados
get_states() {
    TOTAL=$(lxc list -c n --format csv 2>/dev/null | wc -l)
    RUNNING=$(lxc list -c ns --format csv 2>/dev/null | grep RUNNING | wc -l)
    STOPPED=$(lxc list -c ns --format csv 2>/dev/null | grep STOPPED | wc -l)
}

# Función para destruir SOLO la flota serverXX
destroy_fleet() {
    echo "🗑️  Destruyendo flota 'serverXX'..."
    for i in {1..10}; do
        NAME=$(printf "server%02d" $i)
        lxc delete $NAME --force 2>/dev/null
    done
    echo "✅ Flota serverXX eliminada."
    sleep 2
}

# Función de LIMPIEZA NUCLEAR (Borra TODO)
nuke_lab() {
    echo "⚠️  ¡ADVERTENCIA! Esto borrará TODOS los contenedores en LXD."
    read -p "¿Estás 100% seguro? (escribe 'SI' para confirmar): " confirm
    if [[ "$confirm" == "SI" ]]; then
        echo "💥 Detonando limpieza nuclear..."
        # Obtiene todos los nombres de contenedores y los borra
        lxc list -c n --format csv | grep -v '^$' | xargs -r lxc delete --force
        echo "✅ Laboratorio completamente limpio."
        sleep 2
    else
        echo "Operación cancelada."
        sleep 1
    fi
}

# Submenú para cargar Playbooks de Ansible
load_playbook_menu() {
    clear
    echo "=== 🎭 CARGAR PLAYBOOK (ANSIBLE) ==="
    echo "Selecciona el playbook a ejecutar sobre la flota:"
    
    files=($(ls playbook_*.yml 2>/dev/null))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "⚠️  No hay playbooks (playbook_*.yml) en el directorio actual."
        read -p "Presiona Enter para volver..."
        return
    fi

    for i in "${!files[@]}"; do
        echo "  $((i+1))) ${files[$i]}"
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
    elif [[ "$role_opt" == "b" || "$role_opt" == "B" ]]; then
        return
    fi
}

# Bucle principal del menú
while true; do
    clear
    get_states
    
    echo "========================================="
    echo "       🖥️  LXD FLEET MANAGER  🖥️"
    echo "========================================="
    echo "Estado: Total=$TOTAL | Running=$RUNNING | Stopped=$STOPPED"
    echo "-----------------------------------------"
    
    # Mostrar tabla de LXC
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
        echo "2) Destruir flota 'serverXX'"
        echo "3) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) echo "⏳ Encendiendo servidores..."; lxc start --all; sleep 3 ;;
            2) destroy_fleet ;;
            3) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

    elif [ "$RUNNING" -gt 0 ]; then
        echo "1) Cargar Playbook (Ansible)"
        echo "2) Reiniciar todos (Restart)"
        echo "3) Parar todos (Stop)"
        echo "4) Destruir flota 'serverXX'"
        echo "5) Refrescar"
        echo "0) 💥 LIMPIEZA NUCLEAR (Borrar TODO)"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) load_playbook_menu ;;
            2) echo "🔄 Reiniciando servidores..."; lxc restart --all; sleep 3 ;;
            3) echo "🛑 Apagando servidores..."; lxc stop --all; sleep 2 ;;
            4) destroy_fleet ;;
            5) continue ;;
            0) nuke_lab ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    fi
done
