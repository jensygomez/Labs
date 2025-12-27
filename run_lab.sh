#!/bin/bash
# Launcher universal para todos los laboratorios RHCSA EX200
# Uso: bash run_lab.sh <dominio> <slot>
# Ejemplo: bash run_lab.sh storage 05

set -e

DOMAIN="$1"   # e.g., storage, users, selinux
SLOT="$2"     # e.g., 05

if [ -z "$DOMAIN" ] || [ -z "$SLOT" ]; then
    echo "Uso: bash $0 <dominio> <slot>"
    exit 1
fi

# Configuración de la VM
VM_USER="student"
VM_PASS="redhat"
VM_IP="192.168.122.231"

# Carpeta raíz de todos los labs
LAB_ROOT="$HOME/GitHub/Labs"

# Buscar la carpeta exacta del slot/subtema dentro del dominio
SLOT_DIR=$(find "$LAB_ROOT/$DOMAIN" -maxdepth 1 -type d -name "$SLOT*" | head -n1)

if [ -z "$SLOT_DIR" ]; then
    echo "No se encontró la carpeta para $DOMAIN slot $SLOT"
    exit 1
fi

# Seleccionar aleatoriamente un script de nivel/version disponible (inject_V*.sh)
LAB_SCRIPT=$(find "$SLOT_DIR" -maxdepth 1 -type f -name "inject*.sh" | shuf -n1)

if [ -z "$LAB_SCRIPT" ]; then
    echo "No se encontró ningún script inject*.sh en $SLOT_DIR"
    exit 1
fi

echo "Ejecutando lab: $LAB_SCRIPT en la VM $VM_IP..."

# Ejecutar remotamente en la VM
sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" 'bash -s' < "$LAB_SCRIPT"
