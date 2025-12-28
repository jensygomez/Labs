#!/bin/bash
# RHCSA EX200 – Storage Slot 05 – Variation 1
# Solo setup: LV extendido pero filesystem NO actualizado

set -e
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Este script debe ejecutarse como root."
  exit 1
fi

echo "==> Ejecutando setup del laboratorio Resize LV (ext4)..."

# Discos disponibles para labs (excluimos sda y vda)
DISK=$(lsblk -dn -o NAME,SIZE,TYPE | grep 'disk' | grep -E 'sd[a-f]' | sort -k2 -hr | head -n1 | awk '{print $1}')
# Alternativa aleatoria: shuf -n1 en vez de head

[ -z "$DISK" ] && { echo "No se encontraron discos sd[a-f]"; exit 1; }

DEVICE="/dev/$DISK"
VG="vg_exam"
LV="lv_data"
MNT="/data"

wipefs -a "$DEVICE" &>/dev/null
pvcreate -ff -y "$DEVICE" &>/dev/null

if ! vgdisplay "$VG" >/dev/null 2>&1; then
    vgcreate "$VG" "$DEVICE" &>/dev/null
else
    vgextend "$VG" "$DEVICE" &>/dev/null
fi

if ! lvdisplay "/dev/$VG/$LV" >/dev/null 2>&1; then
    lvcreate -L 1G -n "$LV" "$VG" &>/dev/null
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
fi

mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
grep -q "$MNT" /etc/fstab || echo "UUID=$UUID $MNT ext4 defaults 0 0" >> /etc/fstab

# Aquí viene el "fallo" del lab: extendemos LV pero NO resizeamos FS
lvextend -L +1G "/dev/$VG/$LV" &>/dev/null

sync
echo "==> Setup completado. Disco usado: $DEVICE (LV ahora ~2G, FS sigue ~1G)"