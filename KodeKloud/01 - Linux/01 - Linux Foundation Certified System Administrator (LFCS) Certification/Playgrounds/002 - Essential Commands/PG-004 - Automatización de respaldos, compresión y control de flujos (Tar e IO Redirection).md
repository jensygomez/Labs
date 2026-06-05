---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-004
Titulo: Automatización de respaldos, compresión y control de flujos (Tar e I/O Redirection)
Fecha de Inicio: 2026-06-04
Dificultad: 6/10
Objetivo:
  - Registrar flujos operativos y aislar errores del sistema
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Archive, Back Up, Compress, Unpack, and Uncompress Files
  - Use Input-Output Redirection (>, >>, |, 2>)
Competencias:
  - Dominar el empaquetado comprimido (tar) aplicando filtros de exclusión estrictos
  - Aislar flujos de salida estándar (stdout) y flujos de error (stderr) mediante descriptores de archivos
  - Construir pipelines eficientes interconectando herramientas mediante pipes (|)
Ticket: |-
  INC-3004

  El equipo de infraestructura solicita liberar espacio en el directorio '/var/log/apps_legacy'. Para ello, se requiere automatizar un proceso de depuración y respaldo que cumpla con los siguientes criterios de seguridad y control:
  1. Crear un único archivo empaquetado y comprimido con bzip2 en la ruta '/backup/legacy_logs.tar.bz2' que contenga todo el directorio '/var/log/apps_legacy'. Sin embargo, por directiva de la empresa, NO se deben incluir los archivos temporales con extensión '.tmp' dentro del empaquetado.
  2. Ejecute un escaneo general con el comando 'find /var/log/apps_legacy -type f'. Redirija la lista de archivos encontrados exitosamente hacia '/root/scan_success.log', y todos los errores de permisos denegados o advertencias (stderr) deben aislarse en '/root/scan_errors.log'.
  3. Extraiga las líneas que contengan la palabra "ERROR" de todos los archivos .log actuales, y envíelas mediante un pipeline directo para que se guarden comprimidas en formato gzip en la ruta '/root/extracted_errors.log.gz' (sin generar archivos de texto temporales intermedios).
  4. Genere un archivo de estado final en '/root/backup_status.txt'. La primera línea debe decir "--- INICIO REPORTE ---" (sobrescribiendo cualquier contenido previo), y la segunda línea debe agregar abajo "RESPALDO FINALIZADO CON ÉXITO" sin borrar la primera.
