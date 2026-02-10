#!/bin/bash
# engine.sh - Orquestador CorpNet-v2
# DEBUG=1 sudo bash corp-net-v2/engine.sh 

#               ARQUITECTURA EMPRESARIAL CORPNET-V2
#              (Segmentación por Switches Departamentales)
#
#                            ┌─────────────────┐
#                            │     CORE-GW     │
#                            │  (Router / FW)  │
#                            └────────┬────────┘
#                                     │
#           ┌─────────────────────────┴────────────────────────┐
#           │                                                 │
#    [VLAN 10 - MGMT]                                  [VLAN 20 - USERS]
#     Subred 10.0.1.0                                   Subred 10.0.2.0
#           │                                                 │
#  ┌────────┴────────┐               ┌────────────────────────┴────────────────────────┐
#  │  SWITCH SERVER  │               │                 SWITCH CORE / AGG               │
#  └────────┬────────┘               └───────────┬───────────────────────────┬─────────┘
#           │                                    │                           │
#  ┌────────┴────────┐              ┌────────────┴────┐             ┌────────┴────────┐
#  │     SVC-WEB     │              │   SWITCH RH     │             │    SWITCH IT    │
#  │ (Portal Corp)   │              │ (Acceso Empleados)            │ (Acceso Técnico)│
#  └─────────────────┘              └────────┬────────┘             └────────┬────────┘
#                                            │                               │
#                            ┌───────────────┴───────┐           ┌───────────┴───────────┐
#                            │  (Capacidad: n users) │           │ (Devs, Infra, NOC)    │
#                            │   - USR-RH-1          │           │  - USR-IT-ADMIN       │
#                            │   - USR-RH-2          │           │  - USR-IT-DEV         │
#                            │   - ...               │           │  - USR-IT-NOC         │
#                            └───────────────────────┘           └───────────────────────┘


# 1. --- DIRECTORIO BASE Y VARIABLES ---
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$BASE_DIR/.bin"
YQ="$BIN_DIR/yq"
YQ_VERSION="v4.35.2"
YQ_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"

# Exportamos BASE_DIR para que las librerías lo vean
export BASE_DIR
export YQ

# 2. --- AUTO-INSTALACIÓN DE DEPENDENCIAS ---
install_dependencies() {
    # A. Instalamos yq (Binario local para el script)
    if [ ! -f "$YQ" ]; then
        echo "📥 Preparando dependencias locales (yq)..."
        mkdir -p "$BIN_DIR"
        if curl -sL "$YQ_URL" -o "$YQ"; then
            chmod +x "$YQ"
            echo "✅ yq listo."
        else
            echo "❌ Error descargando yq. Verifica internet."
            exit 1
        fi
    fi

    # B. Instalamos paquetes del sistema
    echo "📥 Verificando paquetes del sistema..."
    
    # Lista completa de paquetes necesarios
    local required_packages=(
        "nginx"          # Servidor web para SVC-WEB
        "lynx"           # Navegador de texto para tests
        "curl"           # Tests HTTP/HTTPS
        "nmap-ncat"      # Proporciona 'nc' (netcat) para tests de puertos
        "bind-utils"     # Proporciona 'nslookup', 'dig' para tests DNS
        "iputils"        # Proporciona 'ping' (usualmente ya instalado)
        "iproute"        # Proporciona 'ip' command (usualmente ya instalado)
        "iptables"       # Firewall (usualmente ya instalado)
        "bridge-utils"   # Proporciona 'brctl' para gestión de bridges
    )
    
    local missing_packages=()
    
    # Verificar qué paquetes faltan
    for pkg in "${required_packages[@]}"; do
        if ! rpm -q "$pkg" &> /dev/null; then
            missing_packages+=("$pkg")
        fi
    done
    
    # Instalar solo los que faltan
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "📦 Instalando: ${missing_packages[*]}"
        
        if dnf install -y "${missing_packages[@]}" &> /dev/null; then
            echo "✅ Paquetes de sistema instalados."
        else
            echo "❌ Error instalando algunos paquetes. ¿Eres root?"
            echo "   Paquetes faltantes: ${missing_packages[*]}"
            exit 1
        fi
    else
        echo "✅ Todos los paquetes ya están instalados."
    fi
}

# 3. --- VERIFICACIÓN DE PRIVILEGIOS ---
if [[ $EUID -ne 0 ]]; then
   echo "❌ Error: Debes ejecutar como root (sudo)." 
   exit 1
fi

install_dependencies

# 4. --- IMPORTAR LIBRERÍAS ---
if [ -f "$BASE_DIR/lib/core.sh" ] && [ -f "$BASE_DIR/lib/network.sh" ]; then
    source "$BASE_DIR/lib/core.sh"
    source "$BASE_DIR/lib/network.sh"
    source "$BASE_DIR/lib/firewall.sh" 
    source "$BASE_DIR/lib/services/web/setup.sh"
else
    echo "❌ Error: No se encontraron las librerías en $BASE_DIR/lib/"
    exit 1
fi

# 5. --- FUNCIONES DE ACCIÓN ---
deploy_lab() {
    clear
    echo "🚀 Iniciando despliegue de CorpNet-v2..."
    create_namespaces   
    setup_network      
    apply_firewall  
    # Lanzar el servicio web
    setup_web_service
    echo -e "\n✨ Red establecida y ruteo configurado."
    echo "✨ Laboratorio desplegado correctamente."
    read -p "Presiona Enter para volver..."
}

