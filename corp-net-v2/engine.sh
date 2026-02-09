#!/bin/bash
# engine.sh - Orquestador CorpNet-v2

# 1. --- DIRECTORIO BASE Y VARIABLES ---
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$BASE_DIR/.bin"
YQ="$BIN_DIR/yq"
YQ_VERSION="v4.35.2"
YQ_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"

# 2. --- AUTO-INSTALACIÓN DE DEPENDENCIAS ---
install_dependencies() {
    if [ ! -f "$YQ" ]; then
        echo "📥 Preparando dependencias locales (yq)..."
        mkdir -p "$BIN_DIR"
        # Usamos -s para que sea silencioso y -L para seguir redirecciones
        curl -sL "$YQ_URL" -o "$YQ"
        chmod +x "$YQ"
        echo "✅ Dependencias listas."
    fi
}

# 3. --- VERIFICACIÓN DE PRIVILEGIOS Y PREPARACIÓN ---
if [[ $EUID -ne 0 ]]; then
   echo "❌ Error: Debes ejecutar como root (sudo)." 
   exit 1
fi

# IMPORTANTE: Instalar antes de cargar librerías que usen YQ
install_dependencies

# 4. --- IMPORTAR LIBRERÍAS ---
if [ -f "$BASE_DIR/lib/core.sh" ] && [ -f "$BASE_DIR/lib/network.sh" ]; then
    source "$BASE_DIR/lib/core.sh"
    source "$BASE_DIR/lib/network.sh"
else
    echo "❌ Error: No se encontraron las librerías en $BASE_DIR/lib/"
    exit 1
fi

# 5. --- FUNCIONES DE ACCIÓN ---
deploy_lab() {
    clear
    echo "🚀 Iniciando despliegue de CorpNet-v2..."
    create_namespaces   # Definida en lib/core.sh
    setup_network      # Definida en lib/network.sh
    echo -e "\n✨ Red establecida y ruteo configurado."
    echo "✨ Laboratorio desplegado correctamente."
    read -p "Presiona Enter para volver..."
}

destroy_lab() {
    clear
    echo "🔥 Destruyendo laboratorio..."
    cleanup_namespaces  # Deberías tenerla en lib/core.sh
    echo "🗑️  Sistema limpio."
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
        3) 
            echo "--- Namespaces Activos ---"
            ip netns list
            read -p "Presiona Enter para volver..."
            ;;
        0) exit 0 ;;
        *) echo "❌ Opción inválida."; sleep 1 ;;
    esac
}

# 7. --- BUCLE PRINCIPAL ---
while true; do
    show_menu
done