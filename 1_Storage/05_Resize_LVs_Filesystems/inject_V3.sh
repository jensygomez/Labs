#!/bin/bash
# inject_V3.sh - Resize LVs & Filesystems - Variación 3 (Básico Mixto)
# Escenario: LV creado (1G), espacio libre en VG, filesystem ALEATORIO (ext4 o XFS)
# Tarea: Diagnosticar el tipo de filesystem, extender LV y crecer el FS correctamente

set -euo pipefail

echo "==> Iniciando setup del laboratorio Resize LVs & Filesystems (V3 - Mixto)"

# Disco aleatorio
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
else
    echo "LV $LV ya existe (reutilizando)"
fi

# === ALEATORIO: ext4 o XFS ===
if (( RANDOM % 2 == 0 )); then
    FS_TYPE="ext4"
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
    FSTAB_OPTIONS="defaults"
    echo "Filesystem creado: ext4"
else
    FS_TYPE="xfs"
    mkfs.xfs -f "/dev/$VG/$LV" &>/dev/null
    FSTAB_OPTIONS="defaults"
    echo "Filesystem creado: XFS"
fi

# Montaje persistente
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT" 2>/dev/null || true

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID $MNT $FS_TYPE $FSTAB_OPTIONS 0 0" >> /etc/fstab
    echo "Montaje persistente configurado ($FS_TYPE)"
fi

sync
echo "==> Setup completado"

# ========================
# GENERAR TICKET Y ENVIARLO AL HOST
# ========================

TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Troubleshooting Lab     "
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - Básico (Mixto)"
    echo "Escenario:        Un administrador configuró un volumen adicional en /data"
    echo "                  para aliviar problemas de espacio, pero los usuarios"
    echo "                  siguen reportando que se llena rápidamente."
    echo "                  El trabajo parece incompleto."
    echo
    echo "Información del sistema:"
    echo "  Disco físico usado:     $DISK"
    echo "  Volume Group:          $VG"
    echo "  Logical Volume:        $LV"
    echo "  Punto de montaje:      $MNT"
    echo
    echo
    echo "Pistas para resolver:"
    echo "  • Hay espacio libre en el Volume Group que no está asignado."
    echo "  • El Logical Volume es más pequeño que el disco disponible."
    echo "  • Primero debes identificar correctamente el tipo de filesystem."
    echo "  • Luego, extiende el LV usando el espacio libre (online)."
    echo "  • Finalmente, haz que el filesystem use el nuevo espacio (el comando depende del tipo)."
    echo
    echo "Objetivo final:"
    echo "  /data debe aprovechar casi todo el espacio del disco físico."
    echo "  Verifica con: df -h /data"
    echo "=================================================="
} > "$TICKET_FILE"

# Copiar para el estudiante
cp "$TICKET_FILE" /home/student/lab_ticket_V3.txt
chmod 644 /home/student/lab_ticket_V3.txt

# ENVIAR TICKET AL HOST CON COLORES
echo
echo "=== TICKET DEL LABORATORIO (visible en tu host) ==="
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RESET="\033[0m"

cat << EOF
${YELLOW}==================================================${RESET}
${BLUE}     RHCSA EX200 - Storage Troubleshooting Lab     ${RESET}
${YELLOW}==================================================${RESET}
${CYAN}Variación:${RESET}        Resize LVs & Filesystems - Básico (Mixto)
${CYAN}Escenario:${RESET}        Un administrador configuró un volumen adicional en /data
                  para aliviar problemas de espacio, pero los usuarios
                  siguen reportando que se llena rápidamente.
                  El trabajo parece incompleto.

${CYAN}Información del sistema:${RESET}
  Disco físico usado:     $DISK
  Volume Group:          $VG
  Logical Volume:        $LV
  Punto de montaje:      $MNT


${GREEN}Pistas para resolver:${RESET}
  • Hay espacio libre en el Volume Group que no está asignado.
  • El Logical Volume es más pequeño que el disco disponible.
  • Primero debes identificar correctamente el tipo de filesystem.
  • Luego, extiende el LV usando el espacio libre (online).
  • Finalmente, haz que el filesystem use el nuevo espacio (el comando depende del tipo).

${GREEN}Objetivo final:${RESET}
  /data debe aprovechar casi todo el espacio del disco físico.
  Verifica con: df -h /data
${YELLOW}==================================================${RESET}
EOF

echo
echo "¡Laboratorio V3 (Mixto aleatorio) inyectado! Ticket mostrado arriba."
echo "También guardado en la VM: /home/student/lab_ticket_V3.txt"