#!/bin/bash
# inject_V2.sh - Resize LVs & Filesystems - Variación 2 (XFS + 3 discos + trampa sutil)
# Ejecutar: sudo bash inject_V2.sh

set -euo pipefail

echo "==> Iniciando setup del laboratorio Resize LVs & Filesystems (V2 - XFS)"

# ============================================
# Seleccionar 3 discos aleatorios sd[b-f]
# ============================================
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[a-f]$/ {print "/dev/"$1}'))

if [[ ${#AVAILABLE_DISKS[@]} -lt 3 ]]; then
    echo "ERROR: Se requieren al menos 3 discos sd[b-f] disponibles para V2"
    exit 1
fi

# Mezclar y tomar 3 discos
SHUFFLED_DISKS=($(printf "%s\n" "${AVAILABLE_DISKS[@]}" | shuf))
DISK1="${SHUFFLED_DISKS[0]}"
DISK2="${SHUFFLED_DISKS[1]}"
DISK3="${SHUFFLED_DISKS[2]}"   # Este será el "nuevo" que se añadió después

echo "Discos seleccionados aleatoriamente:"
echo "  - $DISK1 (original 1)"
echo "  - $DISK2 (original 2)"
echo "  - $DISK3 (añadido recientemente)"

VG="vg_data"
LV="lv_app"
MNT="/app"

# ============================================
# Configuración LVM
# ============================================

# Limpiar discos
wipefs -af "$DISK1" "$DISK2" "$DISK3" &>/dev/null

# Crear PVs
pvcreate -ff -y "$DISK1" "$DISK2" "$DISK3" &>/dev/null

# Recrear VG limpio
vgremove -f "$VG" &>/dev/null || true
vgcreate "$VG" "$DISK1" "$DISK2" &>/dev/null
echo "VG $VG creado con $DISK1 y $DISK2"

# Simular que el LV se creó originalmente con stripe sobre los 2 primeros discos
lvremove -f "/dev/$VG/$LV" &>/dev/null || true
lvcreate -l 30%VG -i 2 -I 64 -n "$LV" "$VG" &>/dev/null   # striped sobre 2 discos
mkfs.xfs -f "/dev/$VG/$LV" &>/dev/null
echo "LV $LV creado (30%VG striped sobre 2 discos) y formateado con XFS"

# Montar temporalmente para poblar datos
mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"



# ============================================
# Ticket realista V2
# ============================================
TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Troubleshooting Lab     "
    echo "=================================================="
    echo "Variación:        Resize LVs & Filesystems - Nivel 2 (XFS)"
    echo "Escenario:        La aplicación de negocio está fallando porque no puede escribir"
    echo "                  más datos en /app. El equipo de infraestructura añadió un disco"
    echo "                  nuevo la semana pasada para resolverlo, pero el problema persiste."
    echo
    echo "DESCRIPCIÓN DEL PROBLEMA:"
    echo "  - Los logs muestran errores de 'No space left on device' al intentar escribir en /app."
    echo "  - Los desarrolladores confirman que el directorio está casi lleno."
    echo "  - Existe evidencia de que se añadió capacidad física recientemente."
    echo
    echo "TAREA:"
    echo "  1. Diagnosticar por qué /app no tiene más espacio disponible a pesar del nuevo hardware."
    echo "  2. Extender el almacenamiento disponible sin pérdida de datos ni downtime significativo."
    echo "  3. Asegurar que el filesystem use todo el nuevo espacio."
    echo "  4. Verificar integridad de los datos existentes y persistencia del montaje."
    echo
    echo "=================================================="
    echo "CRITERIOS DE EVALUACIÓN (estilo Red Hat):"
    echo
    echo "✓ El volumen lógico debe usar al menos el 90% del espacio total del VG"
    echo "✓ El filesystem XFS debe reflejar el tamaño completo del LV extendido"
    echo "✓ Operación realizada online (sin desmontar /app)"
    echo "✓ Datos existentes en /app intactos (archivos, logs, backups)"
    echo "✓ Montaje persistente configurado correctamente"
    echo
    echo "PISTAS PARA INVESTIGACIÓN:"
    echo "  - Comienza con: df -h /app, df -i /app, mount | grep /app"
    echo "  - Revisa el stack LVM completo: pvs, vgs, lvs -o +lv_stripes,segtype"
    echo "  - Identifica el tipo de filesystem (importante para el comando de resize)"
    echo
    echo "PUNTOS A CONSIDERAR:"
    echo "  • ¿Qué comando se usa para crecer un filesystem XFS?"
    echo "  • ¿Se puede reducir un XFS online? ¿Por qué importa saberlo?"
    echo "  • ¿Vale la pena restripear el LV para incluir el nuevo disco?"
    echo "  • ¿Cómo confirmar que no hubo corrupción tras la operación?"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket V2 (XFS) generado en /home/student/lab_ticket.txt"
echo
echo "=== RESUMEN DEL SETUP (solo para ti) ==="
echo "Discos: $DISK1, $DISK2 (originales, striped), $DISK3 (nuevo añadido)"
echo "VG: $VG"
echo "LV: $LV (1G inicial, striped sobre 2 discos, XFS)"
echo "Montaje: $MNT con datos reales y ~850M usados"
echo "El estudiante debe extender el LV con el espacio libre del VG y luego"
echo "crecer el filesystem XFS en línea (lvextend + xfs_growfs)."


# ============================================
# Simular uso real y datos importantes
# ============================================
echo "==> Simulando datos de aplicación en $MNT"
mkdir -p "$MNT"/{logs,uploads,config,backup}

echo "Aplicación XYZ - Datos críticos" > "$MNT/config/app.conf"
echo "$(date) - Sistema iniciado" > "$MNT/logs/startup.log"

# Crear varios archivos para simular uso real
for i in {1..20}; do
    dd if=/dev/urandom of="$MNT/uploads/file_$i.dat" bs=1M count=$((RANDOM % 30 + 10)) status=none 2>/dev/null
done

# Archivo grande para llenar casi todo el LV
FS_SIZE_MB=$(df -m "$MNT" | awk 'NR==2 {print $2}')
FILL_MB=$(( FS_SIZE_MB * 90 / 100 ))

dd if=/dev/zero of="$MNT/backup/full_backup.img" bs=1M count=$FILL_MB status=none
sync


umount "$MNT"

# ============================================
# Simular el "administrador anterior" que añadió el tercer disco pero no terminó
# ============================================
vgextend "$VG" "$DISK3" &>/dev/null
echo "VG $VG extendido con $DISK3 (disco nuevo añadido, pero LV no tocado)"

# Montaje persistente
mount "/dev/$VG/$LV" "$MNT"
UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID $MNT xfs defaults 0 0" >> /etc/fstab
    echo "Montaje persistente configurado en /etc/fstab"
fi

echo "==> Setup V2 completado"