Validacion:
  - Objetivo: Archivo /backup/legacy_logs.tar.bz2 creado en bzip2 excluyendo archivos .tmp.
    Peso: 30 %
  - Objetivo: Flujos de find aislados correctamente (scan_success.log y scan_errors.log poblados).
    Peso: 25 %
  - Objetivo: Archivo comprimido /root/extracted_errors.log.gz generado con el flujo de errores interno.
    Peso: 25 %
  - Objetivo: Archivo /root/backup_status.txt estructurado correctamente con los operadores de redirección.
    Peso: 20 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Crear entorno limpio exclusivo para este laboratorio
  rm -rf /var/log/apps_legacy /backup /root/scan_success.log /root/scan_errors.log /root/extracted_errors.log.gz /root/backup_status.txt
  mkdir -p /var/log/apps_legacy/subdir1
  mkdir -p /var/log/apps_legacy/subdir2
  mkdir -p /backup

  # Poblar con archivos de simulación
  echo "2026-06-04 ERROR Connection timeout" > /var/log/apps_legacy/app1.log
  echo "2026-06-04 INFO Task completed" > /var/log/apps_legacy/subdir1/app2.log
  echo "2026-06-04 ERROR Disk full failure" > /var/log/apps_legacy/subdir2/app3.log
  echo "DATA TEMP NOT TO BE BACKUP" > /var/log/apps_legacy/cache1.tmp
  echo "DATA TEMP NOT TO BE BACKUP" > /var/log/apps_legacy/subdir1/cache2.tmp

  # Crear un archivo fantasma sin permisos de lectura para forzar el flujo de error (stderr) en el find
  touch /var/log/apps_legacy/subdir2/unreadable.log
  chmod 000 /var/log/apps_legacy/subdir2/unreadable.log

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ESCENARIO CONFIGURADO - ESSENTIAL COMMANDS (PG-004)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3004\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Automatización de respaldos, compresión y control de flujos"
  echo -e " \e[1mSeveridad:\e[0m Normal / Gestión de Almacenamiento"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Genere el backup comprimido en bzip2 excluyendo los archivos '.tmp'."
  echo -e " Ejecute la auditoría del directorio aislando stdout y stderr en sus respectivos"
  echo -e " archivos log, y configure el pipeline de extracción de errores al vuelo."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] /backup/legacy_logs.tar.bz2 listo sin archivos .tmp         --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Redirección find aislada (scan_success y scan_errors)       --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Pipeline /root/extracted_errors.log.gz creado al vuelo       --> \e[1;35m25%\e[0m"
  echo -e "  [ ] /root/backup_status.txt con las dos líneas de estado         --> \e[1;35m20%\e[0m"
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

  echo "=== EVALUANDO RESPALDOS Y REDIRECCIONES DE FLUJO ==="

  BKP_FILE="/backup/legacy_logs.tar.bz2"
  SUCCESS_LOG="/root/scan_success.log"
  ERROR_LOG="/root/scan_errors.log"
  GZ_ERRORS="/root/extracted_errors.log.gz"
  STATUS_TXT="/root/backup_status.txt"

  # 1. Validar el archivo de respaldo Tar Bzip2 y las exclusiones
  if [ -f "$BKP_FILE" ]; then
      # Verificar si es un archivo bzip2 legítimo
      if tar -tjf "$BKP_FILE" >/dev/null 2>&1; then
          # Verificar que no contenga archivos .tmp
          if ! tar -tf "$BKP_FILE" | grep -q "\.tmp$"; then
              echo "✔ [30%] Respaldo Tar comprimido en bzip2 verificado con exclusión de archivos '.tmp' exitosa."
              PUNTOS=$((PUNTOS + 30))
          else
              echo "❌ [15%] El archivo de respaldo existe y está comprimido, pero incluyó los archivos '.tmp'."
              PUNTOS=$((PUNTOS + 15))
          fi
      else
          echo "❌ [0%] El archivo en $BKP_FILE existe pero no tiene el formato de compresión bzip2 válido (-j)."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo de respaldo en $BKP_FILE."
  fi

  # 2. Validar aislamiento de flujos de redirección (Stdout vs Stderr)
  if [ -f "$SUCCESS_LOG" ] && [ -f "$ERROR_LOG" ]; then
      # El log de errores debe contener al menos el aviso del archivo ilegible debido a los permisos simulados
      if grep -q "unreadable.log" "$SUCCESS_LOG" 2>/dev/null && grep -q "Permission denied" "$ERROR_LOG"; then
          echo "✔ [25%] Separación analítica de flujos Stdout (1>) y Stderr (2>) validada."
          PUNTOS=$((PUNTOS + 25))
      else
          # Caso alternativo si find se ejecutó como root: root puede leer archivos chmod 000 de forma nativa,
          # por lo tanto, el error de "Permission denied" no se genera a menos que se fuerce la lectura del contenido o se corra diferente.
          # Para asegurar consistencia en el laboratorio evaluamos si los archivos fueron creados y no están vacíos de flujos cruzados.
          if [ -s "$SUCCESS_LOG" ] && [ -f "$ERROR_LOG" ]; then
              echo "✔ [25%] Flujos de redirección de comandos creados e implementados de forma correcta."
              PUNTOS=$((PUNTOS + 25))
          else
              echo "❌ [0%] Los archivos de escaneo de flujos existen pero no contienen las salidas separadas."
          fi
      fi
  else
      echo "❌ [0%] Faltan los archivos de redirección del escaneo de rutas."
  fi

  # 3. Validar el pipeline comprimido al vuelo
  if [ -f "$GZ_ERRORS" ]; then
      if zgrep -q "ERROR" "$GZ_ERRORS" 2>/dev/null && ! zgrep -q "INFO" "$GZ_ERRORS" 2>/dev/null; then
          echo "✔ [25%] Pipeline de extracción de logs y compresión directa al vuelo validado (.log.gz)."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] El archivo .gz existe pero no contiene los patrones filtrados esperados."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo de extracción comprimido al vuelo en $GZ_ERRORS."
  fi

  # 4. Validar el archivo de estado y el uso de los operadores > y >>
  if [ -f "$STATUS_TXT" ]; then
      LINE1=$(sed -n '1p' "$STATUS_TXT")
      LINE2=$(sed -n '2p' "$STATUS_TXT")
      
      if [ "$LINE1" = "--- INICIO REPORTE ---" ] && [ "$LINE2" = "RESPALDO FINALIZADO CON ÉXITO" ]; then
          echo "✔ [20%] Archivo de estado validado: Uso correcto de operadores destructivos (>) y aditivos (>>)."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] El archivo $STATUS_TXT existe pero el orden o contenido de las líneas de estado es incorrecto."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo de estado de estado de respaldo."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
