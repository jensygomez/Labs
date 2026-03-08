#!/bin/bash
# =============================================================================
# LAB BLOQUE 3 — SISTEMA DE EJERCICIOS COMPLETO (40 EJERCICIOS)
# Ejecutar como root
# =============================================================================

if [[ $EUID -ne 0 ]]; then
    echo "❌ Este script debe ejecutarse como root."
    exit 1
fi

CONFIG_FILE="/root/.lab_storage_config"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Ejecuta primero lab-storage-base.sh"
    exit 1
fi
source "$CONFIG_FILE"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

BACKUP_FSTAB="/root/fstab.backup.$(date +%s)"
cp /etc/fstab "$BACKUP_FSTAB"

# -----------------------------------------------------------------------------
# FUNCIONES PARA PREPARAR ESCENARIOS
# -----------------------------------------------------------------------------

preparar_ejercicio() {
    local ej_num=$1
    local ej_nombre=$2
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🎯 PREPARANDO EJERCICIO: $ej_num - $ej_nombre${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
}

finalizar_ejercicio() {
    echo -e "\n${GREEN}✅ Escenario preparado. ¡A practicar!${NC}"
    echo -e "${YELLOW}📝 Cuando termines, puedes:${NC}"
    echo "   • Seleccionar otro ejercicio"
    echo "   • Usar opción 41 para resetear"
    echo "   • Verificar con opción 42"
    echo ""
    read -p "Presiona Enter para continuar..."
}

# =============================================================================
# EJERCICIOS BÁSICOS (1-10)
# =============================================================================

ejercicio_01() {
    preparar_ejercicio "01" "Listar dispositivos de bloque"
    echo "🔍 Los discos ya están configurados:"
    echo "   • /dev/vdb (particiones)"
    echo "   • /dev/vdc (LVM)"
    echo "   • /dev/vdd (swap)"
    echo "   • /dev/vde (libre)"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   lsblk -o NAME,SIZE,TYPE,MOUNTPOINT"
    echo "   lsblk -f"
    finalizar_ejercicio
}

ejercicio_02() {
    preparar_ejercicio "02" "Encontrar UUIDs de particiones"
    echo "🔍 Las particiones disponibles son:"
    echo "   $PART1 (ext4)"
    echo "   $PART2 (xfs)"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   blkid $PART1"
    echo "   blkid $PART2"
    echo "   blkid | grep -E 'vdb[1-2]'"
    finalizar_ejercicio
}

ejercicio_03() {
    preparar_ejercicio "03" "Verificar sistemas de archivos montados"
    # Desmontar particiones para que no aparezcan
    umount /mnt/ext4_data /mnt/xfs_data 2>/dev/null || true
    echo "🔍 Estado actual: Las particiones NO están montadas"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   mount | grep /dev/vd"
    echo "   df -h | grep -E '/dev/vd|/srv|/var'"
    echo "   findmnt --df -R /dev/vdb"
    finalizar_ejercicio
}

ejercicio_04() {
    preparar_ejercicio "04" "Inspeccionar capa física LVM"
    echo "🔍 Physical Volume configurado: $DISK_LVM"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   pvs"
    echo "   pvdisplay $DISK_LVM"
    echo "   pvscan"
    finalizar_ejercicio
}

ejercicio_05() {
    preparar_ejercicio "05" "Listar Volume Groups y Logical Volumes"
    echo "🔍 VG: vg_storage"
    echo "   LV: lv_apps (ext4, ${LV_APPS_SIZE}MB)"
    echo "   LV: lv_logs (xfs, ${LV_LOGS_SIZE}MB)"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   vgs"
    echo "   vgdisplay vg_storage"
    echo "   lvs"
    echo "   lvdisplay /dev/vg_storage/lv_apps"
    finalizar_ejercicio
}

ejercicio_06() {
    preparar_ejercicio "06" "Inspeccionar configuración de swap"
    echo "🔍 Swap configurado:"
    echo "   • Partición: $SWAP_PART (activa)"
    echo "   • Swapfile: $SWAPFILE (activo - permisos 600)"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   swapon --show"
    echo "   free -h"
    echo "   cat /proc/swaps"
    finalizar_ejercicio
}

ejercicio_07() {
    preparar_ejercicio "07" "Verificar /etc/fstab"
    echo "🔍 Estado actual: fstab sin errores (base limpia)"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   cat /etc/fstab | grep -v '^#'"
    echo "   grep UUID /etc/fstab"
    echo "   findmnt --verify"
    echo "   mount -av (dry run)"
    finalizar_ejercicio
}

ejercicio_08() {
    preparar_ejercicio "08" "Montar disco libre manualmente"
    echo "🔍 Disco libre: $DISK_FREE (formateado ext4)"
    echo "   Punto de montaje: /data_backup (no montado)"
    echo ""
    echo "📋 Tarea: Montar el disco manualmente"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   mount $DISK_FREE /data_backup"
    echo "   df -h /data_backup"
    finalizar_ejercicio
}

ejercicio_09() {
    preparar_ejercicio "09" "Desmontar punto duplicado"
    # Montar partición en ambos lugares
    mkdir -p /backup_ext4
    mount "$PART1" /mnt/ext4_data 2>/dev/null || true
    mount "$PART1" /backup_ext4 2>/dev/null || true
    echo "🔍 Montaje duplicado creado:"
    echo "   $PART1 → /mnt/ext4_data"
    echo "   $PART1 → /backup_ext4"
    echo ""
    echo "📋 Tarea: Desmontar /backup_ext4 sin afectar /mnt/ext4_data"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   umount /backup_ext4"
    echo "   mount | grep $PART1"
    finalizar_ejercicio
}

ejercicio_10() {
    preparar_ejercicio "10" "Identificar tipos de filesystem en LVM"
    echo "🔍 Logical Volumes:"
    echo "   /dev/vg_storage/lv_apps (ext4)"
    echo "   /dev/vg_storage/lv_logs (xfs)"
    echo ""
    echo "📋 Comandos a practicar:"
    echo "   lsblk -f | grep -A2 vg_storage"
    echo "   df -T | grep -E 'apps|logs'"
    echo "   blkid /dev/vg_storage/lv_apps"
    finalizar_ejercicio
}

# =============================================================================
# EJERCICIOS INTERMEDIOS (11-20)
# =============================================================================

ejercicio_11() {
    preparar_ejercicio "11" "INTER.1 - Corregir error XFS/ext4 en fstab"
    # Añadir el error
    UUID_XFS=$(blkid -s UUID -o value "$PART2")
    cp /etc/fstab /etc/fstab.backup.ej11
    cat >> /etc/fstab << EOF

# --- LAB: ERROR XFS (EJERCICIO 11) ---
UUID=$UUID_XFS /mnt/xfs_data ext4 defaults 0 2
EOF
    echo -e "${RED}⚠️  ERROR INTENCIONAL AÑADIDO: Partición XFS como ext4${NC}"
    echo ""
    echo "📋 Tarea: Identificar y corregir el error"
    echo "   Comando: blkid $PART2 (ver tipo real)"
    echo "   Editar: /etc/fstab (cambiar ext4 → xfs)"
    echo "   Verificar: mount -a"
    finalizar_ejercicio
}

ejercicio_12() {
    preparar_ejercicio "12" "INTER.2 - Sincronizar LV extendido sin FS"
    # Extender LV sin redimensionar FS
    EXTEND_SIZE=$((LV_APPS_SIZE / 2))
    lvextend -L "+${EXTEND_SIZE}M" "$LV_APPS" 2>/dev/null
    echo -e "${RED}⚠️  ERROR INTENCIONAL: lv_apps tiene tamaño LVM > FS${NC}"
    echo "   LVM: $((LV_APPS_SIZE + EXTEND_SIZE))MB"
    echo "   FS:  ${LV_APPS_SIZE}MB"
    echo ""
    echo "📋 Tarea: Redimensionar filesystem"
    echo "   Comando: resize2fs $LV_APPS"
    echo "   Verificar: lvs; df -h /srv/apps"
    finalizar_ejercicio
}

ejercicio_13() {
    preparar_ejercicio "13" "INTER.3 - Montaje persistente disco libre"
    echo "🔍 Disco libre: $DISK_FREE (formateado ext4)"
    echo "   Punto de montaje: /data_backup"
    echo ""
    echo "📋 Tarea: Configurar montaje persistente con UUID"
    echo ""
    echo "📋 Pasos:"
    echo "   1. Obtener UUID: blkid $DISK_FREE"
    echo "   2. Añadir a /etc/fstab:"
    echo "      UUID=... /data_backup ext4 defaults 0 2"
    echo "   3. Probar: umount /data_backup; mount -a"
    finalizar_ejercicio
}

ejercicio_14() {
    preparar_ejercicio "14" "INTER.4 - Corregir permisos swapfile"
    # Cambiar permisos a 644
    swapoff "$SWAPFILE" 2>/dev/null
    chmod 644 "$SWAPFILE"
    cp /etc/fstab /etc/fstab.backup.ej14
    cat >> /etc/fstab << EOF

# --- LAB: SWAP ERROR (EJERCICIO 14) ---
$SWAPFILE swap swap defaults 0 0
EOF
    echo -e "${RED}⚠️  ERROR INTENCIONAL: swapfile con permisos 644${NC}"
    echo ""
    echo "📋 Tarea: Corregir y reactivar swap"
    echo "   Pasos: swapoff; chmod 600; mkswap; swapon"
    finalizar_ejercicio
}

ejercicio_15() {
    preparar_ejercicio "15" "INTER.5 - Extender lv_logs (XFS)"
    echo "🔍 lv_logs actual: ${LV_LOGS_SIZE}MB (xfs)"
    echo ""
    echo "📋 Tarea: Extender lv_logs en 500MB"
    echo ""
    echo "📋 Comandos:"
    echo "   lvextend -L +500M /dev/vg_storage/lv_logs"
    echo "   xfs_growfs /var/log/apps"
    echo "   df -h /var/log/apps"
    finalizar_ejercicio
}

ejercicio_16() {
    preparar_ejercicio "16" "INTER.6 - Migrar LVM paths a UUIDs"
    # Añadir entradas con /dev/ paths
    cp /etc/fstab /etc/fstab.backup.ej16
    cat >> /etc/fstab << EOF

# --- LAB: LVM PATHS (EJERCICIO 16) ---
/dev/vg_storage/lv_apps /srv/apps ext4 defaults 0 2
/dev/vg_storage/lv_logs /var/log/apps xfs defaults 0 2
EOF
    echo -e "${RED}⚠️  CONFIGURACIÓN A CORREGIR: LVM con /dev/ paths${NC}"
    echo ""
    echo "📋 Tarea: Cambiar a UUIDs"
    echo "   Obtener UUIDs: blkid /dev/vg_storage/lv_*"
    echo "   Editar fstab: reemplazar paths con UUID=..."
    finalizar_ejercicio
}

ejercicio_17() {
    preparar_ejercicio "17" "INTER.7 - Redimensionar partición estándar"
    echo "🔍 Partición: $PART1 (${PART1_SIZE_MB}MB, ext4)"
    umount /mnt/ext4_data 2>/dev/null || true
    echo ""
    echo "📋 Tarea: Redimensionar partición al 100% del disco"
    echo ""
    echo "📋 Pasos críticos (orden correcto):"
    echo "   1. fdisk/parted: borrar y recrear con mismo inicio"
    echo "   2. partprobe"
    echo "   3. e2fsck -f $PART1"
    echo "   4. resize2fs $PART1"
    echo "   5. montar y verificar"
    finalizar_ejercicio
}

ejercicio_18() {
    preparar_ejercicio "18" "INTER.8 - Expandir VG con nuevo disco"
    echo "🔍 Disco disponible: $DISK_FREE (sin usar en LVM)"
    echo "   VG actual: vg_storage (solo $DISK_LVM)"
    echo ""
    echo "📋 Tarea: Añadir $DISK_FREE al VG"
    echo ""
    echo "📋 Comandos:"
    echo "   pvcreate $DISK_FREE"
    echo "   vgextend vg_storage $DISK_FREE"
    echo "   vgdisplay vg_storage | grep Free"
    finalizar_ejercicio
}

ejercicio_19() {
    preparar_ejercicio "19" "INTER.9 - Crear LV por extents"
    echo "🔍 VG disponible: vg_storage"
    echo ""
    echo "📋 Tarea: Crear lv_db con 128 extents (formato xfs)"
    echo ""
    echo "📋 Comandos:"
    echo "   vgdisplay vg_storage | grep PE"
    echo "   lvcreate -l 128 -n lv_db vg_storage"
    echo "   mkfs.xfs /dev/vg_storage/lv_db"
    echo "   mkdir -p /var/lib/mysql_data"
    echo "   mount /dev/vg_storage/lv_db /var/lib/mysql_data"
    finalizar_ejercicio
}

ejercicio_20() {
    preparar_ejercicio "20" "INTER.10 - Limpiar montaje redundante"
    # Crear montaje duplicado
    mkdir -p /backup_ext4
    mount "$PART1" /mnt/ext4_data 2>/dev/null || true
    mount "$PART1" /backup_ext4 2>/dev/null || true
    echo -e "${RED}⚠️  PROBLEMA: Montaje duplicado activo${NC}"
    echo ""
    echo "📋 Tarea: Eliminar redundancia"
    echo "   1. Desmontar /backup_ext4"
    echo "   2. Eliminar directorio"
    echo "   3. Verificar no hay entradas en fstab"
    finalizar_ejercicio
}

# =============================================================================
# EJERCICIOS AVANZADOS (21-30)
# =============================================================================

ejercicio_21() {
    preparar_ejercicio "21" "AVAN.1 - Boot failure por UUID inexistente"
    cp /etc/fstab /etc/fstab.backup.ej21
    cat >> /etc/fstab << EOF

# --- LAB: BOOT FAILURE (EJERCICIO 21) ---
UUID=12345678-1234-1234-1234-123456789abc /mnt/noexiste ext4 defaults 0 2
EOF
    echo -e "${RED}⚠️  CRÍTICO: UUID inexistente en fstab${NC}"
    echo "   (Línea descomentada - causará fallo al arrancar)"
    echo ""
    echo "📋 Tarea: Reparar desde emergency mode"
    echo "   • Remount rw: mount -o remount,rw /"
    echo "   • Comentar línea problemática"
    finalizar_ejercicio
}

ejercicio_22() {
    preparar_ejercicio "22" "AVAN.2 - Configurar Stratis"
    echo "🔍 Dispo disponible: $DISK_FREE"
    echo ""
    echo "📋 Tarea: Crear pool Stratis"
    echo ""
    echo "📋 Comandos:"
    echo "   dnf install -y stratisd stratis-cli"
    echo "   systemctl enable --now stratisd"
    echo "   stratis pool create pool_data $DISK_FREE"
    echo "   stratis filesystem create pool_data fs_strat"
    echo "   mkdir /stratis_data"
    echo "   mount /dev/stratis/pool_data/fs_strat /stratis_data"
    finalizar_ejercicio
}

ejercicio_23() {
    preparar_ejercicio "23" "AVAN.3 - Migrar datos de PV dañado"
    echo "🔍 PV actual: $DISK_LVM (vg_storage)"
    echo "   Nuevo disco: $DISK_FREE"
    echo ""
    echo "📋 Tarea: Simular migración por fallo"
    echo ""
    echo "📋 Comandos:"
    echo "   pvcreate $DISK_FREE"
    echo "   vgextend vg_storage $DISK_FREE"
    echo "   pvmove $DISK_LVM"
    echo "   vgreduce vg_storage $DISK_LVM"
    echo "   pvremove $DISK_LVM"
    finalizar_ejercicio
}

ejercicio_24() {
    preparar_ejercicio "24" "AVAN.4 - Configurar VDO"

    echo "🔍 Disco disponible: $DISK_FREE"
    echo ""
    echo "📋 Tarea: Crear volumen VDO con deduplicación"
    echo ""
    echo "📋 Pasos:"
    echo "   dnf install -y vdo kmod-kvdo"
    echo "   vdo create --name=vdo_disk --device=$DISK_FREE --vdoLogicalSize=50G"
    echo "   mkfs.xfs /dev/mapper/vdo_disk"
    echo "   mkdir /vdo_data"
    echo "   mount /dev/mapper/vdo_disk /vdo_data"

    finalizar_ejercicio
}

ejercicio_25() {
    preparar_ejercicio "25" "AVAN.5 - Reducir LV (ext4)"

    echo "⚠️ Operación peligrosa"
    echo ""
    echo "📋 Reducir lv_apps de 3GB a 1GB"
    echo ""
    echo "📋 Pasos:"
    echo "   umount /srv/apps"
    echo "   e2fsck -f /dev/vg_storage/lv_apps"
    echo "   resize2fs /dev/vg_storage/lv_apps 1G"
    echo "   lvreduce -L 1G /dev/vg_storage/lv_apps"
    echo "   mount /srv/apps"

    finalizar_ejercicio
}

ejercicio_26() {
    preparar_ejercicio "26" "AVAN.6 - LVM Snapshot"

    echo "📋 Crear snapshot de lv_apps"
    echo ""
    echo "📋 Comandos:"
    echo "   lvcreate -L 512M -s -n lv_apps_snap /dev/vg_storage/lv_apps"
    echo "   mkdir /mnt/snapshot"
    echo "   mount /dev/vg_storage/lv_apps_snap /mnt/snapshot"

    finalizar_ejercicio
}

ejercicio_27() {
    preparar_ejercicio "27" "AVAN.7 - LUKS Encryption"

    echo "🔍 Disco: $DISK_FREE"
    echo ""
    echo "📋 Pasos:"
    echo "   cryptsetup luksFormat $DISK_FREE"
    echo "   cryptsetup open $DISK_FREE crypt_data"
    echo "   mkfs.xfs /dev/mapper/crypt_data"
    echo "   mkdir /secure_data"
    echo "   mount /dev/mapper/crypt_data /secure_data"

    finalizar_ejercicio
}

ejercicio_28() {
    preparar_ejercicio "28" "AVAN.8 - crypttab + fstab"

    echo "📋 Automatizar volumen cifrado"
    echo ""
    echo "📋 Pasos:"
    echo "   blkid $DISK_FREE"
    echo "   editar /etc/crypttab"
    echo "   crypt_data UUID=<uuid> none luks"
    echo ""
    echo "   editar /etc/fstab"
    echo "   /dev/mapper/crypt_data /secure_data xfs defaults 0 2"

    finalizar_ejercicio
}

ejercicio_29() {
    preparar_ejercicio "29" "AVAN.9 - Restaurar metadata LVM"

    echo "📋 Restaurar metadata"
    echo ""
    echo "📋 Comandos:"
    echo "   ls /etc/lvm/archive"
    echo "   vgcfgrestore vg_storage"
    echo "   lvs"

    finalizar_ejercicio
}

ejercicio_30() {
    preparar_ejercicio "30" "AVAN.10 - Optimizar mount options"

    echo "📋 Optimizar montaje XFS"
    echo ""
    echo "📋 Pasos:"
    echo "   mount -o remount,noatime,nodev /mnt/xfs_data"
    echo ""
    echo "   editar /etc/fstab"
    echo "   añadir opciones:"
    echo "   noatime,nodev"

    finalizar_ejercicio
}
ejercicio_31() {
    preparar_ejercicio "31" "TROUBLE - Diagnosticar XFS"

    echo "📋 Diagnosticar fallo en montaje XFS"
    echo ""
    echo "Comandos útiles:"
    echo "   mount -a"
    echo "   blkid"
    echo "   cat /etc/fstab"

    finalizar_ejercicio
}

ejercicio_32() {
    preparar_ejercicio "32" "TROUBLE - Swap no activo"

    echo "📋 Diagnosticar swap"
    echo ""
    echo "Comandos:"
    echo "   swapon --show"
    echo "   journalctl -xe"
    echo "   ls -l $SWAPFILE"

    finalizar_ejercicio
}

ejercicio_33() {
    preparar_ejercicio "33" "TROUBLE - LVM vs FS mismatch"

    echo "📋 Diagnosticar diferencia tamaño"
    echo ""
    echo "Comandos:"
    echo "   lvs"
    echo "   df -h"
    echo "   resize2fs /dev/vg_storage/lv_apps"

    finalizar_ejercicio
}

ejercicio_34() {
    preparar_ejercicio "34" "TROUBLE - Mount duplicado"

    mount "$PART1" /mnt/ext4_data 2>/dev/null || true
    mount "$PART1" /backup_ext4 2>/dev/null || true

    echo "⚠️ Montaje duplicado creado"

    finalizar_ejercicio
}

ejercicio_35() {
    preparar_ejercicio "35" "TROUBLE - LVM paths sin UUID"

    echo "📋 Convertir paths a UUID"
    echo ""
    echo "Comandos:"
    echo "   blkid /dev/vg_storage/lv_*"
    echo "   editar /etc/fstab"

    finalizar_ejercicio
}

ejercicio_36() {
    preparar_ejercicio "36" "TROUBLE - Disco no montado"

    echo "📋 Recuperar disco /dev/vde"
    echo ""
    echo "Pasos:"
    echo "   mkdir /data_backup"
    echo "   mount /dev/vde /data_backup"

    finalizar_ejercicio
}

ejercicio_37() {
    preparar_ejercicio "37" "TROUBLE - Múltiples swaps"

    echo "📋 Consolidar swap"
    echo ""
    echo "Pasos:"
    echo "   swapon --show"
    echo "   swapoff $SWAPFILE"

    finalizar_ejercicio
}

ejercicio_38() {
    preparar_ejercicio "38" "TROUBLE - Verificar integridad LVM"

    echo "📋 Comandos diagnóstico"
    echo ""
    echo "   pvck"
    echo "   vgck"
    echo "   lvs -o +devices"

    finalizar_ejercicio
}

ejercicio_39() {
    preparar_ejercicio "39" "TROUBLE - Reparar emergency mode"

    echo "📋 Reparación de emergencia"
    echo ""
    echo "Pasos:"
    echo "   mount -o remount,rw /"
    echo "   editar /etc/fstab"
    echo "   comentar líneas incorrectas"

    finalizar_ejercicio
}

ejercicio_40() {
    preparar_ejercicio "40" "TROUBLE - xfs_growfs vs resize2fs"

    echo "📋 Diagnóstico"
    echo ""
    echo "Ext4 usa:"
    echo "   resize2fs"
    echo ""
    echo "XFS usa:"
    echo "   xfs_growfs"

    finalizar_ejercicio
}




# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

resetear_todo() {
    echo -e "${YELLOW}⚠️  Restaurando configuración base...${NC}"
    
    # Restaurar fstab original
    if [[ -f "$BACKUP_DIR/fstab.original" ]]; then
        cp "$BACKUP_DIR/fstab.original" /etc/fstab
    fi
    
    # Restaurar LVM
    lvresize -f -L "${LV_APPS_SIZE}M" "$LV_APPS" 2>/dev/null
    lvresize -f -L "${LV_LOGS_SIZE}M" "$LV_LOGS" 2>/dev/null
    
    # Restaurar swap
    swapoff "$SWAPFILE" 2>/dev/null
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE" 2>/dev/null
    swapon "$SWAPFILE" 2>/dev/null
    swapon "$SWAP_PART" 2>/dev/null
    
    # Desmontar todo
    umount /mnt/ext4_data /mnt/xfs_data /srv/apps /var/log/apps /backup_ext4 /data_backup 2>/dev/null || true
    
    # Limpiar loops
    systemctl restart lab-loops.service 2>/dev/null || true
    
    echo -e "${GREEN}✅ Sistema restaurado a estado base${NC}"
}

ver_estado() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📊 ESTADO ACTUAL DEL SISTEMA${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${BLUE}--- Discos ---${NC}"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE | grep -E "loop|vd|NAME"
    
    echo -e "\n${BLUE}--- Montajes activos ---${NC}"
    mount | grep -E "^/dev"
    
    echo -e "\n${BLUE}--- LVM ---${NC}"
    lvs 2>/dev/null | head -5
    
    echo -e "\n${BLUE}--- Swap ---${NC}"
    swapon --show 2>/dev/null || echo "No swap activo"
    
    echo -e "\n${BLUE}--- fstab (últimas líneas relevantes) ---${NC}"
    tail -20 /etc/fstab | grep -E "LAB|UUID|/dev" | tail -10
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

mostrar_menu() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}            🧪 LABORATORIO BLOQUE 3 - STORAGE (40 EJERCICIOS)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}📁 CONFIGURACIÓN ACTUAL:${NC}"
    echo "   Disco swap:     $DISK_SWAP"
    echo "   Disco LVM:      $DISK_LVM"
    echo "   Disco partic.:  $DISK_PART"
    echo "   Disco libre:    $DISK_FREE"
    echo "   Backup dir:     $BACKUP_DIR"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   🟢 NIVEL BÁSICO (Ej. 1-10)                    🟡 NIVEL INTERMEDIO (Ej. 11-20)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo "   1)  Listar dispositivos                    11)  Corregir error XFS/ext4"
    echo "   2)  Encontrar UUIDs                        12)  Sincronizar LV extendido"
    echo "   3)  Verificar montajes                      13)  Montaje persistente disco"
    echo "   4)  Inspeccionar PV                         14)  Corregir permisos swap"
    echo "   5)  Listar VG y LV                          15)  Extender lv_logs (XFS)"
    echo "   6)  Inspeccionar swap                        16)  Migrar LVM paths → UUIDs"
    echo "   7)  Verificar fstab                         17)  Redimensionar partición"
    echo "   8)  Montar disco manual                     18)  Expandir VG"
    echo "   9)  Desmontar duplicado                     19)  Crear LV por extents"
    echo "  10)  Identificar tipos FS                    20)  Limpiar mount redundante"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}   🔴 NIVEL AVANZADO (Ej. 21-30)                🟠 TROUBLESHOOTING (Ej. 31-40)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo "  21)  Boot failure (UUID)                    31)  Diagnosticar XFS"
    echo "  22)  Configurar Stratis                      32)  Swap no activo"
    echo "  23)  Migrar PV dañado                        33)  LVM vs FS mismatch"
    echo "  24)  Configurar VDO                          34)  Mount duplicado"
    echo "  25)  Reducir LV (peligro)                    35)  LVM paths sin UUID"
    echo "  26)  LVM Snapshot                            36)  Disco no montado"
    echo "  27)  LUKS encryption                          37)  Múltiples swaps"
    echo "  28)  crypttab + fstab                        38)  Verificar integridad LVM"
    echo "  29)  Restaurar metadata LVM                  39)  Reparar emergency mode"
    echo "  30)  Optimizar mount options                 40)  xfs_growfs vs resize2fs"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo "  41)  🔄 RESETEAR TODO"
    echo "  42)  📊 VER ESTADO ACTUAL"
    echo "   0)  Salir"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -n "Selecciona ejercicio [0-42]: "
}

