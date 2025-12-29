#!/bin/bash
# inject_V3.sh - Thin Provisioning + Snapshot Troubleshooting - Nivel 3
# Ejecutar: sudo bash inject_V3.sh
# Requiere al menos 4 discos sd[b-f] disponibles

set -euo pipefail

echo "==> Iniciando setup del laboratorio V3 - Thin LV + Snapshot (Intermedio)"

# ============================================
# Seleccionar 4 discos aleatorios
# ============================================
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/"$1}'))

if [[ ${#AVAILABLE_DISKS[@]} -lt 4 ]]; then
    echo "ERROR: V3 requiere al menos 4 discos sd[b-f] disponibles"
    exit 1
fi

SHUFFLED_DISKS=($(printf "%s\n" "${AVAILABLE_DISKS[@]}" | shuf))
DISK1="${SHUFFLED_DISKS[0]}"
DISK2="${SHUFFLED_DISKS[1]}"
DISK3="${SHUFFLED_DISKS[2]}"
DISK4="${SHUFFLED_DISKS[3]}"   # Este será el disco "nuevo" añadido recientemente

echo "Discos seleccionados:"
echo "  - $DISK1, $DISK2, $DISK3 → para el thin pool original"
echo "  - $DISK4 → disco nuevo añadido pero no usado aún"

VG="vg_app"
POOL="thinpool"
THIN_LV="lv_app"
SNAP_LV="lv_app_snap_old"
MNT="/opt/app"

# ============================================
# Limpiar y preparar
# ============================================
wipefs -af "$DISK1" "$DISK2" "$DISK3" "$DISK4" &>/dev/null
pvcreate -ff -y "$DISK1" "$DISK2" "$DISK3" "$DISK4" &>/dev/null

vgremove -f "$VG" &>/dev/null || true
vgcreate "$VG" "$DISK1" "$DISK2" "$DISK3" &>/dev/null
echo "VG $VG creado con 3 discos"

# ============================================
# Crear thin pool y thin LV
# ============================================
lvremove -f "$VG/$POOL" &>/dev/null || true
lvcreate -L 12G -T "$VG/$POOL" &>/dev/null
lvcreate -V 20G --thinpool "$VG/$POOL" -n "$THIN_LV" &>/dev/null
mkfs.xfs -f "/dev/$VG/$THIN_LV" &>/dev/null
echo "Thin pool $POOL (12G) y thin LV $THIN_LV (virtual 20G) creados con XFS"

# Montar y poblar con datos realistas
mkdir -p "$MNT"
mount "/dev/$VG/$THIN_LV" "$MNT"

echo "==> Poblando datos de aplicación crítica"
mkdir -p "$MNT"/{db,data,logs,config,cache}
echo "DB_PROD=active" > "$MNT/config/database.conf"
echo "$(date) - App started" > "$MNT/logs/app.log"

# Simular datos que cambian con el tiempo
dd if=/dev/urandom of="$MNT/db/main.db" bs=1M count=800 status=none
dd if=/dev/urandom of="$MNT/data/archive.tar.gz" bs=1M count=600 status=none
for i in {1..50}; do
    dd if=/dev/urandom of="$MNT/cache/session_$i.dat" bs=512K count=1 status=none 2>/dev/null
done
sync
umount "$MNT"

# ============================================
# Crear snapshot "olvidado" y simular cambios posteriores
# ============================================
lvcreate -s -n "$SNAP_LV" -L 4G "/dev/$VG/$THIN_LV" &>/dev/null
echo "Snapshot $SNAP_LV creado (simulando backup antiguo)"

# Montar thin LV de nuevo y SIMULAR cambios POST-snapshot (COW)
mount "/dev/$VG/$THIN_LV" "$MNT"
echo "==> Simulando 6 meses de cambios en la app (llenando el snapshot via COW)"
dd if=/dev/urandom of="$MNT/db/main.db" seek=800 bs=1M count=1200 conv=notrunc status=none
dd if=/dev/zero of="$MNT/data/new_large_file.img" bs=1M count=3000 status=none
rm -f "$MNT/cache/session_"*.dat  # borrar archivos antiguos
sync
umount "$MNT"

# ============================================
# Añadir disco nuevo (pero no extender el pool aún)
# ============================================
vgextend "$VG" "$DISK4" &>/dev/null
echo "Disco nuevo $DISK4 añadido al VG, pero thin pool NO extendido"

# Montaje persistente del thin LV principal
mount "/dev/$VG/$THIN_LV" "$MNT"
UUID=$(blkid -s UUID -o value "/dev/$VG/$THIN_LV")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID $MNT xfs defaults 0 0" >> /etc/fstab
fi

echo "==> Setup V3 completado"

# ============================================
# Ticket realista V3
# ============================================
TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Advanced Storage Lab - Nivel 3     "
    echo "=================================================="
    echo "Variación:        Thin Provisioning + Snapshot Troubleshooting"
    echo "Escenario:        La aplicación de producción crítica está fallando intermitentemente"
    echo "                  con errores 'No space left on device' al escribir en /opt/app."
    echo "                  El equipo de infraestructura añadió un disco nuevo hace unos días,"
    echo "                  pero el problema comenzó hace semanas."
    echo
    echo "DESCRIPCIÓN DEL PROBLEMA:"
    echo "  - Los desarrolladores reportan que no pueden crear archivos grandes en /opt/app."
    echo "  - df -h /opt/app muestra espacio libre, pero operaciones de escritura fallan."
    echo "  - Existe un snapshot antiguo que se creó antes de una actualización mayor."
    echo
    echo "TAREA:"
    echo "  1. Diagnosticar la causa raíz del problema de espacio."
    echo "  2. Liberar o manejar adecuadamente el espacio bloqueado."
    echo "  3. Utilizar el nuevo disco añadido para proveer capacidad permanente."
    echo "  4. Asegurar que la aplicación tenga espacio suficiente a largo plazo."
    echo "  5. Verificar integridad de datos y que no haya más riesgo de overflow."
    echo
    echo "=================================================="
    echo "CRITERIOS DE EVALUACIÓN (estilo Red Hat):"
    echo
    echo "✓ Causa raíz identificada (thin pool lleno por snapshot)"
    echo "✓ Snapshot manejado correctamente (merge o remove seguro)"
    echo "✓ Thin pool extendido usando el nuevo disco"
    echo "✓ Thin LV con tamaño virtual aumentado o pool con espacio libre >30%"
    echo "✓ Datos en /opt/app intactos y aplicación funcional"
    echo "✓ Monitoreo básico sugerido (ej: alerta si pool >80%)"
    echo
    echo "PISTAS PARA INVESTIGACIÓN:"
    echo "  - df -h /opt/app vs lvs -o +data_percent,metadata_percent"
    echo "  - lvs -a (ver LVs ocultos como [thinpool_tdata], snapshots)"
    echo "  - vgs para ver espacio libre en VG"
    echo "  - dmsetup status o lvs --segments para detalles profundos"
    echo
    echo "PUNTOS A CONSIDERAR:"
    echo "  • ¿Por qué df muestra espacio pero escribe fallan?"
    echo "  • ¿Es seguro mergear un snapshot antiguo con muchos cambios?"
    echo "  • ¿Remove vs merge? ¿Cuál eliges y por qué?"
    echo "  • ¿Cómo evitar esto en el futuro?"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket V3 generado en /home/student/lab_ticket.txt"
echo
echo "=== RESUMEN DEL SETUP (solo para ti) ==="
echo "VG: $VG (3 discos originales + $DISK4 nuevo)"
echo "Thin pool: $POOL (12G físico, casi lleno por COW del snapshot)"
echo "Thin LV: $THIN_LV (virtual 20G, montado en $MNT)"
echo "Snapshot olvidado: $SNAP_LV (consumiendo casi todo el pool libre)"
echo "Solución típica: gestionar snapshots y ampliar correctamente el thin pool antes de crecer el thin LV."