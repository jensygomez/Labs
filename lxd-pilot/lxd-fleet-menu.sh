#!/bin/bash
# lxd-fleet-menu.sh

ROLES_DIR="./roles"

# Función para contar estados
get_states() {
    TOTAL=$(lxc list -c n --format csv 2>/dev/null | wc -l)
    RUNNING=$(lxc list -c ns --format csv 2>/dev/null | grep RUNNING | wc -l)
    STOPPED=$(lxc list -c ns --format csv 2>/dev/null | grep STOPPED | wc -l)
}

# Función para limpiar y destruir
destroy_fleet() {
    echo "🗑️  Destruyendo flota completa..."
    for i in {1..10}; do
        NAME=$(printf "server%02d" $i)
        lxc delete $NAME --force 2>/dev/null
    done
    echo "✅ Flota eliminada sin dejar rastro."
    sleep 2
}

# Submenú para cargar roles (Ansible)
load_role_menu() {
    if [ ! -d "$ROLES_DIR" ] || [ -z "$(ls -A $ROLES_DIR 2>/dev/null)" ]; then
        echo "⚠️  No hay archivos en la carpeta '$ROLES_DIR'."
        echo "   Crea archivos .yml ahí para que Ansible los lea."
        read -p "Presiona Enter para volver..."
        return
    fi

    clear
    echo "=== 🎭 CARGAR ROL (ANSIBLE) ==="
    echo "Selecciona el rol a aplicar a la flota:"
    
    # Leer archivos dinámicamente
    files=($(ls $ROLES_DIR/*.yml $ROLES_DIR/*.yaml 2>/dev/null))
    for i in "${!files[@]}"; do
        echo "  $((i+1))) $(basename ${files[$i]})"
    done
    echo "  b) Volver al menú principal"
    
    read -p "Opción: " role_opt
    if [[ "$role_opt" =~ ^[0-9]+$ ]] && [ "$role_opt" -ge 1 ] && [ "$role_opt" -le "${#files[@]}" ]; then
        SELECTED_FILE="${files[$((role_opt-1))]}"
        echo "🚀 Ejecutando Ansible Playbook: $SELECTED_FILE"
        # Asumiendo que tienes un inventario o usas el plugin de lxd. 
        # Aquí lanzarías tu comando ansible real. Ejemplo:
        # ansible-playbook -i lxd_inventory.ini $SELECTED_FILE
        echo "(Simulación) ansible-playbook $SELECTED_FILE"
        read -p "Presiona Enter para continuar..."
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

    if [ "$TOTAL" -eq 0 ]; then
        # ESCENARIO A: No hay máquinas
        echo "1) Iniciar VMs (Crear flota base)"
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
        # ESCENARIO B: Hay máquinas pero están paradas
        echo "1) Reiniciar en su estado actual (Start)"
        echo "2) Destruirlas (Sin dejar rastro)"
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
        # ESCENARIO C: Hay máquinas corriendo
        echo "1) Cargar Rol (Ansible Playbooks)"
        echo "2) Reiniciar su estado actual (Restart)"
        echo "3) Parar/Stop (Mantiene configuración)"
        echo "4) Destruirlas (Sin dejar rastro)"
        echo "5) Refrescar"
        echo "q) Salir"
        read -p "Opción: " opt
        case $opt in
            1) load_role_menu ;;
            2) echo "🔄 Reiniciando servidores..."; lxc restart --all; sleep 3 ;;
            3) echo "🛑 Apagando servidores..."; lxc stop --all; sleep 2 ;;
            4) 
                read -p "¿Estás 100% seguro? (s/N): " confirm
                if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then destroy_fleet; fi 
                ;;
            5) continue ;;
            q|Q) exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    fi
done
