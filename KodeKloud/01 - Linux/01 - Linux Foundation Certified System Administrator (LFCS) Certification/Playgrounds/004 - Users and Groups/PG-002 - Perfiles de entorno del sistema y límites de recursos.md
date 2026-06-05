---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: PG-002
Titulo: Perfiles de entorno del sistema y límites de recursos
Fecha de Inicio: 2026-06-05
Dificultad: 4/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - System-Wide Environment Profiles
  - User Resource Limits
Competencias:
  - Configurar variables de entorno globales persistentes mediante /etc/profile.d/
  - Restringir el uso de recursos del sistema (max user processes) por grupo o usuario
  - Definir alias globales obligatorios para el intérprete de comandos (Bash)
Ticket: |-
  INC-2002

  El equipo de seguridad de TI ha emitido dos nuevas directivas obligatorias para el servidor de desarrollo:
  1. Todos los usuarios del sistema deben tener disponible de forma automática la variable de entorno 'CORP_STAGE' con el valor 'PRODUCTION'. Esta configuración debe ser modular y no alterar el archivo principal /etc/profile.
  2. Para evitar ataques de denegación de servicio internos o bucles infinitos accidentales, los miembros del grupo "devs" (creado en el PG-001) deben tener un límite estricto en el número de procesos simultáneos que pueden abrir: un límite blando (soft) de 100 procesos y un límite duro (hard) de 150 procesos.

  Investigue los directorios de perfil y los archivos de control de seguridad de PAM, aplique los cambios y asegure su persistencia.
Validacion:
  - Objetivo: Variable CORP_STAGE definida globalmente de forma modular en /etc/profile.d/.
    Peso: 30 %
  - Objetivo: Límite blando (soft nproc) de 100 procesos aplicado al grupo @devs.
    Peso: 20 %
  - Objetivo: Límite duro (hard nproc) de 150 procesos aplicado al grupo @devs.
    Peso: 20 %
  - Objetivo: Alias global de seguridad 'rm' configurado para todos los usuarios.
    Peso: 30 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Asegurar la existencia del grupo devs (por si se corre aislado del PG-001)
  getent group devs >/dev/null 2>&1 || groupadd -g 2500 devs

  # Limpieza de intentos previos
  rm -f /etc/profile.d/corp_env.sh
  rm -f /etc/security/limits.d/99-devs.conf
  sed -i '/@devs/d' /etc/security/limits.conf

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ESCENARIO CONFIGURADO - MÓDULO USERS & GROUPS (PG-002)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-2002\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Perfiles de entorno del sistema y límites de recursos"
  echo -e " \e[1mSeveridad:\e[0m Alta / Ajuste de Rendimiento y Seguridad"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Configure la variable global modular CORP_STAGE=PRODUCTION, defina un alias"
  echo -e " global para que 'rm' siempre pida confirmación ('rm -i'), y limite los"
  echo -e " procesos máximos (nproc) del grupo '@devs' (Soft: 100, Hard: 150)."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Variable CORP_STAGE en /etc/profile.d/*.sh                  --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Límite @devs soft nproc 100                                --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Límite @devs hard nproc 150                                --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Alias global de seguridad para 'rm' configurado             --> \e[1;35m30%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO ENTORNOS Y LÍMITES DE RECURSOS ==="

  # 1. Validar variable de entorno global en /etc/profile.d/
  # Buscamos en cualquier archivo .sh dentro de la ruta
  if grep -r -q "export CORP_STAGE=PRODUCTION" /etc/profile.d/*.sh 2>/dev/null || grep -r -q "CORP_STAGE=\"PRODUCTION\"" /etc/profile.d/*.sh 2>/dev/null; then
      echo "✔ [30%] Variable global CORP_STAGE configurada modularmente de forma correcta."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] La variable CORP_STAGE no está definida en ningún script de /etc/profile.d/."
  fi

  # 2. Validar límites de recursos (limits.conf o en limits.d/)
  LIMITS_FILES="/etc/security/limits.conf /etc/security/limits.d/*.conf"

  SOFT_CHECK=$(grep -E -h "^\s*@devs\s+soft\s+nproc\s+100" $LIMITS_FILES 2>/dev/null || true)
  HARD_CHECK=$(grep -E -h "^\s*@devs\s+hard\s+nproc\s+150" $LIMITS_FILES 2>/dev/null || true)

  if [ -n "$SOFT_CHECK" ]; then
      echo "✔ [20%] Límite blando (soft nproc) de 100 procesos verificado para @devs."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Falta o está incorrecto el límite blando (soft nproc) para el grupo @devs."
  fi

  if [ -n "$HARD_CHECK" ]; then
      echo "✔ [20%] Límite duro (hard nproc) de 150 procesos verificado para @devs."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Falta o está incorrecto el límite duro (hard nproc) para el grupo @devs."
  fi

  # 4. Validar alias global de seguridad
  if grep -r -q "alias rm=" /etc/profile.d/*.sh 2>/dev/null || grep -q "alias rm=" /etc/bashrc; then
      echo "✔ [30%] Alias global de seguridad para 'rm' configurado exitosamente."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] No se encontró ningún alias global que proteja el comando 'rm'."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
