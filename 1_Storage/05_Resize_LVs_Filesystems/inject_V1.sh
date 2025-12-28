#!/bin/bash
# RHCSA EX200 – Storage Slot 05 – Variation 1
# Purpose: LV extended but filesystem not updated (Basic)
# Modular version: setup + ticket

set -e

# Colores para ticket
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Función: Preparación del entorno de Storage
setup_storage() {
    echo -e "${CYAN}==> Ejecutando setup del laboratorio...${RESET}"

    # Selección dinámica de disco
    DISK=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}' | grep -E '^sd[b-f]$' | shuf -n1)
    DEVICE="/dev/${DISK}"

    VG="vg_exam"
    LV="lv_data"
    MNT="/data"

    # Preparación del disco
    wipefs -a "$DEVICE"
    pvcreate -ff -y "$DEVICE" >/dev/null

    # Crear VG si no existe
    if ! vgdisplay "$VG" >/dev/null 2>&1; then
        vgcreate "$VG" "$DEVICE" >/dev/null
    else
        vgextend "$VG" "$DEVICE" >/dev/null
    fi

    # Crear LV si no existe
    if ! lvdisplay "/dev/$VG/$LV" >/dev/null 2>&1; then
        lvcreate -L 1G -n "$LV" "$VG" >/dev/null
        mkfs.ext4 -F "/dev/$VG/$LV" >/dev/null
    fi

    # Crear punto de montaje
    mkdir -p "$MNT"

    # Montaje inicial
    mount "/dev/$VG/$LV" "$MNT"

    # Persistencia inicial
    UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
    grep -q "$MNT" /etc/fstab || \
        echo "UUID=$UUID $MNT ext4 defaults 0 0" >> /etc/fstab

    # Expansión del LV (sin tocar el filesystem)
    lvextend -L +1G "/dev/$VG/$LV" >/dev/null

    # Limpieza visual
    sync

    echo -e "${GREEN}==> Setup completado.${RESET}"
}

# Función: Mostrar ticket del laboratorio
ticket_storage() {
    echo -e "${YELLOW}=========================================${RESET}"
    echo -e "${BLUE}RHCSA EX200 - Storage Lab${RESET}"
    echo -e "${CYAN}Laboratorio:${RESET} Resize LVs & Filesystems"
    echo -e "${CYAN}Nivel:${RESET} Troubleshooting Básico 1.1 (Inject_V1)"
    echo -e "${CYAN}Dispositivo asignado:${RESET} $DEVICE"
    echo -e "${CYAN}Volume Group:${RESET} $VG"
    echo -e "${CYAN}Logical Volume:${RESET} $LV"
    echo -e "${CYAN}Punto de montaje:${RESET} $MNT"
    echo -e "${CYAN}Estado actual LV:${RESET}"
    lvdisplay "/dev/$VG/$LV" | grep -E "LV Name|LV Size"
    echo -e "${YELLOW}=========================================${RESET}"
}

# --- EJECUCIÓN ---
setup_storage
ticket_storage
