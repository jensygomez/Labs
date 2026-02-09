#!/bin/bash
# engine.sh - Orquestador CorpNet-v2 con menú interactivo

# --- CONFIGURACIÓN ---
BIN_DIR="./.bin"
YQ="$BIN_DIR/yq"
YQ_VERSION="v4.35.2"
YQ_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"

# --- AUTO-INSTALACIÓN DE DEPENDENCIAS ---
install_dependencies() {
    if [ ! -f "$YQ" ]; then
        echo "📥 Preparando dependencias locales (yq)..."
        mkdir -p "$BIN_DIR"
        curl -L "$YQ_URL" -o "$YQ"
        chmod +x "$YQ"
        echo "✅ Dependencias listas."
    fi
}

# --- IMPORTAR LIBRERÍAS (Después de instalar dependencias) ---
# Nota: Aquí sourcearemos tus libs que iremos creando
# source ./lib/core.sh

# --- FUNCIONES DE ACCIÓN ---
deploy_lab() {
    echo "🚀 Iniciando despliegue de CorpNet-v2..."
    # Aquí irá: create_namespaces, create_links, setup_routing...
    echo "✨ Laboratorio desplegado correctamente."
    read -p "Presiona Enter para volver..."
}

destroy_lab() {
    echo "🔥 Destruyendo laboratorio..."
    # Aquí irá: cleanup_namespaces...
    echo "🗑️  Sistema limpio."
    read -p "Presiona Enter para volver..."
}

# --- MENÚ INTERACTIVO ---
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
        3) echo "Próximamente: Status..."; sleep 2 ;;
        0) exit 0 ;;
        *) echo "❌ Opción inválida."; sleep 1 ;;
    esac
}

# --- PUNTO DE ENTRADA ---
if [[ $EUID -ne 0 ]]; then
   echo "❌ Error: Debes ejecutar como root (sudo)." 
   exit 1
fi

install_dependencies

# Bucle infinito del menú
while true; do
    show_menu
done