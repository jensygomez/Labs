#!/bin/bash
# =============================================================================
# LAB BLOQUE 3 — BASE (VERSIÓN LIMPIA - SIN ERRORES EN FSTAB)
# Preparación para LFCS + RHCSA
# Rocky Linux 9 — Ejecutar como root
# =============================================================================

set -e

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
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1" >&2; }
log_error() { echo "❌ $1" >&2; }

get_partition_name() {
    local disk=$1 part_num=$2
    if [[ "$disk" == *"loop"* ]] || [[ "$disk" == *"nvme"* ]]; then
        echo "${disk}p${part_num}"
    else
        echo "${disk}${part_num}"
    fi
}

get_size_mb() {
    local device=$1
    if [[ -b "$device" ]]; then
        blockdev --getsize64 "$device" 2>/dev/null | awk '{print int($1/1024/1024)}'
    else
        echo "0"
    fi
}

# -----------------------------------------------------------------------------
# DETECCIÓN DE DISCOS
# -----------------------------------------------------------------------------
log_info "🔍 Detectando discos disponibles..."

ROOT_DEVICE=$(findmnt -n -o SOURCE /)
log_info "Dispositivo raíz: $ROOT_DEVICE"

# Extraer disco base
if [[ $ROOT_DEVICE == /dev/mapper/* ]]; then
    ROOT_DISK=$(lvs -o+devices 2>/dev/null | grep -B1 "root" | grep "/dev/" | awk '{print $1}' | sed 's/[0-9]*$//' | head -1)
    [[ -z "$ROOT_DISK" ]] && ROOT_DISK=$(lsblk -no PKNAME "$ROOT_DEVICE" | head -1 | sed 's/^/\/dev\//')
else
    ROOT_DISK=$(echo "$ROOT_DEVICE" | sed -E 's/[0-9]+$//')
fi

[[ ! -b "$ROOT_DISK" ]] && ROOT_DISK=$(lsblk -nd -o NAME,TYPE | grep " disk" | grep -v "^sr" | awk 'NR==1 {print "/dev/" $1}')

log_info "Disco del sistema (NO se tocará): $ROOT_DISK"

# -----------------------------------------------------------------------------
# OBTENER DISCOS ADICIONALES
# -----------------------------------------------------------------------------
ALL_DISKS=$(lsblk -nd -o NAME,TYPE | grep " disk" | awk '{print "/dev/" $1}')
AVAILABLE_DISKS=()

for disk in $ALL_DISKS; do
    if [[ "$disk" != "$ROOT_DISK" ]] && [[ "$disk" != "/dev/sr0" ]]; then
        MOUNTED_PARTS=$(lsblk -ln -o MOUNTPOINT "$disk" 2>/dev/null | grep -v "^$" | wc -l)
        [[ $MOUNTED_PARTS -eq 0 ]] && AVAILABLE_DISKS+=("$disk")
    fi
done

NUM_DISKS=${#AVAILABLE_DISKS[@]}

# -----------------------------------------------------------------------------
# CREAR DISCOS LOOP SI ES NECESARIO
# -----------------------------------------------------------------------------
if [[ $NUM_DISKS -lt 4 ]]; then
    DISKS_NEEDED=$((4 - NUM_DISKS))
    log_warning "Faltan $DISKS_NEEDED discos. Creando discos loop..."
    
    LOOP_DIR="/root/lab_disks"
    mkdir -p "$LOOP_DIR"
    
    # Limpiar loops existentes
    for img in "$LOOP_DIR"/*.img; do
        [[ -f "$img" ]] && losetup -j "$img" | awk -F: '{print $1}' | xargs -r losetup -d 2>/dev/null || true
    done
    
    for i in $(seq 1 "$DISKS_NEEDED"); do
        LOOP_FILE="$LOOP_DIR/disk_lab_$i.img"
        [[ ! -f "$LOOP_FILE" ]] && dd if=/dev/zero of="$LOOP_FILE" bs=1M count=3072 status=none
        LOOP_DEV=$(losetup -f --show "$LOOP_FILE")
        AVAILABLE_DISKS+=("$LOOP_DEV")
    done
fi

# -----------------------------------------------------------------------------
# ORDENAR Y ASIGNAR DISCOS
# -----------------------------------------------------------------------------
VALID_DISKS=()
for disk in "${AVAILABLE_DISKS[@]}"; do
    [[ ! -b "$disk" ]] && continue
    [[ "$disk" == "$ROOT_DISK" ]] && continue
    VALID_DISKS+=("$disk")
done

# Ordenar por tamaño
SORTED_DISKS=()
while IFS= read -r disk; do
    SORTED_DISKS+=("$disk")
done < <(for disk in "${VALID_DISKS[@]}"; do
    echo "$(get_size_mb "$disk") $disk"
done | sort -n | awk '{print $2}')

# Asignar roles
DISK_SWAP="${SORTED_DISKS[0]}"
DISK_LVM="${SORTED_DISKS[1]}"
DISK_PART="${SORTED_DISKS[2]}"
DISK_FREE="${SORTED_DISKS[3]}"

log_success "✅ Asignación de discos:"
echo "   - Swap: $DISK_SWAP ($(get_size_mb "$DISK_SWAP")MB)"
echo "   - LVM: $DISK_LVM ($(get_size_mb "$DISK_LVM")MB)"
echo "   - Particiones: $DISK_PART ($(get_size_mb "$DISK_PART")MB)"
echo "   - Libre: $DISK_FREE ($(get_size_mb "$DISK_FREE")MB)"

# -----------------------------------------------------------------------------
# RESPALDO DE CONFIGURACIÓN ORIGINAL
# -----------------------------------------------------------------------------
BACKUP_DIR="/root/lab-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp /etc/fstab "$BACKUP_DIR/fstab.original" 2>/dev/null || touch "$BACKUP_DIR/fstab.original"

# Guardar asignación de discos para scripts posteriores
cat > "$BACKUP_DIR/disk-assignment.conf" << EOF
# Asignación de discos del laboratorio
DISK_SWAP="$DISK_SWAP"
DISK_LVM="$DISK_LVM"
DISK_PART="$DISK_PART"
DISK_FREE="$DISK_FREE"
ROOT_DISK="$ROOT_DISK"
BACKUP_DIR="$BACKUP_DIR"
EOF

# -----------------------------------------------------------------------------
# LIMPIEZA DE DISCOS
# -----------------------------------------------------------------------------
log_info "🧹 Limpiando metadatos de discos de laboratorio..."
for disk in "$DISK_SWAP" "$DISK_LVM" "$DISK_PART" "$DISK_FREE"; do
    log_info "   Limpiando $disk..."
    for part in $(lsblk -ln -o NAME "$disk" 2>/dev/null | grep -v "^$(basename "$disk")\$" | awk '{print "/dev/" $1}'); do
        umount "$part" 2>/dev/null || true
    done
    swapoff "$disk"* 2>/dev/null || true
    pvs | grep -q "$disk" && pvremove -ffy "$disk" 2>/dev/null || true
    wipefs -a "$disk" 2>/dev/null || true
done
udevadm settle 2>/dev/null || true
sleep 2

# =============================================================================
# CONFIGURACIÓN BASE (SIN ERRORES EN FSTAB)
# =============================================================================

# -----------------------------------------------------------------------------
# BLOQUE 1: DISCO DE PARTICIONES
# -----------------------------------------------------------------------------
log_info "📀 Configurando disco de particiones ($DISK_PART)..."
parted -s "$DISK_PART" mklabel gpt
sleep 2

DISK_SIZE_MB=$(get_size_mb "$DISK_PART")
PART1_SIZE_MB=$((DISK_SIZE_MB * 40 / 100))
PART2_SIZE_MB=$((DISK_SIZE_MB - PART1_SIZE_MB - 1))

parted -s "$DISK_PART" mkpart primary ext4 1MiB "${PART1_SIZE_MB}MiB"
parted -s "$DISK_PART" mkpart primary xfs "${PART1_SIZE_MB}MiB" 100%

sleep 3
partprobe "$DISK_PART" 2>/dev/null || udevadm settle 2>/dev/null || true
sleep 2

PART1=$(get_partition_name "$DISK_PART" 1)
PART2=$(get_partition_name "$DISK_PART" 2)

mkfs.ext4 -F "$PART1"
mkfs.xfs -f "$PART2"

mkdir -p /mnt/ext4_data /mnt/xfs_data /backup_ext4

log_success "✅ Particiones creadas: $PART1 (ext4), $PART2 (xfs)"

# -----------------------------------------------------------------------------
# BLOQUE 2: LVM
# -----------------------------------------------------------------------------
log_info "💾 Configurando disco LVM ($DISK_LVM)..."
pvcreate "$DISK_LVM"
vgcreate vg_storage "$DISK_LVM"

TOTAL_PE=$(vgs --noheadings --units m -o vg_free vg_storage 2>/dev/null | tr -d ' m' | cut -d. -f1)
[[ -z "$TOTAL_PE" ]] && TOTAL_PE=$(vgdisplay vg_storage 2>/dev/null | awk '/Free  PE/ {print $5}')

if [[ -n "$TOTAL_PE" ]] && [[ "$TOTAL_PE" -gt 10 ]]; then
    LV_APPS_SIZE=$((TOTAL_PE * 60 / 100))
    LV_LOGS_SIZE=$((TOTAL_PE * 38 / 100))
    
    lvcreate -L "${LV_APPS_SIZE}M" -n lv_apps vg_storage
    lvcreate -L "${LV_LOGS_SIZE}M" -n lv_logs vg_storage
    
    mkfs.ext4 -F /dev/vg_storage/lv_apps
    mkfs.xfs -f /dev/vg_storage/lv_logs
    
    mkdir -p /srv/apps /var/log/apps
else
    log_error "Error creando LVM"
    exit 1
fi

log_success "✅ LVM configurado: lv_apps (${LV_APPS_SIZE}MB), lv_logs (${LV_LOGS_SIZE}MB)"

# -----------------------------------------------------------------------------
# BLOQUE 3: SWAP
# -----------------------------------------------------------------------------
log_info "🔄 Configurando swap..."

# Swap por partición
parted -s "$DISK_SWAP" mklabel gpt
sleep 2
parted -s "$DISK_SWAP" mkpart primary linux-swap 1MiB 100%
sleep 2
partprobe "$DISK_SWAP" 2>/dev/null || udevadm settle 2>/dev/null || true
sleep 2

SWAP_PART=$(get_partition_name "$DISK_SWAP" 1)
mkswap "$SWAP_PART"
swapon "$SWAP_PART"

# Swap por archivo (con permisos correctos inicialmente)
SWAPFILE="/swapfile_lab"
fallocate -l 512M "$SWAPFILE" 2>/dev/null || dd if=/dev/zero of="$SWAPFILE" bs=1M count=512
chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"
swapon "$SWAPFILE"

log_success "✅ Swap configurado (partición + archivo)"

# -----------------------------------------------------------------------------
# BLOQUE 4: DISCO LIBRE
# -----------------------------------------------------------------------------
log_info "💿 Configurando disco libre ($DISK_FREE)..."
mkfs.ext4 -F "$DISK_FREE"
mkdir -p /data_backup
log_success "✅ Disco libre formateado (ext4)"

# -----------------------------------------------------------------------------
# SERVICIO DE PERSISTENCIA PARA LOOPS
# -----------------------------------------------------------------------------
if [[ "$DISK_SWAP" == /dev/loop* ]]; then
    log_info "⚙️  Instalando servicio systemd para persistencia de loops..."
    
    cat > /etc/systemd/system/lab-loops.service << 'EOF'
[Unit]
Description=Re-asociar discos loop del laboratorio al arranque
After=local-fs.target
Before=lvm2-activation.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '\
    for img in /root/lab_disks/*.img; do \
        [ -f "$img" ] && losetup -f --show "$img" 2>/dev/null; \
    done; \
    vgchange -ay 2>/dev/null; \
    swapon -a 2>/dev/null || true'

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable lab-loops.service
    log_success "Servicio lab-loops.service instalado"
fi

# =============================================================================
# GUARDAR CONFIGURACIÓN PARA SCRIPTS DE EJERCICIOS
# =============================================================================
cat > /root/.lab_storage_config << EOF
# Configuración del laboratorio de almacenamiento
DISK_SWAP="$DISK_SWAP"
DISK_LVM="$DISK_LVM"
DISK_PART="$DISK_PART"
DISK_FREE="$DISK_FREE"
PART1="$PART1"
PART2="$PART2"
SWAP_PART="$SWAP_PART"
SWAPFILE="$SWAPFILE"
LV_APPS="/dev/vg_storage/lv_apps"
LV_LOGS="/dev/vg_storage/lv_logs"
VG_NAME="vg_storage"
LV_APPS_SIZE="$LV_APPS_SIZE"
LV_LOGS_SIZE="$LV_LOGS_SIZE"
BACKUP_DIR="$BACKUP_DIR"
PART1_SIZE_MB="$PART1_SIZE_MB"
PART2_SIZE_MB="$PART2_SIZE_MB"
EOF

# =============================================================================
# INSTALAR MENÚ DE EJERCICIOS
# =============================================================================
cp /root/.lab_storage_config "$BACKUP_DIR/"
chmod +x /root/lab-exercises.sh 2>/dev/null || true

log_success "✅ Laboratorio base instalado correctamente"
echo ""
echo "========================================================================"
echo "🎯 LABORATORIO BASE INSTALADO - SIN ERRORES EN FSTAB"
echo "========================================================================"
echo ""
echo "📁 Discos configurados:"
echo "   - Swap:     $DISK_SWAP (con swap partición y swapfile)"
echo "   - LVM:      $DISK_LVM (vg_storage con lv_apps y lv_logs)"
echo "   - Part:     $DISK_PART (con $PART1 y $PART2)"
echo "   - Libre:    $DISK_FREE (formateado ext4)"
echo ""
echo "⚠️  IMPORTANTE: Este script NO ha modificado /etc/fstab"
echo "   El sistema arrancará sin problemas después de reiniciar."
echo ""
echo "📝 Para activar los ejercicios con errores, ejecuta:"
echo "   curl -sSL https://tu-servidor/lab-exercises.sh | bash"
echo "   (o copia el script manualmente)"
echo ""
echo "🔧 Los discos loop persistirán después de reiniciar gracias al servicio"
echo "========================================================================"