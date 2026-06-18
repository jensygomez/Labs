---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-001
Titulo: Estructuras de archivos complejas y consistencia de Inodos - V2
Fecha de Inicio: 2026-06-09
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
Validacion:
  - Objetivo: El directorio maestro /mnt/secure_storage existe y contiene el archivo api.json con los datos correctos.
    Peso: 20 %
  - Objetivo: El archivo /mnt/secure_storage/api_backup.json comparte el mismo Inodo que el maestro de forma persistente.
    Peso: 40 %
  - Objetivo: El archivo /etc/api_core.json es un enlace simbólico (Soft Link) válido que apunta a la ruta absoluta del maestro.
    Peso: 40 %
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
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO AVANZADO CONFIGURADO - ESSENTIAL COMMANDS (PG-001 v2)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-4091 (URGENTE)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Reestructuración de Almacenamiento por Migración de API Core"
  echo -e " \e[1mSeveridad:\e[0m Alta / Producción Bloqueada"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Bhai, escucha bien porque esto llegó escalado desde arquitectura..."
  echo -e "  El equipo migró el microservicio crítico 'payment-gateway' y ahora"
  echo -e "  el contenedor busca su config ESTRICTAMENTE en:"
  echo -e "  \e[1;33m  /opt/payment_gateway/config/api.json\e[0m"
  echo -e ""
  echo -e "  Pero Security no dejó pasar eso así nomás, yaar."
  echo -e "  Ellos exigen que el archivo maestro viva en el volumen seguro de auditoría:"
  echo -e "  \e[1;33m  /mnt/secure_storage/api.json\e[0m  con contenido \e[1;32mPROD_KEY=8f9a2c\e[0m"
  echo -e "  No hay negociación. Compliance es compliance."
  echo -e ""
  echo -e " \e[1mRestricciones — léelas dos veces antes de tocar algo:\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1.\e[0m Duplicar físicamente el archivo está PROHIBIDO."
  echo -e "     Una llave criptográfica en dos lugares = desincronización garantizada."
  echo -e ""
  echo -e "  \e[1;31m2.\e[0m El servicio rota nombres automáticamente, bhai."
  echo -e "     '/mnt/secure_storage/api_backup.json' debe funcionar SIEMPRE,"
  echo -e "     incluso si el maestro cambia de nombre dentro del mismo volumen."
  echo -e "     Si ese acceso se rompe, el pipeline cae. Tú decides cómo lo resuelves."
  echo -e ""
  echo -e "  \e[1;31m3.\e[0m Necesitamos acceso directo desde configuración del sistema:"
  echo -e "     '/etc/api_core.json' apuntando al maestro original."
  echo -e ""
  echo -e "  \e[1;31m4.\e[0m \e[1;31m¡ATENCIÓN!\e[0m Hay múltiples filesystems montados en este servidor."
  echo -e "     Un error en el tipo de enlace y el deployment pipeline se va al piso."
  echo -e "     \e[1;32mInspecciona con 'df' ANTES de ejecutar cualquier cosa.\e[0m"
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación:\e[0m"
  echo -e "  [ ] Maestro '/mnt/secure_storage/api.json' con 'PROD_KEY=8f9a2c' --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Enlace persistente en '/mnt/secure_storage/api_backup.json'   --> \e[1;35m40%\e[0m"
  echo -e "  [ ] Enlace simbólico en '/etc/api_core.json'                      --> \e[1;35m40%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mPista de Pleno:\e[0m Ejecuta 'df -h' primero para entender los límites de los discos."
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
_Recently, I worked on a high-severity incident ticket — INC-4091 — involving storage restructuring for a critical microservice migration in a production environment._

_The core challenge was establishing the correct file linking architecture across multiple mounted filesystems. Before touching anything, I ran `df -h` to inspect the disk layout and identified that `/mnt/secure_storage` was mounted on a separate `tmpfs` filesystem, completely isolated from the root `overlay` filesystem where `/etc` resides._

_Based on that analysis, I made two deliberate technical decisions. First, I created a hard link between `api.json` and `api_backup.json` within the same `tmpfs` volume. I chose a hard link specifically because the service performs automatic file renaming — a hard link shares the same inode, so even if the original filename changes, the backup reference remains intact and points to the same data blocks. Second, I created a symbolic link from `/etc/api_core.json` pointing to the master file. A symlink was the only viable option here because hard links cannot cross filesystem boundaries — that's an enforced kernel-level restriction._

_The solution satisfied all three constraints simultaneously: no physical file duplication, resilience against filename rotation, and cross-filesystem accessibility — achieving a 100% validation score._

_What I value most about this exercise is that it reinforced a fundamental sysadmin mindset: always inspect your environment before operating. One wrong link type would have broken the entire deployment pipeline._