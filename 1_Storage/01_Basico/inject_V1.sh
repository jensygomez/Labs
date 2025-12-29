#!/bin/bash
# inject_V1.sh - Resize LVs & Filesystems - Variación 1
# Copiar TODO este código en la VM y ejecutar: sudo bash inject_V1.sh

set -euo pipefail

echo "==> Iniciando setup del laboratorio Resize LVs & Filesystems (V1)"

# ============================================
# MODIFICACIÓN: Seleccionar 2 discos aleatorios
# ============================================
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/"$1}'))

if [[ ${#AVAILABLE_DISKS[@]} -lt 2 ]]; then
    echo "ERROR: Se requieren al menos 2 discos sd[b-f] disponibles"
    exit 1
fi

# Mezclar y tomar 2 discos
SHUFFLED_DISKS=($(printf "%s\n" "${AVAILABLE_DISKS[@]}" | shuf))
DISK1="${SHUFFLED_DISKS[0]}"
DISK2="${SHUFFLED_DISKS[1]}"

echo "Discos seleccionados aleatoriamente:"
echo "  - $DISK1"
echo "  - $DISK2"

VG="vg_exam"
LV="lv_data"
MNT="/data"

# ============================================
# MODIFICACIÓN: Usar ambos discos para VG
# ============================================

# Limpiar discos
wipefs -af "$DISK1" &>/dev/null
wipefs -af "$DISK2" &>/dev/null

# Crear PVs
pvcreate -ff -y "$DISK1" &>/dev/null
pvcreate -ff -y "$DISK2" &>/dev/null

# Crear o extender VG
if ! vgdisplay "$VG" &>/dev/null; then
    vgcreate "$VG" "$DISK1" &>/dev/null
    echo "VG $VG creado con $DISK1"
else
    vgremove -f "$VG" &>/dev/null 2>&1 || true
    vgcreate "$VG" "$DISK1" &>/dev/null
fi

# Agregar segundo disco al VG
vgextend "$VG" "$DISK2" &>/dev/null
echo "VG $VG extendido con $DISK2"

# LV: crear 30%VG (mucho menos que el espacio total)
if ! lvdisplay "/dev/$VG/$LV" &>/dev/null; then
    lvcreate -l 30%VG -n "$LV" "$VG" &>/dev/null
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
    echo "LV $LV creado (30%VG) y formateado con ext4"
else
    lvremove -f "/dev/$VG/$LV" &>/dev/null 2>&1 || true
    lvcreate -l 30%VG -n "$LV" "$VG" &>/dev/null
    mkfs.ext4 -F "/dev/$VG/$LV" &>/dev/null
fi

# Montaje persistente
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT" 2>/dev/null || true

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
if ! grep -q " $MNT " /etc/fstab; then
    echo "UUID=$UUID $MNT ext4 defaults 0 0" >> /etc/fstab
    echo "Montaje persistente configurado"
fi


echo "==> Simulando uso real en /data para hacer el problema creíble"

# Crear algunos archivos de prueba para que no esté vacío
touch /data/file{1..10}.txt
echo "Archivo de prueba para verificar integridad post-resize" > /data/integrity_check.txt
date > /data/fecha_creacion.txt

# Ocupar ~85% del filesystem del LV para simular llenado real
LV_SIZE_MB=$(df -m /data | awk 'NR==2 {print $2}')
FILE_SIZE_MB=$(( LV_SIZE_MB * 85 / 100 ))

echo "    Generando archivo grande para ocupar ~85% del filesystem..."
dd if=/dev/zero of=/data/bigfile.dat bs=1M count=$FILE_SIZE_MB status=none
sync



echo "==> Setup completado"

# ========================
# GENERAR TICKET REALISTA (SIN SPOILERS)
# ========================

TICKET_FILE="/tmp/current_lab_ticket.txt"

# No necesitamos exponer valores internos en el ticket ahora

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Troubleshooting Lab     "
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - Básico"
    echo "Escenario:        Un usuario reporta que el directorio /data se está quedando sin espacio,"
    echo "                  pero cree que debería haber más capacidad disponible ya que se añadió hardware recientemente."
    echo
    echo "DESCRIPCIÓN DEL PROBLEMA:"
    echo "  - El equipo de desarrollo no puede guardar más archivos en /data porque aparece lleno."
    echo "  - Un administrador previo mencionó que añadió un disco adicional para expandir el almacenamiento,"
    echo "    pero posiblemente no finalizó la configuración."
    echo
    echo "TAREA:"
    echo "  1. Investigar la configuración de almacenamiento actual de /data."
    echo "  2. Identificar y utilizar cualquier espacio disponible no asignado para expandir el almacenamiento."
    echo "  3. Asegurar que el filesystem refleje el nuevo tamaño sin pérdida de datos."
    echo "  4. Verificar que el montaje persista después de un reinicio."
    echo "  5. Confirmar que /data ahora tiene acceso al espacio total disponible (aprox. tamaño esperado basado en hardware)."
    echo
    echo "=================================================="
    echo "CRITERIOS DE EVALUACIÓN (estilo Red Hat):"
    echo
    echo "✓ El almacenamiento subyacente debe ser extendido para usar al menos el 90% del espacio disponible."
    echo
    echo "✓ El filesystem debe ser redimensionado para usar todo el espacio extendido."
    echo
    echo "✓ El montaje debe persistir después de reinicio (configurado en /etc/fstab)."
    echo
    echo "✓ No debe haber pérdida de datos (verificar archivos existentes en /data)."
    echo
    echo "PISTAS PARA INVESTIGACIÓN:"
    echo "  - Usa comandos como df, lsblk, mount para empezar a mapear el almacenamiento."
    echo "  - Si es LVM: pvs, vgs, lvs para detalles profundos."
    echo "  - Comandos de verificación generales: df -h /data, mount | grep /data, cat /etc/fstab."
    echo
    echo "PUNTOS A CONSIDERAR:"
    echo "  • ¿Cómo identificar si hay espacio no utilizado en la capa de almacenamiento?"
    echo "  • ¿Qué pasos seguir para expandir sin downtime ni pérdida de datos?"
    echo "  • ¿En qué orden: hardware > volumen > filesystem?"
    echo "  • ¿Cómo probar la solución sin reiniciar inmediatamente?"
    echo "=================================================="
} > "$TICKET_FILE"

# Copiar para el estudiante
cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket realista generado correctamente"
echo
echo "El estudiante debe descubrir la estructura LVM y extender LV/FS."