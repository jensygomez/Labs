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
# 2. --- VERIFICACIÓN DE YQ (ÚNICA DEPENDENCIA REALMENTE NECESARIA) ---
install_dependencies() {
    # Solo instalamos yq localmente para procesar YAML
    # Los demás paquetes los instala ANSIBLE en la VM
    
    echo -e "${BLUE}📥 Verificando dependencias locales...${NC}"
    
    # A. Instalamos yq (Binario local para el script - necesario para tests YAML)
    if [ ! -f "$YQ" ]; then
        echo -e "${BLUE}📥 Descargando yq para procesamiento YAML...${NC}"
        mkdir -p "$BIN_DIR"
        if curl -sL "$YQ_URL" -o "$YQ"; then
            chmod +x "$YQ"
            echo -e "${GREEN}✅ yq listo.${NC}"
        else
            echo -e "${RED}❌ Error descargando yq. Verifica internet.${NC}"
            echo -e "${YELLOW}   yq es necesario para procesar archivos YAML de tests.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ yq ya está instalado.${NC}"
    fi
    
    # B. Verificar que estamos en el contexto correcto
    # Si se ejecuta desde laptop para opción Ansible, no necesitamos más
    # Si se ejecuta desde VM para laboratorio, mostrar advertencia
    if [[ "$0" == *"engine.sh"* ]] && [ "$1" != "--setup-vm" ]; then
        # Verificar si estamos probablemente en una VM Rocky
        if [ -f /etc/redhat-release ] || [ -f /etc/rocky-release ]; then
            echo -e "${GREEN}✅ Ejecutando en VM Rocky - listo para laboratorio.${NC}"
        else
            echo -e "${YELLOW}⚠️  Ejecutando en sistema no-Rocky.${NC}"
            echo -e "${YELLOW}   Este script está diseñado principalmente para Rocky Linux.${NC}"
            echo -e "${YELLOW}   Para configurar una VM Rocky, usa la opción 0 del menú.${NC}"
            sleep 2
        fi
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
        
        # Detectar distribución del host
        detect_distro() {
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                echo "$ID"
            elif command -v lsb_release &> /dev/null; then
                lsb_release -si | tr '[:upper:]' '[:lower:]'
            else
                echo "unknown"
            fi
        }
        
        local HOST_DISTRO=$(detect_distro)
        
        echo -e "${YELLOW}Para instalar Ansible en $HOST_DISTRO:${NC}"
        case $HOST_DISTRO in
            ubuntu|debian|pop)
                echo "  sudo apt update && sudo apt install -y ansible sshpass"
                INSTALL_CMD="apt"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                echo "  sudo dnf install -y ansible sshpass"
                INSTALL_CMD="dnf"
                ;;
            arch|cachyos|manjaro|endeavouros)
                echo "  sudo pacman -Sy --noconfirm ansible sshpass"
                INSTALL_CMD="pacman"
                ;;
            opensuse*)
                echo "  sudo zypper install -y ansible sshpass"
                INSTALL_CMD="zypper"
                ;;
            macos|darwin)
                echo "  brew install ansible"
                INSTALL_CMD="brew"
                ;;
            *)
                echo "  Consulta: https://docs.ansible.com/ansible/latest/installation_guide/"
                INSTALL_CMD="unknown"
                ;;
        esac
        
        echo ""
        read -p "¿Deseas intentar instalar Ansible? (s/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            case $INSTALL_CMD in
                apt)
                    sudo apt update && sudo apt install -y ansible sshpass python3-pip
                    ;;
                dnf)
                    # Para RHEL/Rocky/CentOS necesitamos EPEL
                    if [[ "$HOST_DISTRO" == "rhel" || "$HOST_DISTRO" == "centos" || "$HOST_DISTRO" == "rocky" ]]; then
                        sudo dnf install -y epel-release
                    fi
                    sudo dnf install -y ansible sshpass python3-pip
                    ;;
                pacman)
                    sudo pacman -Sy --noconfirm ansible sshpass python-pip
                    ;;
                zypper)
                    sudo zypper refresh
                    sudo zypper install -y ansible sshpass python3-pip
                    ;;
                brew)
                    brew install ansible
                    ;;
                *)
                    echo -e "${YELLOW}⚠️ No se pudo detectar el gestor de paquetes${NC}"
                    echo "Instala Ansible manualmente y vuelve a intentar:"
                    echo "  pip3 install ansible"
                    read -p "¿Instalar con pip? (s/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Ss]$ ]]; then
                        pip3 install --user ansible
                        export PATH="$PATH:$HOME/.local/bin"
                    fi
                    ;;
            esac
            
            # Verificar instalación
            if command -v ansible &> /dev/null; then
                echo -e "${GREEN}✅ Ansible instalado correctamente${NC}"
                echo -e "${BLUE}Versión: $(ansible --version | head -1)${NC}"
            else
                echo -e "${RED}❌ Falló la instalación de Ansible${NC}"
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # Verificar si sshpass está instalado (necesario para conexión con password)
    if ! command -v sshpass &> /dev/null; then
        echo -e "${YELLOW}⚠️ sshpass no está instalado${NC}"
        
        # Detectar distribución para instalar sshpass
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian|pop)
                    sudo apt install -y sshpass
                    ;;
                fedora|rhel|centos|rocky)
                    sudo dnf install -y sshpass
                    ;;
                arch|cachyos|manjaro)
                    sudo pacman -Sy --noconfirm sshpass
                    ;;
                opensuse*)
                    sudo zypper install -y sshpass
                    ;;
                *)
                    echo -e "${YELLOW}Instala sshpass manualmente para tu distribución${NC}"
                    ;;
            esac
        fi
    fi
    
    # Cambiar al directorio de Ansible
    cd "$ANSIBLE_DIR" || {
        echo -e "${RED}❌ No se pudo acceder al directorio $ANSIBLE_DIR${NC}"
        read -p "Presiona Enter para continuar..."
        return 1
    }
    
    # Verificar si el script setup-vm.sh existe
    if [ ! -f "setup-vm.sh" ]; then
        echo -e "${RED}❌ No se encuentra setup-vm.sh en $ANSIBLE_DIR${NC}"
        echo -e "${YELLOW}Archivos disponibles:${NC}"
        ls -la
        read -p "Presiona Enter para continuar..."
        return 1
    fi
    
    # Hacer ejecutable si no lo es
    if [ ! -x "setup-vm.sh" ]; then
        chmod +x setup-vm.sh
        echo -e "${GREEN}✅ Permisos de ejecución establecidos para setup-vm.sh${NC}"
    fi
    
    # Verificar si el playbook existe
    if [ ! -f "playbook-base-vm.yml" ]; then
        echo -e "${RED}❌ No se encuentra playbook-base-vm.yml${NC}"
        echo -e "${YELLOW}Asegúrate de que el playbook exista en el directorio${NC}"
        read -p "Presiona Enter para continuar..."
        return 1
    fi
    
    echo -e "${GREEN}🔧 Preparándose para configurar una VM Rocky 9.7...${NC}"
    echo ""
    echo -e "${BLUE}📋 Requisitos de la VM:${NC}"
    echo "   • Rocky Linux 9.7 instalado"
    echo "   • Conexión a Internet"
    echo "   • Usuario root con contraseña conocida"
    echo "   • SSH habilitado (puerto 22)"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE: Este script se ejecuta desde TU HOST${NC}"
    echo "   y configurará la VM de forma remota."
    echo ""
    echo -e "${BLUE}📝 Información del host (desde donde ejecutas):${NC}"
    echo "   Sistema: $(uname -s) $(uname -r)"
    echo "   Distribución: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"' || echo 'Desconocida')"
    echo "   Ansible: $(ansible --version | head -1)"
    echo ""
    
    read -p "¿Continuar con la configuración? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        return 0
    fi
    
    # Ejecutar el script de configuración
    echo -e "${GREEN}🚀 Iniciando configuración...${NC}"
    echo -e "${YELLOW}Nota: Se te pedirá la IP y contraseña de la VM${NC}"
    echo ""
    
    # Verificar si hay argumentos pasados desde línea de comandos
    local VM_IP=""
    local VM_PASS=""
    
    # Verificar si hay parámetros en la ejecución del engine
    if [[ "$*" == *"-i"* ]] || [[ "$*" == *"--ip"* ]]; then
        # Extraer IP de los argumentos
        for i in "$@"; do
            case $i in
                -i=*|--ip=*)
                    VM_IP="${i#*=}"
                    ;;
                -i|--ip)
                    shift
                    VM_IP="$1"
                    ;;
            esac
        done
    fi
    
    # Ejecutar el script
    if [ -n "$VM_IP" ]; then
        echo -e "${BLUE}Usando IP proporcionada: $VM_IP${NC}"
        read -sp "Ingresa la contraseña de root para $VM_IP: " VM_PASS
        echo ""
        ./setup-vm.sh -i "$VM_IP" -p "$VM_PASS"
    else
        # Ejecutar interactivamente
        ./setup-vm.sh
    fi
    
    # Verificar resultado
    local EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        echo ""
        echo -e "${GREEN}==========================================${NC}"
        echo -e "${GREEN}✅ CONFIGURACIÓN COMPLETADA EXITOSAMENTE${NC}"
        echo -e "${GREEN}==========================================${NC}"
        echo ""
        echo -e "${BLUE}🎯 Próximos pasos:${NC}"
        echo "   1. Conéctate a la VM configurada"
        echo "   2. Clona el repositorio corpnet-v2"
        echo "   3. Ejecuta ./engine.sh en la VM"
        echo ""
    else
        echo ""
        echo -e "${RED}==========================================${NC}"
        echo -e "${RED}❌ LA CONFIGURACIÓN FALLÓ (Código: $EXIT_CODE)${NC}"
        echo -e "${RED}==========================================${NC}"
        echo ""
        echo -e "${YELLOW}Posibles soluciones:${NC}"
        echo "   • Verifica que la VM esté encendida"
        echo "   • Asegúrate de que SSH esté habilitado"
        echo "   • Verifica usuario/contraseña de root"
        echo "   • Prueba la conexión manualmente:"
        echo "     ssh root@IP_DE_LA_VM"
        echo ""
    fi
    
    read -p "Presiona Enter para volver al menú principal..."
}
# 6. --- DETECCIÓN DE CONTEXTO SIMPLIFICADA ---
detect_context() {
    # Retorna: "host" si estamos en el laptop, "vm" si estamos en la VM Rocky
    if [ -f /etc/rocky-release ] || [ -f /etc/redhat-release ]; then
        echo "vm"
    else
        echo "host"
    fi
}

