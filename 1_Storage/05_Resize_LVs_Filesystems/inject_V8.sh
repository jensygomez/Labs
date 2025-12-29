#!/bin/bash
# inject_V8.sh - Resize LVs & Filesystems - V8-A (Corrupción lógica avanzada)
# Escenario:
#  - LVM con 2 discos
#  - FS aleatorio (ext4 o XFS)
#  - /etc/fstab inconsistente
#  - Filesystem sucio / inconsistente
#  - LV extendido parcialmente
# Objetivo:
#  - Diagnóstico correcto
#  - Reparación según FS
#  - Corrección de fstab
#  - Crecimiento final correcto

set -euo pipefail

echo "==> Iniciando setup V8-A (Storage Troubleshooting Avanzado)"

# ========================
# Selección de discos
# ========================
DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/"$1}'))
[[ ${#DISKS[@]} -lt 2 ]] && { echo "ERROR: Se requieren al menos 2 discos libres"; exit 1; }

DISK1="${DISKS[0]}"
DISK2="${DISKS[1]}"

VG="vg_data"
LV="lv_data"
MNT="/data"

echo "Discos usados:"
echo "  - $DISK1"
echo "  - $DISK2"

# ========================
# Limpieza previa
# ========================
umount "$MNT" &>/dev/null || true
wipefs -af "$DISK1" "$DISK2" &>/dev/null

# ========================
# LVM
# ========================
pvcreate -ff -y "$DISK1" "$DISK2" &>/dev/null
vgcreate "$VG" "$DISK1" &>/dev/null
vgextend "$VG" "$DISK2" &>/dev/null

# Crear LV pequeño inicialmente
lvcreate -L 1G -n "$LV" "$VG" &>/dev/null

# ========================
# Filesystem ALEATORIO
# ========================
if (( RANDOM % 2 == 0 )); then
    FS_TYPE="ext4"
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
else
    FS_TYPE="xfs"
    mkfs.xfs -f "/dev/$VG/$LV" &>/dev/null
fi

echo "Filesystem creado: $FS_TYPE"

# ========================
# Montaje inicial
# ========================
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

# Crear datos dummy
dd if=/dev/urandom of="$MNT/testfile.bin" bs=1M count=50 &>/dev/null
sync

# ========================
# Introducir corrupción lógica
# ========================
umount "$MNT"

if [[ "$FS_TYPE" == "ext4" ]]; then
    # Marcar FS como sucio
    tune2fs -E force_fsck "/dev/$VG/$LV" &>/dev/null
else
    # XFS: generar inconsistencia leve
    mount -o ro "/dev/$VG/$LV" "$MNT" || true
    umount "$MNT" || true
fi

# ========================
# Extender LV SIN crecer FS
# ========================
lvextend -L +1G "/dev/$VG/$LV" &>/dev/null

# ========================
# /etc/fstab INCORRECTO
# ========================
UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")

# Tipo incorrecto a propósito
if [[ "$FS_TYPE" == "ext4" ]]; then
    FSTAB_FS="xfs"
else
    FSTAB_FS="ext4"
fi

grep -v "$MNT" /etc/fstab > /etc/fstab.tmp
mv /etc/fstab.tmp /etc/fstab

echo "UUID=$UUID $MNT $FSTAB_FS defaults 0 0" >> /etc/fstab

echo "fstab configurado con tipo INCORRECTO ($FSTAB_FS)"

# ========================
# GENERAR TICKET
# ========================
TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Troubleshooting Lab     "
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - V8-A"
    echo "Escenario:        Tras un reinicio inesperado, el"
    echo "                  volumen /data dejó de montar."
    echo "                  El sistema parece inconsistente."
    echo
    echo "Información conocida:"
    echo "  Volume Group:          $VG"
    echo "  Logical Volume:        $LV"
    echo "  Punto de montaje:      $MNT"
    echo
    echo "Síntomas:"
    echo "  • /data no monta correctamente"
    echo "  • Existen mensajes de error al montar"
    echo "  • El tamaño reportado no es consistente"
    echo
    echo "Advertencias:"
    echo "  • NO todos los filesystems se reparan igual"
    echo "  • Un comando incorrecto puede empeorar el daño"
    echo "  • Verifica antes de actuar"
    echo
    echo "Objetivo final:"
    echo "  • /data montado correctamente"
    echo "  • Filesystem consistente"
    echo "  • Tamaño correcto visible con df -h"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "==> V8-A inyectado correctamente"
