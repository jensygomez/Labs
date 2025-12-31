#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 04 (Intermedio)
# Scenario: Contraseña de root olvidada / bloqueada
# ============================================================

set -euo pipefail

# Colores
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

LOG_FILE="/var/log/inject_boot.log"
NEW_BAD_PASS="wrong_$(openssl rand -hex 8)"  # Contraseña aleatoria inválida

# -------------------------------
# Función para mostrar el ticket con colores
# -------------------------------
show_ticket() {
    clear
    cat << 'EOF'

${CYAN}==================================================${RESET}
${CYAN}     INCIDENTE – CONTRASEÑA DE ROOT OLVIDADA${RESET}
${CYAN}==================================================${RESET}

${YELLOW}Escenario:${RESET}
  Un compañero de equipo cambió la contraseña de root
  hace unas semanas y nadie la recuerda. El acceso sudo
  de usuarios normales también falla porque requiere
  autenticación de root o está bloqueado.

${YELLOW}Síntomas observados:${RESET}
  ${RED}- No se puede hacer sudo (Authentication failure)${RESET}
  ${RED}- No se puede entrar como root directamente${RESET}
  ${RED}- El sistema arranca normalmente hasta login${RESET}
  ${RED}- No hay acceso físico al servidor (solo SSH)${RESET}

${YELLOW}Tarea:${RESET}
  1. Recuperar acceso administrativo completo.
  2. Establecer una nueva contraseña segura para root.
  3. Verificar que sudo vuelve a funcionar para usuarios autorizados.
  4. Asegurar que el cambio persiste tras reinicio.

${YELLOW}Restricciones:${RESET}
  - No reinstalar el sistema
  - No usar medios externos si no es necesario
  - Mantener toda la configuración y datos existentes

${YELLOW}Criterios de validación:${RESET}
  ${GREEN}✓${RESET} Se puede hacer login como root con nueva contraseña
  ${GREEN}✓${RESET} Usuarios con permiso pueden usar sudo
  ${GREEN}✓${RESET} No hay mensajes de autenticación fallida
  ${GREEN}✓${RESET} El sistema mantiene integridad SELinux (si aplica)

${CYAN}==================================================${RESET}
EOF
}

# -------------------------------
# Logging (tolerante)
# -------------------------------
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') - inject_V4 Boot ejecutado (root password corrupta)"
    echo "   → Contraseña cambiada a valor inválido aleatorio"
} >> "$LOG_FILE" 2>/dev/null || true

# -------------------------------
# Mostrar ticket
# -------------------------------
show_ticket

# -------------------------------
# Inyección del fallo: cambiar contraseña de root a algo inválido
# -------------------------------
echo -e "${CYAN}[INFO] Cambiando contraseña de root a valor inválido...${RESET}"

# Usamos chpasswd para evitar interactivo
echo "root:$NEW_BAD_PASS" | chpasswd

echo -e "${RED}[OK] Contraseña de root modificada (ahora es inválida)${RESET}"

echo
echo -e "${YELLOW}[ADVERTENCIA] Desde el próximo login o sudo, se denegará acceso root.${RESET}"
echo -e "${YELLOW}[SUGERENCIA] Usa rd.break en GRUB para recuperar acceso:${RESET}"
echo -e "${YELLOW}    1. Edita línea GRUB → añade rd.break${RESET}"
echo -e "${YELLOW}    2. monta /sysroot, chroot, passwd, etc.${RESET}"
echo

# -------------------------------
# Salida limpia
# -------------------------------
echo -e "${GREEN}[OK] inject_V4 terminado correctamente.${RESET}"
exit 0