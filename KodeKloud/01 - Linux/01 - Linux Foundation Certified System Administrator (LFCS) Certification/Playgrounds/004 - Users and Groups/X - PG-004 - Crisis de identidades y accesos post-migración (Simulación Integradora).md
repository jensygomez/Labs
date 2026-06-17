---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: PG-004
Titulo: Crisis de identidades y accesos post-migración (Simulación Integradora)
Fecha de Inicio: 2026-06-03
Dificultad: 8/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Local Users and Groups
  - Template User Environment
  - System-Wide Environment Profiles
  - User Resource Limits
  - User Privileges and Root Access
Competencias:
  - Triage y auditoría forense de archivos de configuración de usuarios (/etc/passwd, shadow, sudoers)
  - Resolución de problemas de herencia y plantillas de perfiles de entorno
  - Corrección de fugas de privilegios e implementación de mínimos privilegios (PoLP)
Ticket: |-
  INC-2004

  Tras una ventana de actualización del sistema de gestión de identidades, el servidor central ha quedado desconfigurado. El equipo de auditoría de seguridad emitió una alerta máxima con los siguientes hallazgos:
  1. El usuario "consultor1" fue creado con IDs erróneos, no expira cuando debería y su grupo primario desapareció.
  2. La plantilla global (/etc/skel) fue modificada indebidamente, eliminando las configuraciones estándar de Bash.
  3. Alguien dejó una regla en sudoers que otorga privilegios totales a cuentas que no deberían tenerlos.
  4. Los límites de seguridad de procesos del grupo "devs" fueron borrados del sistema.
  5. La resolución de nombres en nsswitch quedó corrupta, ralentizando o rompiendo los inicios de sesión.

  Misión: Audite el estado actual del servidor, repare cada falla respetando las normativas corporativas, mantenga la seguridad intacta y devuelva el control total de los accesos al 100%.