# 7. --- MENÚ INTELIGENTE SIMPLIFICADO ---
show_menu() {
    CONTEXT=$(detect_context)
    
    clear
    echo "=========================================="
    echo "       CORPNET-V2 - CONTROL PANEL         "
    echo "=========================================="
    
    # Mostrar solo opción 0 si estamos en el host
    if [ "$CONTEXT" = "host" ]; then
        echo "0) 🔧 Configurar VM Base (Ansible desde Host)"
        echo "   (Esta opción configura una VM Rocky remota)"
        echo ""
        echo "9) 🚪 Salir"
        echo "------------------------------------------"
        read -p "Selecciona una opción [0,9]: " opt
        
        case $opt in
            0) setup_base_vm ;;
            9) 
                echo "¡Hasta pronto!"
                exit 0
                ;;
            *) 
                echo "❌ Opción inválida."
                sleep 1
                ;;
        esac
    else
        # Estamos en la VM - mostrar todas las opciones del laboratorio
        echo "1) 🚀 Desplegar Infraestructura (RH + TI)"
        echo "2) 🧹 Limpiar Laboratorio (Destroy)"
        echo "3) 🔍 Status de la Red (Namespaces/IPs)"
        echo "4) 🧪 Panel de Pruebas y Diagnóstico (YAML)"
        echo ""
        echo "0) ⬅️  (Info: Para configurar VM, ejecuta desde tu laptop)"
        echo "9) 🚪 Salir"
        echo "------------------------------------------"
        read -p "Selecciona una opción [1-4,9]: " opt
        
        case $opt in
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
            0) 
                echo "ℹ️  Para configurar una nueva VM, ejecuta desde tu laptop:"
                echo "   cd ~/Labs/corp-net-v2"
                echo "   sudo ./engine.sh"
                sleep 3
                ;;
            9) 
                echo "¡Hasta pronto!"
                exit 0
                ;;
            *) 
                echo "❌ Opción inválida."
                sleep 1
                ;;
        esac
    fi
}
# 8. --- BUCLE PRINCIPAL ---
while true; do
    show_menu
done