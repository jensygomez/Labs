#!/bin/bash
# inject_V1.sh - Resize LVs & Filesystems - Variación 1
# Escenario: LV creado (1G), hay espacio libre en VG, pero LV NO extendido aún
# Tarea: Extender el LV usando el espacio libre y actualizar el filesystem

set -euo pipefail

echo "==> Iniciando setup del laboratorio Resize LVs & Filesystems (V1)"

# Selección aleatoria de disco sd[b-f]
AVAILABLE_DISKS=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/" $1}')
DISK=$(echo "$AVAILABLE_DISKS" | shuf -n1)

[[ -z "$DISK" ]] && { echo "ERROR: No hay discos sd[b-f] disponibles"; exit 1; }

echo "Disco seleccionado aleatoriamente: $DISK"

VG="vg_exam"
LV="lv_data"
MNT="/data"

# PV + VG
wipefs -af "$DISK" &>/dev/null
pvcreate -ff -y "$DISK" &>/dev/null
if ! vgdisplay "$VG" &>/dev/null; then
    vgcreate "$VG" "$DISK" &>/dev/null
    echo "VG $VG creado"
else
    vgextend "$VG" "$DISK" &>/dev/null
    echo "VG $VG extendido"
fi

# LV: crear 1G si no existe
if ! lvdisplay "/dev/$VG/$LV" &>/dev/null; then
    lvcreate -L 1G -n "$LV" "$VG" &>/dev/null
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
    echo "LV $LV creado (1G) y formateado con ext4"
else
    echo "LV $LV ya existe"
fi

# Montaje persistente
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT" 2>/dev/null || true

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID $MNT ext4 defaults 0 0" >> /etc/fstab
    echo "Montaje persistente configurado"
fi

sync
echo "==> Setup completado"

# ========================
# GENERAR TICKET
# ========================

TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Troubleshooting Lab     "
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - Básico"
    echo "Escenario:        Un administrador anterior configuró almacenamiento adicional"
    echo "                  en /data, pero los usuarios reportan falta de espacio."
    echo "                  Parece que el trabajo quedó a medias."
    echo
    echo "Información del sistema:"
    echo "  Disco físico usado: _____ $DISK"
    echo "  Volume Group: ___________ $VG"
    echo "  Logical Volume: _________ $LV"
    echo "  Punto de montaje: _______ $MNT"
    echo
    echo "Pistas para resolver:"
    echo "  • Hay un VG con espacio libre no utilizado."
    echo "  • El LV actual no ocupa todo el disco disponible."
    echo "  • El filesystem montado podría no reflejar el tamaño real del LV."
    echo "  • Investiga comandos para extender volúmenes lógicos sin perder datos."
    echo "  • Luego, actualiza el sistema de archivos para usar el nuevo espacio."
    echo
    echo "Objetivo final:"
    echo "  El directorio /data debe usar prácticamente todo el espacio del disco físico asignado."
    echo "  Verifica con: df -h /data"
    echo "=================================================="
} > "$TICKET_FILE"

# Copiar para el estudiante
cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket V1 generado correctamente"