destroy_lab() {
    clear
    echo "🔥 Destruyendo laboratorio..."
    cleanup_namespaces  
    echo "🗑️  Sistema limpio."
    read -p "Presiona Enter para volver..."
}
show_status() {
    clear
    echo -e "\e[1;34m===============================================================\e[0m"
    echo -e "🔍 \e[1;37m        MAPA DINÁMICO DE INFRAESTRUCTURA (V2.0)\e[0m"
    echo -e "\e[1;34m===============================================================\e[0m"

    local namespaces=$(ip netns list | cut -d' ' -f1)
    
    if [ -z "$namespaces" ]; then
        echo -e "\n  \e[1;31m⚠️  No hay infraestructura desplegada.\e[0m"
    else
        # --- SECCIÓN 1: MAPA DE SWITCHES (BRIDGES) ---
        echo -e "\n\e[1;35m🌐 TOPOLOGÍA DE SWITCHES (BRIDGES):\e[0m"
        local routers=$(ip netns exec "$namespaces" 2>/dev/null | xargs -n1 | grep -v "not found" | xargs ip netns list | cut -d' ' -f1) # Filtro rápido
        
        # Iteramos sobre los routers para ver sus puentes
        for ns in $namespaces; do
            local bridges=$(ip netns exec "$ns" ip link show type bridge | grep -v "lo" | awk -F': ' '{print $2}')
            for br in $bridges; do
                # Contamos cuántos cables (veth) hay pegados a este bridge
                local interfaces=$(ip netns exec "$ns" brctl show "$br" | awk 'NR>1 {print $4}' | wc -l)
                echo -e "   \e[1;36m[Switch: $br]\e[0m en \e[1;32m$ns\e[0m | Puertos activos: \e[1;37m$interfaces\e[0m"
            done
        done

        # --- SECCIÓN 2: DETALLE DE NODOS ---
        for ns in $namespaces; do
            echo -e "\n\e[1;32m📦 Nodo: $ns\e[0m"
            
            # 1. Información de Red e Identidad
            local ips=$(ip netns exec "$ns" ip -4 addr show scope global | awk '{print $2}' | xargs)
            local gw=$(ip netns exec "$ns" ip route show default | awk '{print $3}')
            # Detectamos a qué bridge está conectado el nodo (mirando eth0)
            echo -e "   \e[1;37m🌐 Red:\e[0m  IP: [ ${ips:-N/A} ]  |  Gateway: [ ${gw:-None} ]"

            # 2. Matriz de Seguridad (Zero-Trust)
            echo -e "   \e[1;37m🛡️  Seguridad (IPTables):\e[0m"
            
            # Verificamos si tiene el forwarding activo (es un router)
            local forwarding=$(ip netns exec "$ns" sysctl -n net.ipv4.ip_forward)
            if [ "$forwarding" == "1" ]; then
                echo -e "      \e[0;33m⚡ MODO ROUTER: Reenvío de tráfico habilitado\e[0m"
            fi

            # Extraer reglas ACCEPT de la cadena INPUT
            local rules=$(ip netns exec "$ns" iptables -S INPUT | grep "\-A" | grep "ACCEPT")
            
            if [ -z "$rules" ]; then
                echo -e "      \e[0;90m🔒 Locked: Sin acceso inbound permitido\e[0m"
            else
                echo "$rules" | while read -r line; do
                    local src=$(echo "$line" | grep -oP '(?<=-s )[0-9./]+' || echo "Anywhere")
                    local port=$(echo "$line" | grep -oP '(?<=--dport )[0-9]+' || echo "Any")
                    local proto=$(echo "$line" | grep -oP '(?<=-p )[a-z]+' || echo "all")
                    echo -e "      \e[0;36m-> Permite $proto/$port desde $src\e[0m"
                done
            fi
        done
    fi
    echo -e "\n\e[1;34m===============================================================\e[0m"
    read -p "Presiona Enter para volver..."
}
# 6. --- MENÚ INTERACTIVO ---
show_menu() {
    clear
    echo "=========================================="
    echo "       CORPNET-V2 - CONTROL PANEL         "
    echo "=========================================="
    echo "0) 🔧 Configurar VM Base (Ansible)"
    echo "1) 🚀 Desplegar Infraestructura (RH + TI)"
    echo "2) 🧹 Limpiar Laboratorio (Destroy)"
    echo "3) 🔍 Status de la Red (Namespaces/IPs)"
    echo "4) 🧪 Panel de Pruebas y Diagnóstico (YAML)"
    echo "9) 🚪 Salir"
    echo "------------------------------------------"
    read -p "Selecciona una opción: " opt
    
    case $opt in
        0) setup_base_vm ;;
        1) deploy_lab ;;
        2) destroy_lab ;;
        3) show_status ;;
        4) 
            if [ -f "$BASE_DIR/lib/tester.sh" ]; then
                source "$BASE_DIR/lib/tester.sh"
                run_dynamic_tests
            else
                echo "❌ Error: No se encuentra el motor de pruebas"
                sleep 2
            fi
            ;;
        9) exit 0 ;;
        *) echo "❌ Opción inválida."; sleep 1 ;;
    esac
}

setup_base_vm() {
    echo "🔧 Configurando VM Base con Ansible..."
    
    # Solicitar IP de la VM
    read -p "Ingresa la IP de la VM Rocky 9.7: " VM_IP
    
    # Cambiar al directorio de Ansible
    cd "$BASE_DIR/ansible-corpnet-v2" || {
        echo "❌ Directorio ansible-corpnet-v2 no encontrado"
        sleep 2
        return
    }
    
    # Ejecutar script wrapper
    ./setup-vm.sh "$VM_IP"
    
    echo "✅ Configuración completada. Presiona Enter para continuar..."
    read
}
# 7. --- BUCLE PRINCIPAL ---
while true; do
    show_menu
done