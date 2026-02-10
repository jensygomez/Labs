#!/bin/bash
# Script para configurar VM Rocky 9.7 desde el host

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
debug() { [ -n "$DEBUG" ] && echo -e "${BLUE}[DEBUG]${NC} $1"; }

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Configura una VM Rocky 9.7 para el laboratorio CorpNet-v2"
    echo ""
    echo "Opciones:"
    echo "  -i, --ip IP          IP de la VM (requerido)"
    echo "  -p, --password PASS  Contraseña de root de la VM"
    echo "  -s, --skip-test      Saltar prueba de conexión SSH"
    echo "  -d, --debug          Modo depuración"
    echo "  -h, --help           Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 -i 192.168.122.100"
    echo "  $0 --ip 192.168.122.50 --password redhat"
    echo ""
    exit 0
}

# Parsear argumentos
VM_IP=""
VM_PASS=""
SKIP_TEST=0
DEBUG=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--ip)
            VM_IP="$2"
            shift 2
            ;;
        -p|--password)
            VM_PASS="$2"
            shift 2
            ;;
        -s|--skip-test)
            SKIP_TEST=1
            shift
            ;;
        -d|--debug)
            DEBUG=1
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            error "Argumento desconocido: $1"
            show_help
            ;;
    esac
done

# Verificar argumentos obligatorios
if [ -z "$VM_IP" ]; then
    echo "=========================================="
    echo "   CONFIGURADOR ANSIBLE PARA ROCKY 9.7    "
    echo "=========================================="
    
    # Solicitar IP de la VM
    read -p "Ingresa la IP de la VM Rocky 9.7: " VM_IP
    if [ -z "$VM_IP" ]; then
        error "Debes proporcionar una IP"
        exit 1
    fi
fi

if [ -z "$VM_PASS" ]; then
    read -sp "Ingresa la contraseña de root de la VM: " VM_PASS
    echo ""
    if [ -z "$VM_PASS" ]; then
        error "Debes proporcionar la contraseña"
        exit 1
    fi
fi

# Verificar si Ansible está instalado
if ! command -v ansible &> /dev/null; then
    error "Ansible no está instalado."
    echo "Instala Ansible primero:"
    echo "  Ubuntu/Debian: sudo apt install ansible sshpass"
    echo "  Fedora/RHEL:   sudo dnf install ansible sshpass"
    exit 1
fi

# Verificar si sshpass está instalado
if ! command -v sshpass &> /dev/null; then
    warn "sshpass no está instalado. Instalando..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y sshpass
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y sshpass
    else
        error "No se pudo instalar sshpass. Instálalo manualmente."
        exit 1
    fi
fi

# Prueba de conexión SSH (opcional)
if [ "$SKIP_TEST" -eq 0 ]; then
    info "Probando conexión SSH a ${VM_IP}..."
    if ! timeout 5 sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$VM_IP "echo 'Conexión SSH exitosa'" &>/dev/null; then
        error "No se pudo conectar a ${VM_IP} con las credenciales proporcionadas"
        echo "Verifica:"
        echo "  1. La VM está encendida"
        echo "  2. La IP es correcta"
        echo "  3. SSH está habilitado en la VM"
        echo "  4. La contraseña de root es correcta"
        echo ""
        read -p "¿Intentar de todas formas? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 1
        fi
    else
        info "✅ Conexión SSH exitosa"
    fi
fi

# Crear archivo de inventario temporal
INVENTORY_FILE="/tmp/inventory_corpnet_$$.yml"
debug "Creando inventario temporal: $INVENTORY_FILE"

cat > "$INVENTORY_FILE" << EOF
all:
  hosts:
    rocky-vm:
      ansible_host: "${VM_IP}"
      ansible_user: root
      ansible_ssh_pass: "${VM_PASS}"
  vars:
    student_ssh_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByFDKwjMDeGJ5GRhXmZHa75h7dK9JcPHvWWtesSO3/x student@lab-3tier"
    static_ip: "${VM_IP}"
    netmask: "24"
    gateway: "192.168.122.1"
    dns_servers: ["8.8.8.8", "1.1.1.1"]
EOF

info "Inventario temporal creado: $INVENTORY_FILE"

# Ejecutar Ansible
echo "🚀 Ejecutando configuración en ${VM_IP}..."
echo "Esto tomará unos minutos..."

# Determinar nivel de verbosidad
VERBOSITY=""
if [ "$DEBUG" -eq 1 ]; then
    VERBOSITY="-vvv"
fi

# Ejecutar playbook
if ansible-playbook -i "$INVENTORY_FILE" playbook-base-vm.yml $VERBOSITY; then
    echo ""
    echo "=========================================="
    info "✅ CONFIGURACIÓN COMPLETADA EXITOSAMENTE"
    echo "=========================================="
    echo ""
    echo "📋 RESUMEN DE CONFIGURACIÓN:"
    echo "   Host: ${VM_IP}"
    echo "   Usuario: student"
    echo "   Contraseña: redhat"
    echo "   SSH disponible en: ssh student@${VM_IP}"
    echo ""
    echo "🔧 SERVICIOS CONFIGURADOS:"
    echo "   • SSH con autenticación por password y clave"
    echo "   • MariaDB listo para usar"
    echo "   • IP estática configurada"
    echo "   • Usuario 'student' con sudo sin password"
    echo "   • Prompt dinámico para namespaces"
    echo ""
    echo "🚀 PRÓXIMOS PASOS:"
    echo "   1. Conectarse a la VM: ssh student@${VM_IP}"
    echo "   2. Clonar repositorio corpnet-v2"
    echo "   3. Ejecutar ./engine.sh desde la VM"
    echo ""
    
    # Probar conexión rápida
    info "Probando conexión final..."
    if sshpass -p "redhat" ssh -o StrictHostKeyChecking=no student@$VM_IP "echo '✅ Conexión como student exitosa'" &>/dev/null; then
        info "Todo funcionando correctamente!"
    else
        warn "Conexión como student falló, pero root funciona. Verifica manualmente."
    fi
    
    # Limpiar archivo temporal
    rm -f "$INVENTORY_FILE"
    debug "Archivo temporal eliminado"
    
else
    error "La ejecución de Ansible falló"
    echo ""
    echo "Posibles soluciones:"
    echo "  1. Verifica que la VM tenga acceso a Internet"
    echo "  2. Intenta ejecutar manualmente:"
    echo "     ansible-playbook -i '$INVENTORY_FILE' playbook-base-vm.yml"
    echo "  3. Revisa los logs en la VM: /var/log/messages"
    
    # Mantener archivo temporal para depuración si hay debug
    if [ "$DEBUG" -eq 1 ]; then
        warn "Archivo de inventario mantenido para depuración: $INVENTORY_FILE"
    else
        rm -f "$INVENTORY_FILE"
    fi
    exit 1
fi