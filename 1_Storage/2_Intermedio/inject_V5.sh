#!/bin/bash
# inject_V5.sh - Stratis Storage Management + Resize/Troubleshooting - Nivel 5 (Intermedio)
# Ejecutar: sudo bash inject_V5.sh
# Requiere al menos 3 discos sd[a-f] disponibles

set -euo pipefail

echo "==> Iniciando setup del laboratorio V5 - Stratis + Resize/Troubleshooting"

# ============================================
# Seleccionar 3 discos aleatorios sd[a-f]
# ============================================
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[a-f]$/ {print "/dev/"$1}'))

if [[ ${#AVAILABLE_DISKS[@]} -lt 3 ]]; then
    echo "ERROR: V5 requiere al menos 3 discos sd[a-f]"
    exit 1
fi

SHUFFLED_DISKS=($(printf "%s\n" "${AVAILABLE_DISKS[@]}" | shuf))
DISK1="${SHUFFLED_DISKS[0]}"
DISK2="${SHUFFLED_DISKS[1]}"
DISK3="${SHUFFLED_DISKS[2]}"   # Disco nuevo añadido pero no usado aún

echo "Discos seleccionados:"
echo "  - $DISK1 y $DISK2 → originales en el pool Stratis"
echo "  - $DISK3 → nuevo añadido recientemente"

STRATIS_POOL="stratis_pool_secure"
STRATIS_FS="stratis_fs_app"
MNT="/stratis/app"

# ============================================
# Limpiar discos y detener Stratis si existe
# ============================================
wipefs -af "$DISK1" "$DISK2" "$DISK3" &>/dev/null

systemctl restart stratisd 2>/dev/null || systemctl start stratisd

# Eliminar cualquier configuración previa de Stratis
stratis pool destroy "$STRATIS_POOL" &>/dev/null || true

# ============================================
# Crear pool Stratis con los dos primeros discos
# ============================================
stratis pool create "$STRATIS_POOL" "$DISK1" "$DISK2"
echo "Stratis pool $STRATIS_POOL creado con $DISK1 y $DISK2"

# Crear filesystem Stratis inicial (30% del pool aproximadamente)
stratis fs create "$STRATIS_POOL" "$STRATIS_FS"
echo "Stratis filesystem $STRATIS_FS creado"

# ============================================
# Montar y poblar con datos realistas
# ============================================
mkdir -p "$MNT"
mount "/stratis/$STRATIS_POOL/$STRATIS_FS" "$MNT"

echo "==> Simulando datos de aplicación moderna en $MNT"
mkdir -p "$MNT"/{data,logs,config,cache,backup}

echo "STRATIS_APP=production" > "$MNT/config/app.conf"
echo "$(date) - Service started" > "$MNT/logs/service.log"

# Crear varios archivos para simular uso real
for i in {1..30}; do
    dd if=/dev/urandom of="$MNT/data/file_$i.bin" bs=1M count=$((RANDOM % 40 + 10)) status=none 2>/dev/null
done

# Llenar casi todo el filesystem (90%)
FS_SIZE_MB=$(df -m "$MNT" | awk 'NR==2 {print $2}')
FILL_MB=$(( FS_SIZE_MB * 90 / 100 ))

dd if=/dev/zero of="$MNT/backup/large_dataset.img" bs=1M count=$FILL_MB status=none
sync

umount "$MNT"

# ============================================
# Simular admin anterior: añadió disco nuevo al sistema pero olvidó agregarlo al pool
# ============================================
echo "Disco nuevo $DISK3 disponible en el sistema, pero NO agregado al pool Stratis"

# ============================================
# Configurar montaje persistente vía /etc/fstab (usando UUID de Stratis)
# =========================================
mount "/stratis/$STRATIS_POOL/$STRATIS_FS" "$MNT"
STRATIS_UUID=$(blkid -s UUID -o value "/stratis/$STRATIS_POOL/$STRATIS_FS")

if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$STRATIS_UUID $MNT xfs defaults,x-systemd.requires=stratisd.service 0 0" >> /etc/fstab
    echo "Montaje persistente configurado en /etc/fstab con dependencia de stratisd"
fi

echo "==> Setup V5 completado"

# ============================================
# Ticket realista V5
# ============================================
TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Lab - Nivel 5 (Intermedio)     "
    echo "=================================================="
    echo "Variación:        Stratis Storage Troubleshooting & Expansion"
    echo "Escenario:        Una aplicación containerizada moderna está fallando al escribir"
    echo "                  datos en /stratis/app por falta de espacio en disco."
    echo "                  El equipo de infraestructura añadió un nuevo disco físico hace unos días"
    echo "                  para ampliar la capacidad, pero el problema sigue ocurriendo."
    echo
    echo "DESCRIPCIÓN DEL PROBLEMA:"
    echo "  - Los pods/containers reportan 'No space left on device'."
    echo "  - df -h /stratis/app muestra el volumen casi lleno."
    echo "  - La empresa está migrando de LVM tradicional a Stratis para gestión simplificada."
    echo
    echo "TAREA:"
    echo "  1. Diagnosticar el stack de almacenamiento actual de /stratis/app."
    echo "  2. Identificar y utilizar el disco nuevo añadido para expandir la capacidad."
    echo "  3. Extender el almacenamiento disponible sin pérdida de datos ni downtime significativo."
    echo "  4. Verificar que el filesystem refleje todo el nuevo espacio y que los datos estén intactos."
    echo
    echo "=================================================="
    echo "CRITERIOS DE EVALUACIÓN (estilo Red Hat):"
    echo
    echo "✓ El pool Stratis debe incluir el nuevo disco físico"
    echo "✓ El pool debe usar al menos el 90% de la capacidad total disponible"
    echo "✓ El filesystem Stratis debe reflejar automáticamente el tamaño extendido"
    echo "✓ Operación realizada online (sin desmontar /stratis/app)"
    echo "✓ Datos existentes en /stratis/app intactos"
    echo "✓ Montaje persistente configurado correctamente y funcional tras reinicio"
    echo
    echo "PISTAS PARA INVESTIGACIÓN:"
    echo "  - Comienza con: df -h /stratis/app, mount | grep stratis, blkid"
    echo "  - Comandos clave de Stratis: stratis pool list, stratis blockdev list, stratis fs list"
    echo "  - Revisa discos no utilizados: lsblk, stratis blockdev list --available"
    echo "  - Documentación útil: man stratis-cli o stratis --help"
    echo
    echo "PUNTOS A CONSIDERAR:"
    echo "  • ¿Cómo se añade un nuevo disco a un pool Stratis existente?"
    echo "  • ¿Stratis redimensiona automáticamente el filesystem tras extender el pool?"
    echo "  • ¿Qué diferencias clave hay entre Stratis y LVM tradicional en este escenario?"
    echo "  • ¿Cómo confirmar que stratisd está corriendo y sano?"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket V5 (Stratis) generado en /home/student/lab_ticket.txt"
echo
echo "=== RESUMEN DEL SETUP (solo para ti) ==="
echo "Discos: $DISK1, $DISK2 (en pool Stratis), $DISK3 (nuevo, disponible pero no agregado)"
echo "Pool Stratis: $STRATIS_POOL"
echo "Filesystem Stratis: $STRATIS_FS"
echo "Montaje: $MNT con datos reales y uso simulado al ~90%"
echo "Solución típica:"
echo "  stratis pool add-data $STRATIS_POOL $DISK3"
echo "  (Stratis extiende automáticamente el filesystem XFS subyacente)"
echo "  Verificar con: df -h $MNT y stratis pool list"