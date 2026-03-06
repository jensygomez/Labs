#!/bin/bash
# =============================================================================
# LAB BLOQUE 3 — ALMACENAMIENTO (VERSIÓN FINAL - CON TODAS LAS CORRECCIONES)
# Preparación para LFCS + RHCSA
# Rocky Linux 9 — Ejecutar como root
# =============================================================================

set -e  # Salir si hay error

# -----------------------------------------------------------------------------
# VERIFICACIÓN INICIAL
# -----------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "❌ Este script debe ejecutarse como root."
    exit 1
fi

# -----------------------------------------------------------------------------
# FUNCIONES DE UTILIDAD
# -----------------------------------------------------------------------------
log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_warning() {
    echo "⚠️  $1" >&2
}

log_error() {
    echo "❌ $1" >&2
}

# Función para obtener nombre de partición correcto
get_partition_name() {
    local disk=$1
    local part_num=$2
    
    if [[ "$disk" == *"loop"* ]]; then
        echo "${disk}p${part_num}"
    elif [[ "$disk" == *"nvme"* ]]; then
        echo "${disk}p${part_num}"
    elif [[ "$disk" == *"sd"* ]] || [[ "$disk" == *"vd"* ]]; then
        echo "${disk}${part_num}"
    else
        echo "${disk}${part_num}"
    fi
}

# Función para obtener tamaño en MB
get_size_mb() {
    local device=$1
    if [[ -b "$device" ]]; then
        blockdev --getsize64 "$device" 2>/dev/null | awk '{print int($1/1024/1024)}'
    else
        echo "0"
    fi
}

# -----------------------------------------------------------------------------
# DETECCIÓN CORRECTA DEL DISCO DEL SISTEMA
# -----------------------------------------------------------------------------
log_info "🔍 Detectando discos disponibles..."

# Método más robusto para encontrar el disco del sistema
ROOT_DEVICE=$(findmnt -n -o SOURCE /)
log_info "Dispositivo raíz: $ROOT_DEVICE"

