---
Curso: Practica Avanzada de Bash Scripting
Modulo: Gestión de Almacenamiento e I/O
Playground: LAB-02-V1
Titulo: Rotación y compresión de logs - V1
Fecha de Inicio: 2026-06-06
Dificultad: 4/10
Objetivo:
  - Identificar y manipular archivos basados en atributos de tamaño
  - Automatizar tareas de mantenimiento de disco y compresión de datos
Temas:
  - Uso básico del comando 'find' con filtros de tamaño (-size)
  - Compresión estándar con 'gzip' y empaquetado/movimiento de archivos
  - Operador de truncado/vaciado de archivos por redirección
Ticket: |-
  INC-1002 - Alerta de Espacio en Disco por Logs de Aplicaciones Heredadas

  El equipo de monitoreo reporta que el directorio de logs de la aplicación heredada está llenando la partición debido a que los archivos crecen de forma descontrolada. Se solicita un script de mantenimiento básico que identifique los archivos de log que superen un tamaño crítico, los respalde comprimidos en otra ruta para auditoría, y limpie el archivo original para liberar espacio inmediatamente.

  Requerimientos del Ticket (Junior L1):
  1. El script debe buscar todos los archivos con extensión `.log` dentro del directorio `/tmp/app_logs` que tengan un tamaño **mayor a 10 Megabytes** (en find se denota como `+10M`).
  2. Por cada archivo que cumpla la condición, debe:
     - Copiarlo al directorio de respaldo `/tmp/backup_logs/`.
     - Comprimir esa copia usando el comando `gzip` para ahorrar espacio.
     - Vaciar (truncar) el archivo de log original en `/tmp/app_logs` para que quede en 0 bytes pero mantenga los permisos (puedes usar el operador `> /ruta/del/archivo`).
  3. El script debe registrar en un archivo llamado `/tmp/rotacion.log` cada archivo que procese, con el formato: "MODIFICADO: [ruta_del_archivo]".
