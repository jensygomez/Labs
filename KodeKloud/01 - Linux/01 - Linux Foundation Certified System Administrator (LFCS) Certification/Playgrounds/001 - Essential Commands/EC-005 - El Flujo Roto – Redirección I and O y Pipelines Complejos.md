---
Curso: Transición Sysadmin a DevOps - Essential Commands LFCS/RHCSA
Modulo: Essential Commands (Redirección I/O y Pipelines Complejos)
Playground: EC-005
Titulo: El Flujo Roto – Redirección I/O y Pipelines Complejos
Fecha de Inicio: 2026-06-28
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Standard Input/Output/Error (FD 0, 1, 2) y su manipulación
  - Redirección >, >>, <, 2>, &>, 2>&1, <& y >&
  - Pipes simples (|) y pipes compuestos con tee
  - tee para bifurcar flujos (ver en tiempo real + guardar)
  - xargs para ejecución batch y paralela desde stdin
  - Here Documents (<<EOF) y Here Strings (<<<) para inyección multi-línea
  - Combinación de descriptores de archivo en pipelines complejos
Competencias: |-
  - Diagnosticar procesos que fallan silenciosamente separando stdout (FD 1) y stderr (FD 2) en archivos independientes para análisis forense del ETL.
  - Combinar y reordenar descriptores de archivo (2>&1, &>, >|) para consolidar flujos cuando se requiere un reporte unificado de errores y salida.
  - Utilizar tee en pipelines para monitorear en tiempo real la ejecución del ETL mientras se persiste la evidencia en disco y se envía a node03.
  - Automatizar el procesamiento batch de múltiples archivos de entrada del ETL usando xargs con control de concurrencia (-P) y delimitadores personalizados (-d).
  - Emplear Here Documents para inyectar comandos multi-línea y configuraciones complejas en sesiones SSH remotas, evitando problemas de escaping.
  - Orquestar pipelines completos que capturen, transformen y enruten evidencia desde node02 hacia node03 sin materializar archivos intermedios innecesarios.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_ec005.sh


  #!/bin/bash
  set -e

  PASS="caleston123"
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT}"

  echo -e "\e[1;33m⏳ Verificando sshpass en node01...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      echo caleston123 | sudo -S apt-get install -y sshpass -qq
  fi

  echo -e "\e[1;33m⏳ Instalando sshpass en nodos remotos...\e[0m"
  $SSH2 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"
  $SSH3 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Inyectando proceso ETL y archivos de entrada en node02...\e[0m"
  $SSH2 bash << 'NODE02_INJECT' || echo -e "\e[1;33m  [!] Detalle en node02, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'

      # 1. Crear estructura de directorios para el ETL
      mkdir -p /opt/etl/input
      mkdir -p /opt/etl/output
      mkdir -p /opt/etl/scripts

      # 2. Crear 15 archivos de entrada (suficiente para demostrar xargs sin excederse)
      for i in {1..15}; do
          filename=$(printf "data_%03d.csv" $i)
          if [ $((i % 4)) -eq 0 ]; then
              # Archivos que causarán errores (cada 4 archivos: 4, 8, 12)
              cat > /opt/etl/input/$filename << EOF
  id,name,value,status
  $i,record_${i}_a,corrupted_data,INVALID
  $i,record_${i}_b,malformed_entry,ERROR
  EOF
          else
              # Archivos válidos
              cat > /opt/etl/input/$filename << EOF
  id,name,value,status
  $i,record_${i}_a,$((i * 100)),VALID
  $i,record_${i}_b,$((i * 150)),VALID
  $i,record_${i}_c,$((i * 200)),VALID
  EOF
          fi
      done

      # 3. Crear script ETL (SIN sleep, ejecución instantánea)
      cat > /opt/etl/scripts/etl_processor.sh << 'ETLSCRIPT'
  #!/bin/bash
  # Simula un proceso ETL que escribe en stdout y stderr

  INPUT_FILE="$1"
  FILENAME=$(basename "$INPUT_FILE")

  echo "[ETL] Procesando: $FILENAME"
  echo "[ETL] Leyendo datos de $INPUT_FILE"

  if grep -q "INVALID\|ERROR" "$INPUT_FILE"; then
      # Errores van a stderr (se pierden si no se capturan)
      echo "[ETL-ERROR] Archivo corrupto: $FILENAME" >&2
      echo "[ETL-ERROR] Datos malformados detectados" >&2
      echo "[ETL-WARN] Validación de integridad fallida" >&2
      exit 1
  else
      # Salida normal va a stdout
      echo "[ETL] Transformación completada: $FILENAME"
      echo "[ETL] Registros procesados: 3"
      echo "[ETL] Carga exitosa en destino"
      cp "$INPUT_FILE" /opt/etl/output/processed_$FILENAME
      exit 0
  fi
  ETLSCRIPT
      chmod +x /opt/etl/scripts/etl_processor.sh

      # 4. Crear script de validación post-ETL (para el Here Document)
      cat > /opt/etl/scripts/post_validator.sh << 'VALIDATOR'
  #!/bin/bash
  echo "=== VALIDACIÓN POST-ETL ==="
  echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Hostname: $(hostname)"

  TOTAL_INPUT=$(ls /opt/etl/input/*.csv 2>/dev/null | wc -l)
  TOTAL_OUTPUT=$(ls /opt/etl/output/processed_*.csv 2>/dev/null | wc -l)
  TOTAL_ERRORES=$((TOTAL_INPUT - TOTAL_OUTPUT))

  echo ""
  echo "--- ESTADÍSTICAS ---"
  echo "Archivos de entrada: $TOTAL_INPUT"
  echo "Archivos procesados: $TOTAL_OUTPUT"
  echo "Archivos con error: $TOTAL_ERRORES"
  echo "Tasa de éxito: $(awk "BEGIN {printf \"%.1f\", ($TOTAL_OUTPUT/$TOTAL_INPUT)*100}")%"

  echo ""
  echo "--- INTEGRIDAD ---"
  for f in /opt/etl/output/*.csv; do
      if [ -f "$f" ]; then
          SIZE=$(stat -c%s "$f")
          echo "[OK] $(basename $f): $SIZE bytes"
      fi
  done

  echo ""
  echo "=== VALIDACIÓN COMPLETADA ==="
  VALIDATOR
      chmod +x /opt/etl/scripts/post_validator.sh

      # 5. Ejecutar el ETL una vez SIN capturar stderr (simulando el problema actual)
      echo -e "\e[1;33m  [!] Ejecutando ETL sin captura de errores (estado actual del problema)...\e[0m"
      cd /opt/etl/input
      for file in *.csv; do
          /opt/etl/scripts/etl_processor.sh "$file" >/dev/null 2>&1 || true
      done

      echo "[EC-005] Escenario ETL inyectado correctamente."
  SUDO_INNER
  NODE02_INJECT

  echo -e "\e[1;33m⏳ Preparando bóveda de evidencia en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/ec-005/
      mkdir -p /opt/ops-compliance/ec-005/
      chown -R bob:bob /opt/ops-compliance/ec-005/
      chmod 750 /opt/ops-compliance/ec-005/
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en preparación de node03, continuando...\e[0m'"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m EC-005-v1 | El Flujo Roto | Dificultad: 6/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/ec-005/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El equipo de operaciones reporta que el pipeline ETL en node02 falla de forma"
  echo -e " silenciosa. Los reportes llegan vacíos a node03, pero nadie sabe por qué: los"
  echo -e " errores se pierden porque nadie capturó stderr, y stdout no se persiste."
  echo -e ""
  echo -e " El ETL procesa 15 archivos CSV desde /opt/etl/input/ hacia /opt/etl/output/."
  echo -e " Algunos archivos contienen datos corruptos que generan errores en stderr,"
  echo -e " los cuales se pierden porque el proceso actual no redirige correctamente"
  echo -e " los descriptores de archivo."
  echo -e ""
  echo -e " Como ingeniero L2, debes diagnosticar el flujo roto, implementar redirecciones"
  echo -e " adecuadas y establecer pipelines robustos que capturen toda la evidencia."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención desde node01 vía SSH hacia node02."
  echo -e " \e[1m>\e[0m No materializar archivos de reporte o scripts temporales en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente de node02 a node03 por pipeline."
  echo -e " \e[1m>\e[0m En ningún momento stderr puede perderse en /dev/null."
  echo -e ""
  echo -e "\e[1;33m MISIONES TÉCNICAS (TICKET DE DIAGNÓSTICO ETL - NIVEL L2)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1mMISIÓN 1: Diagnóstico y Reporte Consolidado (30%)\e[0m"
  echo -e "    Ejecuta el ETL sobre los 15 archivos de /opt/etl/input/ con redirección"
  echo -e "    explícita: captura stdout en \e[1m/tmp/etl_stdout.log\e[0m y stderr en"
  echo -e "    \e[1m/tmp/etl_stderr.log\e[0m por separado."
  echo -e "    Luego genera un reporte unificado en \e[1m/tmp/etl_full.log\e[0m que combine"
  echo -e "    ambos flujos, pero marcando cada línea con su origen: \e[1m[STDOUT]\e[0m o"
  echo -e "    \e[1m[STDERR]\e[0m. Identifica qué tipo de errores están causando las fallas."
  echo -e "    \e[1;33mHerramientas clave:\e[0m >, 2>, sed/awk, 2>&1"
  echo -e ""
  echo -e " \e[1mMISIÓN 2: Monitoreo en Tiempo Real con tee (30%)\e[0m"
  echo -e "    Re-ejecuta el ETL usando \e[1mtee\e[0m en un pipeline para:"
  echo -e "      a) Ver la salida en tiempo real en tu terminal."
  echo -e "      b) Guardar todo en \e[1m/tmp/etl_live.log\e[0m."
  echo -e "      c) Enviar simultáneamente solo las líneas con ERROR o WARN hacia node03"
  echo -e "         al archivo \e[1m/opt/ops-compliance/ec-005/realtime_errors.txt\e[0m."
  echo -e "    \e[1;33mHerramientas clave:\e[0m tee, grep, pipeline SSH"
  echo -e ""
  echo -e " \e[1mMISIÓN 3: Procesamiento Batch + Validación (25%)\e[0m"
  echo -e "    Usa \e[1mxargs\e[0m para ejecutar el transformador en paralelo (\e[1m-P 4\e[0m)"
  echo -e "    sobre los 15 archivos, consolidando stderr de todas las ejecuciones en un"
  echo -e "    único stream hacia node03 (\e[1m/opt/ops-compliance/ec-005/batch_errors.txt\e[0m)."
  echo -e "    Después, usa un \e[1mHere Document\e[0m para inyectar via SSH el script de"
  echo -e "    validación post-ETL que está en /opt/etl/scripts/post_validator.sh. El"
  echo -e "    resultado de la validación debe fluir a node03 en"
  echo -e "    \e[1m/opt/ops-compliance/ec-005/validation.txt\e[0m."
  echo -e "    \e[1;33mHerramientas clave:\e[0m xargs -P -I, <<EOF, pipeline SSH"
  echo -e ""
  echo -e "\e[1;33m EVIDENCIA FINAL EN NODE03 (15%)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " Destino: \e[1m/opt/ops-compliance/ec-005/etl_diagnosis.txt\e[0m"
  echo -e " Debe contener la salida concatenada de las 3 misiones:"
  echo -e "  - Reporte consolidado con marcadores [STDOUT]/[STDERR]"
  echo -e "  - Errores filtrados del monitoreo en tiempo real"
  echo -e "  - Errores del procesamiento batch con xargs"
  echo -e "  - Resultado de la validación post-ETL"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Separación correcta de stdout/stderr en archivos independientes    15%"
  echo -e "  [ ] Reporte consolidado con marcadores [STDOUT]/[STDERR]               15%"
  echo -e "  [ ] Uso de tee para bifurcar flujo en tiempo real                      15%"
  echo -e "  [ ] Procesamiento paralelo con xargs (-P 4) sobre 15 archivos          10%"
  echo -e "  [ ] Here Document inyectado via SSH sin archivos temporales            15%"
  echo -e "  [ ] Pipelines completos sin materializar archivos en node01            15%"
  echo -e "  [ ] Evidencia (etl_diagnosis.txt) presente en bóveda node03            15%"
  echo -e "                                                                         -----"
  echo -e "                                                              TOTAL:     100%"
  echo -e ""
  echo -e "\e[1;33m TIEMPO ESTIMADO: 25-30 minutos\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_ec005.sh && rm -f /tmp/setup_ec005.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - Redirection
  - Pipes
  - tee
  - xargs
  - Here-Documents
  - File-Descriptors
  - ETL-Diagnosis
Escenario: |-
  - Situación Desde node01 te conectas a node02 donde corre un pipeline ETL (Extract, Transform, Load) que procesa datos críticos de negocio. El proceso "falla silenciosamente"=> los errores se pierden porque nadie capturó stderr, la salida estándar no se persiste, y el equipo de operaciones lleva días sin entender por qué los reportes finales llegan vacíos a node03.

  Tu misión
  1. Diagnosticar el proceso ETL ejecutándolo con redirección explícita: captura stdout en /tmp/etl_stdout.log y stderr en /tmp/etl_stderr.log por separado. Identifica qué tipo de errores (permisos, conexiones, datos malformed) están causando las fallas silenciosas.

  2. Generar un reporte consolidado combinando ambos flujos (stdout + stderr) en un único archivo /tmp/etl_full.log, pero asegurándote de que cada línea quede marcada con su origen ([STDOUT] o [STDERR]) para facilitar el análisis posterior.

  3. Re-ejecutar el ETL usando tee en un pipeline para que puedas ver la salida en tiempo real en tu terminal, guardarla en /tmp/etl_live.log, y simultáneamente enviar una copia filtrada (solo líneas con ERROR o WARN) hacia node03 via SSH.

  4. El ETL debe procesar 50 archivos de entrada ubicados en /opt/etl/input/. Usa xargs para ejecutar el transformador en paralelo (-P 4) sobre cada archivo, capturando el resultado de cada uno en /opt/etl/output/ y consolidando los errores en un único stream hacia node03.

  5. Usar un Here Document para inyectar en node02 un script de validación post-ETL multi-línea (que verifique integridad, cuente registros y compare checksums). El resultado de esta validación debe fluir directamente a node03 mediante un pipeline SSH, sin dejar archivos temporales en node01.

  Regla de Oro, En ningún momento puedes permitir que stderr se pierda en /dev/null "porque sí". Todo flujo (stdout, stderr o combinado) debe ser capturado, transformado o reenviado. node01 solo actúa como puente: nada se materializa allí de forma permanente.
---
---

[[Laboratorios del LFCS]]

---