Validacion:
  - Objetivo: Usuario 'consultor1' corregido (UID 2501, grupo primario 'devs', expiración 2026-12-31).
    Peso: 25 %
  - Objetivo: Plantilla /etc/skel restaurada y con el archivo corporativo WELCOME_CORP.txt.
    Peso: 20 %
  - Objetivo: Fuga de sudoers corregida; el grupo @devs solo puede ejecutar 'systemctl restart'.
    Peso: 20 %
  - Objetivo: Límites de recursos (soft/hard nproc) del grupo @devs restaurados de forma persistente.
    Peso: 20 %
  - Objetivo: Archivo nsswitch.conf reparado para buscar en archivos locales primero y luego sssd.
    Peso: 15 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # 1. Forzar escenario de Caos de Identidades
  groupadd -g 2500 devs 2>/dev/null || true
  userdel -r consultor1 2>/dev/null || true

  # Crear usuario corrupto (UID incorrecto, sin expiración, grupo primario incorrecto)
  useradd -u 9999 -g nobody consultor1
  chage -E -1 consultor1

  # 2. Romper plantilla global /etc/skel
  rm -f /etc/skel/WELCOME_CORP.txt
  rm -f /etc/skel/.bashrc /etc/skel/.bash_profile 2>/dev/null || true

  # 3. Inyectar Fuga Crítica en Sudoers
  rm -f /etc/sudoers.d/devs-privileges
  echo "consultor1 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/security-breach

  # 4. Eliminar límites de recursos
  sed -i '/@devs/d' /etc/security/limits.conf 2>/dev/null || true
  rm -f /etc/security/limits.d/*devs*.conf 2>/dev/null || true

  # 5. Romper la sintaxis de NSSwitch
  sed -i 's/^passwd:.*/passwd:      sssd [NOTFOUND=return] files/' /etc/nsswitch.conf
  sed -i 's/^group:.*/group:       sssd [NOTFOUND=return] files/' /etc/nsswitch.conf

  clear
  echo -e "\e[1;31m================================================================================\e[0m"
  echo -e "\e[1;37;41m 🔥 CRISIS EN IDENTIDADES Y ACCESOS: INICIANDO PG-004 (EXAMEN) 🔥 \e[0m"
  echo -e "\e[1;31m================================================================================\e[0m"
  echo -e " El servidor de desarrollo ha sufrido una corrupción severa de configuraciones."
  echo -e " Múltiples directivas de seguridad, accesos y entornos están comprometidos."
  echo -e ""
  echo -e " \e[1mRequerimientos técnicos para el Triage:\e[0m"
  echo -e "  1. Arreglar 'consultor1' (UID:2501, GID primario:devs, Expiración:2026-12-31)."
  echo -e "  2. Recuperar archivos ocultos base en /etc/skel/ y añadir WELCOME_CORP.txt."
  echo -e "  3. Eliminar el archivo backdoor de sudoers y delegar solo 'systemctl restart'."
  echo -e "  4. Configurar límites de procesos para @devs (Soft: 100, Hard: 150)."
  echo -e "  5. Corregir el orden de NSSwitch (files primero, luego sssd)."
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Piense como Sysadmin, repare la infraestructura y ejecute la validación.\e[0m"
  echo -e "\e[1;31m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO EL EXAMEN INTEGRADOR DE USER AND GROUPS (PG-004) ==="

  # 1. Validar corrección del usuario consultor1
  if id consultor1 >/dev/null 2>&1; then
      UID_C=$(id -u consultor1)
      GID_C=$(id -g consultor1)
      EXP_C=$(getent shadow consultor1 | cut -d: -f8)
      
      if [ "$UID_C" -eq 2501 ] && [ "$GID_C" -eq 2500 ] && [ "$EXP_C" = "20819" ]; then
          echo "✔ [25%] Objetivo 1: Cuentas y parámetros del usuario 'consultor1' corregidos al 100%."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] Objetivo 1: 'consultor1' existe, pero el UID ($UID_C), GID ($GID_C) o la expiración no coinciden."
      fi
  else
      echo "❌ [0%] Objetivo 1: El usuario 'consultor1' no fue encontrado en el sistema."
  fi

  # 2. Validar integridad de /etc/skel
  if [ -f /etc/skel/WELCOME_CORP.txt ] && [ -f /etc/skel/.bashrc ]; then
      echo "✔ [20%] Objetivo 2: Esqueleto del sistema (/etc/skel) restaurado y funcional."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Objetivo 2: Falta 'WELCOME_CORP.txt' o los archivos ocultos (.bashrc) en la plantilla."
  fi

  # 3. Validar resolución de fuga en Sudoers
  if [ -f /etc/sudoers.d/security-breach ]; then
      echo "❌ [0%] Objetivo 3: Alerta de seguridad activa: El backdoor '/etc/sudoers.d/security-breach' sigue existiondo."
  else
      FILE_SUDO="/etc/sudoers.d/devs-privileges"
      if [ -f "$FILE_SUDO" ] && grep -E "^\s*@devs\s+.*NOPASSWD:\s*\/usr\/bin\/systemctl\s+restart" "$FILE_SUDO" >/dev/null 2>&1; then
          echo "✔ [20%] Objetivo 3: Fuga de privilegios mitigada y accesos granulares activos."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] Objetivo 3: Se eliminó el backdoor, pero no se crearon los accesos correctos en '$FILE_SUDO'."
      fi
  fi

  # 4. Validar restauración de límites
  LIMITS_FILES="/etc/security/limits.conf /etc/security/limits.d/*.conf"
  SOFT_CHECK=$(grep -E -h "^\s*@devs\s+soft\s+nproc\s+100" $LIMITS_FILES 2>/dev/null || true)
  HARD_CHECK=$(grep -E -h "^\s*@devs\s+hard\s+nproc\s+150" $LIMITS_FILES 2>/dev/null || true)

  if [ -n "$SOFT_CHECK" ] && [ -n "$HARD_CHECK" ]; then
      echo "✔ [20%] Objetivo 4: Límites de control de procesos del grupo @devs restablecidos."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Objetivo 4: Los límites de recursos para el grupo de desarrollo siguen vacíos o incorrectos."
  fi

  # 5. Validar orden de NSSwitch
  PASSWD_NSS=$(grep "^passwd:" /etc/nsswitch.conf || true)
  if echo "$PASSWD_NSS" | grep -E "files\s+sssd" >/dev/null 2>&1; then
      echo "✔ [15%] Objetivo 5: Orden de resolución NSSwitch reparado (files -> sssd)."
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ [0%] Objetivo 5: NSSwitch sigue buscando en red antes que de forma local."
  fi

  echo "=========================================="
  echo "CALIFICACIÓN FINAL INTEGRAL: $PUNTOS / 100"
  echo "=========================================="
---

[[Laboratorios del LFCS]]
---
