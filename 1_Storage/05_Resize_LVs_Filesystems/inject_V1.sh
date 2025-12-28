#!/bin/bash
# inject_V1.sh - Variación 1: LV extendido, filesystem NO actualizado (ext4)

set -e

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Este script debe ejecutarse como root."
    exit 1
fi

echo "==> Configurando laboratorio Resize LV (V1)..."

# Selección ALEATORIA de disco entre sdb, sdc, sdd, sde, sdf
DISK=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print $1}' | shuf -n1)

[ -z "$DISK" ] && { echo "ERROR: No se encontraron discos sd[b-f] disponibles"; exit 1; }

DEVICE="/dev/$DISK"
VG="vg_exam"
LV="lv_data"
MNT="/data"

echo "Disco seleccionado aleatoriamente: $DEVICE"

# Limpieza y creación PV
wipefs -af "$DEVICE" &>/dev/null
pvcreate -ff -y "$DEVICE" &>/dev/null

# VG: crear o extender
if ! vgdisplay "$VG" >/dev/null 2>&1; then
    vgcreate "$VG" "$DEVICE" &>/dev/null
else
    vgextend "$VG" "$DEVICE" &>/dev/null
fi

# LV: crear si no existe
if ! lvdisplay "/dev/$VG/$LV" >/dev/null 2>&1; then
    lvcreate -L 1G -n "$LV" "$VG" &>/dev/null
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
fi

# Montaje persistente
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
grep -q "^UUID=$UUID" /etc/fstab || echo "UUID=$UUID $MNT ext4 defaults 0 0" >> /etc/fstab

# ¡Aquí está el "fallo" del laboratorio!
lvextend -L +1G "/dev/$VG/$LV" &>/dev/null

sync
echo "==> Laboratorio listo: LV extendido a ~2G, filesystem sigue en ~1G"
echo "    Usa: resize2fs /dev/vg_exam/lv_data para solucionarlo"