#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 03 (Básico)
# Scenario: Root filesystem montado como read-only
# ============================================================

set -euo pipefail


LOG_FILE="/var/log/inject_boot.log"

# -------------------------------
# Función para mostrar el ticket con colores
# -------------------------------
show_ticket() {
    clear
    cat << 'EOF'

${CYAN}==================================================${RESET}
${CYAN}     INCIDENTE – ROOT FILESYSTEM EN READ-ONLY${RESET}
${CYAN}==================================================${RESET}

${YELLOW}Escenario:${RESET}
  Tras un mantenimiento reciente, el sistema arranca
  aparentemente normal, pero no permite realizar
  cambios en el sistema de archivos raíz.

${YELLOW}Síntomas observados:${RESET}
  ${RED}- El sistema permite login normal como usuario${RESET}
  ${RED}- Comandos como touch, mkdir, yum, dnf fallan con:${RESET}
  ${RED}  "Read-only file system"${RESET}
  ${RED}- El montaje de / muestra "ro" en lugar de "rw"${RESET}
  ${RED}- No se pueden crear ni modificar archivos en /${RESET}

${YELLOW}Tarea:${RESET}
  1. Identificar por qué el root filesystem está en modo read-only.
  2. Restaurar el montaje correcto en read-write.
  3. Asegurar que el cambio sea persistente tras reinicio.

${YELLOW}Restricciones:${RESET}
  - No reinstalar el sistema
  - No usar live CD/ISO si no es estrictamente necesario
  - Mantener todos los datos existentes

${YELLOW}Criterios de validación:${RESET}
  ${GREEN}✓${RESET} El root filesystem está montado como rw
  ${GREEN}✓${RESET} Se pueden crear/modificar archivos en /
  ${GREEN}✓${RESET} El cambio persiste tras reboot
  ${GREEN}✓${RESET} El sistema arranca en multi-user.target

${CYAN}==================================================${RESET}
EOF
}

# -------------------------------
# Logging (tolerante)
# -------------------------------
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') - inject_V3 Boot ejecutado (root read-only)"
    echo "   → Forzando parámetro 'ro' en GRUB"
} >> "$LOG_FILE" 2>/dev/null || true

# -------------------------------
# Mostrar ticket
# -------------------------------
show_ticket

# -------------------------------
# Inyección del fallo
# -------------------------------
echo -e "${CYAN}[INFO] Inyectando fallo: root filesystem en read-only...${RESET}"

# Añadimos "ro" al final de GRUB_CMDLINE_LINUX si no está ya
if ! grep -q " ro$" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ro /' /etc/default/grub
else
    echo -e "${YELLOW}[INFO] Ya existe 'ro' al final, asegurando...${RESET}"
fi

# Regeneramos grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1

echo -e "${GREEN}[OK] Parámetro 'ro' añadido a GRUB_CMDLINE_LINUX${RESET}"
echo -e "${GREEN}[OK] grub2-mkconfig ejecutado${RESET}"

echo
echo -e "${YELLOW}[ADVERTENCIA] En el próximo reinicio, / estará montado como read-only.${RESET}"
echo -e "${YELLOW}[ADVERTENCIA] Podrás loguearte, pero no modificar nada en raíz.${RESET}"
echo -e "${YELLOW}[SUGERENCIA] Prueba editar la línea de GRUB temporalmente (tecla 'e') o corrige /etc/default/grub${RESET}"
echo

# -------------------------------
# Salida limpia
# -------------------------------
echo -e "${GREEN}[OK] inject_V3 terminado correctamente.${RESET}"
exit 0