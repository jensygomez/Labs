#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 02
# Scenario: Servicio crítico bloqueando el boot
# Nivel: Producción realista
# Author: Jensy Gomez
# ============================================================

set -euo pipefail

# -------------------------------
# Variables
# -------------------------------
SERVICE_NAME="app-critical.service"
MOUNT_POINT="/data/app"

LOG_FILE="/var/log/inject_boot.log"
TICKET_FILE="/root/TICKET_BOOT_02.txt"

# -------------------------------
# Logging silencioso
# -------------------------------
log_injection() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Inject V2 Boot executed" >> "$LOG_FILE"
}

# -------------------------------
# Crear servicio crítico
# -------------------------------
cat << EOF > /etc/systemd/system/${SERVICE_NAME}
[Unit]
Description=Critical Application Service
Requires=${MOUNT_POINT}.mount
After=${MOUNT_POINT}.mount
DefaultDependencies=no

[Service]
Type=simple
ExecStart=/bin/sleep infinity

[Install]
WantedBy=multi-user.target
EOF

# -------------------------------
# Crear unidad mount inexistente
# -------------------------------
cat << EOF > /etc/systemd/system/${MOUNT_POINT//\//-}.mount
[Unit]
Description=Application Data Mount

[Mount]
What=/dev/mapper/vg_data-lv_app
Where=${MOUNT_POINT}
Type=xfs

[Install]
WantedBy=multi-user.target
EOF

# -------------------------------
# NO crear el directorio ni validar el mount
# Esto provoca el bloqueo real del boot
# -------------------------------

systemctl daemon-reexec
systemctl enable ${SERVICE_NAME}
systemctl enable ${MOUNT_POINT}.mount

# -------------------------------
# Ticket de incidente
# -------------------------------
cat << 'EOF' > "$TICKET_FILE"
==================================================
        INCIDENTE – SISTEMA NO FINALIZA EL ARRANQUE
==================================================

Escenario:
  Tras un reinicio, el sistema queda detenido durante
  el proceso de arranque y no alcanza el estado operativo.

Síntomas observados:
  - Boot incompleto
  - systemd esperando una dependencia
  - No se alcanza multi-user.target

Tarea:
  1. Identificar qué unidad está bloqueando el arranque.
  2. Determinar por qué la dependencia no se cumple.
  3. Restaurar el arranque normal del sistema.
  4. Verificar persistencia tras reboot.

Restricciones:
  - No reinstalar
  - No deshabilitar servicios sin análisis
  - Mantener consistencia del sistema

Criterios de validación:
  ✓ Boot completo sin bloqueos
  ✓ multi-user.target alcanzado
  ✓ Servicio crítico manejado correctamente

==================================================
EOF

chmod 600 "$TICKET_FILE"

# -------------------------------
# Logging
# -------------------------------
log_injection

exit 0
