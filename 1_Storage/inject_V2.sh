#!/bin/bash
# inject_V2.sh - Resize LVs & Filesystems - Variación 2 (Básico con XFS)
# Escenario: LV creado (1G) con XFS, hay espacio libre en VG, pero LV NO extendido
# Tarea: Extender el LV y crecer el filesystem XFS online

set -euo pipefail

echo "==> Iniciando setup del laboratorio Resize LVs & Filesystems (V2 - XFS)"

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
    mkfs.xfs -f "/dev/$VG/$LV" &>/dev/null
    echo "LV $LV creado (1G) y formateado con XFS"
else
    echo "LV $LV ya existe (reutilizando)"
fi

# Montaje persistente
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT" 2>/dev/null || true

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID $MNT xfs defaults 0 0" >> /etc/fstab
    echo "Montaje persistente configurado (XFS)"
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
    echo
    echo "Escenario:"
    echo "  Un administrador anterior preparó un volumen para datos"
    echo "  usando XFS en /data, pero los usuarios se quejan"
    echo "  de que rápidamente se llena el espacio."
    echo "  Parece que no se completó la configuración final."
    echo
    echo "Información del sistema:"
    echo "  Disco físico usado: _____ $DISK"
    echo "  Volume Group: ___________ $VG"
    echo "  Logical Volume: _________ $LV"
    echo "  Punto de montaje: _______ $MNT"
    echo
    echo "Pistas para resolver:"
    echo "  - El VG tiene espacio sin asignar."
    echo "  - El LV actual es más pequeño que el disco físico disponible."
    echo "  - XFS permite crecer online, sin desmontar."
    echo "  - Investiga cómo extender un LV y luego hacer que XFS use el nuevo espacio."
    echo "  - El comando para XFS es diferente al de ext4."
    echo
    echo "Objetivo final:"
    echo "  El directorio /data debe aprovechar casi todo el espacio del disco asignado."
    echo "  Verifica con: df -h /data"
    echo "=================================================="
} > "$TICKET_FILE"

# Copiar para el estudiante
cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

# Mostrar ticket en el host (sin colores)
echo
echo "=== TICKET DEL LABORATORIO (visible en tu host) ==="
cat "$TICKET_FILE"

echo
echo "¡Laboratorio V2 (XFS) inyectado!"
echo "Ticket guardado en la VM: /home/student/lab_ticket.txt"
