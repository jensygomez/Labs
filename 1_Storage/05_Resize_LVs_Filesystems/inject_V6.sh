#!/bin/bash
# inject_V6.sh - Resize LVs & Filesystems - Variación 6 (FS no redimensionado)
# Escenario: El LV fue extendido correctamente, pero el filesystem no fue ajustado.
# Tarea: Detectar inconsistencia y crecer el FS sin tocar LVM.

set -euo pipefail

echo "==> Iniciando setup Resize LVs & Filesystems (V6 - FS no redimensionado)"

# Seleccionar dos discos
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/" $1}'))
[[ ${#AVAILABLE_DISKS[@]} -lt 2 ]] && { echo "ERROR: Se requieren 2 discos"; exit 1; }

DISK1="${AVAILABLE_DISKS[0]}"
DISK2="${AVAILABLE_DISKS[1]}"

VG="vg_exam"
LV="lv_data"
MNT="/data"

echo "Discos usados:"
echo "  • $DISK1"
echo "  • $DISK2"

# Preparar discos
wipefs -af "$DISK1" "$DISK2" &>/dev/null
pvcreate -ff -y "$DISK1" "$DISK2" &>/dev/null
vgcreate "$VG" "$DISK1" "$DISK2" &>/dev/null

# Crear LV pequeño primero
lvcreate -L 1G -n "$LV" "$VG" &>/dev/null

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

# Ahora EXTENDEMOS EL LV A TODO EL VG
lvextend -l 100%VG "/dev/$VG/$LV" &>/dev/null

# NOTA: NO redimensionamos el filesystem
# ERROR intencional del laboratorio

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
echo "UUID=$UUID $MNT $FS_TYPE defaults 0 0" >> /etc/fstab

sync
echo "==> Setup V6 completado (LV extendido, FS NO)"

# ========================
# GENERAR TICKET
# ========================

TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Troubleshooting Lab     "
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - Avanzado"
    echo "Escenario:        Se amplió el almacenamiento del sistema,"
    echo "                  pero /data sigue mostrando el tamaño antiguo."
    echo
    echo "Observaciones:"
    echo "  • El volumen lógico parece tener el tamaño correcto."
    echo "  • El sistema de archivos no refleja ese tamaño."
    echo "  • No hay errores de montaje."
    echo
    echo "Pistas:"
    echo "  • Compara lvs con df -h."
    echo "  • Identifica correctamente el filesystem."
    echo "  • No modifiques LVM nuevamente."
    echo
    echo "Objetivo final:"
    echo "  • /data debe usar todo el espacio disponible."
    echo "  • No se deben perder datos."
    echo "  • Verifica con: df -h /data"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "==> Ticket V6 generado correctamente"
