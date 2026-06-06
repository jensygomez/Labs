---
Curso: Practica Avanzada de Bash Scripting
Modulo: Automatización e Inventario
Playground: LAB-01-V1
Titulo: Inventario automático de servidores - V1
Fecha de Inicio: 2026-06-06
Dificultad: 3/10
Objetivo:
  - Validar conectividad básica de red mediante Bash
  - Automatizar la recolección de telemetría simple vía SSH
Temas:
  - Lectura de archivos línea por línea (Loops while)
  - Control de flujos condicionales e interactividad con comandos ($?)
  - Redirección básica de reportes planos
Ticket: |-
  INC-1001 - Relevamiento Inicial de Servidores para Auditoría de Sistemas

  El equipo de infraestructura necesita mapear qué servidores de la subred de pruebas están encendidos (Online) o apagados (Offline). Para los servidores que contesten el ping, se requiere extraer de forma remota su tiempo de actividad (Uptime) y el nombre de su sistema operativo.

  Requerimientos del Ticket (Junior L1):
  1. El script debe leer una lista de IPs ubicada estrictamente en `/tmp/servidores.txt`.
  2. Por cada IP, se debe enviar un único paquete de ping (`ping -c 1`).
  3. Si el servidor responde, se debe marcar como "ONLINE" y conectarse por SSH para extraer el uptime (comando `uptime -p`) y el sistema operativo (leyendo `/etc/os-release`).
  4. Si el servidor no responde el ping, se debe reportar como "OFFLINE" y saltar al siguiente.
  5. Toda la salida consolidada debe guardarse en un reporte plano en `/tmp/reporte_inventario.txt`.
Validacion:
  - Objetivo: El script lee correctamente el archivo de texto provisto.
    Peso: 30 %
  - Objetivo: Identificación correcta de nodos ONLINE y extracción de métricas vía SSH.
    Peso: 40 %
  - Objetivo: Generación del reporte final en la ruta `/tmp/reporte_inventario.txt`.
    Peso: 30 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_bash_01
  #!/bin/bash
  set -e


  # Simulación de archivo de inventario de red corporativo
  # Usaremos 127.0.0.1 (Online) y una IP inválida de laboratorio (Offline)
  echo "127.0.0.1" > /tmp/servidores.txt
  echo "10.255.255.1" >> /tmp/servidores.txt

  # REQUISITO DE ENTORNO: Garantizar que puedas hacer SSH a tu propia máquina para el laboratorio.
  # Si no tienes las llaves generadas, este bloque te ayuda.
  if [ ! -f ~/.ssh/id_rsa ]; then
      echo "Generando llaves SSH de prueba locales..."
      ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
      cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
      chmod 600 ~/.ssh/authorized_keys
  fi

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ENTORNO BASH LAB-01-V1 CONFIGURADO (NIVEL JUNIOR L1)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Tu entorno ha sido preparado."
  echo -e " 1. Lista de IPs generada en: \e[1m/tmp/servidores.txt\e[0m"
  echo -e " 2. Debes editar o completar tu script en: \e[1m/tmp/inventario.sh\e[0m"
  echo -e " 3. Cuando termines, ejecuta el Script de Validación para medir tu puntaje."
  echo -e "\e[1;36m================================================================================\e[0m"
  EOF
  bash /tmp/setup_bash_01 && rm -f /tmp/setup_bash_01
tags:
  - Laboratorios-del-LFCS
Script a Completar: |-
  # Copia este bloque dentro de /tmp/inventario.sh y completa los TODO

  #!/bin/bash

  INPUT_FILE="/tmp/servidores.txt"
  OUTPUT_FILE="/tmp/reporte_inventario.txt"

  # Limpiar reporte anterior si existe
  > "$OUTPUT_FILE"

  # Validar que el archivo de entrada exista
  if [ ! -f "$INPUT_FILE" ]; then
      echo "Error: El archivo de entrada no existe."
      exit 1
  fi

  # Bucle para leer el archivo línea por línea
  while read -r IP || [ -n "$IP" ]; do
      # Saltarse líneas vacías
      [ -z "$IP" ] && continue
      
      echo "Procesando nodo: $IP..."
      
      # ==================================================================
      # TODO 1: Envía UN SOLO PING (-c 1) a la IP actual. 
      # Recuerda silenciar la salida redirigiéndola a /dev/null para que
      # no ensucie la pantalla del administrador.
      # ==================================================================
      # >>> INYECTA TU COMANDO PING AQUÍ <<<
      
      # ==================================================================
      # TODO 2: Evalúa el resultado del ping usando la variable de estado ($?).
      # - Si el ping fue exitoso (0):
      #     * Conéctate por SSH a la IP (usa: ssh -o StrictHostKeyChecking=no "$IP" "comando")
      #     * Extrae el uptime descriptivo.
      #     * Extrae el nombre del OS (puedes usar: grep '^NAME=' /etc/os-release | cut -d'"' -f2)
      #     * Escribe en el archivo $OUTPUT_FILE el formato: "IP: $IP | STATUS: ONLINE | OS: $OS | UPtime: $UPTIME"
      # - Si el ping falló (no es 0):
      #     * Escribe en el archivo $OUTPUT_FILE el formato: "IP: $IP | STATUS: OFFLINE"
      # ==================================================================
      # >>> INYECTA TU LÓGICA CONDICIONAL IF/ELSE AQUÍ <<<

  done < "$INPUT_FILE"

  echo "Reporte generado con éxito en $OUTPUT_FILE."
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0
  REP="/tmp/reporte_inventario.txt"

  echo "=== VALIDANDO LAB-01-V1 (JUNIOR L1) ==="

  if [ -f "$REP" ]; then
      echo "✔ [30%] Archivo de reporte final detectado en la ruta correcta."
      PUNTOS=$((PUNTOS + 30))
      
      # Validar nodo OFFLINE
      if grep -q "10.255.255.1 | STATUS: OFFLINE" "$REP"; then
          echo "✔ [35%] Captura y aislamiento de nodos caídos (OFFLINE) validada."
          PUNTOS=$((PUNTOS + 35))
      else
          echo "❌ [0%] El nodo offline 10.255.255.1 no está registrado correctamente o el formato de texto difiere."
      fi
      
      # Validar nodo ONLINE
      if grep -q "127.0.0.1 | STATUS: ONLINE" "$REP" && grep -q "OS:" "$REP" && grep -q "UPtime:" "$REP"; then
          echo "✔ [35%] Extracción de telemetría remota (SSH + Uptime + OS) de nodos activos validada con éxito."
          PUNTOS=$((PUNTOS + 35))
      else
          echo "❌ [0%] El nodo activo 127.0.0.1 no contiene el estado ONLINE o carece de las métricas SSH requeridas."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo de reporte en /tmp/reporte_inventario.txt. Asegúrate de ejecutar tu script."
  fi

  echo "====================================================="
  echo "🎯 SCORE FINAL DE AUTOMATIZACIÓN JUNIOR: $PUNTOS / 100"
  echo "====================================================="
---
[[Laboratorios del LFCS]]
---
