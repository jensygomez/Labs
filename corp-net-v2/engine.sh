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

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
        echo -e "${BLUE}📥 Preparando dependencias locales (yq)...${NC}"
        mkdir -p "$BIN_DIR"
        if curl -sL "$YQ_URL" -o "$YQ"; then
            chmod +x "$YQ"
            echo -e "${GREEN}✅ yq listo.${NC}"
        else
            echo -e "${RED}❌ Error descargando yq. Verifica internet.${NC}"
            exit 1
        fi
    fi

    # B. Instalamos paquetes del sistema
    echo -e "${BLUE}📥 Verificando paquetes del sistema...${NC}"
    
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
        echo -e "${YELLOW}📦 Instalando: ${missing_packages[*]}${NC}"
        
        if dnf install -y "${missing_packages[@]}" &> /dev/null; then
            echo -e "${GREEN}✅ Paquetes de sistema instalados.${NC}"
        else
            echo -e "${RED}❌ Error instalando algunos paquetes. ¿Eres root?${NC}"
            echo -e "${YELLOW}   Paquetes faltantes: ${missing_packages[*]}${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Todos los paquetes ya están instalados.${NC}"
    fi
}

# 3. --- VERIFICACIÓN DE PRIVILEGIOS ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Error: Debes ejecutar como root (sudo).${NC}" 
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
    echo -e "${RED}❌ Error: No se encontraron las librerías en $BASE_DIR/lib/${NC}"
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

# 6. --- NUEVA FUNCIÓN: CONFIGURAR VM BASE CON ANSIBLE ---
setup_base_vm() {
    clear
    echo "=========================================="
    echo "   CONFIGURAR VM BASE (ANSIBLE)           "
    echo "=========================================="
    
    # Verificar si el directorio ansible existe
    ANSIBLE_DIR="$BASE_DIR/ansible-corpnet-v2"
    if [ ! -d "$ANSIBLE_DIR" ]; then
        echo -e "${RED}❌ No se encuentra el directorio de Ansible${NC}"
        echo -e "${YELLOW}   Esperado en: $ANSIBLE_DIR${NC}"
        echo ""
        echo -e "${BLUE}📁 Estructura esperada:${NC}"
        echo "   corpnet-v2/"
        echo "   ├── ansible-corpnet-v2/"
        echo "   │   ├── setup-vm.sh"
        echo "   │   ├── playbook-base-vm.yml"
        echo "   │   └── ..."
        echo "   └── engine.sh"
        echo ""
        read -p "Presiona Enter para continuar..."
        return 1
    fi
    
    # Verificar si Ansible está instalado en el host
    if ! command -v ansible &> /dev/null; then
        echo -e "${RED}❌ Ansible no está instalado en este sistema${NC}"
        echo ""
        echo -e "${YELLOW}Para instalar Ansible:${NC}"
        echo "  Ubuntu/Debian: sudo apt install ansible sshpass"
        echo "  Fedora/RHEL:   sudo dnf install ansible sshpass"
        echo "  macOS:         brew install ansible"
        echo ""
        read -p "¿Deseas intentar instalar Ansible? (s/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y ansible sshpass
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y ansible sshpass
            elif command -v brew &> /dev/null; then
                brew install ansible
            else
                echo -e "${YELLOW}⚠️ No se pudo detectar el gestor de paquetes${NC}"
                echo "Instala Ansible manualmente y vuelve a intentar"
            fi
        else
            return 1
        fi
    fi
    
    # Cambiar al directorio de Ansible
    cd "$ANSIBLE_DIR" || return 1
    
    # Verificar si el script setup-vm.sh existe y es ejecutable
    if [ ! -f "setup-vm.sh" ]; then
        echo -e "${RED}❌ No se encuentra setup-vm.sh en $ANSIBLE_DIR${NC}"
        read -p "Presiona Enter para continuar..."
        return 1
    fi
    
    if [ ! -x "setup-vm.sh" ]; then
        chmod +x setup-vm.sh
    fi
    
    echo -e "${GREEN}🔧 Preparándose para configurar una VM Rocky 9.7...${NC}"
    echo ""
    echo -e "${BLUE}📋 Requisitos de la VM:${NC}"
    echo "   • Rocky Linux 9.7 instalado"
    echo "   • Conexión a Internet"
    echo "   • Usuario root con contraseña conocida"
    echo "   • SSH habilitado"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE: Este script se ejecuta desde TU HOST${NC}"
    echo "   y configurará la VM de forma remota."
    echo ""
    
    read -p "¿Continuar con la configuración? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        return 0
    fi
    
    # Ejecutar el script de configuración
    echo -e "${GREEN}🚀 Iniciando configuración...${NC}"
    echo ""
    
    # Ejecutar el script - se puede pasar la IP como argumento
    if [ -f "setup-vm.sh" ]; then
        ./setup-vm.sh
    else
        echo -e "${RED}❌ Error: No se pudo ejecutar setup-vm.sh${NC}"
    fi
    
    echo ""
    read -p "Presiona Enter para volver al menú principal..."
}

# 7. --- MENÚ INTERACTIVO ---
show_menu() {
    clear
    echo -e "${BLUE}==========================================${NC}"
    echo -e "       ${GREEN}CORPNET-V2 - CONTROL PANEL${NC}         "
    echo -e "${BLUE}==========================================${NC}"
    echo "0) 🔧 Configurar VM Base (Ansible)"
    echo "1) 🚀 Desplegar Infraestructura (RH + TI)"
    echo "2) 🧹 Limpiar Laboratorio (Destroy)"
    echo "3) 🔍 Status de la Red (Namespaces/IPs)"
    echo "4) 🧪 Panel de Pruebas y Diagnóstico (YAML)"
    echo "9) 🚪 Salir"
    echo -e "${BLUE}------------------------------------------${NC}"
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
                echo -e "${RED}❌ Error: No se encuentra el motor de pruebas${NC}"
                sleep 2
            fi
            ;;
        9) 
            echo -e "${GREEN}¡Hasta pronto!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Opción inválida.${NC}"
            sleep 1
            ;;
    esac
}

# 8. --- BUCLE PRINCIPAL ---
while true; do
    show_menu
done