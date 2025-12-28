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
# GENERAR TICKET Y ENVIARLO AL HOST
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
    echo "  Disco físico usado:     $DISK"
    echo "  Volume Group:          $VG"
    echo "  Logical Volume:        $LV"
    echo "  Punto de montaje:      $MNT"
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

# ENVIAR EL TICKET AL HOST (con colores)
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
${CYAN}Variación:${RESET}        Resize LVs & Filesystems - Básico
${CYAN}Escenario:${RESET}        Un administrador anterior configuró almacenamiento adicional
                  en /data, pero los usuarios reportan falta de espacio.
                  Parece que el trabajo quedó a medias.

${CYAN}Información del sistema:${RESET}
  Disco físico usado:     $DISK
  Volume Group:          $VG
  Logical Volume:        $LV
  Punto de montaje:      $MNT


${GREEN}Pistas para resolver:${RESET}
  • Hay un VG con espacio libre no utilizado.
  • El LV actual no ocupa todo el disco disponible.
  • El filesystem montado podría no reflejar el tamaño real del LV.
  • Investiga comandos para extender volúmenes lógicos sin perder datos.
  • Luego, actualiza el sistema de archivos para usar el nuevo espacio.

${GREEN}Objetivo final:${RESET}
  El directorio /data debe usar prácticamente todo el espacio del disco físico asignado.
  Verifica con: df -h /data
${YELLOW}==================================================${RESET}
EOF

echo
echo "¡Laboratorio inyectado! Ticket mostrado arriba."
echo "También guardado en la VM: /home/student/lab_ticket_V1.txt"