# =============================================================================
# BUCLE PRINCIPAL
# =============================================================================

while true; do
    mostrar_menu
    read -r opcion
    
    case $opcion in
        1) ejercicio_01 ;; 2) ejercicio_02 ;; 3) ejercicio_03 ;; 4) ejercicio_04 ;;
        5) ejercicio_05 ;; 6) ejercicio_06 ;; 7) ejercicio_07 ;; 8) ejercicio_08 ;;
        9) ejercicio_09 ;; 10) ejercicio_10 ;; 11) ejercicio_11 ;; 12) ejercicio_12 ;;
        13) ejercicio_13 ;; 14) ejercicio_14 ;; 15) ejercicio_15 ;; 16) ejercicio_16 ;;
        17) ejercicio_17 ;; 18) ejercicio_18 ;; 19) ejercicio_19 ;; 20) ejercicio_20 ;;
        21) ejercicio_21 ;; 22) ejercicio_22 ;; 23) ejercicio_23 ;; 24) ejercicio_24 ;;
        25) ejercicio_25 ;; 26) ejercicio_26 ;; 27) ejercicio_27 ;; 28) ejercicio_28 ;;
        29) ejercicio_29 ;; 30) ejercicio_30 ;; 31) ejercicio_31 ;; 32) ejercicio_32 ;; 
        33) ejercicio_33 ;; 34) ejercicio_34 ;; 35) ejercicio_35 ;; 36) ejercicio_36 ;; 
        37) ejercicio_37 ;; 38) ejercicio_38 ;; 39) ejercicio_39 ;; 40) ejercicio_40 ;;
        
        
        41) resetear_todo ;;
        42) ver_estado ;;
        0) 
            echo -e "${GREEN}¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción no válida${NC}"
            sleep 2
            ;;
    esac
done
