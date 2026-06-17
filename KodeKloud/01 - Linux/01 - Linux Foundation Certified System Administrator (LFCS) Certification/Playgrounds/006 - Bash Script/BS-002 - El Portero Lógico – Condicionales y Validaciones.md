---
Curso: Bash Scripting para Sysadmins
Modulo: Fundamentos y Lógica Condicional
Playground: BS-002-v1
Titulo: El Portero Lógico – Condicionales y Validaciones
Fecha de Inicio: 2026-06-13
Dificultad: 3/10
Level Escalation: L1
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para Devops Enginner y Kubernets
Temas: |-
  - Condicionales (if/elif/else) y operadores de comparación (-gt, -lt, -eq, -ne)
  - Test de existencia y atributos de archivos/directorios (-d, -f, -w, -s)
  - Códigos de salida ($?) y control de flujo con exit codes
  - Manejo de mensajes de error y validaciones de precondiciones
Competencias: |-
  - Diseñar flujos lógicos en Bash que validen el entorno antes de ejecutar tareas críticas (como respaldos o despliegues).
  - Verificar existencia de directorios de destino y crearlos automáticamente con permisos seguros si es necesario.
  - Evaluar el espacio disponible en disco de forma programática y abortar la ejecución si no se cumple el umbral mínimo.
  - Implementar manejo de errores con códigos de salida estandarizados y mensajes claros para facilitar la depuración y la integración en pipelines CI/CD.
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  LAB_ID="BS-002-v1"
  LAB_NAME="El Portero Lógico"
  USER_CURRENT=$(whoami)
  WORK_DIR="$HOME/lab-bash-002"
  SOURCE_DIR="$WORK_DIR/datos_origen"
  TARGET_SCRIPT="$WORK_DIR/respaldo_seguro.sh"

  echo -e "\e[1;33m⏳ Preparando entorno de laboratorio...\e[0m"
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"
  mkdir -p "$SOURCE_DIR"

  # Generar datos de prueba para respaldar
  echo "configuracion_db=production" > "$SOURCE_DIR/app.conf"
  echo "usuario_admin" > "$SOURCE_DIR/users.txt"
  dd if=/dev/urandom of="$SOURCE_DIR/dummy_data.bin" bs=1K count=50 2>/dev/null

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "  TICKET INC-2002  │  Severidad: ALTA   │  Ambiente: ESTACIÓN LOCAL"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "  \e[1;33m⏱️  $LAB_ID — $LAB_NAME\e[0m"
  echo -e "  Módulo: Fundamentos Bash  │  Dificultad: 3/10  │  Nivel: L1"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Estación del Administrador — \e[1;32m$USER_CURRENT\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  El equipo de \e[1mDevOps\e[0m ha solicitado automatizar el proceso de respaldo de"
  echo -e "  configuración crítica. Sin embargo, los respaldos anteriores fallaron"
  echo -e "  silenciosamente porque el disco de destino se llenó, corrompiendo archivos"
  echo -e "  y generando archives \e[1mtar\e[0m incompletos de 0 bytes."
  echo ""
  echo -e "  Se requiere un script 'inteligente' que actúe como portero lógico. Antes"
  echo -e "  de intentar comprimir la carpeta \e[1mdatos_origen\e[0m, el script debe validar"
  echo -e "  el entorno: verificar si la carpeta de destino existe (y crearla si no),"
  echo -e "  y comprobar que existan al menos \e[1m1 GB\e[0m de espacio libre. Si no hay"
  echo -e "  espacio, debe abortar la operación inmediatamente con un código de error."
  echo ""
  echo -e "  Tu misión es completar el script \e[1mrespaldo_seguro.sh\e[0m utilizando"
  echo -e "  condicionales (\e[1mif/elif/else\e[0m), operadores de test (\e[1m-d\e[0m, \e[1m-lt\e[0m) y"
  echo -e "  gestión adecuada de los códigos de salida (\e[1mexit 0\e[0m / \e[1mexit 1\e[0m)."
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m Validación de existencia del directorio con \e[1m-d\e[0m y creación automática  \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Cálculo correcto del espacio libre en KB (ej. con \e[1mdf\e[0m y \e[1mawk\e[0m)     \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Condicional \e[1mif/else\e[0m que aborta con \e[1mexit 1\e[0m si el espacio es insuficiente \e[0;35m→ 30%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Ejecución exitosa de \e[1mtar\e[0m y finalización con \e[1mexit 0\e[0m si hay espacio  \e[0;35m→ 20%\e[0m"
  echo ""
  echo -e "\e[1;31m  REGLA DE ORO:\e[0m El script debe ser robusto. Un buen Sysadmin valida antes de ejecutar."
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""

  cat << 'EOF_INNER' > "$TARGET_SCRIPT"
  #!/bin/bash
  # ==============================================================================
  # Script: respaldo_seguro.sh
  # Objetivo: Validar entorno y ejecutar respaldo comprimido de forma segura.
  # ==============================================================================

  # Variables de configuración
  DIR_ORIGEN="$HOME/lab-bash-002/datos_origen"
  DIR_DESTINO="$HOME/lab-bash-002/respaldo_destino"
  ESPACIO_MINIMO_KB=1048576 # 1 GB expresado en Kilobytes

  echo "🔒 Iniciando validación de entorno para respaldo..."

  # TODO 1: Validar si DIR_DESTINO existe.
  # Usa el operador -d. Si NO existe, créalo con 'mkdir -p' y muestra un mensaje.
  # if [ ! -d "$DIR_DESTINO" ]; then
  #     ...
  # fi

  # TODO 2: Obtener el espacio libre actual en KB del DIR_DESTINO.
  # Pista: Usa 'df -k "$DIR_DESTINO"' combinado con 'awk' para obtener solo el número de la columna 4.
  # Ejemplo: ESPACIO_LIBRE_KB=$(df -k "$DIR_DESTINO" | awk 'NR==2 {print $4}')
  # ESPACIO_LIBRE_KB=

  # TODO 3: Estructura condicional IF / ELSE para validar el espacio.
  # if [ "$ESPACIO_LIBRE_KB" -lt "$ESPACIO_MINIMO_KB" ]; then
  #     echo "❌ ERROR: Espacio insuficiente en $DIR_DESTINO"
  #     # Abortar el script con código de error
  #     exit ...
  # else
  #     echo "✅ Espacio verificado. Procediendo con el respaldo..."
  #     # Ejecutar comando tar para comprimir DIR_ORIGEN dentro de DIR_DESTINO
  #     # Ejemplo: tar -czf "$DIR_DESTINO/backup_$(date +%F).tar.gz" -C "$DIR_ORIGEN" .
  #     
  #     echo "✅ Respaldo completado con éxito."
  #     # Finalizar el script con código de éxito
  #     exit ...
  # fi
  EOF_INNER

  # Permisos: El estudiante debe cambiarlo a +x, pero lo dejamos en 644 inicialmente
  # para que sea parte del reto o lo cambien ellos mismos.
  chmod 644 "$TARGET_SCRIPT"

  echo -e "\e[1;32m✔ Entorno configurado exitosamente.\e[0m"
  echo -e "📂 Ingresa al directorio de trabajo con: \e[1;33mcd $WORK_DIR\e[0m"
  echo -e "📝 Tu script para editar es: \e[1;33m$TARGET_SCRIPT\e[0m"
  echo -e "\e[1;36m¡Buena suerte, Sysadmin! La lógica es tu mejor herramienta.\e[0m"
  EOF

  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
---
[[Laboratorios del LFCS]]
---
Recently, I was tasked with solving a recurring and silent failure in our backup pipeline. Configuration files were being lost because the destination disk would fill up, and the tar process would complete without throwing any errors — it just created empty, corrupted archives. Nobody noticed until it was too late.

I wrote a Bash script from scratch to act as a logical gatekeeper before any backup attempt. The script first checks whether the destination directory exists, and if it doesn't, it creates it automatically. Then it calculates the available disk space in kilobytes using `df` and `awk`, and compares it against a defined minimum threshold of 1 GB. If there isn't enough space, the script aborts immediately with a non-zero exit code so any monitoring system can catch the failure. Only when both conditions are met does it proceed to compress the source directory using `tar` with gzip compression, naming the archive with the current date for traceability.

The key lesson here wasn't just the scripting — it was understanding that a silent failure is more dangerous than a loud one. The system was technically running, but producing nothing useful. I wanted the script to fail fast and fail visibly.