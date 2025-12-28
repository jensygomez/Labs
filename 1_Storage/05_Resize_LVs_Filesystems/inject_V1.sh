#!/bin/bash
# inject_V1.sh - Resize LV & Filesystem - Variación 1
# LV extendido, filesystem NO actualizado (ext4)

set -euo pipefail  # ¡Importante! Si algo falla, para inmediatamente

echo "==> Iniciando setup del laboratorio Resize LVs & Filesystems (V1)"

# Selección aleatoria de disco disponible (sd[b-f])
AVAILABLE_DISKS=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/" $1}')
DISK=$(echo "$AVAILABLE_DISKS" | shuf -n1)

if [[ -z "$DISK" ]]; then
    echo "ERROR: No se encontraron discos sd[b-f] disponibles"
    exit 1
fi

echo "Disco seleccionado aleatoriamente: $DISK"

VG="vg_exam"
LV="lv_data"
MNT="/data"

# Limpieza y PV
wipefs -af "$DISK"
pvcreate -ff -y "$DISK"
echo "PV creado en $DISK"

# VG: crear o extender
if ! vgdisplay "$VG" &>/dev/null; then
    vgcreate "$VG" "$DISK"
    echo "VG $VG creado"
else
    vgextend "$VG" "$DISK"
    echo "VG $VG extendido con $DISK"
fi

# Crear LV si no existe
if ! lvdisplay "/dev/$VG/$LV" &>/dev/null; then
    lvcreate -L 1G -n "$LV" "$VG"
    mkfs.ext4 -F "/dev/$VG/$LV"
    echo "LV $LV creado (1G) y formateado con ext4"
else
    echo "LV $LV ya existe, reutilizando"
fi

# Montaje persistente
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID $MNT ext4 defaults 0 0" >> /etc/fstab
    echo "Entrada añadida a /etc/fstab"
fi

# ¡El "fallo" del laboratorio!
lvextend -L +1G "/dev/$VG/$LV"
echo "¡LV extendido exitosamente! Ahora ~2G"
echo "Pero el filesystem sigue en ~1G → ¡tarea del estudiante: resize2fs!"

sync
echo "==> Laboratorio listo y perfecto"
echo "Comando para solucionar: resize2fs /dev/vg_exam/lv_data"
echo "Verificar con: df -h /data  (antes y después)"