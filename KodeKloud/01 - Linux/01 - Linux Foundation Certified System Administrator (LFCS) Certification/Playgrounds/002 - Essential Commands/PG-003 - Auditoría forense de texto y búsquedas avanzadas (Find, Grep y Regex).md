---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-003
Titulo: Auditoría forense de texto y búsquedas avanzadas (Find, Grep y Regex)
Fecha de Inicio: 2026-06-04
Dificultad: 6/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Search for Files (find)
  - Search File Using Grep
  - Analyze Text Using Basic Regular Expressions (BRE)
  - Extended Regular Expressions (ERE)
Competencias:
  - Dominar búsquedas avanzadas en el sistema de archivos por tamaño y tiempo de modificación
  - Aislar registros específicos en logs masivos mediante patrones condicionales complejos (Grep -E)
  - Filtrar y limpiar archivos de configuración eliminando ruido visual (comentarios y espacios)
Ticket: |-
  INC-3003

  El equipo de Seguridad de la Información sospecha que un ex-empleado ocultó archivos pesados de configuración en el directorio '/var/log/audit_drop' y dejó registros de IPs comprometidas en el log del sistema.

  Se solicita realizar las siguientes tareas de auditoría de inmediato:
  1. Localizar dentro de '/var/log/audit_drop' cualquier archivo que tenga un tamaño mayor a 5MB Y que haya sido modificado en las últimas 24 horas. Copie ese archivo (o archivos) al directorio '/root/audit_found/'.
  2. Buscar en el archivo '/var/log/audit_drop/network.log' todas las líneas que contengan direcciones IP que comiencen estrictamente con el rango privado '10.' seguido de cualquier número (patrón BRE), y guardar el resultado en '/root/internal_ips.txt'.
  3. Auditar el mismo log de red y extraer todas las líneas que muestren errores de tipo 'CRITICAL' o 'FATAL' usando una sola expresión regular extendida (ERE), guardando el resultado en '/root/critical_errors.txt'.
  4. El archivo de configuración de la aplicación está lleno de comentarios. Genere una copia limpia en '/root/app.conf.clean' que elimine todas las líneas que comiencen con '#' y todas las líneas que estén completamente vacías.
Validacion:
  - Objetivo: Archivos pesados y recientes localizados y respaldados en /root/audit_found/.
    Peso: 25 %
  - Objetivo: Extracción de IPs en rango 10.x validada con formato BRE en /root/internal_ips.txt.
    Peso: 25 %
  - Objetivo: Filtrado condicional (CRITICAL|FATAL) validado con ERE en /root/critical_errors.txt.
    Peso: 25 %
  - Objetivo: Archivo de configuración limpio de comentarios y líneas vacías en /root/app.conf.clean.
    Peso: 25 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Limpieza de laboratorios previos
  rm -rf /var/log/audit_drop
  rm -rf /root/audit_found
  rm -f /root/internal_ips.txt
  rm -f /root/critical_errors.txt
  rm -f /root/app.conf.clean

  # Crear entorno de simulación
  mkdir -p /var/log/audit_drop
  mkdir -p /root/audit_found

  # Crear archivo pesado reciente (> 5MB)
  dd if=/dev/urandom of=/var/log/audit_drop/suspicious_data.dat bs=1M count=6 2>/dev/null
  # Crear archivo viejo que no debe ser copiado
  touch -d "2 days ago" /var/log/audit_drop/old_garbage.dat
  dd if=/dev/urandom of=/var/log/audit_drop/old_garbage.dat bs=1M count=6 2>/dev/null

  # Crear archivo de log de red simulado
  cat << 'LOGS' > /var/log/audit_drop/network.log
  2026-06-04 01:00:02 INFO Connection from 192.168.1.50 accepted
  2026-06-04 01:05:12 CRITICAL Database connection lost from 10.0.0.15
  2026-06-04 01:10:22 WARNING High latency detected
  2026-06-04 01:15:45 FATAL Auth failure on core-router for 10.254.1.1
  2026-06-04 01:20:00 INFO Status OK from 172.16.5.4
  2026-06-04 01:22:11 CRITICAL Hardware fault on slot 2
  LOGS

  # Crear archivo de configuración ruidoso
  cat << 'CONF' > /var/log/audit_drop/app.conf
  # Configuration File for Core App v2
  server_name = enterprise_node

  # Network Settings
  listen_port = 8443
  max_connections = 5000

  # Security parameters
  # ssl_enabled = true

  debug_mode = false
  CONF

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔍 ESCENARIO CONFIGURADO - ESSENTIAL COMMANDS (PG-003)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3003\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Auditoría forense de texto y búsquedas avanzadas"
  echo -e " \e[1mSeveridad:\e[0m Alta / Auditoría de Seguridad"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Use find para aislar el binario oculto reciente. Filtre network.log usando"
  echo -e " expresiones regulares para extraer logs específicos, y limpie app.conf"
  echo -e " removiendo líneas vacías y comentarios."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Copiar archivos >5MB modificados en <24h a /root/audit_found/ -> \e[1;35m25%\e[0m"
  echo -e "  [ ] Filtrar IPs '10.' (BRE) hacia /root/internal_ips.txt         --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Filtrar CRITICAL o FATAL (ERE) hacia /root/critical_errors.txt-> \e[1;35m25%\e[0m"
  echo -e "  [ ] Depurar app.conf sin '#' ni líneas vacías en app.conf.clean --> \e[1;35m25%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Combine 'find -size -mmin/-mtime', 'grep' estándar y 'grep -E' con redirecciones.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO EXTRACCIÓN TEXTUAL Y BÚSQUEDAS FORENSES ==="

  # 1. Validar la búsqueda de find
  if [ -f /root/audit_found/suspicious_data.dat ] && [ ! -f /root/audit_found/old_garbage.dat ]; then
      echo "✔ [25%] Búsqueda condicional de find ejecutada correctamente (Solo copió el archivo pesado reciente)."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El directorio /root/audit_found/ no tiene los archivos correctos filtrados por fecha y tamaño."
  fi

  # 2. Validar extracción BRE de IPs rango 10.
  if [ -f /root/internal_ips.txt ] && grep -q "10.0.0.15" /root/internal_ips.txt && grep -q "10.254.1.1" /root/internal_ips.txt && ! grep -q "192.168" /root/internal_ips.txt; then
      echo "✔ [25%] Reporte BRE de IPs del rango 10.x generado con éxito."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El archivo /root/internal_ips.txt no contiene las IPs correctas o arrastró otros rangos."
  fi

  # 3. Validar extracción ERE de errores combinados
  if [ -f /root/critical_errors.txt ] && grep -q "CRITICAL" /root/critical_errors.txt && grep -q "FATAL" /root/critical_errors.txt && ! grep -q "INFO" /root/critical_errors.txt; then
      echo "✔ [25%] Reporte ERE condicional (CRITICAL|FATAL) validado correctamente."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El archivo /root/critical_errors.txt está vacío o mal filtrado."
  fi

  # 4. Validar limpieza de archivo de configuración
  CLEAN_FILE="/root/app.conf.clean"
  if [ -f "$CLEAN_FILE" ]; then
      if ! grep -q "^#" "$CLEAN_FILE" && ! grep -q "^$" "$CLEAN_FILE" && grep -q "server_name" "$CLEAN_FILE"; then
          echo "✔ [25%] Archivo de configuración limpio generado sin comentarios ni líneas en blanco."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] El archivo limpio aún contiene líneas vacías o comentarios tipo '#'."
      fi
  else
      echo "❌ [0%] No se ha generado el archivo depurado $CLEAN_FILE."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
