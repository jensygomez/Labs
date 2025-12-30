#!/bin/bash
# inject_V4.sh - LUKS over LVM + Resize Encrypted Volume - Nivel 4 (Intermedio)
# Ejecutar: sudo bash inject_V4.sh
# Requiere al menos 3 discos sd[a-f] disponibles

set -euo pipefail

echo "==> Iniciando setup del laboratorio V4 - LUKS sobre LVM + Resize"

# ============================================
# Seleccionar 3 discos aleatorios sd[a-f]
# ============================================
AVAILABLE_DISKS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^sd[a-f]$/ {print "/dev/"$1}'))

if [[ ${#AVAILABLE_DISKS[@]} -lt 3 ]]; then
    echo "ERROR: V4 requiere al menos 3 discos sd[a-f]"
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
echo "LV $LV creado (30%VG)"

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

# Crear varios archivos para simular uso real
for i in {1..20}; do
    dd if=/dev/urandom of="$MNT/backup/file_$i.dat" bs=1M count=$((RANDOM % 30 + 10)) status=none 2>/dev/null
done

# Llenar casi todo el LV (90%)
FS_SIZE_MB=$(df -m "$MNT" | awk 'NR==2 {print $2}')
FILL_MB=$(( FS_SIZE_MB * 90 / 100 ))

dd if=/dev/zero of="$MNT/backup/large_encrypted_backup.img" bs=1M count=$FILL_MB status=none
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
echo "$PASS_PHRASE" | cryptsetup open "/dev/$VG/$LV" "$CRYPT_NAME" -
UUID_FS=$(blkid -s UUID -o value "/dev/mapper/$CRYPT_NAME")
if ! grep -q "$MNT" /etc/fstab; then
    echo "UUID=$UUID_FS $MNT xfs defaults 0 0" >> /etc/fstab
fi

# Abrir y montar para dejar el sistema listo
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
    echo "  - Los logs muestran errores de 'No space left on device' al intentar escribir en /var/sensitive."
    echo "  - Los desarrolladores confirman que el directorio está casi lleno."
    echo "  - Existe evidencia de que se añadió capacidad física recientemente."
    echo "  - Los datos son sensibles y deben permanecer encriptados."
    echo
    echo "TAREA:"
    echo "  1. Diagnosticar por qué /var/sensitive no tiene más espacio disponible a pesar del nuevo hardware."
    echo "  2. Extender el almacenamiento disponible manteniendo el cifrado, sin pérdida de datos ni downtime significativo."
    echo "  3. Asegurar que el filesystem use todo el nuevo espacio."
    echo "  4. Verificar integridad de los datos existentes y persistencia del montaje."
    echo
    echo "=================================================="
    echo "CRITERIOS DE EVALUACIÓN (estilo Red Hat):"
    echo
    echo "✓ El volumen lógico debe usar al menos el 90% del espacio total del VG"
    echo "✓ El contenedor LUKS debe reflejar el tamaño completo del LV extendido"
    echo "✓ El filesystem XFS debe reflejar el tamaño completo del contenedor LUKS extendido"
    echo "✓ Operación realizada online (sin desmontar /var/sensitive)"
    echo "✓ Datos existentes en /var/sensitive intactos (archivos, logs, backups)"
    echo "✓ Montaje persistente configurado correctamente"
    echo
    echo "PISTAS PARA INVESTIGACIÓN:"
    echo "  - Comienza con: df -h /var/sensitive, df -i /var/sensitive, mount | grep /var/sensitive"
    echo "  - Revisa el stack LVM completo: pvs, vgs, lvs -o +segtype"
    echo "  - Identifica el tipo de filesystem (importante para el comando de resize)"
    echo "  - Verifica el estado de cifrado: cryptsetup status crypt_data"
    echo
    echo "PUNTOS A CONSIDERAR:"
    echo "  • ¿Qué comando se usa para crecer un contenedor LUKS abierto?"
    echo "  • ¿En qué orden: LV → LUKS → FS?"
    echo "  • ¿Vale la pena restripear el LV para incluir el nuevo disco?"
    echo "  • ¿Cómo confirmar que no hubo corrupción tras la operación?"
    echo "=================================================="
} > "$TICKET_FILE"

cp "$TICKET_FILE" /home/student/lab_ticket.txt
chmod 644 /home/student/lab_ticket.txt

echo "Ticket V4 (LUKS) generado en /home/student/lab_ticket.txt"
echo
echo "=== RESUMEN DEL SETUP (solo para ti) ==="
echo "Discos: $DISK1, $DISK2 (originales), $DISK3 (nuevo añadido)"
echo "VG: $VG"
echo "LV: $LV (30%VG inicial)"
echo "LUKS: /dev/mapper/$CRYPT_NAME (casi lleno al 90%)"
echo "Montaje: $MNT con datos reales y uso simulado"
echo "Passphrase: ex200lab (en /etc/luks/crypt_data.key)"
echo "El estudiante debe extender el LV con el espacio libre del VG, luego"
echo "redimensionar LUKS y crecer el filesystem XFS en línea (lvextend + cryptsetup resize + xfs_growfs)."