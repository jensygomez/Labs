#!/bin/bash
# inject_V4.sh - Resize LVs & Filesystems - Variación 4 (Intermedio)
# Escenario: LV y FS pueden crecer correctamente, pero el montaje persistente está roto
# Tarea: Diagnosticar resize + corregir fstab para persistencia

set -euo pipefail

echo "==> Iniciando setup Resize LVs & Filesystems (V4 - Persistencia)"

AVAILABLE_DISKS=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/" $1}')
DISK=$(echo "$AVAILABLE_DISKS" | shuf -n1)

[[ -z "$DISK" ]] && { echo "ERROR: No hay discos sd[b-f] disponibles"; exit 1; }

VG="vg_exam"
LV="lv_data"
MNT="/data"

echo "Disco seleccionado: $DISK"

# Preparar disco
wipefs -af "$DISK" &>/dev/null
pvcreate -ff -y "$DISK" &>/dev/null

if ! vgdisplay "$VG" &>/dev/null; then
    vgcreate "$VG" "$DISK" &>/dev/null
else
    vgextend "$VG" "$DISK" &>/dev/null
fi

# LV inicial pequeño
if ! lvdisplay "/dev/$VG/$LV" &>/dev/null; then
    lvcreate -L 1G -n "$LV" "$VG" &>/dev/null
fi

# FS aleatorio
if (( RANDOM % 2 == 0 )); then
    FS_TYPE="ext4"
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
else
    FS_TYPE="xfs"
    mkfs.xfs -f "/dev/$VG/$LV" &>/dev/null
fi

mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT" &>/dev/null || true

# === fstab INCORRECTO A PROPÓSITO ===
REAL_UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
FAKE_UUID=$(uuidgen)

# Usamos UUID incorrecto o FS incorrecto
if (( RANDOM % 2 == 0 )); then
    echo "UUID=$FAKE_UUID $MNT $FS_TYPE defaults 0 0" >> /etc/fstab
    BROKEN_REASON="UUID incorrecto"
else
    WRONG_FS=$([[ "$FS_TYPE" == "ext4" ]] && echo "xfs" || echo "ext4")
    echo "UUID=$REAL_UUID $MNT $WRONG_FS defaults 0 0" >> /etc/fstab
    BROKEN_REASON="Tipo de filesystem incorrecto"
fi

sync
echo "fstab configurado con error: $BROKEN_REASON"

# ========================
# GENERAR TICKET
# ========================

TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Troubleshooting Lab     "
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - Intermedio"
    echo "Escenario:        Se amplió el almacenamiento para /data,"
    echo "                  pero tras reiniciar el sistema, el punto"
    echo "                  de montaje no se comporta como se espera."
    echo
    echo "Información del sistema:"
    echo "  Disco físico usado: _____ $DISK"
    echo "  Volume Group: ___________ $VG"
    echo "  Logical Volume: _________ $LV"
    echo "  Punto de montaje: _______ $MNT"
    echo
    echo "Pistas:"
    echo "  • El Volume Group tiene espacio libre disponible."
    echo "  • El Logical Volume puede crecer sin problema."
    echo "  • El problema NO está solo en el tamaño."
    echo "  • Verifica el montaje persistente."
    echo
    echo "Objetivo final:"
    echo "  • /data debe usar casi todo el espacio disponible."
    echo "  • El sistema debe montar /data correctamente tras reiniciar."
    echo "  • Verifica con: mount -a y df -h /data"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "==> Ticket V4 generado correctamente"