# Extraer el disco base correctamente
if [[ $ROOT_DEVICE == /dev/mapper/* ]]; then
    # Es un LVM - encontrar el disco físico
    ROOT_DISK=$(lvs -o+devices 2>/dev/null | grep -B1 "root" | grep "/dev/" | awk '{print $1}' | sed 's/[0-9]*$//' | head -1)
    if [[ -z "$ROOT_DISK" ]]; then
        # Fallback: listar discos y excluir los que no son sistema
        ROOT_DISK=$(lsblk -no PKNAME "$ROOT_DEVICE" | head -1)
        if [[ -n "$ROOT_DISK" ]]; then
            ROOT_DISK="/dev/$ROOT_DISK"
        fi
    fi
else
    # Es una partición directa
    ROOT_DISK=$(echo "$ROOT_DEVICE" | sed -E 's/[0-9]+$//')
fi

# Verificar que ROOT_DISK es un disco válido
if [[ -z "$ROOT_DISK" ]] || [[ ! -b "$ROOT_DISK" ]]; then
    log_warning "No se pudo determinar el disco del sistema automáticamente."
    # Listar discos y pedir al usuario que identifique
    echo "Discos disponibles:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    echo ""
    read -p "Introduce el nombre del disco del sistema (ej. vda, sda): " SYS_DISK
    ROOT_DISK="/dev/$SYS_DISK"
fi

log_info "Disco del sistema (NO se tocará): $ROOT_DISK"

# -----------------------------------------------------------------------------
# OBTENER DISCOS ADICIONALES (EXCLUYENDO SISTEMA Y CDROM)
# -----------------------------------------------------------------------------
# Obtener todos los discos
ALL_DISKS=$(lsblk -nd -o NAME,TYPE | grep " disk" | awk '{print "/dev/" $1}')

AVAILABLE_DISKS=()
for disk in $ALL_DISKS; do
    # Excluir disco del sistema y CDROM
    if [[ "$disk" != "$ROOT_DISK" ]] && [[ "$disk" != "/dev/sr0" ]] && [[ "$disk" != "/dev/cdrom"* ]]; then
        # Verificar que no tiene particiones montadas del sistema
        MOUNTED_PARTS=$(lsblk -ln -o MOUNTPOINT "$disk" 2>/dev/null | grep -v "^$" | wc -l)
        if [[ $MOUNTED_PARTS -eq 0 ]]; then
            AVAILABLE_DISKS+=("$disk")
        else
            log_warning "Disco $disk tiene particiones montadas - se omite"
        fi
    fi
done

NUM_DISKS=${#AVAILABLE_DISKS[@]}
log_info "Discos adicionales libres encontrados: $NUM_DISKS"

# Mostrar discos disponibles
for disk in "${AVAILABLE_DISKS[@]}"; do
    echo "   - $disk ($(get_size_mb "$disk")MB)"
done

# -----------------------------------------------------------------------------
# CREAR DISCOS LOOP SI ES NECESARIO
# -----------------------------------------------------------------------------
if [[ $NUM_DISKS -lt 4 ]]; then
    DISKS_NEEDED=$((4 - NUM_DISKS))
    log_warning "Se necesitan 4 discos. Faltan: $DISKS_NEEDED"
    
    # Preguntar si crear discos loop
    read -p "¿Crear discos loop para completar? (s/N): " -r CREATE_LOOP
    
    if [[ "$CREATE_LOOP" =~ ^[Ss]$ ]]; then
        log_info "Creando $DISKS_NEEDED discos loop de 3GB en /root/lab_disks/..."
        LOOP_DIR="/root/lab_disks"
        mkdir -p "$LOOP_DIR"
        
        # Limpiar loops existentes
        losetup -D 2>/dev/null || true
        
        for i in $(seq 1 "$DISKS_NEEDED"); do
            LOOP_FILE="$LOOP_DIR/disk_lab_$i.img"
            if [[ ! -f "$LOOP_FILE" ]]; then
                dd if=/dev/zero of="$LOOP_FILE" bs=1M count=3072 status=progress 2>/dev/null
            fi
            LOOP_DEV=$(losetup -f --show "$LOOP_FILE")
            AVAILABLE_DISKS+=("$LOOP_DEV")
            log_success "Creado disco loop: $LOOP_DEV (3GB)"
            sleep 1
        done
    else
        log_error "Se necesitan 4 discos para el laboratorio."
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# ORDENAR DISCOS POR TAMAÑO (EXCLUYENDO LOS QUE NO SON VÁLIDOS)
# -----------------------------------------------------------------------------
VALID_DISKS=()
for disk in "${AVAILABLE_DISKS[@]}"; do
    if [[ -b "$disk" ]] && [[ "$disk" != "$ROOT_DISK" ]]; then
        VALID_DISKS+=("$disk")
    fi
done

if [[ ${#VALID_DISKS[@]} -lt 4 ]]; then
    log_error "No hay suficientes discos válidos. Encontrados: ${#VALID_DISKS[@]}"
    exit 1
fi

# Ordenar por tamaño
SORTED_DISKS=()
while IFS= read -r disk; do
    SORTED_DISKS+=("$disk")
done < <(for disk in "${VALID_DISKS[@]}"; do
    SIZE=$(get_size_mb "$disk")
    echo "$SIZE $disk"
done | sort -n | awk '{print $2}')

# Asignar roles
DISK_SWAP="${SORTED_DISKS[0]}"
DISK_LVM="${SORTED_DISKS[1]}"
DISK_PART="${SORTED_DISKS[2]}"
DISK_FREE="${SORTED_DISKS[3]}"

log_success "✅ Asignación de discos:"
echo "   - Swap (${DISK_SWAP}): $(( $(get_size_mb "$DISK_SWAP") / 1024 ))GB"
echo "   - LVM (${DISK_LVM}): $(( $(get_size_mb "$DISK_LVM") / 1024 ))GB"
echo "   - Particiones (${DISK_PART}): $(( $(get_size_mb "$DISK_PART") / 1024 ))GB"
echo "   - Libre (${DISK_FREE}): $(( $(get_size_mb "$DISK_FREE") / 1024 ))GB"

# -----------------------------------------------------------------------------
# BACKUP AUTOMÁTICO
# -----------------------------------------------------------------------------
BACKUP_DIR="/root/lab-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
log_info "📦 Creando backup en: $BACKUP_DIR"

[ -f /etc/fstab ] && cp /etc/fstab "$BACKUP_DIR/fstab.original"

{
    echo "=== ESTADO ORIGINAL DEL SISTEMA ==="
    echo "Fecha: $(date)"
    echo ""
    echo "--- Discos ---"
    lsblk -f
    echo ""
    echo "--- Montajes actuales ---"
    mount | grep -E "^/dev"
    echo ""
    echo "--- Swap actual ---"
    swapon --show
} > "$BACKUP_DIR/estado-inicial.txt"
log_success "✅ Estado inicial guardado"

# -----------------------------------------------------------------------------
# LIMPIEZA DE METADATOS (SOLO EN DISCOS DE LAB)
# -----------------------------------------------------------------------------
log_info "🧹 Limpiando metadatos de discos de laboratorio..."

cleanup_disk() {
    local disk=$1
    log_info "   Limpiando $disk..."
    
    # Desmontar todo lo relacionado con este disco
    for part in $(lsblk -ln -o NAME "$disk" 2>/dev/null | grep -v "^$(basename "$disk")\$" | awk '{print "/dev/" $1}'); do
        umount "$part" 2>/dev/null || true
    done
    
    # Desactivar swap
    swapoff "$disk"* 2>/dev/null || true
    
    # Desactivar LVM
    pvs | grep -q "$disk" && pvremove -ffy "$disk" || true
    
    # Limpiar firmas
    wipefs -a "$disk" 2>/dev/null || true
}

# Limpiar solo los discos de laboratorio (NO el del sistema)
cleanup_disk "$DISK_SWAP"
cleanup_disk "$DISK_LVM"
cleanup_disk "$DISK_PART"
cleanup_disk "$DISK_FREE"

# Esperar a que el sistema reconozca los cambios
udevadm settle 2>/dev/null || true
sleep 3

log_success "✅ Limpieza completada."

# =============================================================================
# BLOQUE 3.1 — PARTICIONES Y FILESYSTEMS
# =============================================================================
log_info "📀 Configurando disco de particiones ($DISK_PART)..."

# Crear tabla de particiones
parted -s "$DISK_PART" mklabel gpt
sleep 2

# Calcular tamaños (40% y 60%)
DISK_SIZE_MB=$(get_size_mb "$DISK_PART")
PART1_SIZE_MB=$((DISK_SIZE_MB * 40 / 100))
PART2_SIZE_MB=$((DISK_SIZE_MB - PART1_SIZE_MB - 1))

# Crear particiones
parted -s "$DISK_PART" mkpart primary ext4 1MiB "${PART1_SIZE_MB}MiB"
parted -s "$DISK_PART" mkpart primary xfs "${PART1_SIZE_MB}MiB" 100%

# Esperar a que las particiones aparezcan
sleep 3
partprobe "$DISK_PART" 2>/dev/null || udevadm settle 2>/dev/null || true
sleep 3

# Obtener nombres de particiones
PART1=$(get_partition_name "$DISK_PART" 1)
PART2=$(get_partition_name "$DISK_PART" 2)

# Verificar que las particiones existen
if [[ ! -e "$PART1" ]]; then
    log_error "No se pudo crear $PART1"
    ls -la /dev/loop*
    exit 1
fi

if [[ ! -e "$PART2" ]]; then
    log_error "No se pudo crear $PART2"
    ls -la /dev/loop*
    exit 1
fi

# Formatear
mkfs.ext4 -F "$PART1"
mkfs.xfs -f "$PART2"

# Crear puntos de montaje
mkdir -p /mnt/ext4_data
mkdir -p /mnt/xfs_data

# Montar
mount "$PART1" /mnt/ext4_data
mount "$PART2" /mnt/xfs_data

log_success "✅ Particiones creadas:"
echo "   - $PART1 (ext4) - ${PART1_SIZE_MB}MB"
echo "   - $PART2 (xfs) - ${PART2_SIZE_MB}MB"

# =============================================================================
# BLOQUE 3.2 — FSTAB (ERRORES INTENCIONALES)
# =============================================================================
UUID_EXT4=$(blkid -s UUID -o value "$PART1")
UUID_XFS=$(blkid -s UUID -o value "$PART2")

cp /etc/fstab "$BACKUP_DIR/fstab.before_lab"

{
    echo ""
    echo "# --- LAB STORAGE: PARTICIONES ---"
    echo "UUID=$UUID_EXT4 /mnt/ext4_data ext4 defaults 0 2"
    echo "UUID=$UUID_XFS /mnt/xfs_data ext4 defaults 0 2"
    echo ""
    echo "# --- LAB STORAGE: BOOT FAILURE ---"
    echo "# UUID=12345678-1234-1234-1234-123456789abc /mnt/noexiste ext4 defaults 0 2"
} >> /etc/fstab

# Desmontar para que los ejercicios tengan que montar
umount /mnt/ext4_data
umount /mnt/xfs_data

log_success "✅ Entradas de fstab creadas"

# =============================================================================
# BLOQUE 3.3 — LVM INTELIGENTE
# =============================================================================
log_info "💾 Configurando disco LVM ($DISK_LVM)..."

# Calcular tamaños reales del disco
LVM_SIZE_MB=$(get_size_mb "$DISK_LVM")
LVM_SIZE_MB=$((LVM_SIZE_MB - 10))  # Dejar margen para metadata

# Crear PV y VG
pvcreate "$DISK_LVM"
vgcreate vg_storage "$DISK_LVM"

# Calcular tamaños de LV (60% y 40% del espacio disponible)
TOTAL_PE=$(vgdisplay vg_storage | grep "Total PE" | awk '{print $3}')
if [[ -n "$TOTAL_PE" ]]; then
    # Usar extents si está disponible
    LV_APPS_PE=$((TOTAL_PE * 60 / 100))
    LV_LOGS_PE=$((TOTAL_PE - LV_APPS_PE))
    
    lvcreate -l "$LV_APPS_PE" -n lv_apps vg_storage
    lvcreate -l "$LV_LOGS_PE" -n lv_logs vg_storage
    
    LV_APPS_SIZE=$((LV_APPS_PE * 4))  # Aproximación en MB (cada extent suele ser 4MB)
    LV_LOGS_SIZE=$((LV_LOGS_PE * 4))
else
    # Fallback a MB
    LV_APPS_SIZE=$((LVM_SIZE_MB * 60 / 100))
    LV_LOGS_SIZE=$((LVM_SIZE_MB - LV_APPS_SIZE))
    
    lvcreate -L "${LV_APPS_SIZE}M" -n lv_apps vg_storage
    lvcreate -L "${LV_LOGS_SIZE}M" -n lv_logs vg_storage
fi

log_info "   Tamaños LVM: lv_apps=${LV_APPS_SIZE}MB, lv_logs=${LV_LOGS_SIZE}MB"

# Formatear
mkfs.ext4 -F /dev/vg_storage/lv_apps
mkfs.xfs -f /dev/vg_storage/lv_logs

# Crear puntos de montaje
mkdir -p /srv/apps
mkdir -p /var/log/apps

# Montar
mount /dev/vg_storage/lv_apps /srv/apps
mount /dev/vg_storage/lv_logs /var/log/apps

# Añadir a fstab (con mala práctica - usar /dev/ paths)
{
    echo ""
    echo "# --- LAB STORAGE: LVM ---"
    echo "/dev/vg_storage/lv_apps /srv/apps ext4 defaults 0 2"
    echo "/dev/vg_storage/lv_logs /var/log/apps xfs defaults 0 2"
} >> /etc/fstab

log_success "✅ LVM configurado"

# =============================================================================
# BLOQUE 3.4 — LVM EXTENDIDO SIN FS
# =============================================================================
log_info "📈 Extendiendo lv_apps sin redimensionar FS..."

# Extender un 50% del tamaño original
EXTEND_SIZE=$((LV_APPS_SIZE / 2))
lvextend -L "+${EXTEND_SIZE}M" /dev/vg_storage/lv_apps

log_success "✅ lv_apps extendido a $((LV_APPS_SIZE + EXTEND_SIZE))MB (FS sigue en ${LV_APPS_SIZE}MB)"

# =============================================================================
# BLOQUE 3.5 — SWAP
# =============================================================================
log_info "🔄 Configurando swap..."

# Swap por partición (usar el disco completo)
parted -s "$DISK_SWAP" mklabel gpt
sleep 2
parted -s "$DISK_SWAP" mkpart primary linux-swap 1MiB 100%
sleep 2
partprobe "$DISK_SWAP" 2>/dev/null || udevadm settle 2>/dev/null || true
sleep 2

SWAP_PART=$(get_partition_name "$DISK_SWAP" 1)

if [[ -e "$SWAP_PART" ]]; then
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"
    {
        echo ""
        echo "# --- LAB STORAGE: SWAP PARTICION ---"
        echo "$SWAP_PART swap swap defaults 0 0"
    } >> /etc/fstab
    log_success "✅ Swap partición creada"
fi

# Swap por archivo (con error de permisos)
SWAPFILE="/swapfile_lab"
if command -v fallocate &>/dev/null; then
    fallocate -l 512M "$SWAPFILE" 2>/dev/null || dd if=/dev/zero of="$SWAPFILE" bs=1M count=512
else
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=512
fi

chmod 644 "$SWAPFILE"  # Permiso incorrecto (debería ser 600)
mkswap "$SWAPFILE"
swapon "$SWAPFILE" 2>/dev/null || log_warning "Swapfile no activo (permisos incorrectos - es intencional)"

{
    echo ""
    echo "# --- LAB STORAGE: SWAP ARCHIVO (ERROR) ---"
    echo "$SWAPFILE swap swap defaults 0 0"
} >> /etc/fstab

log_success "✅ Swap configurado"

# =============================================================================
# BLOQUE 3.6 — DISCO LIBRE
# =============================================================================
log_info "💿 Configurando disco libre ($DISK_FREE)..."

mkfs.ext4 -F "$DISK_FREE"
mkdir -p /data_backup
# NO se monta, NO se añade a fstab

log_success "✅ Disco libre formateado (ext4) pero no montado"

# =============================================================================
# BLOQUE 3.7 — MONTAJE DUPLICADO
# =============================================================================
log_info "🔗 Creando montaje duplicado..."

# Montar la misma partición en otro lugar
if [[ -e "$PART1" ]]; then
    mkdir -p /backup_ext4
    mount "$PART1" /backup_ext4
    log_success "✅ Montaje duplicado creado ($PART1 en /backup_ext4)"
fi

# =============================================================================
# BLOQUE 3.8 — VERIFICACIÓN FINAL
# =============================================================================
# Desmontar todo para que los ejercicios tengan que montar
umount /srv/apps 2>/dev/null || true
umount /var/log/apps 2>/dev/null || true
umount /backup_ext4 2>/dev/null || true

# Reactivar swap para que esté disponible
swapon -a 2>/dev/null || true

# =============================================================================
# RESUMEN FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo "🎉 LAB BLOQUE 3 — ALMACENAMIENTO PREPARADO"
echo "========================================================================"
echo ""
echo "📊 CONFIGURACIÓN DE DISCOS:"
echo "---------------------------"
echo "🔹 SWAP:        $DISK_SWAP ($(( $(get_size_mb "$DISK_SWAP") / 1024 ))GB)"
echo "   └─ Partición swap + swapfile con error"
echo ""
echo "🔹 LVM:         $DISK_LVM ($(( $(get_size_mb "$DISK_LVM") / 1024 ))GB)"
echo "   ├─ vg_storage"
echo "   ├─ lv_apps (ext4, ${LV_APPS_SIZE}MB + ${EXTEND_SIZE}MB extendido sin FS)"
echo "   └─ lv_logs (xfs, ${LV_LOGS_SIZE}MB)"
echo ""
echo "🔹 PARTICIONES: $DISK_PART ($(( $(get_size_mb "$DISK_PART") / 1024 ))GB)"
echo "   ├─ $PART1 (ext4, ${PART1_SIZE_MB}MB)"
echo "   └─ $PART2 (xfs, ${PART2_SIZE_MB}MB) - ERROR en fstab (tipo ext4)"
echo ""
echo "🔹 LIBRE:       $DISK_FREE ($(( $(get_size_mb "$DISK_FREE") / 1024 ))GB)"
echo "   └─ Formateado ext4 pero NO montado"
echo ""
echo "⚠️  ERRORES INTENCIONALES:"
echo "---------------------------"
echo "1. /etc/fstab: Partición XFS con tipo 'ext4'"
echo "2. /etc/fstab: Uso de /dev/ paths para LVM (en lugar de UUIDs)"
echo "3. lv_apps: Tamaño LVM > tamaño FS (necesita resize2fs)"
echo "4. /swapfile_lab: Permisos 644 (debería ser 600)"
echo "5. Montaje duplicado: Misma partición en dos lugares"
echo "6. $DISK_FREE: Formateado pero no montado"
echo "7. /etc/fstab: Línea comentada con UUID inexistente (para boot failure)"
echo ""
echo "📦 BACKUP: $BACKUP_DIR"
echo ""
echo "========================================================================"

# Instrucciones para discos loop
if [[ "$DISK_SWAP" == /dev/loop* ]]; then
    echo ""
    echo "⚠️  IMPORTANTE - Discos Loop detectados:"
    echo "   Para reactivar después de reboot:"
    echo "   # Asociar archivos a loop devices"
    echo "   for img in /root/lab_disks/*.img; do losetup -f --show \$img; done"
    echo "   # Activar LVM"
    echo "   vgchange -ay"
    echo "   # Activar swap y montajes"
    echo "   swapon -a && mount -a"
    echo ""
fi

log_success "✅ LABORATORIO LISTO PARA PRACTICAR"