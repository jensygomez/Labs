#!/bin/bash
# RHCSA EX200 – Boot & Recovery Slot 02
# Purpose: Servicio crítico bloqueando el boot
# Author: Jensy Gomez

set -euo pipefail

SERVICE_NAME="broken-boot.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
LOG_FILE="/var/log/inject_boot.log"

log_injection() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Inject V2 executed" >> "$LOG_FILE"
}

# Validación básica
command -v systemctl &> /dev/null || exit 1

# Crear servicio roto (pero realista)
cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Broken Boot Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/fakebinary
Restart=no

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar servicio
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

# Logging silencioso
log_injection

exit 0
