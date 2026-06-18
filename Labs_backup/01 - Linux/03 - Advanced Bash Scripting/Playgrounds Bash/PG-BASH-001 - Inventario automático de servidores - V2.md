---
Curso: Practica Avanzada de Bash Scripting
Modulo: Automatización e Inventario
Playground: LAB-01-V2
Titulo: Inventario automático de servidores - V2 (Edición Junior L1)
Fecha de Inicio: 2026-06-06
Dificultad: 4/10
Objetivo:
  - Optimizar scripts de red previniendo bloqueos por caídas de servicios
  - Manejar parámetros básicos de tiempo de espera (timeouts) en comandos nativos
Temas:
  - Parámetros de límites de tiempo en Ping y SSH (ConnectTimeout)
  - Validación básica de archivos vacíos en Bash (-s)
  - Formateo de reportes con encabezados dinámicos
Ticket: |-
  INC-1011 - Optimización del Script de Inventario por Bloqueos en la Red

  El script de inventario básico (V1) funciona, pero el equipo de Operaciones reporta dos problemas:
  1. Cuando una IP de la lista no existe, el script tarda demasiado tiempo esperando que el comando `ping` termine.
  2. Si una máquina responde el ping, pero su servicio SSH está caído o bloqueado por un firewall, el script se queda colgado indefinidamente, retrasando el reporte matutino.

  Requerimientos del Ticket (Junior L1 - V2):
  1. Validar antes de iniciar que el archivo `/tmp/servidores.txt` no esté vacío. Si está vacío, el script debe avisar y salir.
  2. Al generar el reporte en `/tmp/reporte_inventario.txt`, la primera línea debe ser un encabezado que diga: "=== REPORTE DE INVENTARIO CORPORATIVO ===".
  3. Optimizar el `ping`: Configurar el comando para que solo envíe 1 paquete (`-c 1`) y que tenga un tiempo de espera máximo de 2 segundos (`-W 2`).
  4. Optimizar el `ssh`: Añadir la opción de configuración `-o ConnectTimeout=2` para que si el SSH no conecta en 2 segundos, aborte y marque el servicio como inaccesible.
Validacion:
  - Objetivo: Validación de archivo no vacío implementada correctamente al inicio del script.
    Peso: 20 %
  - Objetivo: Encabezado institucional insertado correctamente en el archivo de salida.
    Peso: 20 %
  - Objetivo: Comando ping optimizado con flags de tolerancia de tiempo (-W).
    Peso: 30 %
  - Objetivo: Conexión SSH protegida contra congelamientos usando ConnectTimeout.
    Peso: 30 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_bash_01_v2
  #!/bin/bash
  set -e

  # Limpieza de entornos de pruebas
  rm -f /tmp/servidores.txt
  rm -f /tmp/reporte_inventario.txt
  rm -f /tmp/inventario_v2.sh

  # Simulación de archivo de inventario con tres escenarios de red:
  # 1. Host Online con SSH funcional (127.0.0.1)
  # 2. Host Completamente Offline (10.255.255.1 -> Fallará el ping rápido)
  # 3. Host Online pero SSH Caído/Bloqueado (Usaremos una IP que responda ping pero no SSH, o simularemos el timeout)
  echo "127.0.0.1" > /tmp/servidores.txt
  echo "10.255.255.1" >> /tmp/servidores.txt
  echo "10.255.255.2" >> /tmp/servidores.txt

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ENTORNO BASH LAB-01-V2 CONFIGURADO (NIVEL JUNIOR L1 - OPTIMIZADO)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Tu entorno ha sido preparado para la V2:"
  echo -e "  - Archivo de entrada: \e[1m/tmp/servidores.txt\e[0m"
  echo -e "  - Tu script intermedio a completar en: \e[1m/tmp/inventario_v2.sh\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " ¡Asegúrate de aplicar los Timeouts para que el validador no se quede colgado!"
  echo -e "\e[1;36m================================================================================\e[0m"
  EOF
  bash /tmp/setup_bash_01_v2 && rm -f /tmp/setup_bash_01_v2
tags:
  - Laboratorios-del-LFCS
