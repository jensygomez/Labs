#!/bin/bash
# RHCSA EX200 – Boot & Recovery Slot 03
# Purpose: /etc/fstab rompe el arranque (emergency mode real)
# Author: Jensy Gomez

set -euo pipefail

LOG_FILE="/var/log/inject_boot.log"
MOUNT_POINT="/data"
BROKEN_DEVICE="/dev/sdz1"
FSTAB="/etc/fstab"

log_injection() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Inject V3 executed (fstab broken)" >> "$LOG_FILE"
}

# Validaciones básicas
[ "$(id -u)" -eq 0 ] || exit 1
[ -f "$FSTAB" ] || exit 1

# Crear punto de montaje si no existe (silencioso)
mkdir -p "$MOUNT_POINT"

# Backup de seguridad (oculto al alumno)
cp -p "$FSTAB" "${FSTAB}.bak_ex200"

# Inyectar entrada inválida en fstab
# Dispositivo inexistente + sin nofail => emergency mode
echo "${BROKEN_DEVICE}  ${MOUNT_POINT}  ext4  defaults  0  0" >> "$FSTAB"

# Logging
log_injection

exit 0
