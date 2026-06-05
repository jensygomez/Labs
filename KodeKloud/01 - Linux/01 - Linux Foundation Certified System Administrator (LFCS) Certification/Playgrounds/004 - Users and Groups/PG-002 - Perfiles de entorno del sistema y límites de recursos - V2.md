---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: PG-002
Titulo: Perfiles de entorno del sistema y límites de recursos - V2
Fecha de Inicio: 2026-06-05
Dificultad: 7.5/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno Level 2/3
Temas:
  - System-Wide Environment Profiles Hardening
  - PAM Resource Limits & Memory Constraints (limits.conf)
  - Shell Audit Traceability (History Customization)
Competencias:
  - Asegurar la inmutabilidad de variables globales del sistema operativo mediante directivas de Shell
  - Mitigar ataques de denegación de servicio (DoS) y fugas de memoria mediante contención multifactor en PAM (`nproc` y `as`)
  - Configurar persistencia inmediata de telemetría e historial en entornos multiusuario
Ticket: |-
  INC-7022 (CRÍTICO) - Inestabilidad de Memoria y Evasión de Auditoría en Nodo de Staging

  El clúster de compilación reportó un pánico menor debido a que scripts automatizados del grupo '@devs' están spawneando subprocesos de Node.js de forma descontrolada, consumiendo la memoria virtual total asignada al espacio de usuario. Adicionalmente, el equipo de SecOps detectó que algunos consultores limpian deliberadamente su historial de comandos (`history -c`) antes de desloguearse para evadir auditorías.

  Requerimientos Técnicos del Ticket:
  1. Restricción de Recursos Quirúrgica (PAM):
     - Bloquear al grupo '@devs' para que no pueda levantar más de 80 procesos simultáneos de forma blanda (soft nproc) y un límite destructivo de 120 (hard nproc).
     - Añadir un límite estricto de Memoria Virtual Maxima (Address Space / `as`) de 2GB (2097152 KB) por proceso para evitar el desborde del host.
     - Esta configuración DEBE residir exclusivamente en el archivo `/etc/security/limits.d/50-devs-hardening.conf`.
  2. Inmutabilidad de Entorno Global:
     - Configurar de manera modular la variable corporativa `CORP_STAGE="PRODUCTION"`.
     - Garantizar que ningún usuario intermedio pueda alterar, modificar o hacer `unset` de esta variable durante su sesión.
  3. Trazabilidad Forense de Terminales:
     - Configurar de forma global en los perfiles del sistema las directivas necesarias para forzar que el historial de comandos se guarde de forma INMEDIATA en cada pulsación de enter (`history -a`) y elevar la capacidad de retención a 10,000 líneas.
Validacion:
  - Objetivo: Archivo /etc/security/limits.d/50-devs-hardening.conf contiene las cuotas de nproc y memoria virtual (as).
    Peso: 35 %
  - Objetivo: Script modular de entorno define CORP_STAGE y lo bloquea con atributo readonly.
    Peso: 35 %
  - Objetivo: Configuración global de auditoría de historial inyectada de forma correcta en /etc/profile.d/.
    Peso: 30 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Garantizar la existencia del grupo devs para el entorno aislado
  getent group devs >/dev/null 2>&1 || groupadd -g 2500 devs



  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO AVANZADO CONFIGURADO - USERS & GROUPS (PG-002 v2)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-7022\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Perfiles de entorno del sistema y límites de recursos"
  echo -e " \e[1mSeveridad:\e[0m Crítica / Mitigación de Denegación de Servicio (DoS)"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Restrinja el Address Space y procesos simultáneos del grupo '@devs' en limits.d."
  echo -e " Aplique la variable inmutable CORP_STAGE y configure el vaciado inmediato del"
  echo -e " historial de comandos para auditoría interna."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación:\e[0m"
  echo -e "  [ ] Cuotas nproc (80/120) y límite 'as' de 2GB en limits.d      --> \e[1;35m35%\e[0m"
  echo -e "  [ ] Variable CORP_STAGE inmutable con atributo 'readonly'       --> \e[1;35m35%\e[0m"
  echo -e "  [ ] Auditoría inmediata de historial (history -a) configurada   --> \e[1;34m30%\e[0m"
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

  echo "=== AUDITORÍA FORENSE DE RECURSOS Y COMPLIANCE DE ENTORNO ==="

  TARGET_LIMITS="/etc/security/limits.d/50-devs-hardening.conf"
  ENV_FILE="/etc/profile.d/corp_env.sh"
  AUDIT_FILE="/etc/profile.d/audit_history.sh"

  # 1. Validar Archivo de Límites y Contención de Recursos
  if [ -f "$TARGET_LIMITS" ]; then
      SOFT_NPROC=$(grep -E "^\s*@devs\s+soft\s+nproc\s+80" "$TARGET_LIMITS" || true)
      HARD_NPROC=$(grep -E "^\s*@devs\s+hard\s+nproc\s+120" "$TARGET_LIMITS" || true)
      HARD_AS=$(grep -E "^\s*@devs\s+hard\s+as\s+2097152" "$TARGET_LIMITS" || true)
      
      if [ -n "$SOFT_NPROC" ] && [ -n "$HARD_NPROC" ] && [ -n "$HARD_AS" ]; then
          echo "✔ [35%] Límites de procesos (80/120) y Address Space (2GB) inyectados correctamente en limits.d."
          PUNTOS=$((PUNTOS + 35))
      else
          echo "❌ [10%] El archivo de límites existe pero no cumple con todas las métricas (nproc o 'as' faltantes/incorrectos)."
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo "❌ [0%] No se encontró el archivo de límites corporativo exigido en: $TARGET_LIMITS"
  fi

  # 2. Validar Inmutabilidad de la Variable de Entorno
  if [ -f "$ENV_FILE" ]; then
      if grep -q "CORP_STAGE=" "$ENV_FILE" && grep -q "readonly CORP_STAGE" "$ENV_FILE"; then
          echo "✔ [35%] Variable CORP_STAGE definida y bloqueada como inmutable con 'readonly'."
          PUNTOS=$((PUNTOS + 35))
      else
          echo "❌ [0%] La variable existe pero no cuenta con el flag de protección 'readonly'."
      fi
  else
      echo "❌ [0%] No se creó el script de entorno modular corporativo en $ENV_FILE."
  fi

  # 3. Validar Auditoría Avanzada de Historial de Comandos
  if [ -f "$AUDIT_FILE" ] || grep -q "history -a" /etc/profile.d/*.sh 2>/dev/null; then
      ACTUAL_FILE=$(grep -l "history -a" /etc/profile.d/*.sh 2>/dev/null | head -n 1)
      if grep -q "HISTSIZE=10000" "$ACTUAL_FILE" && (grep -q "PROMPT_COMMAND=" "$ACTUAL_FILE" || grep -q "history -a" "$ACTUAL_FILE"); then
          echo "✔ [30%] Configuración forense de historial de comandos validada (Persistencia inmediata activa)."
          PUNTOS=$((PUNTOS + 30))
      else
          echo "❌ [15%] Captura de historial detectada, pero los valores de tamaño (HISTSIZE) o vaciado inmediato no están alineados."
          PUNTOS=$((PUNTOS + 15))
      fi
  else
      echo "❌ [0%] No se detectaron políticas globales de auditoría para el historial de Bash."
  fi

  echo "====================================================="
  echo "🎯 RESULTADO DE LA MITIGACIÓN: $PUNTOS / 100"
  echo "====================================================="
---
[[Laboratorios del LFCS]]
---

