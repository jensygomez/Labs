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
    # source "$BASE_DIR/lib/firewall.sh" # Descomentar cuando lo creemos
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
    echo "🔍 --- [ STATUS DE LA RED ] ---"
    local namespaces=$(ip netns list | cut -d' ' -f1)
    
    if [ -z "$namespaces" ]; then
        echo "⚠️  No hay namespaces activos."
    else
        for ns in $namespaces; do
            echo -e "\n📦 Nodo: \e[1;32m$ns\e[0m"
            # Mostrar IPs
            echo -n "   🌐 IPs: "
            ip netns exec "$ns" ip -4 addr show scope global | awk '{print $2}' | xargs
            # Mostrar Rutas principales
            echo -n "   🛣️  Ruta Default: "
            ip netns exec "$ns" ip route show default | awk '{print $3}'
        done
    fi
    echo -e "\n------------------------------------------"
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