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
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  # ── 1. PREPARACIÓN REAL DEL ENTORNO RESTRINGIDO ──────────────────────────────
  echo -e "\e[1;33m⏳ Configurando entorno para el incidente INC-7022...\e[0m"

  # Asegurar el grupo devs
  getent group devs >/dev/null 2>&1 || groupadd -g 2500 devs

  # Crear un usuario de prueba (consultor) asignado a ese grupo para validar después
  if ! id -u consultor01 >/dev/null 2>&1; then
      # Se crea con password "Accenture123*" para que puedas testearlo
      useradd -m -g devs -s /bin/bash -c "Consultor Externo - Dev" consultor01
      echo "consultor01:Accenture123*" | chpasswd
      echo "✔ Usuario de prueba 'consultor01' creado (Pass: Accenture123*)."
  fi

  # Limpieza preventiva de archivos que el estudiante debe crear
  rm -f /etc/security/limits.d/50-devs-hardening.conf
  rm -f /etc/profile.d/corp_env.sh
  rm -f /etc/profile.d/audit_history.sh

  # ── 2. DESPLIEGUE DEL TICKET EN PANTALLA ─────────────────────────────────────
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO AVANZADO CONFIGURADO - USERS & GROUPS (PG-002 v2)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-7022\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m  Inestabilidad de Memoria y Evasión de Auditoría en Nodo de Staging"
  echo -e " \e[1mSeveridad:\e[0m Crítica / Mitigación de Denegación de Servicio (DoS)"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " A las 02:17 horas, el sistema de monitoreo del clúster de compilación generó"
  echo -e " una alerta de pánico menor. La investigación preliminar reveló que scripts"
  echo -e " automatizados asociados al grupo '@devs' estaban spawneando subprocesos de"
  echo -e " Node.js de manera descontrolada, agotando progresivamente la memoria virtual"
  echo -e " asignada al espacio de usuario y comprometiendo la estabilidad del host."
  echo -e ""
  echo -e " Mientras el equipo de infraestructura contenía el incidente, SecOps levantó"
  echo -e " una alerta paralela de igual gravedad: los registros de auditoría mostraban"
  echo -e " que un subconjunto de consultores estaba ejecutando \e[1mhistory -c\e[0m de forma"
  echo -e " deliberada antes de cerrar sesión, borrando toda trazabilidad de sus acciones"
  echo -e " en el nodo. Esta conducta constituye una violación directa a la política de"
  echo -e " trazabilidad forense corporativa."
  echo -e ""
  echo -e " Se le asigna este ticket con carácter de urgencia. Usted deberá implementar"
  echo -e " tres controles de forma simultánea: restringir quirúrgicamente los recursos"
  echo -e " del grupo '@devs' mediante PAM limits.d, declarar la variable de entorno"
  echo -e " corporativa \e[1mCORP_STAGE\e[0m como inmutable a nivel de sistema, y configurar el"
  echo -e " volcado inmediato del historial de comandos en todos los perfiles globales"
  echo -e " para garantizar trazabilidad completa de sesión desde este momento en adelante."
  echo -e ""
  echo -e " \e[1;31m RESTRICCIONES OPERACIONALES:\e[0m"
  echo -e " \e[1;31m ►\e[0m La configuración PAM DEBE residir exclusivamente en:"
  echo -e "   \e[1m/etc/security/limits.d/50-devs-hardening.conf\e[0m"
  echo -e " \e[1;31m ►\e[0m La variable \e[1mCORP_STAGE\e[0m debe ser declarada de forma modular y"
  echo -e "   ningún usuario intermedio podrá alterarla ni hacer unset durante su sesión."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación:\e[0m"
  echo -e "  [ ] Cuotas nproc (80/120) y límite 'as' de 2GB en limits.d      --> \e[1;35m35%\e[0m"
  echo -e "  [ ] Variable CORP_STAGE inmutable con atributo 'readonly'        --> \e[1;35m35%\e[0m"
  echo -e "  [ ] Auditoría inmediata de historial (history -a) configurada    --> \e[1;34m30%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  echo -e "\e[1;32m✔ Entorno listo. Entra como root y aplica las directivas de seguridad.\e[0m"
  echo -e "\e[1;33m💡 Tip de Sysadmin:\e[0m Puedes usar una pestaña paralela para loguearte como"
  echo -e "   \e[1mconsultor01\e[0m y comprobar si tus bloqueos de memoria y de history funcionan."
  echo ""
  EOF
  bash /tmp/setup.sh && rm -f /tmp/setup.sh
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

## 🗣️ Resumen en inglés B2 — Tono de entrevista real

---

Recently I dealt with a critical dual-threat incident on a staging node that required me to implement three security controls simultaneously under time pressure.

The first problem was a resource exhaustion scenario. Automated scripts tied to the developers group were spawning uncontrolled Node.js subprocesses, progressively consuming all virtual memory allocated to user space and threatening host stability. I resolved this by writing a dedicated PAM resource limits file under `/etc/security/limits.d/`, where I applied soft and hard process quotas of 80 and 120 concurrent processes respectively, and enforced a hard 2GB virtual address space ceiling using the `as` parameter — which is the correct control for virtual memory on modern Linux kernels, since `rss` has been deprecated and ignored by the kernel for years.

The second problem was a forensic evasion pattern that SecOps flagged in parallel. A subset of external consultants was deliberately running `history -c` before logging out, wiping all command traceability from the node. I addressed this on two fronts. I declared a corporate environment variable `CORP_STAGE` as `readonly` through a dedicated modular script in `/etc/profile.d/`, making it immutable for the entire session — any attempt to overwrite or unset it returns an error at the shell level. I also configured `PROMPT_COMMAND` globally to flush the command history to disk after every single command, so even if someone clears the in-memory buffer, the file on disk already has the complete session record.

Every control was deployed through modular, isolated files — nothing touched monolithic system configs. Each policy is independently auditable and can be rolled back without affecting anything else on the system.