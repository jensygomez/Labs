#!/bin/bash
# engine.sh - Orquestador CorpNet-v2

# 1. --- DIRECTORIO BASE Y VARIABLES ---
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$BASE_DIR/.bin"
YQ="$BIN_DIR/yq"
YQ_VERSION="v4.35.2"
YQ_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"

# Exportamos BASE_DIR para que las librerías lo vean
export BASE_DIR

# 2. --- AUTO-INSTALACIÓN DE DEPENDENCIAS ---
install_dependencies() {
    if [ ! -f "$YQ" ]; then
        echo "📥 Preparando dependencias locales (yq)..."
        mkdir -p "$BIN_DIR"
        curl -sL "$YQ_URL" -o "$YQ"
        chmod +x "$YQ"
        echo "✅ Dependencias listas."
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
    # apply_firewall    # Descomentar cuando lo tengamos listo
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
    echo -e "🔍 \e[1;37m        ESTADO GLOBAL DE RED Y SEGURIDAD (ZERO-TRUST)\e[0m"
    echo -e "\e[1;34m===============================================================\e[0m"

    local namespaces=$(ip netns list | cut -d' ' -f1)
    
    if [ -z "$namespaces" ]; then
        echo -e "\n  \e[1;31m⚠️  No hay infraestructura desplegada.\e[0m"
    else
        for ns in $namespaces; do
            echo -e "\n\e[1;32m📦 Nodo: $ns\e[0m"
            
            # 1. Información de Red
            local ips=$(ip netns exec "$ns" ip -4 addr show scope global | awk '{print $2}' | xargs)
            local gw=$(ip netns exec "$ns" ip route show default | awk '{print $3}')
            echo -e "   \e[1;37m🌐 Red:\e[0m  IP(s): [ ${ips:-N/A} ]  |  GW: [ ${gw:-None} ]"

            # 2. Matriz de Seguridad (Microsegmentación)
            echo -e "   \e[1;37m🛡️  Políticas Inbound (Firewall):\e[0m"
            
            # Extraer reglas ACCEPT de iptables que tengan origen específico
            local rules=$(ip netns exec "$ns" iptables -L INPUT -n -v | grep "ACCEPT" | grep -E "[0-9]+\.[0-9]+")
            
            if [ -z "$rules" ]; then
                # Si no hay reglas específicas, revisamos si es el Router o está todo cerrado
                if [ "$ns" == "CORE-GW" ]; then
                    echo -e "      \e[0;33m⚡ Router: Tránsito Permitido (Forwarding UP)\e[0m"
                else
                    echo -e "      \e[0;90m🔒 Locked: Solo tráfico de salida permitido\e[0m"
                fi
            else
                # Formatear las reglas encontradas
                echo "$rules" | while read -r line; do
                    local src=$(echo "$line" | awk '{print $8}')
                    local proto=$(echo "$line" | awk '{print $4}')
                    local port=$(echo "$line" | grep "dpt:" | sed 's/.*dpt://')
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
    echo "1) 🚀 Desplegar Infraestructura"
    echo "2) 🧹 Limpiar Laboratorio (Destroy)"
    echo "3) 🔍 Status de la Red (Namespaces/IPs)"
    echo "0) 🚪 Salir"
    echo "------------------------------------------"
    read -p "Selecciona una opción: " opt
    
    case $opt in
        1) deploy_lab ;;
        2) destroy_lab ;;
        3) show_status ;;
        0) exit 0 ;;
        *) echo "❌ Opción inválida."; sleep 1 ;;
    esac
}

# 7. --- BUCLE PRINCIPAL ---
while true; do
    show_menu
done