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
  cat << 'EOF' > /tmp/setup_sh

  #!/bin/bash
  set -e

  # Parámetros de Red del Playground (Usuario bob / Contraseña caleston123 nativa)
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

  echo -e "\e[1;33m⏳ Desplegando entorno distribuido y trampas de descriptores en el clúster...\e[0m"

  # 1. Ejecución de aprovisionamiento remoto en node02 (Servidor Afectado)
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_TARGET} "sudo bash -c '
      # Creación de identidades lógicas locales en node02
      id -u app_owner &>/dev/null || useradd -m -d /srv/app_owner -s /bin/bash app_owner
      id -u sre_operator &>/dev/null || useradd -m -d /srv/sre_operator -s /bin/bash sre_operator

      # Limpieza de directorios locales
      rm -rf /srv/app_owner/apps_legacy /srv/sre_operator/*
      mkdir -p /srv/app_owner/apps_legacy/core_service
      mkdir -p /srv/app_owner/apps_legacy/cache_v2

      # Inyección de artefactos de telemetría
      echo \"2026-06-05 FATAL Kernel panic in thread 2\" > /srv/app_owner/apps_legacy/core_service/kernel.log
      echo \"2026-06-05 CRITICAL Database cluster isolated\" > /srv/app_owner/apps_legacy/core_service/db.log
      echo \"2026-06-05 ERROR Connection timeout\" > /srv/app_owner/apps_legacy/app1.log
      echo \"2026-06-05 INFO Pipeline execution normal\" > /srv/app_owner/apps_legacy/app2.log

      # Trampas de patrón (Excluir \"cache\")
      echo \"TEMPORARY CORRUPT DATA\" > /srv/app_owner/apps_legacy/cache_v2/volatile.log
      echo \"METRICS STORAGE\" > /srv/app_owner/apps_legacy/core_service/app_cache.log

      # Trampa de tiempo (Modificado hace 5 días)
      echo \"2026-06-01 ERROR Old unparsed error\" > /srv/app_owner/apps_legacy/core_service/old_legacy.log
      touch -d \"5 days ago\" /srv/app_owner/apps_legacy/core_service/old_legacy.log

      # Trampa de descriptores (Forzar Permission Denied nativo)
      touch /srv/app_owner/apps_legacy/core_service/secure_vault.log
      chmod 000 /srv/app_owner/apps_legacy/core_service/secure_vault.log

      # Matriz de permisos artesanal y ACLs en node02
      chown -R app_owner:app_owner /srv/app_owner/apps_legacy
      chmod 750 /srv/app_owner /srv/app_owner/apps_legacy
      setfacl -m u:sre_operator:--x /srv/app_owner
      setfacl -R -m u:sre_operator:r-x /srv/app_owner/apps_legacy/
      setfacl -m u:sre_operator:--- /srv/app_owner/apps_legacy/core_service/secure_vault.log

      chown -R sre_operator:sre_operator /srv/sre_operator
      chmod 700 /srv/sre_operator
  '"

  # 2. Limpieza de evidencias previas en la Bóveda (node03)
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_VAULT} "sudo rm -rf /opt/evidence-vault/* && sudo mkdir -p /opt/evidence-vault/ && sudo chown -R bob:bob /opt/evidence-vault/"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ENTORNO DISTRIBUIDO SRE CONFIGURADO - NIVEL 9/10 (PG-004-MN-SYSADMIN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-8044 (SEVERIDAD: CRÍTICA / MULTI-NODE PIPELINES)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m node01 (Estación Local — Administrador \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo de Producción:\e[0m    node02 (Servidor con fallas — Identidad: \e[1;35msre_operator\e[0m)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Repositorio Seguro — Ruta: \e[1;35m/opt/evidence-vault/\e[0m)"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mContexto Técnico Distribuido del Incidente:\e[0m"
  echo -e "  El volumen compartido de logs en producción (node02) está al límite."
  echo -e "  Usted debe operar de manera remota e interceptar/canalizar los flujos de"
  echo -e "  datos desde su estación de trabajo (node01), garantizando que las"
  echo -e "  evidencias procesadas queden bajo custodia inmutable exclusivamente en node03."
  echo -e ""
  echo -e "  No está permitido almacenar datos locales permanentes en node01 ni en node02."
  echo -e "  Las restricciones de permisos y trampas de descriptores siguen vigentes"
  echo -e "  de forma nativa en el sistema de archivos de node02."
  echo -e ""
  echo -e " \e[1mTareas Requeridas — Ejecutar de forma remota bajo privilegios controlados:\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Respaldo Criptográfico con Filtrado de Red\e[0m"
  echo -e "     Empaquete y comprima el directorio remoto '/srv/app_owner/apps_legacy' de node02"
  echo -e "     utilizando el algoritmo XZ. El archivo resultante debe ser depositado en"
  echo -e "     'node03:/opt/evidence-vault/critical_legacy.tar.xz'."
  echo -e "     Filtros obligatorios: Excluya rutas con la palabra 'cache' y procese"
  echo -e "     únicamente archivos modificados en las últimas 24 horas."
  echo -e ""
  echo -e "  \e[1;31m2. Bifurcación Forense de Descriptores de Red\e[0m"
  echo -e "     Ejecute el rastreo con 'find' de las estructuras de '/srv/app_owner/apps_legacy'"
  echo -e "     dentro de node02. Los flujos deben segregarse en tránsito a través de la red:"
  echo -e "     Las rutas exitosas van a 'node03:/opt/evidence-vault/audit_success.log'."
  echo -e "     Los errores de permisos (stderr nativo) van a 'node03:/opt/evidence-vault/audit_errors.log'."
  echo -e ""
  echo -e "  \e[1;31m3. Pipeline de Telemetría Distribuido en Memoria\e[0m"
  echo -e "     Extraiga en masa las líneas que contengan 'ERROR', 'CRITICAL' o 'FATAL' de todos"
  echo -e "     los archivos '.log' válidos en node02. Conecte las salidas directamente en red"
  echo -e "     hacia un flujo comprimido en 'node03:/opt/evidence-vault/telemetry_signals.log.gz'."
  echo -e "     Requerimiento: Cero archivos intermedios o basura en los discos locales."
  echo -e ""
  echo -e "  \e[1;31m4. Reporte Operativo Centralizado\e[0m"
  echo -e "     Escriba en 'node03:/opt/evidence-vault/backup_status.txt' la metadata de la operación:"
  echo -e "     Línea 1: TIMESTAMP: [fecha_actual_sistema]"
  echo -e "     Línea 2: STATUS: OPERACIÓN MULTI-NODO COMPILADA CON ÉXITO"
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación (Entregables validados estrictamente en node03):\e[0m"
  echo -e "  [ ] critical_legacy.tar.xz localizado en node03 sin datos corruptos --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Bifurcación remota audit_success y audit_errors aislada en node03 --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Pipeline telemetry_signals.log.gz en node03 sin duplicados        --> \e[1;35m25%\e[0m"
  echo -e "  [ ] backup_status.txt estructurado con timestamps inmutables en node03 --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO DE RED:\e[0m Resuelva las tareas simulando la identidad de"
  echo -e "                        'sre_operator' en node02 (vía sudo/ssh). No altere permisos."
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash


  cat > /tmp/validador.sh << 'EOF'
  #!/bin/bash
  PUNTOS=0

  NODE_TARGET="node02"
  NODE_VAULT="node03"
  USER_NET="bob"
  VAULT_DIR="/opt/evidence-vault"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"

  echo -e "\n=== 🕵️ EVALUANDO PIPELINES DISTRIBUIDOS Y CUSTODIA (INC-8044) ==="

  # 1. Validar el paquete .tar.xz en la Bóveda (node03)
  echo "⏳ Analizando integridad del respaldo remoto en node03..."
  if ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "[ -f $VAULT_DIR/critical_legacy.tar.xz ]" 2>/dev/null; then
      # Extraer contenido en memoria desde node03 para verificar exclusiones de la trampa "cache"
      TAR_CONTENT=$(ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "tar -tf $VAULT_DIR/critical_legacy.tar.xz" 2>/dev/null || true)
      
      if echo "$TAR_CONTENT" | grep -q "kernel.log" && ! echo "$TAR_CONTENT" | grep -E "cache|old_legacy" ; then
          echo "✔ [30%] critical_legacy.tar.xz validado con filtros de tiempo y exclusión de palabras clave."
          PUNTOS=$((PUNTOS + 30))
      else
          echo "❌ [0%] El archivo .tar.xz existe en node03 pero falló los filtros estricto (contiene archivos antiguos o caches)."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo critical_legacy.tar.xz en node03."
  fi

  # 2. Validar bifurcación forense de descriptores en node03
  echo "⏳ Auditando segregación de descriptores (stdout/stderr)..."
  if ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "[ -f $VAULT_DIR/audit_success.log ] && [ -f $VAULT_DIR/audit_errors.log ]" 2>/dev/null; then
      ERRORS_CONTENT=$(ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "cat $VAULT_DIR/audit_errors.log" 2>/dev/null || true)
      
      if echo "$ERRORS_CONTENT" | grep -q "Permission denied"; then
          echo "✔ [25%] Bifurcación forense de descriptores de flujo verificada con éxito en node03."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [10%] Los archivos existen, pero los errores de permisos (stderr) no fueron capturados correctamente."
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo "❌ [0%] Faltan los reportes de auditoría segregados (audit_success/audit_errors) en node03."
  fi

  # 3. Validar pipeline de telemetría in-memory
  echo "⏳ Verificando agregación de señales de telemetría en node03..."
  if ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "[ -f $VAULT_DIR/telemetry_signals.log.gz ]" 2>/dev/null; then
      LOGS_CONTENT=$(ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "zcat $VAULT_DIR/telemetry_signals.log.gz" 2>/dev/null || true)
      
      if echo "$LOGS_CONTENT" | grep -q "FATAL" && ! echo "$LOGS_CONTENT" | grep -q "Old unparsed error"; then
          # Comprobar duplicación
          DUPS=$(echo "$LOGS_CONTENT" | wc -l)
          UNIQ=$(echo "$LOGS_CONTENT" | sort -u | wc -l)
          if [ "$DUPS" -eq "$UNIQ" ]; then
              echo "✔ [25%] Pipeline de telemetría en red validado sin duplicados ni archivos basura."
              PUNTOS=$((PUNTOS + 25))
          else
              echo "❌ [10%] El archivo existe pero el flujo retiene líneas duplicadas."
              PUNTOS=$((PUNTOS + 10))
          fi
      else
          echo "❌ [0%] El stream de datos contiene eventos obsoletos o no filtró los patrones requeridos."
      fi
  else
      echo "❌ [0%] No se encuentra la telemetría unificada telemetry_signals.log.gz en la bóveda."
  fi

  # 4. Validar metadata de auditoría corporativa
  if ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "[ -f $VAULT_DIR/backup_status.txt ]" 2>/dev/null; then
      STATUS_TXT=$(ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "cat $VAULT_DIR/backup_status.txt" 2>/dev/null || true)
      if echo "$STATUS_TXT" | grep -q "TIMESTAMP:" && echo "$STATUS_TXT" | grep -q "STATUS: OPERACIÓN MULTI-NODO COMPILADA CON ÉXITO"; then
          echo "✔ [20%] Reporte operativo inmutable verificado estructuralmente en node03."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] El reporte backup_status.txt no cumple con las líneas y el formato estricto."
      fi
  else
      echo "❌ [0%] Falta el informe operativo backup_status.txt en node03."
  fi

  # Resultado global
  echo -e "\n========================================"
  if [ $PUNTOS -eq 100 ]; then
      echo -e "🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m"
      echo -e "Felicidades. Has demostrado habilidades de nivel Ingeniero SRE Pleno/Senior."
  else
      echo -e "❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m"
      echo -e "Audite la manipulación remota de flujos de texto o la persistencia en node03."
  fi
  echo "========================================"
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh
---
[[Laboratorios del LFCS]]

---
