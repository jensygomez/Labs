#!/bin/bash
# inject_V7-A.sh - Resize LVs & Filesystems
# Advanced Troubleshooting (Realistic Production Scenario)
# RHCSA EX200

set -euo pipefail

echo "==> Iniciando setup del laboratorio V7-A (Advanced Troubleshooting)"

# Selección de dos discos físicos
AVAILABLE_DISKS=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/" $1}')
DISK1=$(echo "$AVAILABLE_DISKS" | shuf -n1)
DISK2=$(echo "$AVAILABLE_DISKS" | grep -v "$DISK1" | shuf -n1)

[[ -z "$DISK1" || -z "$DISK2" ]] && {
    echo "ERROR: No hay suficientes discos disponibles"
    exit 1
}

echo "Discos seleccionados: $DISK1 y $DISK2"

VG="vg_exam"
LV="lv_data"
MNT="/data"

# Limpieza
wipefs -af "$DISK1" "$DISK2" &>/dev/null

# Crear PVs
pvcreate -ff -y "$DISK1" "$DISK2" &>/dev/null

# Crear VG con ambos discos
vgcreate "$VG" "$DISK1" "$DISK2" &>/dev/null
echo "VG $VG creado con dos discos"

# Crear LV pequeño inicialmente
lvcreate -L 1G -n "$LV" "$VG" &>/dev/null
echo "LV $LV creado con tamaño inicial 1G"

# Filesystem aleatorio
if (( RANDOM % 2 == 0 )); then
    FS_TYPE="ext4"
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
else
    FS_TYPE="xfs"
    mkfs.xfs -f "/dev/$VG/$LV" &>/dev/null
fi

echo "Filesystem creado: $FS_TYPE"

# Montaje
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
echo "UUID=$UUID $MNT $FS_TYPE defaults 0 0" >> /etc/fstab

# === TRAMPA PRINCIPAL ===
# Se extiende el LV pero NO el filesystem
lvextend -L +1G "/dev/$VG/$LV" &>/dev/null
echo "LV extendido en +1G (filesystem NO ajustado)"

sync

echo "==> Setup V7-A completado"

# ========================
# GENERAR TICKET
# ========================

TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "      RHCSA EX200 - Advanced Storage Troubleshooting"
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - V7-A"
    echo
    echo "Escenario:"
    echo "  El equipo de operaciones reporta que /data sigue"
    echo "  quedándose sin espacio, a pesar de que recientemente"
    echo "  se agregaron discos al servidor."
    echo
    echo "Observaciones:"
    echo "  • El sistema arranca sin errores."
    echo "  • /data está montado correctamente."
    echo "  • El Volume Group tiene espacio disponible."
    echo
    echo "Tareas:"
    echo "  1. Analizar el estado de los discos, VG y LV."
    echo "  2. Verificar si el tamaño del filesystem coincide"
    echo "     con el tamaño real del Logical Volume."
    echo "  3. Aplicar la corrección adecuada SIN downtime."
    echo
    echo "Objetivo final:"
    echo "  /data debe reflejar el tamaño correcto del LV."
    echo
    echo "Validación:"
    echo "  df -h /data"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket V7-A generado correctamente"
