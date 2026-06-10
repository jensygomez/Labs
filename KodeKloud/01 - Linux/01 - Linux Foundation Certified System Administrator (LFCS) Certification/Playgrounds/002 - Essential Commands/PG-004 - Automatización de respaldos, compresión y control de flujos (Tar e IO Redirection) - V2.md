---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-004
Titulo: Automatización de respaldos, compresión y control de flujos (Tar e I/O Redirection) - V2
Fecha de Inicio: 2026-06-05
Dificultad: 8/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS con máxima puntuación
  - Dominar la orquestación avanzada de flujos, descriptores y políticas de respaldo empresarial
Temas:
  - Advanced Tar Engineering & XZ Enterprise Compression
  - Advanced Stream Redirection & File Descriptors Isolation (2>&1, tee)
  - Live RegEx Stream Ingestion (High-performance pipelines)
Competencias:
  - Implementar empaquetados industriales de alta compresión (XZ) aplicando exclusiones multicapa por patrones y tiempo
  - Gestionar y bifurcar flujos de datos complejos en tiempo real mediante descriptores de archivos estructurados
  - Construir pipelines de telemetría forense utilizando expresiones regulares para la detección de anomalías al vuelo
Validacion:
  - Objetivo: Respaldo /backup/critical_legacy.tar.xz operativo bajo algoritmo XZ y exclusiones de caché validadas.
    Peso: 30 %
  - Objetivo: Separación quirúrgica de flujos find (audit_success.log y audit_errors.log funcionales).
    Peso: 25 %
  - Objetivo: Pipeline forense /root/telemetry_signals.log.gz generado con filtrado RegEx extendido y ordenamiento único.
    Peso: 25 %
  - Objetivo: Archivo de estado /root/backup_status.txt estructurado con marcas dinámicas y operadores correctos.
    Peso: 20 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup.sh

  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  echo -e "\e[1;33m⏳ Desplegando entorno distribuido y trampas de descriptores en el clúster...\e[0m"

  # ── 1. Aprovisionamiento remoto en node02 ───────────────────────────────────
  $SSH -t ${USER_NET}@${NODE_TARGET} "sudo bash -c '

      # Creación de identidades lógicas locales en node02
      id -u app_owner   &>/dev/null || useradd -m -d /srv/app_owner   -s /bin/bash app_owner
      id -u sre_operator &>/dev/null || useradd -m -d /srv/sre_operator -s /bin/bash sre_operator

      # Limpieza de directorios locales
      rm -rf /srv/app_owner/apps_legacy /srv/sre_operator/*
      mkdir -p /srv/app_owner/apps_legacy/core_service
      mkdir -p /srv/app_owner/apps_legacy/cache_v2

      # Inyección de artefactos de telemetría
      echo \"2026-06-05 FATAL Kernel panic in thread 2\"          > /srv/app_owner/apps_legacy/core_service/kernel.log
      echo \"2026-06-05 CRITICAL Database cluster isolated\"      > /srv/app_owner/apps_legacy/core_service/db.log
      echo \"2026-06-05 ERROR Connection timeout\"                > /srv/app_owner/apps_legacy/app1.log
      echo \"2026-06-05 INFO Pipeline execution normal\"          > /srv/app_owner/apps_legacy/app2.log

      # Trampas de patrón (Excluir \"cache\")
      echo \"TEMPORARY CORRUPT DATA\"  > /srv/app_owner/apps_legacy/cache_v2/volatile.log
      echo \"METRICS STORAGE\"         > /srv/app_owner/apps_legacy/core_service/app_cache.log

      # Trampa de tiempo (Modificado hace 5 días — no debe incluirse)
      echo \"2026-06-01 ERROR Old unparsed error\" > /srv/app_owner/apps_legacy/core_service/old_legacy.log
      touch -d \"5 days ago\" /srv/app_owner/apps_legacy/core_service/old_legacy.log

      # Trampa de descriptores (Permission Denied nativo)
      touch /srv/app_owner/apps_legacy/core_service/secure_vault.log
      chmod 000 /srv/app_owner/apps_legacy/core_service/secure_vault.log

      # Matriz de permisos artesanal y ACLs en node02
      chown -R app_owner:app_owner /srv/app_owner/apps_legacy
      chmod 750 /srv/app_owner /srv/app_owner/apps_legacy
      setfacl -m  u:sre_operator:--x /srv/app_owner
      setfacl -R -m u:sre_operator:r-x /srv/app_owner/apps_legacy/
      setfacl -m  u:sre_operator:--- /srv/app_owner/apps_legacy/core_service/secure_vault.log

      chown -R sre_operator:sre_operator /srv/sre_operator
      chmod 700 /srv/sre_operator
  '"

  echo -e "\e[1;33m⏳ [node01 → node03] Preparando bóveda de custodia de evidencias...\e[0m"

  # ── 2. Preparar bóveda en node03 ─────────────────────────────────────────────
  $SSH -t ${USER_NET}@${NODE_VAULT} "sudo bash -c '
      rm -rf /opt/evidence-vault/*
      mkdir -p /opt/evidence-vault/
      chown -R bob:bob /opt/evidence-vault/
  '"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ENTORNO DISTRIBUIDO SRE CONFIGURADO — NIVEL 8/10 (PG-004-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-8044 (SEVERIDAD: CRÍTICA / MULTI-NODE PIPELINES)\e[0m"
  echo -e "\e[1;36m  Módulo: Essential Commands  │  Dificultad: 8/10  │  Nivel: L2/L3\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo de Producción:\e[0m    node02 (Servidor con fallas — Identidad: \e[1;35msre_operator\e[0m)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Repositorio Seguro — \e[1;35m/opt/evidence-vault/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mContexto Técnico del Incidente:\e[0m"
  echo -e "  El volumen compartido de logs en producción (node02) está al límite."
  echo -e "  Usted debe operar de manera remota e interceptar/canalizar los flujos de"
  echo -e "  datos desde su estación de trabajo (node01), garantizando que las"
  echo -e "  evidencias procesadas queden bajo custodia inmutable exclusivamente en node03."
  echo -e ""
  echo -e "  No está permitido almacenar datos locales permanentes en node01 ni en node02."
  echo -e "  Las restricciones de permisos y trampas de descriptores siguen vigentes"
  echo -e "  de forma nativa en el sistema de archivos de node02."
  echo -e ""
  echo -e " \e[1mTareas Requeridas (ejecutar remotamente desde node01):\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Respaldo Criptográfico con Filtrado de Red\e[0m"
  echo -e "     Empaquete y comprima el directorio remoto '/srv/app_owner/apps_legacy' de node02"
  echo -e "     con el algoritmo XZ. El archivo resultante debe depositarse en:"
  echo -e "     \e[1mnode03:/opt/evidence-vault/critical_legacy.tar.xz\e[0m"
  echo -e "     Filtros obligatorios: Excluya rutas con 'cache' y procese únicamente"
  echo -e "     archivos modificados en las últimas 24 horas."
  echo -e ""
  echo -e "  \e[1;31m2. Bifurcación Forense de Descriptores de Red\e[0m"
  echo -e "     Ejecute 'find' sobre '/srv/app_owner/apps_legacy' en node02."
  echo -e "     Segregue los flujos en tránsito a través de la red:"
  echo -e "     - Rutas exitosas  → \e[1mnode03:/opt/evidence-vault/audit_success.log\e[0m"
  echo -e "     - Errores nativos → \e[1mnode03:/opt/evidence-vault/audit_errors.log\e[0m"
  echo -e ""
  echo -e "  \e[1;31m3. Pipeline de Telemetría Distribuido en Memoria\e[0m"
  echo -e "     Extraiga líneas con 'ERROR', 'CRITICAL' o 'FATAL' de todos los '.log'"
  echo -e "     válidos en node02. Conecte la salida directamente hacia:"
  echo -e "     \e[1mnode03:/opt/evidence-vault/telemetry_signals.log.gz\e[0m"
  echo -e "     Requerimiento: Cero archivos intermedios en disco."
  echo -e ""
  echo -e "  \e[1;31m4. Reporte Operativo Centralizado\e[0m"
  echo -e "     Escriba en \e[1mnode03:/opt/evidence-vault/backup_status.txt\e[0m:"
  echo -e "     Línea 1: TIMESTAMP: [fecha_actual_sistema]"
  echo -e "     Línea 2: STATUS: OPERACIÓN MULTI-NODO COMPILADA CON ÉXITO"
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación (validados en node03):\e[0m"
  echo -e "  [ ] critical_legacy.tar.xz en node03 sin datos corrupto
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  cat > /tmp/validador.sh << 'EOF'
  #!/bin/bash
  PUNTOS=0

  NODE_TARGET="node02"
  NODE_VAULT="node03"
  USER_NET="bob"
  PASS="caleston123"
  VAULT_DIR="/opt/evidence-vault"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  EVALUANDO PIPELINES DISTRIBUIDOS Y CUSTODIA — INC-8044 (PG-004-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # ── 1. Validar el paquete .tar.xz en la Bóveda (node03) ──────────────────────
  echo -e "\n\e[1;37m⏳ [1/4] Analizando integridad del respaldo remoto en node03...\e[0m"

  if $SSH ${USER_NET}@${NODE_VAULT} "[ -f $VAULT_DIR/critical_legacy.tar.xz ]" 2>/dev/null; then
      TAR_CONTENT=$($SSH ${USER_NET}@${NODE_VAULT} \
          "tar -tf $VAULT_DIR/critical_legacy.tar.xz" 2>/dev/null || true)

      if echo "$TAR_CONTENT" | grep -q "kernel.log" && \
         ! echo "$TAR_CONTENT" | grep -qE "cache|old_legacy"; then
          echo -e "\e[1;32m  ✔ [30%] critical_legacy.tar.xz validado con filtros de tiempo y exclusión de cache.\e[0m"
          PUNTOS=$((PUNTOS + 30))
      else
          echo -e "\e[1;31m  ❌ [0%] El .tar.xz existe pero falló los filtros (contiene archivos antiguos o caches).\e[0m"
          echo "$TAR_CONTENT" | grep -qE "cache"       && echo -e "       → Contiene rutas con 'cache' — use --exclude"
          echo "$TAR_CONTENT" | grep -q "old_legacy"   && echo -e "       → Contiene old_legacy.log — verifique filtro -mtime -1"
          ! echo "$TAR_CONTENT" | grep -q "kernel.log" && echo -e "       → No se encontró kernel.log — revise la ruta de origen"
      fi
  else
      echo -e "\e[1;31m  ❌ [0%] No se encuentra critical_legacy.tar.xz en node03:$VAULT_DIR/\e[0m"
  fi

  # ── 2. Validar bifurcación forense de descriptores en node03 ─────────────────
  echo -e "\n\e[1;37m⏳ [2/4] Auditando segregación de descriptores (stdout/stderr) en node03...\e[0m"

  if $SSH ${USER_NET}@${NODE_VAULT} \
      "[ -f $VAULT_DIR/audit_success.log ] && [ -f $VAULT_DIR/audit_errors.log ]" 2>/dev/null; then
      ERRORS_CONTENT=$($SSH ${USER_NET}@${NODE_VAULT} \
          "cat $VAULT_DIR/audit_errors.log" 2>/dev/null || true)

      if echo "$ERRORS_CONTENT" | grep -q "Permission denied"; then
          echo -e "\e[1;32m  ✔ [25%] Bifurcación forense verificada — stderr capturado correctamente en node03.\e[0m"
          PUNTOS=$((PUNTOS + 25))
      else
          echo -e "\e[1;33m  ⚠️  [10%] Archivos presentes pero stderr no contiene 'Permission denied'.\e[0m"
          echo -e "       → Verifique que redirigió 2> hacia audit_errors.log y no mezcló con stdout"
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo -e "\e[1;31m  ❌ [0%] Faltan audit_success.log o audit_errors.log en node03:$VAULT_DIR/\e[0m"
  fi

  # ── 3. Validar pipeline de telemetría in-memory en node03 ────────────────────
  echo -e "\n\e[1;37m⏳ [3/4] Verificando agregación de señales de telemetría en node03...\e[0m"

  if $SSH ${USER_NET}@${NODE_VAULT} \
      "[ -f $VAULT_DIR/telemetry_signals.log.gz ]" 2>/dev/null; then
      LOGS_CONTENT=$($SSH ${USER_NET}@${NODE_VAULT} \
          "zcat $VAULT_DIR/telemetry_signals.log.gz" 2>/dev/null || true)

      if echo "$LOGS_CONTENT" | grep -q "FATAL" && \
         ! echo "$LOGS_CONTENT" | grep -q "Old unparsed error"; then
          DUPS=$( echo "$LOGS_CONTENT" | wc -l)
          UNIQ=$(echo "$LOGS_CONTENT" | sort -u | wc -l)
          if [ "$DUPS" -eq "$UNIQ" ]; then
              echo -e "\e[1;32m  ✔ [25%] Pipeline de telemetría validado sin duplicados ni archivos basura.\e[0m"
              PUNTOS=$((PUNTOS + 25))
          else
              echo -e "\e[1;33m  ⚠️  [10%] Archivo presente pero contiene líneas duplicadas ($DUPS líneas / $UNIQ únicas).\e[0m"
              echo -e "       → Verifique que no procesó el mismo archivo dos veces en el pipeline"
              PUNTOS=$((PUNTOS + 10))
          fi
      else
          echo -e "\e[1;31m  ❌ [0%] El stream contiene eventos obsoletos o no filtró ERROR/CRITICAL/FATAL.\e[0m"
          echo "$LOGS_CONTENT" | grep -q "Old unparsed error" && \
              echo -e "       → Contiene old_legacy.log — excluya archivos modificados hace más de 24h"
          ! echo "$LOGS_CONTENT" | grep -q "FATAL" && \
              echo -e "       → No se encontró FATAL — revise el grep y los archivos de origen"
      fi
  else
      echo -e "\e[1;31m  ❌ [0%] No se encuentra telemetry_signals.log.gz en node03:$VAULT_DIR/\e[0m"
  fi

  # ── 4. Validar metadata de auditoría corporativa ──────────────────────────────
  echo -e "\n\e[1;37m⏳ [4/4] Verificando reporte operativo en node03...\e[0m"

  if $SSH ${USER_NET}@${NODE_VAULT} \
      "[ -f $VAULT_DIR/backup_status.txt ]" 2>/dev/null; then
      STATUS_TXT=$($SSH ${USER_NET}@${NODE_VAULT} \
          "cat $VAULT_DIR/backup_status.txt" 2>/dev/null || true)

      if echo "$STATUS_TXT" | grep -q "TIMESTAMP:" && \
         echo "$STATUS_TXT" | grep -q "STATUS: OPERACIÓN MULTI-NODO COMPILADA CON ÉXITO"; then
          echo -e "\e[1;32m  ✔ [20%] Reporte operativo estructurado correctamente en node03.\e[0m"
          PUNTOS=$((PUNTOS + 20))
      else
          echo -e "\e[1;31m  ❌ [0%] backup_status.txt no cumple con el formato requerido.\e[0m"
          ! echo "$STATUS_TXT" | grep -q "TIMESTAMP:"  && \
              echo -e "       → Falta la línea 'TIMESTAMP: [fecha]'"
          ! echo "$STATUS_TXT" | grep -q "STATUS: OPERACIÓN MULTI-NODO COMPILADA CON ÉXITO" && \
              echo -e "       → Falta la línea 'STATUS: OPERACIÓN MULTI-NODO COMPILADA CON ÉXITO' (texto exacto)"
      fi
  else
      echo -e "\e[1;31m  ❌ [0%] Falta backup_status.txt en node03:$VAULT_DIR/\e[0m"
  fi

  # ── Resultado Final ────────────────────────────────────────────────────────────
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
      echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — Nivel Ingeniero SRE Pleno demostrado."
  elif [ $PUNTOS -ge 55 ]; then
      echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los ❌."
  else
      echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Audite los pipelines remotos y la persistencia en node03."
  fi
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh
---
[[Laboratorios del LFCS]]

---
