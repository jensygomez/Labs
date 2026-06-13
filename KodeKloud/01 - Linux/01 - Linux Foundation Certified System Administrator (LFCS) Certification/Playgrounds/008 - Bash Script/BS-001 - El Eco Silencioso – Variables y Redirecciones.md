---
Curso: Bash Scripting para Sysadmins
Modulo: Fundamentos
Playground: BS-001-v1
Titulo: El Eco Silencioso – Variables y Redirecciones
Fecha de Inicio: 2026-06-13
Dificultad: 2/10
Level Escalation: L1
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para Devops Enginner y Kubernets
Temas: |-
  - Variables de entorno y variables locales
  - Redirección de salida estándar (stdout) y error (stderr)
  - Permisos de ejecución (chmod +x)
  - Shebang (#!/bin/bash)
  - Captura de salida de comandos (command substitution)
Competencias: |-
  - Crear scripts básicos con permisos de ejecución correctos.
  - Almacenar la salida de comandos en variables.
  - Redirigir salida estándar y errores a archivos.
  - Generar reportes automatizados con marcas de tiempo.
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  LAB_ID="BS-001-v1"
  LAB_NAME="El Eco Silencioso"
  USER_CURRENT=$(whoami)
  WORK_DIR="$HOME/lab-bash-001"
  REPORT_DIR="$WORK_DIR/reportes"
  TARGET_SCRIPT="$WORK_DIR/reporte_servidor.sh"

  echo -e "\e[1;33m⏳ Preparando entorno de laboratorio...\e[0m"
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"
  mkdir -p "$REPORT_DIR"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "  TICKET INC-1001  │  Severidad: MEDIA  │  Ambiente: ESTACIÓN LOCAL"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "  \e[1;33m⏱️  $LAB_ID — $LAB_NAME\e[0m"
  echo -e "  Módulo: Fundamentos Bash  │  Dificultad: 2/10  │  Nivel: L1"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Estación del Administrador — \e[1;32m$USER_CURRENT\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  El equipo de \e[1mNOC\e[0m ha reportado un problema de fatiga operativa que se"
  echo -e "  repite turno tras turno. Cada vez que el personal de guardia necesita"
  echo -e "  conocer el estado del servidor, debe ejecutar manualmente los comandos"
  echo -e "  \e[1mdf -h\e[0m, \e[1mfree -m\e[0m y \e[1muptime\e[0m, uno por uno, sin ningún registro histórico"
  echo -e "  de los resultados ni trazabilidad de los errores que puedan presentarse."
  echo ""
  echo -e "  La solicitud que llega al ingeniero encargado es concreta: automatizar"
  echo -e "  esa rutina de revisión mediante un script de Bash que genere un reporte"
  echo -e "  diario con marca de tiempo precisa y que capture tanto la salida estándar"
  echo -e "  como cualquier error que ocurra durante la ejecución, dejando todo"
  echo -e "  registrado en un archivo de log identificable y trazable."
  echo ""
  echo -e "  Para lograrlo, el ingeniero deberá crear y configurar el archivo"
  echo -e "  \e[1mreporte_servidor.sh\e[0m asegurando el shebang correcto y sus permisos de"
  echo -e "  ejecución; definir dentro del script una variable \e[1mFECHA\e[0m que capture"
  echo -e "  el momento exacto de ejecución con formato \e[1mYYYY-MM-DD_HH-MM\e[0m usando"
  echo -e "  sustitución de comandos; y redirigir la salida de los tres comandos de"
  echo -e "  estado — tanto \e[1mstdout\e[0m como \e[1mstderr\e[0m — hacia el archivo de destino"
  echo -e "  \e[1m\$REPORT_DIR/estado_\$FECHA.log\e[0m, garantizando que ningún evento"
  echo -e "  quede sin registrar."
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m Script con permisos de ejecución (\e[1mchmod +x\e[0m)                   \e[0;35m→ 30%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Variable \e[1mFECHA\e[0m correctamente formateada y utilizada             \e[0;35m→ 30%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Redirección \e[1m2>&1\e[0m funcional — captura errores y salida estándar \e[0;35m→ 40%\e[0m"
  echo ""
  echo -e "\e[1;31m  REGLA DE ORO:\e[0m No ejecutes el script como \e[1mroot\e[0m. Practica con tu usuario."
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""

  cat << 'EOF_INNER' > "$TARGET_SCRIPT"
  #!/bin/bash
  # ==============================================================================
  # Script: reporte_servidor.sh
  # Objetivo: Generar reporte de estado del sistema con marca de tiempo.
  # ==============================================================================

  # TODO 1: Define la variable FECHA usando el comando 'date' con el formato adecuado.
  # Ejemplo de formato: YYYY-MM-DD_HH-MM
  # FECHA=

  # TODO 2: Define la variable ARCHIVO_SALIDA usando la carpeta de reportes y la variable FECHA.
  # ARCHIVO_SALIDA=

  echo "⏳ Generando reporte del servidor..."

  # TODO 3: Ejecuta 'df -h', 'free -m' y 'uptime'.
  # Debes redirigir tanto la salida estándar (1) como la de error (2) al ARCHIVO_SALIDA.

  echo "✅ Reporte generado con éxito. Revisa la carpeta de reportes."
  EOF_INNER

  chmod 644 "$TARGET_SCRIPT"

  echo -e "\e[1;32m✔ Entorno configurado exitosamente.\e[0m"
  echo -e "📂 Ingresa al directorio de trabajo con: \e[1;33mcd $WORK_DIR\e[0m"
  echo -e "📝 Tu script para editar es: \e[1;33m$TARGET_SCRIPT\e[0m"
  echo -e "\e[1;36m¡Buena suerte, Sysadmin! El reloj corre.\e[0m"
  EOF
  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
tags:
  - Advanced-Bash-Scripting
  - Laboratorios-del-LFCS
Script Validacion: |-
  cat << 'EOF' > /tmp/validador-bash-lab-01.sh
  #!/bin/bash
  PUNTOS=0
  LAB_DIR="$HOME/lab-bash-001"
  TARGET_SCRIPT="$LAB_DIR/reporte_servidor.sh"
  REPORT_DIR="$LAB_DIR/reportes"

  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  AUDITORÍA DE SCRIPT — INC-1001 (BS-001-v1)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # 1. Permisos de Ejecución (30%)
  echo -e "\n\e[1;37m⏳ [1/3] Verificando permisos de ejecución del script...\e[0m"
  if [ -x "$TARGET_SCRIPT" ]; then
    echo -e "\e[1;32m  ✔ [30%] El script tiene permisos de ejecución (chmod +x) correctamente aplicados.\e[0m"
    PUNTOS=$((PUNTOS + 30))
  else
    echo -e "\e[1;31m  ❌ [0%] El script NO tiene permisos de ejecución.\e[0m"
    echo -e "       → Diagnóstico: El sistema de archivos bloquea la ejecución directa './reporte_servidor.sh'."
    echo -e "       → Solución: Ejecuta 'chmod +x $TARGET_SCRIPT'"
  fi

  # 2. Variable de Fecha Dinámica (30%)
  echo -e "\n\e[1;37m⏳ [2/3] Verificando declaración de variable de tiempo (FECHA)...\e[0m"
  # Buscamos que se asigne algo a FECHA y que invoque al comando 'date'
  if grep -qE "FECHA=.*date" "$TARGET_SCRIPT" 2>/dev/null; then
    echo -e "\e[1;32m  ✔ [30%] Se detecta la asignación dinámica de la variable FECHA usando 'date'.\e[0m"
    PUNTOS=$((PUNTOS + 30))
  else
    echo -e "\e[1;31m  ❌ [0%] No se detecta una variable 'FECHA' generada dinámicamente.\e[0m"
    echo -e "       → Diagnóstico: Revisa la sintaxis. Debe ser algo como: FECHA=\$(date +'%Y-%m-%d_%H-%M')"
    echo -e "       → Solución: Edita el script y asegura que la variable capture la salida del comando date."
  fi

  # 3. Redirección y Generación Real del Log (40%)
  echo -e "\n\e[1;37m⏳ [3/3] Verificando redirección de salida (stdout + stderr) y generación de log...\e[0m"

  # A. Verificar sintaxis de redirección en el código
  REDIRECT_OK=$(grep -cE "2>&1|&>" "$TARGET_SCRIPT" 2>/dev/null || echo 0)

  # B. Ejecutar el script silenciosamente para probar su lógica real (usamos bash para evitar fallo por falta de +x)
  bash "$TARGET_SCRIPT" >/dev/null 2>&1

  # C. Buscar el archivo generado más reciente en la carpeta de reportes
  LOG_FILE=$(ls -t "$REPORT_DIR"/estado_*.log 2>/dev/null | head -n 1)

  if [ "$REDIRECT_OK" -gt 0 ] && [ -n "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
    echo -e "\e[1;32m  ✔ [40%] Redirección correcta (2>&1) y archivo de log generado con contenido.\e[0m"
    echo -e "       → Archivo detectado: \e[1;36m$(basename "$LOG_FILE")\e[0m"
    PUNTOS=$((PUNTOS + 40))
  else
    echo -e "\e[1;31m  ❌ [0%] Fallo en la redirección o no se generó el archivo de log.\e[0m"
    if [ "$REDIRECT_OK" -eq 0 ]; then
      echo -e "       → Diagnóstico Código: No se encontró el operador '2>&1' o '&>' en el script."
    fi
    if [ -z "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
      echo -e "       → Diagnóstico Ejecución: No se encontró un archivo 'estado_*.log' con contenido en '$REPORT_DIR'."
    fi
    echo -e "       → Solución: Asegura que los comandos terminen con '>> \$ARCHIVO_SALIDA 2>&1'"
  fi

  # Resultado Final
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
    echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — ¡Excelente! Dominio de variables y redirecciones en Bash."
  elif [ $PUNTOS -ge 60 ]; then
    echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revisa los puntos ❌."
  else
    echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — El script no cumple con los requisitos mínimos de automatización."
  fi
  echo -e "\e[1;36m================================================================================\e[0m\n"
  EOF

  chmod +x /tmp/validador-bash-lab-01.sh
  bash /tmp/validador-bash-lab-01.sh
  # No borramos el validador inmediatamente para que el estudiante pueda inspeccionar la lógica (cat /tmp/validador-bash-lab-01.sh)
---
[[Laboratorios del LFCS]]



---

Actually, yes — there's a situation that comes to mind from my current role.

We had a recurring issue on the NOC floor where the on-call staff was manually checking server health every single shift — running `df -h`, `free -m`, and `uptime` one by one, with no logs, no timestamps, no way to trace what the system looked like at 2 AM when an incident started. If something went wrong overnight, we had no historical baseline to compare against.

I took it upon myself to solve that. I wrote a Bash script that automates the entire health check and generates a timestamped log file on every run. The filename itself encodes the exact moment of execution — down to the minute — so logs never overwrite each other and you always know when each snapshot was taken.

I also made sure the script captures not just standard output but stderr as well, using `2>&1` redirection. That was important to me — a script that silently swallows errors gives you a false sense of stability. If something fails, I want that failure on record.

The result was a simple but reliable audit trail that the team could reference during post-incident reviews. No more "we don't know what the disk looked like before it filled up." The data was just there.

It's a straightforward solution, but it reflects something I care about: if you're going to monitor systems, you need to actually _keep_ what you observe. Otherwise you're just watching, not recording.

---

