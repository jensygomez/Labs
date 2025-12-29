#!/bin/bash
# inject_V9.sh - Resize LVs & Filesystems - V9 (Avanzado real)
# Escenario: Storage aparentemente correcto en runtime, fallo crítico tras reboot

set -euo pipefail

echo "==> Iniciando setup V9 - Storage Troubleshooting Avanzado"

# -----------------------------
# Selección de discos (2 discos)
# -----------------------------
DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/"$1}' | shuf))
[[ ${#DISKS[@]} -lt 2 ]] && { echo "ERROR: Se requieren al menos 2 discos"; exit 1; }

DISK1="${DISKS[0]}"
DISK2="${DISKS[1]}"

echo "Discos seleccionados:"
echo "  - $DISK1"
echo "  - $DISK2"

VG="vg_exam"
LV="lv_data"
MNT="/data"

# -----------------------------
# Preparar discos
# -----------------------------
wipefs -af "$DISK1" "$DISK2" &>/dev/null
pvcreate -ff -y "$DISK1" "$DISK2" &>/dev/null
vgcreate "$VG" "$DISK1" "$DISK2" &>/dev/null
echo "VG $VG creado con 2 PV"

# -----------------------------
# Crear LV parcialmente
# -----------------------------
lvcreate -L 1G -n "$LV" "$VG" &>/dev/null
echo "LV $LV creado (1G)"

# -----------------------------
# FS aleatorio
# -----------------------------
if (( RANDOM % 2 == 0 )); then
    FS_REAL="ext4"
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
else
    FS_REAL="xfs"
    mkfs.xfs -f "/dev/$VG/$LV" &>/dev/null
fi
echo "Filesystem real creado: $FS_REAL"

# -----------------------------
# Montaje inicial (OK)
# -----------------------------
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

# -----------------------------
# EXTENSIÓN INCOMPLETA DEL LV
# -----------------------------
lvextend -L +512M "/dev/$VG/$LV" &>/dev/null
echo "LV extendido parcialmente (+512M)"
# ⚠️ FS NO redimensionado

# -----------------------------
# Corrupción lógica del VG
# (simulación: PV inconsistente)
# -----------------------------
pvremove -ff -y "$DISK2" &>/dev/null || true
echo "Advertencia: Un PV quedó inconsistente"

# -----------------------------
# fstab MAL CONFIGURADO
# -----------------------------
UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")

if [[ "$FS_REAL" == "xfs" ]]; then
    FS_WRONG="ext4"
else
    FS_WRONG="xfs"
fi

echo "UUID=$UUID $MNT $FS_WRONG defaults 0 0" >> /etc/fstab
echo "fstab configurado con filesystem incorrecto ($FS_WRONG)"

sync
echo "==> Setup V9 completado (sistema ARRANCA OK)"
