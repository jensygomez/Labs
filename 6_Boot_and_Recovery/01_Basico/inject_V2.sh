#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 02
# Scenario: Entrada incorrecta en /etc/fstab → emergency mode
# ============================================================

set -euo pipefail



# Variables del escenario
BAD_UUID="12345678-1234-1234-1234-123456789abc"   # UUID inventado que no existe
BAD_MOUNTPOINT="/mnt/datos_criticos"
LOG_FILE="/var/log/inject_boot.log"

# -------------------------------
# Función para mostrar el ticket con colores
# -------------------------------
show_ticket() {
    clear
    cat << 'EOF'

${CYAN}==================================================${RESET}
${CYAN}       INCIDENTE – SISTEMA ENTRA EN MODO EMERGENCIA${RESET}
${CYAN}==================================================${RESET}

${YELLOW}Escenario:${RESET}
  Tras un reinicio rutinario, el sistema no completa
  el arranque normal. Se detiene en modo emergencia
  y solicita la contraseña de root.

${YELLOW}Síntomas observados:${RESET}
  ${RED}- El sistema entra directamente en emergency mode${RESET}
  ${RED}- Aparece el mensaje: "Give root password for maintenance"${RESET}
  ${RED}- No se montan todos los filesystems esperados${RESET}
  ${RED}- No hay acceso normal al login de usuarios${RESET}

${YELLOW}Tarea:${RESET}
  1. Identificar la causa del fallo de arranque.
  2. Corregir la configuración responsable.
  3. Asegurar que el sistema arranque correctamente de forma persistente.
  4. Verificar el arranque normal tras reinicio.

${YELLOW}Restricciones:${RESET}
  - No reinstalar el sistema
  - No eliminar datos existentes
  - No modificar configuraciones innecesarias

${YELLOW}Criterios de validación:${RESET}
  ${GREEN}✓${RESET} El sistema arranca en multi-user.target (modo normal)
  ${GREEN}✓${RESET} No se solicita contraseña de mantenimiento
  ${GREEN}✓${RESET} El archivo /etc/fstab es válido
  ${GREEN}✓${RESET} El cambio persiste tras reboot

${CYAN}==================================================${RESET}
EOF
}

# -------------------------------
# Logging (tolerante a errores)
# -------------------------------
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') - inject_V2 Boot ejecutado (fstab corrupto)" 
    echo "   → UUID falso añadido: $BAD_UUID → $BAD_MOUNTPOINT"
} >> "$LOG_FILE" 2>/dev/null || true

# -------------------------------
# Mostrar ticket inmediatamente
# -------------------------------
show_ticket

# -------------------------------
# Inyección del fallo
# -------------------------------
echo -e "${CYAN}[INFO] Inyectando fallo en /etc/fstab...${RESET}"

# Añadimos una línea incorrecta al final de fstab
cat << BADENTRY >> /etc/fstab
UUID=$BAD_UUID  $BAD_MOUNTPOINT  xfs  defaults  0 0
BADENTRY

echo -e "${GREEN}[INFO] Línea añadida a /etc/fstab:${RESET}"
echo "UUID=$BAD_UUID  $BAD_MOUNTPOINT  xfs  defaults  0 0"

echo
echo -e "${YELLOW}[ADVERTENCIA] El sistema entrará en emergency mode en el próximo reinicio.${RESET}"
echo -e "${YELLOW}[ADVERTENCIA] Usa la contraseña de root para entrar y arreglarlo.${RESET}"
echo

# -------------------------------
# Salida limpia
# -------------------------------
echo -e "${GREEN}[OK] inject_V2 terminado correctamente.${RESET}"
exit 0