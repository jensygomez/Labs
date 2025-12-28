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
# TICKET PERSONALIZADO V1 CON COLORES Y LIMPIEZA DE PANTALLA
# ========================
clear  # Limpia la pantalla antes de mostrar el ticket

# Colores ANSI
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Ticket con colores y pistas (sin comandos directos)
echo -e "${YELLOW}==================================================${RESET}" | tee /home/student/lab_ticket_V1.txt
echo -e "${BLUE}     RHCSA EX200 - Storage Troubleshooting Lab     ${RESET}" | tee -a /home/student/lab_ticket_V1.txt
echo -e "${YELLOW}==================================================${RESET}" | tee -a /home/student/lab_ticket_V1.txt
echo -e "${CYAN}Variación:${RESET}        Resize LVs & Filesystems - Básico" | tee -a /home/student/lab_ticket_V1.txt
echo -e "${CYAN}Escenario:${RESET}        Parece que un administrador anterior comenzó a configurar un volumen lógico" | tee -a /home/student/lab_ticket_V1.txt
echo -e "                  para almacenamiento de datos, pero dejó el trabajo incompleto." | tee -a /home/student/lab_ticket_V1.txt
echo -e "                  El punto de montaje /data está activo, pero el tamaño parece" | tee -a /home/student/lab_ticket_V1.txt
echo -e "                  insuficiente para las necesidades reportadas. Un usuario ha" | tee -a /home/student/lab_ticket_V1.txt
echo -e "                  mencionado problemas de espacio, posiblemente por una extensión" | tee -a /home/student/lab_ticket_V1.txt
echo -e "                  fallida o no completada." | tee -a /home/student/lab_ticket_V1.txt
echo | tee -a /home/student/lab_ticket_V1.txt

# Info real
CURRENT_LV_SIZE=$(lvs -o lv_size --noheadings --units g "/dev/$VG/$LV" | xargs)
VG_FREE=$(vgs -o vg_free --noheadings --units g "$VG" | xargs)

echo -e "${CYAN}Disco físico:${RESET}     $DISK" | tee -a /home/student/lab_ticket_V1.txt
echo -e "${CYAN}Volume Group:${RESET}     $VG" | tee -a /home/student/lab_ticket_V1.txt
echo -e "${CYAN}Logical Volume:${RESET}   $LV" | tee -a /home/student/lab_ticket_V1.txt
echo -e "${CYAN}Punto de montaje:${RESET} $MNT" | tee -a /home/student/lab_ticket_V1.txt
echo | tee -a /home/student/lab_ticket_V1.txt
echo -e "${CYAN}Estado actual:${RESET}" | tee -a /home/student/lab_ticket_V1.txt
echo -e "  Tamaño del LV:     $CURRENT_LV_SIZE" | tee -a /home/student/lab_ticket_V1.txt
echo -e "  Espacio libre VG:  $VG_FREE (¿puedes usarlo?)" | tee -a /home/student/lab_ticket_V1.txt
echo -e "  Filesystem:        ~1G (ext4, verifica con df -h /data)" | tee -a /home/student/lab_ticket_V1.txt
echo | tee -a /home/student/lab_ticket_V1.txt
echo -e "${GREEN}PISTAS PARA INVESTIGAR:${RESET}" | tee -a /home/student/lab_ticket_V1.txt
echo -e "  1. Revisa el espacio disponible en el VG y PVs asociados." | tee -a /home/student/lab_ticket_V1.txt
echo -e "     ¿Hay espacio libre que no se está usando?" | tee -a /home/student/lab_ticket_V1.txt
echo -e "  2. Evalúa el tamaño actual del LV y compara con el disco físico." | tee -a /home/student/lab_ticket_V1.txt
echo -e "     ¿Parece que alguien intentó extenderlo pero falló?" | tee -a /home/student/lab_ticket_V1.txt
echo -e "  3. Verifica el filesystem montado en /data." | tee -a /home/student/lab_ticket_V1.txt
echo -e "     ¿El tamaño coincide con el LV? Si no, ¿por qué?" | tee -a /home/student/lab_ticket_V1.txt
echo -e "  4. Deduce cómo usar el espacio libre para aumentar el almacenamiento" | tee -a /home/student/lab_ticket_V1.txt
echo -e "     sin perder datos, y asegúrate de que el cambio sea persistente." | tee -a /home/student/lab_ticket_V1.txt
echo | tee -a /home/student/lab_ticket_V1.txt
echo -e "${GREEN}Verificación final:${RESET}" | tee -a /home/student/lab_ticket_V1.txt
echo -e "     Usa comandos para ver el espacio en /data – debe usar todo el disco disponible." | tee -a /home/student/lab_ticket_V1.txt
echo -e "${YELLOW}==================================================${RESET}" | tee -a /home/student/lab_ticket_V1.txt

chmod 644 /home/student/lab_ticket_V1.txt

echo "¡Ticket generado con pistas! El estudiante puede verlo con:"
echo "    cat /home/student/lab_ticket_V1.txt"
echo "==> Laboratorio V1 listo para investigar y resolver"