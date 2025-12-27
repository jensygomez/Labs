#!/bin/bash
# Launcher para todos los laboratorios RHCSA EX200

DOMAIN="$1"      # e.g., storage, users, selinux
SLOT="$2"        # e.g., 05, 01

# Configuración centralizada de la VM
VM_USER="student"
VM_PASS="redhat"
VM_IP="192.168.122.231"

# Carpeta raíz de los labs
LAB_ROOT="$HOME/GitHub/Labs/$DOMAIN"

# Selección de variación (puede ser aleatoria o la primera)
LAB_SCRIPT=$(ls -d "$LAB_ROOT"/"$SLOT"_*/*inject*.sh 2>/dev/null | shuf -n1)

# Ejecución remota en la VM
sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_IP 'bash -s' < "$LAB_SCRIPT"