Validacion:
  - Objetivo: El script detecta exclusivamente los logs que superan las cuotas de tamaño establecidas.
    Peso: 40 %
  - Objetivo: Las copias comprimidas (.gz) se generan correctamente en la ruta de respaldo.
    Peso: 30 %
  - Objetivo: Los archivos de log originales son truncados con éxito a 0 bytes sin ser eliminados.
    Peso: 30 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_bash_02
  #!/bin/bash
  set -e

  # Limpieza absoluta de entornos previos
  rm -rf /tmp/app_logs /tmp/backup_logs /tmp/rotacion.log /tmp/rotar_logs.sh
  mkdir -p /tmp/app_logs
  mkdir -p /tmp/backup_logs

  # Simulación de logs de producción de diferentes tamaños
  # 1. Un log gigante que DEBE ser rotado (Aprox 12 MB)
  dd if=/dev/zero of=/tmp/app_logs/access_giant.log bs=1M count=12 2>/dev/null

  # 2. Un log mediano que NO debe ser rotado (Aprox 2 MB)
  dd if=/dev/zero of=/tmp/app_logs/error_medium.log bs=1M count=2 2>/dev/null

  # 3. Otro log gigante que DEBE ser rotado (Aprox 15 MB)
  dd if=/dev/zero of=/tmp/app_logs/database_heavy.log bs=1M count=15 2>/dev/null

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ENTORNO BASH LAB-02-V1 CONFIGURADO (NIVEL JUNIOR L1 - DIFICULTAD 4/10)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Tu entorno ha sido preparado con datos de prueba:"
  echo -e "  - Directorio de logs operativos: \e[1m/tmp/app_logs/\e[0m"
  echo -e "  - Directorio de destino de respaldos: \e[1m/tmp/backup_logs/\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " Escribe tu solución en: \e[1m/tmp/rotar_logs.sh\e[0m"
  echo -e " Al finalizar, ejecuta el Script de Validación para medir tu puntaje."
  echo -e "\e[1;36m================================================================================\e[0m"
  EOF
  bash /tmp/setup_bash_02 && rm -f /tmp/setup_bash_02
tags:
  - Laboratorios-del-LFCS
Script a Completar: |-
  # Copia este bloque dentro de /tmp/rotar_logs.sh y completa los TODO

  #!/bin/bash

  SOURCE_DIR="/tmp/app_logs"
  BACKUP_DIR="/tmp/backup_logs"
  LOG_AUDIT="/tmp/rotacion.log"

  # Limpiar log de auditoría del script si existía
  > "$LOG_AUDIT"

  # Bucle usando 'find' para localizar archivos de más de 10MB
  # Usamos un loop 'while read' alimentado por la salida de find
  find "$SOURCE_DIR" -type f -name "*.log" -size +10M | while read -r ARCHIVO; do
      
      # Extraer solo el nombre del archivo (sin la ruta completa /tmp/app_logs/)
      # Esto te servirá para moverlo limpiamente al directorio de respaldo
      NOMBRE_BASE=$(basename "$ARCHIVO")
      
      echo "Procesando archivo pesado detectado: $NOMBRE_BASE"
      
      # ==================================================================
      # TODO 1: Copia el archivo actual ($ARCHIVO) hacia el directorio de
      # respaldo ($BACKUP_DIR) manteniendo su nombre original ($NOMBRE_BASE).
      # Luego, aplica el comando 'gzip' sobre la copia que acabas de crear
      # dentro de $BACKUP_DIR para comprimirla (ej: gzip "$BACKUP_DIR/$NOMBRE_BASE").
      # ==================================================================
      # >>> INYECTA TU LÓGICA DE COPIA Y COMPRESIÓN AQUÍ <<<
      
      # ==================================================================
      # TODO 2: Vacía (trunca) el archivo original en caliente para liberar espacio.
      # Un Sysadmin Junior podría cometer el error de borrarlo (rm), lo cual
      # rompería la aplicación. Debes usar redirección destructiva para
      # dejarlo en 0 bytes (puedes hacer: > "$ARCHIVO").
      # No olvides registrar la operación en el archivo $LOG_AUDIT agregando
      # la línea: "MODIFICADO: $ARCHIVO" (usa el operador correcto para añadir).
      # ==================================================================
      # >>> INYECTA TU LÓGICA DE TRUNCADO Y REGISTRO AQUÍ <<<

  done

  echo "Proceso de rotación completado."
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0
  SRC="/tmp/app_logs"
  BKP="/tmp/backup_logs"
  AUDIT="/tmp/rotacion.log"

  echo "=== VALIDANDO LAB-02-V1 (ROTACIÓN JUNIOR L1) ==="

  # 1. Validar que el archivo mediano no haya sido tocado y mantenga su tamaño
  if [ -f "$SRC/error_medium.log" ] && [ "$(stat -c '%s' "$SRC/error_medium.log")" -gt 0 ]; then
      echo "✔ [40%] Discriminación de archivos correcta: El log menor a 10MB no fue alterado."
      PUNTOS=$((PUNTOS + 40))
  else
      echo "❌ [0%] Error: El archivo mediano fue modificado o eliminado por error."
  fi

  # 2. Validar que los archivos grandes hayan sido truncados a 0 bytes
  if [ -s "$SRC/access_giant.log" ] || [ -s "$SRC/database_heavy.log" ]; then
      echo "❌ [0%] Los archivos gigantes no han sido vaciados; siguen ocupando espacio en disco."
  fi

  if [ -f "$SRC/access_giant.log" ] && [ "$(stat -c '%s' "$SRC/access_giant.log")" -eq 0 ] && \
     [ -f "$SRC/database_heavy.log" ] && [ "$(stat -c '%s' "$SRC/database_heavy.log")" -eq 0 ]; then
      echo "✔ [30%] Truncado en caliente validado de forma exitosa (Tamaño actual: 0 bytes)."
      PUNTOS=$((PUNTOS + 30))
  fi

  # 3. Validar existencia de respaldos comprimidos y log de auditoría
  if [ -f "$BKP/access_giant.log.gz" ] && [ -f "$BKP/database_heavy.log.gz" ] && [ -s "$AUDIT" ]; then
      echo "✔ [30%] Respaldos GZIP generados correctamente en la ruta de auditoría."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] Faltan las copias comprimidas (.log.gz) en el directorio de respaldo o el log de auditoría."
  fi

  echo "====================================================="
  echo "🎯 SCORE FINAL DE ROTACIÓN JUNIOR: $PUNTOS / 100"
  echo "====================================================="
---
[[Laboratorios del LFCS]]

---