Script a Completar: |-
  # Copia este bloque dentro de /tmp/inventario_v2.sh y completa los TODO

  #!/bin/bash

  INPUT_FILE="/tmp/servidores.txt"
  OUTPUT_FILE="/tmp/reporte_inventario.txt"

  # ==================================================================
  # TODO 1: Añadir una validación de seguridad Junior.
  # Si el archivo $INPUT_FILE NO existe O está VACÍO (puedes usar el operador [ ! -s "$INPUT_FILE" ]),
  # muestra un mensaje en pantalla que diga "Archivo vacío o inexistente" y sal con "exit 1".
  # ==================================================================
  # >>> INYECTA TU VALIDACIÓN DE ARCHIVO AQUÍ <<<

  # ==================================================================
  # TODO 2: Inicializa el archivo de reporte ($OUTPUT_FILE) agregando
  # la siguiente línea exacta como encabezado inicial (sobrescribiendo el archivo):
  # "=== REPORTE DE INVENTARIO CORPORATIVO ==="
  # ==================================================================
  # >>> INYECTA TU ENCABEZADO AQUÍ <<<

  # Bucle de lectura
  while read -r IP || [ -n "$IP" ]; do
      [ -z "$IP" ] && continue
      
      echo "Validando conectividad hacia: $IP..."
      
      # ==================================================================
      # TODO 3: Modifica el comando ping de la V1. Envía 1 paquete (-c 1),
      # pero añade el flag "-W 2" (esperar máximo 2 segundos por respuesta).
      # No olvides redirigir la salida a /dev/null para mantener limpia la pantalla.
      # ==================================================================
      # >>> INYECTA TU COMANDO PING OPTIMIZADO AQUÍ <<<
      ping_status=$?
      
      if [ $ping_status -eq 0 ]; then
          echo "Nodo $IP respondiendo. Extrayendo telemetría por SSH..."
          
          # ==================================================================
          # TODO 4: Modifica la conexión SSH de la V1. 
          # Añade el argumento: -o ConnectTimeout=2 para evitar bloqueos.
          # Recuerda la sintaxis: ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 "$IP" "comando"
          # Extrae el uptime (uptime -p) y el OS (grep '^NAME=' /etc/os-release | cut -d'"' -f2).
          # Si el SSH tiene éxito, escribe en $OUTPUT_FILE:
          # "IP: $IP | STATUS: ONLINE | OS: $OS | UPtime: $UPTIME"
          # Si el SSH falla (por timeout), escribe en $OUTPUT_FILE:
          # "IP: $IP | STATUS: ONLINE | SSH_ERROR"
          # ==================================================================
          # >>> INYECTA TU LÓGICA SSH CON TIMEOUT Y SU CONDICIONAL AQUÍ <<<
          
      else
          # Si el ping falló
          echo "IP: $IP | STATUS: OFFLINE" >> "$OUTPUT_FILE"
      fi

  done < "$INPUT_FILE"

  echo "Proceso V2 finalizado."
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0
  REP="/tmp/reporte_inventario.txt"
  SCRIPT="/tmp/inventario_v2.sh"

  echo "=== VALIDANDO LAB-01-V2 (JUNIOR L1 OPTIMIZADO) ==="

  # 1. Validar existencia del encabezado
  if [ -f "$REP" ] && grep -q "=== REPORTE DE INVENTARIO CORPORATIVO ===" "$REP"; then
      echo "✔ [20%] Encabezado institucional detectado en la primera línea del reporte."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El archivo de reporte no tiene el encabezado requerido."
  fi

  # 2. Validar que el script contiene el control de archivo vacío (-s)
  if [ -f "$SCRIPT" ] && grep -E -- "-s\s+\\\"\?\\\?INPUT_FILE" "$SCRIPT" >/dev/null 2>&1 || grep -q "!-s" "$SCRIPT" || grep -q "! -s" "$SCRIPT"; then
      echo "✔ [20%] Control preventivo de carga de archivos vacios/inexistentes (-s) verificado."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] No se detectó la validación perimetral de tamaño de archivo (-s) al inicio del script."
  fi

  # 3. Validar la optimización del comando ping
  if [ -f "$SCRIPT" ] && grep -q -- "-W" "$SCRIPT"; then
      echo "✔ [30%] Parámetro de tiempo de espera límite de red (-W) implementado en el ping."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El comando ping no cuenta con restricciones de tiempo de espera (-W)."
  fi

  # 4. Validar protección ConnectTimeout en SSH
  if [ -f "$SCRIPT" ] && grep -q "ConnectTimeout=" "$SCRIPT"; then
      echo "✔ [30%] Protección de socket SSH activa mediante directiva ConnectTimeout."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] Las conexiones SSH siguen expuestas a bloqueos indefinidos por falta de ConnectTimeout."
  fi

  echo "====================================================="
  echo "🎯 SCORE FINAL LAB-01-V2 JUNIOR: $PUNTOS / 100"
  echo "====================================================="
---
[[Laboratorios del LFCS]]

---
