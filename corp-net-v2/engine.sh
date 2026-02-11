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

# hola
#hola
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
    echo "   CONFIGURAR VM BASE (ANSIBLE - HOST)    "
    echo "=========================================="

    local ANSIBLE_DIR="$BASE_DIR/ansible"

    if [ ! -d "$ANSIBLE_DIR" ]; then
        echo -e "${RED}❌ No se encuentra el directorio ansible/${NC}"
        read -p "Presiona Enter para volver..."
        return 1
    fi

    if ! command -v ansible-playbook &>/dev/null; then
        echo -e "${RED}❌ ansible-playbook no está instalado en el host${NC}"
        echo -e "${YELLOW}Instala Ansible y vuelve a intentar.${NC}"
        read -p "Presiona Enter para volver..."
        return 1
    fi

    read -rp "IP de la VM Rocky: " VM_IP
    read -rsp "Password root: " VM_PASS
    echo ""

    echo -e "${GREEN}🚀 Ejecutando playbooks Ansible...${NC}"

    pushd "$ANSIBLE_DIR" >/dev/null || return 1

    ansible-playbook playbooks/base.yml \
        -e "ansible_host=$VM_IP ansible_password=$VM_PASS"

    ansible-playbook playbooks/network.yml \
        -e "ansible_host=$VM_IP ansible_password=$VM_PASS"

    ansible-playbook playbooks/reboot.yml \
        -e "ansible_host=$VM_IP ansible_password=$VM_PASS"

    popd >/dev/null

    echo -e "${GREEN}✅ VM configurada correctamente.${NC}"
    read -p "Presiona Enter para volver..."
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