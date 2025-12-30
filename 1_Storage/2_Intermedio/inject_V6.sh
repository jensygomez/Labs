#!/bin/bash
# inject_V6.sh - VDO (Virtual Data Optimizer) Troubleshooting & Expansion - Nivel 6 (Intermedio)
# Ejecutar: sudo bash inject_V6.sh
# Requiere al menos 3 discos sd[a-f] disponibles

set -euo pipefail

echo "==> Iniciando setup del laboratorio V6 - VDO + Expansion/Troubleshooting"

# ============================================
# Seleccionar 3 discos aleatorios sd[a-f]
# ============================================
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[a-f]$/ {print "/dev/"$1}'))

if [[ ${#AVAILABLE_DISKS[@]} -lt 3 ]]; then
    echo "ERROR: V6 requiere al menos 3 discos sd[a-f]"
    exit 1
fi

SHUFFLED_DISKS=($(printf "%s\n" "${AVAILABLE_DISKS[@]}" | shuf))
DISK1="${SHUFFLED_DISKS[0]}"
DISK2="${SHUFFLED_DISKS[1]}"
DISK3="${SHUFFLED_DISKS[2]}"   # Disco nuevo añadido pero no usado

echo "Discos seleccionados:"
echo "  - $DISK1 y $DISK2 → originales en el VG"
echo "  - $DISK3 → nuevo añadido recientemente"

VG="vg_vdo"
VDO_NAME="vdo_data"
LV_PHYS="lv_vdo_phys"
LV_VIRT="lv_vdo_virt"
MNT="/data/vdo"

# ============================================
# Limpiar y preparar LVM
# ============================================
wipefs -af "$DISK1" "$DISK2" "$DISK3" &>/dev/null
pvcreate -ff -y "$DISK1" "$DISK2" &>/dev/null

vgremove -f "$VG" &>/dev/null || true
vgcreate "$VG" "$DISK1" "$DISK2" &>/dev/null
echo "VG $VG creado con dos discos"

lvremove -f "$VG/$LV_PHYS" &>/dev/null || true
lvcreate -l 30%VG -n "$LV_PHYS" "$VG" &>/dev/null
echo "LV físico $LV_PHYS creado (30%VG)"

# ============================================
# Crear VDO sobre el LV físico (logical size = 3x physical para overprovisioning)
# ============================================
PHYS_SIZE_G=$(lvs --units g -o lv_size --noheadings "/dev/$VG/$LV_PHYS" | awk '{print int($1)}')
LOGICAL_SIZE_G=$(( PHYS_SIZE_G * 3 ))  # 3x para simular overprovisioning adaptable

vdo remove --name="$VDO_NAME" &>/dev/null || true
vdo create --name="$VDO_NAME" --device="/dev/$VG/$LV_PHYS" --vdoLogicalSize="${LOGICAL_SIZE_G}G" --verbose &>/dev/null
echo "VDO $VDO_NAME creado con tamaño lógico ${LOGICAL_SIZE_G}G (3x physical)"

# ============================================
# Crear LV virtual sobre VDO (igual al logical size)
# ============================================
lvremove -f "$VG/$LV_VIRT" &>/dev/null || true
lvcreate -L "${LOGICAL_SIZE_G}G" -T "$VG/$LV_VIRT" -V /dev/mapper/"$VDO_NAME" &>/dev/null
mkfs.xfs -f "/dev/$VG/$LV_VIRT" &>/dev/null
echo "LV virtual $LV_VIRT creado sobre VDO y formateado con XFS"

# ============================================
# Montar y poblar con datos realistas (duplicados para simular dedup)
# ============================================
mkdir -p "$MNT"
mount "/dev/$VG/$LV_VIRT" "$MNT"

echo "==> Simulando datos con duplicación/compresión para VDO"
mkdir -p "$MNT"/{archive,logs,backup,duplicates}

echo "VDO_APP=active" > "$MNT/config/vdo.conf"
echo "$(date) - System log" > "$MNT/logs/system.log"

# Crear archivos duplicados para dedup
for i in {1..10}; do
    dd if=/dev/urandom of="$MNT/archive/base_file.bin" bs=1M count=50 status=none 2>/dev/null
    cp "$MNT/archive/base_file.bin" "$MNT/duplicates/dup_$i.bin"
done

# Llenar casi todo el espacio lógico (90%)
FS_SIZE_MB=$(df -m "$MNT" | awk 'NR==2 {print $2}')
FILL_MB=$(( FS_SIZE_MB * 90 / 100 ))

dd if=/dev/zero of="$MNT/backup/compressible_data.img" bs=1M count=$FILL_MB status=none
sync

umount "$MNT"

# ============================================
# Simular admin anterior: añadió disco nuevo pero no extendió VDO
# ============================================
pvcreate -ff -y "$DISK3" &>/dev/null
vgextend "$VG" "$DISK3" &>/dev/null
echo "Disco nuevo $DISK3 añadido al VG (pero ni LV físico ni VDO extendidos)"

# ============================================
# Montaje persistente
# ============================================
mount "/dev/$VG/$LV_VIRT" "$MNT"
UUID=$(blkid -s UUID -o value "/dev/$VG/$LV_VIRT")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID $MNT xfs defaults 0 0" >> /etc/fstab
    echo "Montaje persistente configurado"
fi

echo "==> Setup V6 completado"

# ============================================
# Ticket realista V6
# ============================================
TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Lab - Nivel 6 (Intermedio)     "
    echo "=================================================="
    echo "Variación:        VDO Deduplication/Compression Troubleshooting"
    echo "Escenario:        El almacenamiento optimizado para backups y archivos duplicados"
    echo "                  está reportando falta de espacio en /data/vdo."
    echo "                  La aplicación de archiving falla al escribir nuevos datos."
    echo "                  Se añadió un disco nuevo recientemente para ampliar capacidad."
    echo
    echo "DESCRIPCIÓN DEL PROBLEMA:"
    echo "  - df -h /data/vdo muestra casi lleno (~90%)."
    echo "  - Los logs muestran 'No space left on device' a pesar de compresión/deduplicación activa."
    echo "  - VDO se usa para optimizar espacio con datos redundantes."
    echo
    echo "TAREA:"
    echo "  1. Diagnosticar el stack de almacenamiento VDO completo de /data/vdo."
    echo "  2. Extender el VDO utilizando el nuevo disco añadido."
    echo "  3. Asegurar que el tamaño lógico refleje la expansión sin pérdida de datos."
    echo "  4. Verificar integridad, deduplicación y persistencia post-expansión."
    echo
    echo "=================================================="
    echo "CRITERIOS DE EVALUACIÓN (estilo Red Hat):"
    echo
    echo "✓ LV subyacente (físico) extendido usando el nuevo espacio del VG"
    echo "✓ VDO físico y lógico redimensionados correctamente"
    echo "✓ Filesystem XFS crecido para usar el nuevo tamaño lógico"
    echo "✓ Operación online (sin desmontar /data/vdo)"
    echo "✓ Datos existentes intactos y deduplicación funcional"
    echo "✓ Montaje persistente configurado"
    echo
    echo "PISTAS PARA INVESTIGACIÓN:"
    echo "  - df -h /data/vdo, mount | grep /data/vdo, vdostats --human-readable"
    echo "  - lvs, vgs, pvs, dmsetup status"
    echo "  - Verifica VDO: vdo status --name=vdo_data"
    echo
    echo "PUNTOS A CONSIDERAR:"
    echo "  • ¿En qué orden se extiende: LV físico → VDO físico → VDO lógico → FS?"
    echo "  • ¿Se puede hacer todo online?"
    echo "  • ¿Qué comandos redimensionan VDO (growPhysical, growLogical)?"
    echo "  • ¿Cómo verificar ahorros de dedup/compresión post-operación?"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket V6 (VDO) generado en /home/student/lab_ticket.txt"
echo
echo "=== RESUMEN DEL SETUP (solo para ti) ==="
echo "Discos: $DISK1, $DISK2 (originales), $DISK3 (nuevo)"
echo "VG: $VG"
echo "LV físico: $LV_PHYS (30%VG inicial)"
echo "VDO: $VDO_NAME (lógico ~${LOGICAL_SIZE_G}G, basado en 3x physical)"
echo "LV virtual: $LV_VIRT (sobre VDO)"
echo "Montaje: $MNT con datos duplicados/comprimibles"
echo "Solución típica:"
echo "  lvextend -l +100%FREE /dev/$VG/$LV_PHYS"
echo "  vdo growPhysical --name=$VDO_NAME"
echo "  vdo growLogical --name=$VDO_NAME --vdoLogicalSize=<nuevo_tamaño>G  # e.g., 2-3x new physical"
echo "  xfs_growfs $MNT"