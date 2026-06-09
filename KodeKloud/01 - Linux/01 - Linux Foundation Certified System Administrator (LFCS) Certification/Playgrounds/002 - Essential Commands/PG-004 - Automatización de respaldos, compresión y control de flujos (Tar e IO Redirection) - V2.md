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

  # Limpieza forense absoluta de laboratorios previos
  rm -rf /var/log/apps_legacy /backup /root/audit_success.log /root/audit_errors.log /root/telemetry_signals.log.gz /root/backup_status.txt
  mkdir -p /var/log/apps_legacy/core_service
  mkdir -p /var/log/apps_legacy/cache_v2
  mkdir -p /backup

  # Inyección de archivos simulados con marcas de tiempo actuales (0 días de modificación)
  echo "2026-06-05 FATAL Kernel panic in thread 2" > /var/log/apps_legacy/core_service/kernel.log
  echo "2026-06-05 CRITICAL Database cluster isolated" > /var/log/apps_legacy/core_service/db.log
  echo "2026-06-05 ERROR Connection timeout" > /var/log/apps_legacy/app1.log
  echo "2026-06-05 INFO Pipeline execution normal" > /var/log/apps_legacy/app2.log

  # Archivos que deben ser excluidos por patrón de palabra (cache)
  echo "TEMPORARY CORRUPT DATA" > /var/log/apps_legacy/cache_v2/volatile.log
  echo "METRICS STORAGE" > /var/log/apps_legacy/core_service/app_cache.log

  # Archivo que debe ser excluido por tiempo (Simulando modificación de hace 5 días atrás)
  touch -d "5 days ago" /var/log/apps_legacy/core_service/old_legacy.log
  echo "2026-06-01 ERROR Old unparsed error" >> /var/log/apps_legacy/core_service/old_legacy.log

  # Forzar error de permisos denegados nativo para la validación de stderr
  touch /var/log/apps_legacy/core_service/secure_vault.log
  chmod 000 /var/log/apps_legacy/core_service/secure_vault.log

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO AVANZADO CONFIGURADO - ESSENTIAL COMMANDS (PG-004 v2)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-8044 (CRÍTICO)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Automatización de Respaldos de Telemetría e Ingeniería de Flujos"
  echo -e " \e[1mSeveridad:\e[0m Crítica / Cumplimiento de Auditoría SRE"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  El equipo de SRE emitió una alerta de capacidad. El volumen compartido"
  echo -e "  de logs está llegando a su límite y la tendencia no da margen de espera."
  echo -e "  En paralelo, SecOps tiene una auditoría activa y exige evidencia"
  echo -e "  procesada antes del cierre de ventana. No hay extensión de plazo."
  echo -e ""
  echo -e "  La situación tiene cuatro frentes abiertos simultáneamente."
  echo -e "  Cada uno es independiente en su ejecución, pero todos convergen"
  echo -e "  en el mismo objetivo: dejar el entorno respaldado, auditado"
  echo -e "  y con un reporte inmutable que el sistema de monitoreo pueda consumir."
  echo -e ""
  echo -e " \e[1mLo que se necesita resolver — cuatro frentes, sin excepción:\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Respaldo Empresarial con Filtrado Estricto\e[0m"
  echo -e "     El directorio '/var/log/apps_legacy' debe ser empaquetado y"
  echo -e "     comprimido con el algoritmo XZ hacia '/backup/critical_legacy.tar.xz'."
  echo -e "     Pero no todo entra al respaldo. Dos filtros son obligatorios:"
  echo -e "     ningún archivo o ruta que contenga la palabra 'cache' debe incluirse,"
  echo -e "     y únicamente se procesarán archivos modificados en las últimas 24 horas."
  echo -e "     Un respaldo sin filtros no es un respaldo forense, es ruido comprimido."
  echo -e ""
  echo -e "  \e[1;31m2. Bifurcación Forense de Flujos de Diagnóstico\e[0m"
  echo -e "     Se debe ejecutar un rastreo con 'find' sobre ese mismo directorio."
  echo -e "     Los resultados exitosos van a '/root/audit_success.log'."
  echo -e "     Los errores de permisos y advertencias van a '/root/audit_errors.log'."
  echo -e "     Ambos flujos deben estar completamente aislados entre sí."
  echo -e "     Mezclar stdout y stderr en un mismo archivo invalida la evidencia."
  echo -e ""
  echo -e "  \e[1;31m3. Pipeline de Telemetría sin Archivos Intermedios\e[0m"
  echo -e "     De todos los archivos '.log' en la ruta raíz de la aplicación,"
  echo -e "     extraiga masivamente las líneas que contengan 'ERROR', 'CRITICAL'"
  echo -e "     o 'FATAL'. Todo en un único pipeline directo: sin tocar disco,"
  echo -e "     sin archivos temporales. Las líneas deben ordenarse de forma única"
  echo -e "     y el resultado final guardarse comprimido en '/root/telemetry_signals.log.gz'."
  echo -e "     La eficiencia aquí no es opcional, es parte del requerimiento."
  echo -e ""
  echo -e "  \e[1;31m4. Reporte Operativo Inmutable\e[0m"
  echo -e "     Genere '/root/backup_status.txt' con estructura precisa."
  echo -e "     Primera línea: la marca de tiempo exacta del sistema bajo el"
  echo -e "     formato 'TIMESTAMP: [fecha]', sobrescribiendo cualquier contenido previo."
  echo -e "     Segunda línea: el mensaje 'STATUS: OPERACIÓN COMPILADA CON ÉXITO'"
  echo -e "     concatenado sin destruir la primera línea."
  echo -e "     El sistema de monitoreo leerá este archivo. El formato no es sugerencia."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación:\e[0m"
  echo -e "  [ ] Backup critical_legacy.tar.xz listo (filtros: cache + mtime)    --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Bifurcación find (audit_success / audit_errors) aislada          --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Pipeline telemetry_signals.log.gz (ERE multi-patrón + unique)    --> \e[1;35m25%\e[0m"
  echo -e "  [ ] backup_status.txt estructurado con marcas TIMESTAMP / STATUS     --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mNota de Campo:\e[0m Cuatro frentes, una sola ventana de tiempo."
  echo -e "              Trabaje por capas. Valide cada salida antes de avanzar."
  echo -e "              SecOps no acepta resultados parciales como evidencia."
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO COMPRESIÓN INDUSTRIAL Y COMPLIANCE DE FLUJOS ==="

  BKP_FILE="/backup/critical_legacy.tar.xz"
  SUCCESS_LOG="/root/audit_success.log"
  ERROR_LOG="/root/audit_errors.log"
  GZ_TELEMETRY="/root/telemetry_signals.log.gz"
  STATUS_TXT="/root/backup_status.txt"

  # 1. Validar el archivo de respaldo Tar XZ y sus exclusiones complejas
  if [ -f "$BKP_FILE" ]; then
      # Validar formato XZ legítimo (-J)
      if tar -tJf "$BKP_FILE" >/dev/null 2>&1; then
          # Verificar exclusiones de la palabra 'cache'
          if ! tar -tf "$BKP_FILE" | grep -q "cache"; then
              # Verificar exclusión por tiempo (old_legacy.log no debe existir en el tar)
              if ! tar -tf "$BKP_FILE" | grep -q "old_legacy.log"; then
                  echo "✔ [30%] Respaldo corporativo Tar XZ verificado con exclusión analítica de tiempo y patrones."
                  PUNTOS=$((PUNTOS + 30))
              else
                  echo "❌ [15%] El respaldo XZ se creó, pero falló el filtro de tiempo (-mtime); incluyó archivos antiguos."
                  PUNTOS=$((PUNTOS + 15))
              fi
          else
              echo "❌ [10%] El respaldo XZ se creó, pero no aplicó la política de exclusión de directorios/archivos 'cache'."
              PUNTOS=$((PUNTOS + 10))
          fi
      else
          echo "❌ [0%] El archivo existe en la ruta pero no corresponde a una compresión XZ válida (-J)."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo de respaldo empresarial en $BKP_FILE."
  fi

  # 2. Validar aislamiento de flujos (Stdout vs Stderr)
  if [ -f "$SUCCESS_LOG" ] && [ -f "$ERROR_LOG" ]; then
      if [ -s "$SUCCESS_LOG" ] && [ -s "$ERROR_LOG" ]; then
          echo "✔ [25%] Separación analítica de flujos Stdout (1>) y Stderr (2>) validada con éxito."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [10%] Los archivos de log existen pero uno de los flujos está vacío (¿Olvidó capturar los errores de permisos?)."
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo "❌ [0%] Faltan los archivos de redirección del escaneo forense de rutas."
  fi

  # 3. Validar Pipeline de Telemetría e ingesta masiva
  if [ -f "$GZ_TELEMETRY" ]; then
      # Validar que contenga patrones complejos y esté filtrado con orden único
      if zgrep -q "FATAL" "$GZ_TELEMETRY" && zgrep -q "CRITICAL" "$GZ_TELEMETRY" && ! zgrep -q "INFO" "$GZ_TELEMETRY"; then
          echo "✔ [25%] Pipeline síncrono de telemetría masiva validado (Filtros RegEx extendidos y ordenamiento único implementados)."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] El flujo interno de datos comprimidos no cumple con el filtrado exclusivo de señales críticas."
      fi
  else
      echo "❌ [0%] No se encuentra el concentrador de señales comprimidas al vuelo en $GZ_TELEMETRY."
  fi

  # 4. Validar el reporte operativo dinámico
  if [ -f "$STATUS_TXT" ]; then
      LINE1=$(sed -n '1p' "$STATUS_TXT")
      LINE2=$(sed -n '2p' "$STATUS_TXT")
      
      if echo "$LINE1" | grep -q "^TIMESTAMP: " && [ "$LINE2" = "STATUS: OPERACIÓN COMPILADA CON ÉXITO" ]; then
          echo "✔ [20%] Reporte de ejecución inyectado con éxito empleando operadores dinámicos (> y >>)."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] La estructura de reporte diverge del formato exigido por monitoreo centralizado."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo de estado de ejecución de respaldo."
  fi

  echo "====================================================="
  echo "🎯 CONTROL DE RESPALDOS Y REDIRECCIÓN COMPLETA: $PUNTOS / 100"
  echo "====================================================="
---
[[Laboratorios del LFCS]]

---
