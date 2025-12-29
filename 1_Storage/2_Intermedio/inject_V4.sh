#!/bin/bash
# inject_V4.sh - LUKS over LVM + Resize Encrypted Volume - Nivel 4 (Intermedio)
# Ejecutar: sudo bash inject_V4.sh
# Requiere al menos 3 discos sd[b-f] disponibles

set -euo pipefail

echo "==> Iniciando setup del laboratorio V4 - LUKS sobre LVM + Resize"

# ============================================
# Seleccionar 3 discos aleatorios
# ============================================
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[b-f]$/ {print "/dev/"$1}'))

if [[ ${#AVAILABLE_DISKS[@]} -lt 3 ]]; then
    echo "ERROR: V4 requiere al menos 3 discos sd[b-f]"
    exit 1
fi

SHUFFLED_DISKS=($(printf "%s\n" "${AVAILABLE_DISKS[@]}" | shuf))
DISK1="${SHUFFLED_DISKS[0]}"
DISK2="${SHUFFLED_DISKS[1]}"
DISK3="${SHUFFLED_DISKS[2]}"   # Disco nuevo añadido pero no usado

echo "Discos seleccionados:"
echo "  - $DISK1 y $DISK2 → originales en el VG"
echo "  - $DISK3 → nuevo añadido recientemente"

VG="vg_secure"
LV="lv_encrypted"
CRYPT_NAME="crypt_data"
MNT="/var/sensitive"
PASS_PHRASE="ex200lab"   # Contraseña fija para el lab (en producción nunca así)

# ============================================
# Limpiar y preparar LVM
# ============================================
wipefs -af "$DISK1" "$DISK2" "$DISK3" &>/dev/null
pvcreate -ff -y "$DISK1" "$DISK2" &>/dev/null

vgremove -f "$VG" &>/dev/null || true
vgcreate "$VG" "$DISK1" "$DISK2" &>/dev/null
echo "VG $VG creado con dos discos"

lvremove -f "$VG/$LV" &>/dev/null || true
lvcreate -l 30%VG -n "$LV" "$VG" &>/dev/null
echo "LV $LV creado (30% del VG)"


# ============================================
# Crear LUKS sobre el LV
# ============================================
echo "$PASS_PHRASE" | cryptsetup luksFormat -q --type luks2 "/dev/$VG/$LV" -
echo "$PASS_PHRASE" | cryptsetup open "/dev/$VG/$LV" "$CRYPT_NAME" -

mkfs.xfs "/dev/mapper/$CRYPT_NAME" &>/dev/null
echo "Contenedor LUKS creado y formateado con XFS"

# ============================================
# Montar y poblar con datos sensibles realistas
# ============================================
mkdir -p "$MNT"
mount "/dev/mapper/$CRYPT_NAME" "$MNT"

echo "==> Simulando datos regulados/sensibles"
mkdir -p "$MNT"/{patient_records,financial,logs,backup}

echo "GDPR_COMPLIANT=true" > "$MNT/config/compliance.conf"
echo "Patient ID,Name,Diagnosis" > "$MNT/patient_records/patients.csv"
for i in {1..500}; do
    echo "$i,Patient_$i,Condition_$(shuf -i 1-20 -n 1)" >> "$MNT/patient_records/patients.csv"
done

# Llenar casi todo el espacio
dd if=/dev/zero of="$MNT/backup/large_encrypted_backup.img" bs=1M count=3200 status=none
sync

umount "$MNT"
cryptsetup close "$CRYPT_NAME"

# ============================================
# Simular admin anterior: añadió disco nuevo pero no extendió nada
# ============================================
pvcreate -ff -y "$DISK3" &>/dev/null
vgextend "$VG" "$DISK3" &>/dev/null
echo "Disco nuevo $DISK3 añadido al VG (pero ni LV ni LUKS extendidos)"

# ============================================
# Configurar apertura automática al boot (con passphrase en archivo para lab)
# ============================================
mkdir -p /etc/luks
echo "$PASS_PHRASE" > /etc/luks/crypt_data.key
chmod 600 /etc/luks/crypt_data.key

# Añadir a /etc/crypttab
if ! grep -q "$CRYPT_NAME" /etc/crypttab; then
    echo "$CRYPT_NAME UUID=$(blkid -s UUID -o value /dev/$VG/$LV) /etc/luks/crypt_data.key luks" >> /etc/crypttab
fi

# Añadir montaje persistente en fstab
UUID_FS=$(blkid -s UUID -o value "/dev/mapper/$CRYPT_NAME")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID_FS $MNT xfs defaults 0 0" >> /etc/fstab
fi

# Abrir y montar para dejar el sistema listo
echo "$PASS_PHRASE" | cryptsetup open "/dev/$VG/$LV" "$CRYPT_NAME" -
mount "/dev/mapper/$CRYPT_NAME" "$MNT"

echo "==> Setup V4 completado"

# ============================================
# Ticket realista V4
# ============================================
TICKET_FILE="/tmp/current_lab_ticket.txt"

{
    echo "=================================================="
    echo "     RHCSA EX200 - Storage Lab - Nivel 4 (Intermedio)     "
    echo "=================================================="
    echo "Variación:        LUKS Encrypted LVM Resize"
    echo "Escenario:        El sistema de datos sensibles regulados está reportando"
    echo "                  errores de espacio insuficiente en /var/sensitive."
    echo "                  La aplicación asociada está fallando al guardar nuevos registros."
    echo "                  Se añadió capacidad física adicional hace una semana."
    echo
    echo "DESCRIPCIÓN DEL PROBLEMA:"
    echo "  - df -h /var/sensitive muestra casi lleno (~90-95%)."
    echo "  - Los logs de la aplicación muestran 'No space left on device'."
    echo "  - Los datos son sensibles y deben permanecer encriptados."
    echo
    echo "TAREA:"
    echo "  1. Diagnosticar el stack de almacenamiento completo de /var/sensitive."
    echo "  2. Extender el almacenamiento disponible manteniendo el cifrado."
    echo "  3. Asegurar que el volumen encriptado use la nueva capacidad."
    echo "  4. Verificar integridad de los datos existentes y funcionamiento post-expansión."
    echo
    echo "=================================================="
    echo "CRITERIOS DE EVALUACIÓN (estilo Red Hat):"
    echo
    echo "✓ LV subyacente extendido usando el nuevo espacio del VG"
    echo "✓ Contenedor LUKS redimensionado correctamente"
    echo "✓ Filesystem XFS crecido para usar todo el espacio nuevo"
    echo "✓ Operación realizada online (sin desmontar ni cerrar LUKS si es posible)"
    echo "✓ Datos sensibles intactos"
    echo "✓ Apertura y montaje persisten tras reinicio"
    echo
    echo "PISTAS PARA INVESTIGACIÓN:"
    echo "  - lsblk, df -h, mount, cryptsetup status, dmsetup table"
    echo "  - lvs, vgs, pvs"
    echo "  - /etc/crypttab y /etc/fstab"
    echo
    echo "PUNTOS A CONSIDERAR:"
    echo "  • ¿En qué orden se extiende: LV → LUKS → FS o viceversa?"
    echo "  • ¿Se puede hacer todo online?"
    echo "  • ¿Qué comando redimensiona un contenedor LUKS abierto?"
    echo "  • ¿Cómo verificar que el cifrado sigue activo?"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket V4 generado en /home/student/lab_ticket.txt"
echo
echo "=== RESUMEN DEL SETUP (solo para ti) ==="
echo "VG: $VG (original: $DISK1+$DISK2, nuevo: +$DISK3)"
echo "LV: $LV (4G inicial)"
echo "LUKS: /dev/mapper/$CRYPT_NAME (casi lleno)"
echo "Montaje: $MNT con datos sensibles y ~3.2G usados"
echo "Passphrase: ex200lab (en /etc/luks/crypt_data.key)"
echo "Solución típica:"
echo "  lvextend -l +100%FREE /dev/$VG/$LV"
echo "  cryptsetup resize $CRYPT_NAME"
echo "  xfs_growfs $MNT"