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

  # 1. LIMPIEZA FORENSE ABSOLUTA Y CREACIÓN DE IDENTIDADES
  # Creamos las identidades lógicas para simular el entorno corporativo aislado
  id -u app_owner &>/dev/null || useradd -m -d /srv/app_owner -s /bin/bash app_owner
  id -u sre_operator &>/dev/null || useradd -m -d /srv/sre_operator -s /bin/bash sre_operator

  # Limpieza de directorios de trabajo compartidos y privados
  rm -rf /srv/app_owner/apps_legacy /srv/sre_operator/*
  mkdir -p /srv/app_owner/apps_legacy/core_service
  mkdir -p /srv/app_owner/apps_legacy/cache_v2

  # 2. INYECCIÓN DE ARTEFACTOS CON TRAMPAS DE INGENIERÍA
  # Archivos válidos para telemetría (Modificados hoy, contienen patrones requeridos)
  echo "2026-06-05 FATAL Kernel panic in thread 2" > /srv/app_owner/apps_legacy/core_service/kernel.log
  echo "2026-06-05 CRITICAL Database cluster isolated" > /srv/app_owner/apps_legacy/core_service/db.log
  echo "2026-06-05 ERROR Connection timeout" > /srv/app_owner/apps_legacy/app1.log
  echo "2026-06-05 INFO Pipeline execution normal" > /srv/app_owner/apps_legacy/app2.log

  # TRAMPA DE PATRÓN (Excluir por palabra "cache" en archivo o ruta)
  echo "TEMPORARY CORRUPT DATA" > /srv/app_owner/apps_legacy/cache_v2/volatile.log
  echo "METRICS STORAGE" > /srv/app_owner/apps_legacy/core_service/app_cache.log

  # TRAMPA DE TIEMPO (Modificado hace 5 días, contiene patrones pero NO debe entrar en el find/tar)
  touch -d "5 days ago" /srv/app_owner/apps_legacy/core_service/old_legacy.log
  echo "2026-06-01 ERROR Old unparsed error" >> /srv/app_owner/apps_legacy/core_service/old_legacy.log

  # TRAMPA DE DESCRIPTORES (Forzar error de permisos nativo para la redirección de stderr)
  # Este archivo causará un "Permission Denied" real cuando el operador ejecute su pipeline o find.
  touch /srv/app_owner/apps_legacy/core_service/secure_vault.log
  chmod 000 /srv/app_owner/apps_legacy/core_service/secure_vault.log

  # 3. MATRIZ DE PERMISOS ARTESANAL
  # El software y logs le pertenecen a la aplicación
  chown -R app_owner:app_owner /srv/app_owner/apps_legacy
  chmod 750 /srv/app_owner /srv/app_owner/apps_legacy

  # Otorgamos al sre_operator permisos de lectura por ACL para simular acceso de auditoría
  setfacl -R -m u:sre_operator:r-x /srv/app_owner/apps_legacy/
  setfacl -m u:sre_operator:--- /srv/app_owner/apps_legacy/core_service/secure_vault.log

  # El directorio del operador es estrictamente privado y suyo
  chown -R sre_operator:sre_operator /srv/sre_operator
  chmod 700 /srv/sre_operator

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ENTORNO AISLADO SRE CONFIGURADO - NIVEL 8/10 (PG-004-v2-SYSADMIN-PLENO)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-8044 (SEVERIDAD: CRÍTICA / INFRASTRUCTURE DRILL)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mTu Identidad Operativa:\e[0m Cambie con: \e[1;32msudo su - sre_operator\e[0m"
  echo -e " \e[1mRuta Base de Datos de Aplicación:\e[0m /srv/app_owner/apps_legacy"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mContexto Técnico del Incidente:\e[0m"
  echo -e "  El volumen compartido de logs está al límite. SecOps y SRE exigen la"
  echo -e "  ejecución de cuatro tareas de ingeniería de flujos de datos de manera"
  echo -e "  simultánea, sin usar privilegios de root para evitar alterar hashes forenses."
  echo -e ""
  echo -e "  El entorno cuenta con restricciones reales a nivel de sistema de archivos."
  echo -e "  Ciertas rutas generarán errores nativos de entrada/salida y permisos."
  echo -e "  Su capacidad para manipular descriptores de archivo estándar (stdout/stderr)"
  echo -e "  y pipelines eficientes será puesta a prueba."
  echo -e ""
  echo -e " \e[1mTareas Requeridas — Ejecutar estrictamente como 'sre_operator':\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Respaldo Empresarial con Filtrado Estricto\e[0m"
  echo -e "     Empaquete y comprima el directorio '/srv/app_owner/apps_legacy' usando"
  echo -e "     el algoritmo XZ hacia '/srv/sre_operator/critical_legacy.tar.xz'."
  echo -e "     Filtros obligatorios: No incluya ningún archivo o ruta que contenga"
  echo -e "     la palabra 'cache', y procese únicamente archivos modificados"
  echo -e "     en las últimas 24 horas. *(Evite arrastrar el archivo de hace 5 días)*."
  echo -e ""
  echo -e "  \e[1;31m2. Bifurcación Forense de Flujos de Diagnóstico\e[0m"
  echo -e "     Ejecute un rastreo con 'find' sobre el directorio '/srv/app_owner/apps_legacy'."
  echo -e "     Los resultados exitosos (rutas encontradas) van a '/srv/sre_operator/audit_success.log'."
  echo -e "     Los errores de permisos (stderr nativo) van a '/srv/sre_operator/audit_errors.log'."
  echo -e "     Ambos archivos deben quedar completamente aislados."
  echo -e ""
  echo -e "  \e[1;31m3. Pipeline de Telemetría en Memoria Estricto\e[0m"
  echo -e "     De todos los archivos '.log' válidos en la infraestructura del app_owner,"
  echo -e "     extraiga de forma masiva las líneas que contengan exactamente 'ERROR',"
  echo -e "     'CRITICAL' o 'FATAL' mediante un único flujo de pipes ('|')."
  echo -e "     Requerimiento: No use archivos temporales intermedios. Las líneas deben"
  echo -e "     ordenarse descartando duplicados y el resultado debe guardarse comprimido"
  echo -e "     en '/srv/sre_operator/telemetry_signals.log.gz'."
  echo -e ""
  echo -e "  \e[1;31m4. Reporte Operativo de Monitoreo\e[0m"
  echo -e "     Genere el archivo '/srv/sre_operator/backup_status.txt' con la estructura:"
  echo -e "     Línea 1: La marca de tiempo exacta bajo el formato 'TIMESTAMP: [fecha]'"
  echo -e "     Línea 2: El mensaje 'STATUS: OPERACIÓN COMPILADA CON ÉXITO' concatenado."
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación (Entregables en /srv/sre_operator/):\e[0m"
  echo -e "  [ ] critical_legacy.tar.xz generado bajo filtros estrictos            --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Bifurcación de descriptores (audit_success / audit_errors) lista   --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Pipeline telemetry_signals.log.gz sin basura ni duplicados         --> \e[1;35m25%\e[0m"
  echo -e "  [ ] backup_status.txt estructurado de forma inmutable                  --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO PLENA:\e[0m No modifique los permisos de 'secure_vault.log'."
  echo -e "                      Un Sysadmin Pleno redirige el flujo de errores, no lo evade."
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash

  # ==============================================================================
  # SCRIPT DE EVALUACIÓN AUTOMÁTICA (PG-004-v2-SYSADMIN-PLENO)
  # ==============================================================================

  PUNTOS=0
  TARGET_DIR="/srv/sre_operator"

  echo -e "\e[1;36m=== EVALUANDO AUTOMATIZACIÓN DE FLUJOS SRE Y DESCRIPTORES (8/10) ===\e[0m"

  # 1. VALIDAR RESPALDO TAR.XZ CON FILTROS
  if [ -f "$TARGET_DIR/critical_legacy.tar.xz" ]; then
      # Listar el contenido del tar de forma interna para evaluar qué se empaquetó
      TAR_CONTENT=$(tar -tf "$TARGET_DIR/critical_legacy.tar.xz")
      
      # Verificaciones internas:
      # - NO debe contener la palabra cache
      # - NO debe contener old_legacy.log (filtro de tiempo >24h)
      # - DEBE contener app1.log o kernel.log
      HAS_CACHE=$(echo "$TAR_CONTENT" | grep "cache")
      HAS_OLD=$(echo "$TAR_CONTENT" | grep "old_legacy.log")
      HAS_VALID=$(echo "$TAR_CONTENT" | grep -E "app1.log|kernel.log" || true)
      
      if [ -z "$HAS_CACHE" ] && [ -z "$HAS_OLD" ] && [ -n "$HAS_VALID" ]; then
          echo -e "✔ \e[1;32m[30%]\e[0m critical_legacy.tar.xz empaquetado correctamente con filtros de mtime y exclusión."
          PUNTOS=$((PUNTOS + 30))
      else
          echo -e "❌ \e[1;31m[0%]\e[0m critical_legacy.tar.xz contiene fallas. O arrastró archivos de cache/viejos o está vacío."
      fi
  else
      echo -e "❌ \e[1;31m[0%]\e[0m No se encontró el respaldo critical_legacy.tar.xz."
  fi

  # 2. VALIDAR BIFURCACIÓN FORENSE (stdout vs stderr nativo)
  SUCCESS_LOG="$TARGET_DIR/audit_success.log"
  ERRORS_LOG="$TARGET_DIR/audit_errors.log"

  if [ -f "$SUCCESS_LOG" ] && [ -f "$ERRORS_LOG" ]; then
      # El archivo de errores DEBE contener el string de "Permission denied" de secure_vault.log
      # El archivo de éxito NO debe contener mensajes de error.
      VALID_ERROR=$(grep -i "permission denied" "$ERRORS_LOG" || true)
      ERRORS_IN_SUCCESS=$(grep -i "permission denied" "$SUCCESS_LOG" || true)
      
      if [ -n "$VALID_ERROR" ] && [ -z "$ERRORS_IN_SUCCESS" ]; then
          echo -e "✔ \e[1;32m[25%]\e[0m Bifurcación forense de descriptores exitosa. Flujos stdout y stderr completamente aislados."
          PUNTOS=$((PUNTOS + 25))
      else
          echo -e "❌ \e[1;31m[0%]\e[0m Error en la bifurcación. El flujo de errores se mezcló con el de éxito o no se capturó."
      fi
  else
      echo -e "❌ \e[1;31m[0%]\e[0m Faltan archivos de auditoría indispensables (audit_success o audit_errors)."
  fi

  # 3. VALIDAR PIPELINE DE TELEMETRÍA (Compresión al vuelo sin archivos intermedios)
  TELEMETRY_GZ="$TARGET_DIR/telemetry_signals.log.gz"
  if [ -f "$TELEMETRY_GZ" ]; then
      # Descomprimir en memoria para verificar contenido
      GZ_CONTENT=$(zcat "$TELEMETRY_GZ" 2>/dev/null || true)
      
      # Chequear patrones requeridos y exclusión de duplicados
      HAS_FATAL=$(echo "$GZ_CONTENT" | grep "FATAL" || true)
      HAS_CRITICAL=$(echo "$GZ_CONTENT" | grep "CRITICAL" || true)
      HAS_INFO=$(echo "$GZ_CONTENT" | grep "INFO" || true)
      
      # Verificar ordenamiento único: Si hay duplicados o no está ordenado, fallará
      TOTAL_LINES=$(echo "$GZ_CONTENT" | wc -l)
      UNIQUE_LINES=$(echo "$GZ_CONTENT" | sort -u | wc -l)
      
      if [ -n "$HAS_FATAL" ] && [ -n "$HAS_CRITICAL" ] && [ -z "$HAS_INFO" ] && [ "$TOTAL_LINES" -eq "$UNIQUE_LINES" ] && [ "$TOTAL_LINES" -gt 0 ]; then
          echo -e "✔ \e[1;32m[25%]\e[0m Pipeline de telemetría correcto. Filtrado multi-patrón limpio, ordenado y comprimido."
          PUNTOS=$((PUNTOS + 25))
      else
          echo -e "❌ \e[1;31m[0%]\e[0m telemetry_signals.log.gz inválido. Contiene eventos no deseados o líneas duplicadas."
      fi
  else
      echo -e "❌ \e[1;31m[0%]\e[0m No se encontró el archivo de telemetría masiva telemetry_signals.log.gz."
  fi

  # 4. VALIDAR REPORTE OPERATIVO INMUTABLE
  STATUS_FILE="$TARGET_DIR/backup_status.txt"
  if [ -f "$STATUS_FILE" ]; then
      LINE_COUNT=$(wc -l < "$STATUS_FILE")
      HAS_TIMESTAMP=$(grep -E "^TIMESTAMP:" "$STATUS_FILE" || true)
      HAS_STATUS=$(grep -E "^STATUS: OPERACIÓN COMPILADA CON ÉXITO" "$STATUS_FILE" || true)
      
      if [ "$LINE_COUNT" -eq 2 ] && [ -n "$HAS_TIMESTAMP" ] && [ -n "$HAS_STATUS" ]; then
          echo -e "✔ \e[1;32m[20%]\e[0m backup_status.txt estructurado perfectamente acorde a la especificación de monitoreo."
          PUNTOS=$((PUNTOS + 20))
      else
          echo -e "❌ \e[1;31m[0%]\e[0m backup_status.txt tiene una estructura incorrecta, falta un campo o se destruyeron líneas."
      fi
  else
      echo -e "❌ \e[1;31m[0%]\e[0m No se generó el reporte operativo backup_status.txt."
  fi

  # POSTEO DE RESULTADOS FINAL
  echo -e "\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -eq 100 ]; then
      echo -e "  \e[1;32mCALIFICACIÓN FINAL: $PUNTOS / 100 — PIPELINE SRE COMPLETADO EN NIVEL PLENO\e[0m"
  else
      echo -e "  \e[1;31mCALIFICACIÓN FINAL: $PUNTOS / 100 — REVISE EL MANEJO DE DESCRIPTORES Y PIPES\e[0m"
  fi
  echo -e "\e[1;36m================================================================================\e[0m"
---
[[Laboratorios del LFCS]]

---
