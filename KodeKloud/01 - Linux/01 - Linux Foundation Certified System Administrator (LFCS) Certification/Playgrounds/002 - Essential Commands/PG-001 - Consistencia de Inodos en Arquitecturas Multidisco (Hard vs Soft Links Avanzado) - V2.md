---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-001
Titulo: Consistencia de Inodos en Arquitecturas Multidisco (Hard vs Soft Links Avanzado)
Fecha de Inicio: 2026-06-05
Dificultad: 6/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno Level 2/3
Temas:
  - Create, Delete, Copy, and Move Files and Directories
  - Create and Manage Hard Links (Filesystem Constraints)
  - Create and Manage Soft Links
  - Read and Use System Documentation (df, stat)
Competencias:
  - Analizar la topología de almacenamiento (`df` / `mount`) antes de estructurar enlaces
  - Resolver restricciones del Kernel de Linux respecto a enlaces cruzados entre dispositivos (Cross-device links)
  - Diseñar persistencia de configuración para microservicios críticos
Ticket: |-
  INC-4091 (Urgente) - Reestructuración de Almacenamiento por Migración de API Core

  El equipo de Arquitectura de Software migró un microservicio crítico ("payment-gateway"). El contenedor nativo busca su archivo de configuración estrictamente en la ruta '/opt/payment_gateway/config/api.json'. 

  Sin embargo, el equipo de Seguridad exige que el archivo maestro original resida en el nuevo volumen dedicado y seguro de auditoría montado en '/mnt/secure_storage/api.json' con el contenido "PROD_KEY=8f9a2c".

  Restricciones y Requerimientos del Ticket:
  1. No se permite duplicar físicamente el archivo para evitar desincronizaciones de llaves criptográficas.
  2. Debido a que el servicio realiza rotaciones automáticas de nombres, el acceso desde la ruta alternativa '/mnt/secure_storage/api_backup.json' NO debe romperse bajo ninguna circunstancia, incluso si el archivo maestro original cambia de nombre o se mueve dentro de ese mismo volumen de almacenamiento.
  3. Se debe habilitar un acceso directo desde el directorio de configuración del sistema en '/etc/api_core.json' apuntando al maestro original.
  4. ¡ATENCIÓN SYSADMIN!: El servidor cuenta con múltiples sistemas de archivos montados. Deberá inspeccionar la estructura con 'df' antes de operar, ya que un error en la elección del tipo de enlace causará la caída del pipeline de despliegue.
Validacion:
  - Objetivo: El directorio maestro /mnt/secure_storage existe y contiene el archivo api.json con los datos correctos.
    Peso: 20 %
  - Objetivo: El archivo /mnt/secure_storage/api_backup.json comparte el mismo Inodo que el maestro de forma persistente.
    Peso: 40 %
  - Objetivo: El archivo /etc/api_core.json es un enlace simbólico (Soft Link) válido que apunta a la ruta absoluta del maestro.
    Peso: 40 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Limpieza absoluta de escenarios previos
  rm -rf /mnt/secure_storage
  rm -rf /opt/payment_gateway
  rm -f /etc/api_core.json

  # SIMULACIÓN DE ESCENARIO PLENO: Creamos un sistema de archivos virtual en memoria (tmpfs)
  # para simular un segundo disco físico montado en /mnt/secure_storage.
  # Esto romperá cualquier intento de hacer un Hard Link desde /etc o /opt hacia /mnt.
  mkdir -p /mnt/secure_storage
  if ! mountpoint -q /mnt/secure_storage; then
      mount -t tmpfs -o size=10M tmpfs /mnt/secure_storage
  fi

  # Crear la ruta donde el contenedor buscará la configuración
  mkdir -p /opt/payment_gateway/config

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO AVANZADO CONFIGURADO - ESSENTIAL COMMANDS (PG-001 v2)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-4091\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Consistencia de Inodos en Arquitecturas Multidisco"
  echo -e " \e[1mSeveridad:\e[0m Alta / Producción Bloqueada"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " El microservicio requiere que resuelvas la disposición de enlaces."
  echo -e " Recuerda la regla de oro del Kernel de Linux sobre los Filesystems y los Inodos."
  echo -e " Si ejecutas un comando prohibido, el sistema operativo te arrojará un error."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación:\e[0m"
  echo -e "  [ ] Maestro '/mnt/secure_storage/api.json' con 'PROD_KEY=8f9a2c' --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Enlace persistente en '/mnt/secure_storage/api_backup.json'   --> \e[1;35m40%\e[0m"
  echo -e "  [ ] Enlace simbólico en '/etc/api_core.json'                      --> \e[1;35m40%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mPista de Pleno:\e[0m Ejecuta 'df -h' primero para entender los límites de los discos.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO ENTORNO MULTIDISCO Y CONSISTENCIA DE INODOS ==="

  MAESTRO="/mnt/secure_storage/api.json"
  HARD_L="/mnt/secure_storage/api_backup.json"
  SOFT_L="/etc/api_core.json"

  # 1. Validar archivo maestro original
  if [ -f "$MAESTRO" ] && grep -q "PROD_KEY=8f9a2c" "$MAESTRO"; then
      echo "✔ [20%] Archivo maestro original creado correctamente en el volumen seguro."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El archivo maestro en $MAESTRO no existe o su contenido es erróneo."
  fi

  # 2. Validar Hard Link (Debe estar en el mismo filesystem /mnt/secure_storage)
  if [ -f "$MAESTRO" ] && [ -f "$HARD_L" ]; then
      INODO_M=$(stat -c '%i' "$MAESTRO")
      INODO_H=$(stat -c '%i' "$HARD_L")
      DEV_M=$(stat -c '%d' "$MAESTRO")
      DEV_H=$(stat -c '%d' "$HARD_L")
      
      if [ "$INODO_M" -eq "$INODO_H" ] && [ "$DEV_M" = "$DEV_H" ]; then
          echo "✔ [40%] Enlace persistente validado con éxito. Inodo compartido: $INODO_M dentro del mismo dispositivo."
          PUNTOS=$((PUNTOS + 40))
      else
          echo "❌ [0%] El archivo $HARD_L no es un Hard Link legítimo o está en discos diferentes."
      fi
  else
      echo "❌ [0%] Falta crear el enlace permanente persistente en $HARD_L."
  fi

  # 3. Validar Soft Link (Este sí puede cruzar filesystems desde /etc hasta /mnt)
  if [ -L "$SOFT_L" ]; then
      TARGET_SOFT=$(readlink "$SOFT_L")
      if [ "$TARGET_SOFT" = "$MAESTRO" ]; then
          echo "✔ [40%] Enlace simbólico en $SOFT_L apunta correctamente al volumen montado."
          PUNTOS=$((PUNTOS + 40))
      else
          echo "❌ [0%] El enlace simbólico existe pero no apunta a la ruta absoluta del maestro."
      fi
  else
      echo "❌ [0%] El archivo en $SOFT_L no es un enlace simbólico válido."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---
[[Laboratorios del LFCS]]
---
