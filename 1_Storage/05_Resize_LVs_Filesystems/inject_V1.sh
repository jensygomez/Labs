#!/bin/bash
# inject_V1.sh - Resize LVs & Filesystems - Variación 1
# Escenario: LV creado (1G), hay espacio libre en VG, pero LV NO extendido aún
# Tarea: Extender el LV usando el espacio libre y resize el filesystem

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
# TICKET PERSONALIZADO V1
# ========================
echo
echo "==================================================" | tee /tmp/lab_ticket.txt
echo "     RHCSA EX200 - Storage Troubleshooting Lab     " | tee -a /tmp/lab_ticket.txt
echo "==================================================" | tee -a /tmp/lab_ticket.txt
echo "Variación:        Resize LVs & Filesystems - Básico" | tee -a /tmp/lab_ticket.txt
echo "Escenario:        Se ha creado un Logical Volume, pero" | tee -a /tmp/lab_ticket.txt
echo "                  hay espacio libre en el Volume Group" | tee -a /tmp/lab_ticket.txt
echo "                  que no está siendo utilizado." | tee -a /tmp/lab_ticket.txt
echo | tee -a /tmp/lab_ticket.txt
echo "Disco físico:     $DISK" | tee -a /tmp/lab_ticket.txt
echo "Volume Group:     $VG" | tee -a /tmp/lab_ticket.txt
echo "Logical Volume:   $LV" | tee -a /tmp/lab_ticket.txt
echo "Punto de montaje: $MNT" | tee -a /tmp/lab_ticket.txt
echo | tee -a /tmp/lab_ticket.txt

# Info real actual
CURRENT_LV_SIZE=$(lvs -o lv_size --noheadings --units g "/dev/$VG/$LV" | xargs)
VG_FREE=$(vgs -o vg_free --noheadings --units g "$VG" | xargs)

echo "Estado actual:" | tee -a /tmp/lab_ticket.txt
echo "  Tamaño del LV:     $CURRENT_LV_SIZE" | tee -a /tmp/lab_ticket.txt
echo "  Espacio libre VG:  $VG_FREE (disponible para extender)" | tee -a /tmp/lab_ticket.txt
echo "  Filesystem:        ~1G (ext4)" | tee -a /tmp/lab_ticket.txt
echo | tee -a /tmp/lab_ticket.txt
echo "TAREA DEL ESTUDIANTE:" | tee -a /tmp/lab_ticket.txt
echo "  1. Extender el LV usando todo el espacio libre:" | tee -a /tmp/lab_ticket.txt
echo "        lvextend -l +100%FREE /dev/vg_exam/lv_data" | tee -a /tmp/lab_ticket.txt
echo "  2. Actualizar el filesystem:" | tee -a /tmp/lab_ticket.txt
echo "        resize2fs /dev/vg_exam/lv_data" | tee -a /tmp/lab_ticket.txt
echo | tee -a /tmp/lab_ticket.txt
echo "Verificación final:" | tee -a /tmp/lab_ticket.txt
echo "        df -h /data   ← debe mostrar ~2G (o el tamaño del disco)" | tee -a /tmp/lab_ticket.txt
echo "==================================================" | tee -a /tmp/lab_ticket.txt

# Copiar ticket al home del student para que lo vea fácil
cp /tmp/lab_ticket.txt /home/student/lab_ticket_V1.txt
chmod 644 /home/student/lab_ticket_V1.txt

echo
echo "¡Ticket generado! El estudiante puede verlo con:"
echo "    cat /home/student/lab_ticket_V1.txt"
echo "==> Laboratorio V1 listo para resolver"