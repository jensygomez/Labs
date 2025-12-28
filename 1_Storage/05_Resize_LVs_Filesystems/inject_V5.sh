#!/bin/bash
# inject_V5.sh - Resize LVs & Filesystems - Variación 5 (VG incompleto)
# Escenario: Hay dos discos disponibles, pero solo uno fue agregado al VG.
# Tarea: Detectar disco faltante, extender VG, luego LV y FS.

set -euo pipefail

echo "==> Iniciando setup Resize LVs & Filesystems (V5 - VG incompleto)"

# Seleccionar dos discos distintos
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/" $1}'))

[[ ${#AVAILABLE_DISKS[@]} -lt 2 ]] && { echo "ERROR: Se requieren al menos 2 discos"; exit 1; }

DISK1="${AVAILABLE_DISKS[0]}"
DISK2="${AVAILABLE_DISKS[1]}"

VG="vg_exam"
LV="lv_data"
MNT="/data"

echo "Discos disponibles:"
echo "  • $DISK1 (en uso)"
echo "  • $DISK2 (NO usado)"

# Preparar discos
wipefs -af "$DISK1" "$DISK2" &>/dev/null
pvcreate -ff -y "$DISK1" "$DISK2" &>/dev/null

# Crear VG SOLO con el primer disco
vgcreate "$VG" "$DISK1" &>/dev/null

# Crear LV ocupando casi todo el VG
lvcreate -l 90%VG -n "$LV" "$VG" &>/dev/null

# FS aleatorio
if (( RANDOM % 2 == 0 )); then
    FS_TYPE="ext4"
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
else
    FS_TYPE="xfs"
    mkfs.xfs -f "/dev/$VG/$LV" &>/dev/null
fi

mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
echo "UUID=$UUID $MNT $FS_TYPE defaults 0 0" >> /etc/fstab

sync
echo "==> Setup V5 completado"

# ========================
# GENERAR TICKET
# ========================

TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Troubleshooting Lab     "
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - Intermedio/Avanzado"
    echo "Escenario:        Se agregó almacenamiento al sistema,"
    echo "                  pero /data no puede crecer tanto"
    echo "                  como se esperaba."
    echo
    echo "Información del sistema:"
    echo "  Volume Group:    $VG"
    echo "  Logical Volume:  $LV"
    echo "  Punto de montaje:$MNT"
    echo
    echo "Pistas:"
    echo "  • Hay más de un disco físico disponible."
    echo "  • El VG no está usando todo el almacenamiento posible."
    echo "  • El LV ya ocupa casi todo el VG actual."
    echo "  • El filesystem funciona correctamente."
    echo
    echo "Objetivo final:"
    echo "  • /data debe crecer usando TODO el almacenamiento disponible."
    echo "  • El cambio debe ser persistente."
    echo "  • Verifica con: vgs, lvs, df -h /data"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "==> Ticket V5 generado correctamente"
