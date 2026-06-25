---
Curso: Bash Scripting para Sysadmins
Modulo: Tuberías, Filtrado y Análisis de Logs
Playground: BS-004
Titulo: El Cazador de Logs – Parseo con Grep y Awk
Fecha de Inicio: 2026-06-25
Dificultad: 3/10
Level Escalation: L1
Objetivo: |-
  Aprobar LFCS y RHCSA
  Pensar como Sysadmin Linux Pleno
  Prepararme para DevOps Engineer y Sysadmin Kubernetes
Temas: |-
  Tuberías (`|`) para encadenar comandos
  Filtrado de líneas con `grep` y expresiones regulares básicas
  Extracción de columnas con `awk`
  Ordenamiento y conteo con `sort` y `uniq -c`
  Bloqueo de IPs con `iptables` o `firewalld`
  Logging con marcas de tiempo y niveles de severidad
Competencias: |-
  Analizar archivos de log del sistema (`/var/log/auth.log` o `/var/log/secure`)
  Construir pipelines de comandos (`grep | awk | sort | uniq`)
  Automatizar el bloqueo de direcciones IP maliciosas usando `iptables`
  Manejar la diferencia entre distribuciones Debian (`auth.log`) y RHEL (`secure`)
  Generar logs de auditoría con marcas de tiempo
  Aplicar umbrales de tolerancia (más de N intentos)
  Garantizar idempotencia: no duplicar reglas de firewall
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  LAB_ID="BS-004-v1"
  LAB_NAME="El Cazador de Logs – Parseo con Grep y Awk"
  USER_CURRENT=$(whoami)
  WORK_DIR="$HOME/lab-bash-004"
  LOG_FILE="$WORK_DIR/bloqueos.log"
  SAMPLE_LOG="$WORK_DIR/sample_auth.log"
  SCRIPT_TARGET="$WORK_DIR/cazador_de_logs.sh"

  echo -e "\e[1;33m⏳ Preparando entorno de laboratorio...\e[0m"
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"

  # ==============================================================================
  # Generar log de autenticación para práctica con AWK
  # ==============================================================================
  cat > "$SAMPLE_LOG" << 'LOGEOF'
  Jun 25 03:12:01 jump-host sshd[12340]: Failed password for invalid user admin from 203.0.113.45 port 54321 ssh2
  Jun 25 03:12:03 jump-host sshd[12341]: Failed password for invalid user root from 203.0.113.45 port 54322 ssh2
  Jun 25 03:12:05 jump-host sshd[12342]: Failed password for invalid user test from 203.0.113.45 port 54323 ssh2
  Jun 25 03:12:07 jump-host sshd[12343]: Failed password for invalid user admin from 203.0.113.45 port 54324 ssh2
  Jun 25 03:12:09 jump-host sshd[12344]: Failed password for invalid user ubuntu from 203.0.113.45 port 54325 ssh2
  Jun 25 03:12:11 jump-host sshd[12345]: Failed password for invalid user user from 203.0.113.45 port 54326 ssh2
  Jun 25 03:12:13 jump-host sshd[12346]: Failed password for invalid user admin from 203.0.113.45 port 54327 ssh2
  Jun 25 03:12:15 jump-host sshd[12347]: Failed password for invalid user root from 203.0.113.45 port 54328 ssh2
  Jun 25 03:12:17 jump-host sshd[12348]: Failed password for invalid user test from 203.0.113.45 port 54329 ssh2
  Jun 25 03:12:19 jump-host sshd[12349]: Failed password for invalid user admin from 203.0.113.45 port 54330 ssh2
  Jun 25 03:12:21 jump-host sshd[12350]: Failed password for invalid user ubuntu from 203.0.113.45 port 54331 ssh2
  Jun 25 03:12:23 jump-host sshd[12351]: Failed password for invalid user user from 203.0.113.45 port 54332 ssh2
  Jun 25 03:12:25 jump-host sshd[12352]: Failed password for invalid user admin from 203.0.113.45 port 54333 ssh2
  Jun 25 03:12:27 jump-host sshd[12353]: Failed password for invalid user root from 203.0.113.45 port 54334 ssh2
  Jun 25 03:15:01 jump-host sshd[12360]: Failed password for invalid user admin from 198.51.100.23 port 54340 ssh2
  Jun 25 03:15:03 jump-host sshd[12361]: Failed password for invalid user root from 198.51.100.23 port 54341 ssh2
  Jun 25 03:15:05 jump-host sshd[12362]: Failed password for invalid user test from 198.51.100.23 port 54342 ssh2
  Jun 25 03:15:07 jump-host sshd[12363]: Failed password for invalid user admin from 198.51.100.23 port 54343 ssh2
  Jun 25 03:15:09 jump-host sshd[12364]: Failed password for invalid user ubuntu from 198.51.100.23 port 54344 ssh2
  Jun 25 03:15:11 jump-host sshd[12365]: Failed password for invalid user user from 198.51.100.23 port 54345 ssh2
  Jun 25 03:15:13 jump-host sshd[12366]: Failed password for invalid user admin from 198.51.100.23 port 54346 ssh2
  Jun 25 03:15:15 jump-host sshd[12367]: Failed password for invalid user root from 198.51.100.23 port 54347 ssh2
  Jun 25 03:15:17 jump-host sshd[12368]: Failed password for invalid user test from 198.51.100.23 port 54348 ssh2
  Jun 25 03:15:19 jump-host sshd[12369]: Failed password for invalid user admin from 198.51.100.23 port 54349 ssh2
  Jun 25 03:15:21 jump-host sshd[12370]: Failed password for invalid user ubuntu from 198.51.100.23 port 54350 ssh2
  Jun 25 03:18:01 jump-host sshd[12380]: Failed password for invalid user admin from 192.0.2.99 port 54360 ssh2
  Jun 25 03:18:03 jump-host sshd[12381]: Failed password for invalid user root from 192.0.2.99 port 54361 ssh2
  Jun 25 03:18:05 jump-host sshd[12382]: Failed password for invalid user test from 192.0.2.99 port 54362 ssh2
  Jun 25 03:18:07 jump-host sshd[12383]: Failed password for invalid user admin from 192.0.2.99 port 54363 ssh2
  Jun 25 03:18:09 jump-host sshd[12384]: Failed password for invalid user ubuntu from 192.0.2.99 port 54364 ssh2
  Jun 25 03:18:11 jump-host sshd[12385]: Failed password for invalid user user from 192.0.2.99 port 54365 ssh2
  Jun 25 03:18:13 jump-host sshd[12386]: Failed password for invalid user admin from 192.0.2.99 port 54366 ssh2
  Jun 25 03:18:15 jump-host sshd[12387]: Failed password for invalid user root from 192.0.2.99 port 54367 ssh2
  Jun 25 03:18:17 jump-host sshd[12388]: Failed password for invalid user test from 192.0.2.99 port 54368 ssh2
  Jun 25 03:21:01 jump-host sshd[12390]: Failed password for invalid user admin from 45.33.32.156 port 54370 ssh2
  Jun 25 03:21:03 jump-host sshd[12391]: Failed password for invalid user root from 45.33.32.156 port 54371 ssh2
  Jun 25 03:21:05 jump-host sshd[12392]: Failed password for invalid user test from 45.33.32.156 port 54372 ssh2
  Jun 25 03:21:07 jump-host sshd[12393]: Failed password for invalid user admin from 45.33.32.156 port 54373 ssh2
  Jun 25 03:21:09 jump-host sshd[12394]: Failed password for invalid user ubuntu from 45.33.32.156 port 54374 ssh2
  Jun 25 03:21:11 jump-host sshd[12395]: Failed password for invalid user user from 45.33.32.156 port 54375 ssh2
  Jun 25 03:21:13 jump-host sshd[12396]: Failed password for invalid user admin from 45.33.32.156 port 54376 ssh2
  Jun 25 03:21:15 jump-host sshd[12397]: Failed password for invalid user root from 45.33.32.156 port 54377 ssh2
  Jun 25 03:24:01 jump-host sshd[12400]: Failed password for invalid user admin from 185.220.101.34 port 54380 ssh2
  Jun 25 03:24:03 jump-host sshd[12401]: Failed password for invalid user root from 185.220.101.34 port 54381 ssh2
  Jun 25 03:24:05 jump-host sshd[12402]: Failed password for invalid user test from 185.220.101.34 port 54382 ssh2
  Jun 25 03:24:07 jump-host sshd[12403]: Failed password for invalid user admin from 185.220.101.34 port 54383 ssh2
  Jun 25 03:24:09 jump-host sshd[12404]: Failed password for invalid user ubuntu from 185.220.101.34 port 54384 ssh2
  Jun 25 03:24:11 jump-host sshd[12405]: Failed password for invalid user user from 185.220.101.34 port 54385 ssh2
  Jun 25 03:24:13 jump-host sshd[12406]: Failed password for invalid user admin from 185.220.101.34 port 54386 ssh2
  Jun 25 03:30:01 jump-host sshd[12410]: Failed password for bob from 10.0.0.5 port 54390 ssh2
  Jun 25 03:30:03 jump-host sshd[12411]: Failed password for bob from 10.0.0.5 port 54391 ssh2
  Jun 25 03:30:05 jump-host sshd[12412]: Failed password for bob from 10.0.0.5 port 54392 ssh2
  Jun 25 03:40:01 jump-host sshd[12440]: Accepted password for bob from 10.0.0.100 port 54500 ssh2
  Jun 25 03:41:01 jump-host sshd[12450]: Accepted password for alice from 10.0.0.101 port 54510 ssh2
  Jun 25 03:42:01 jump-host sshd[12460]: Accepted password for charlie from 10.0.0.102 port 54520 ssh2
  LOGEOF

  clear

  # ==============================================================================
  # Mostrar ticket de incidente
  # ==============================================================================
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;36m  TICKET INC-4521  │  Severidad: SEV-3  │  Ambiente: PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  ⏱️  $LAB_ID — $LAB_NAME\e[0m"
  echo -e "  Módulo: Tuberías y Filtrado  │  Dificultad: 3/10  │  Nivel: L1"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Jump-Host — \e[1;32m$USER_CURRENT\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  \e[1;37m📋 SÍNTOMA REPORTADO:\e[0m"
  echo -e "  Múltiples intentos de fuerza bruta SSH detectados en el servidor bastión."
  echo -e "  Se detectaron intentos fallidos desde múltiples IPs en las últimas 24h."
  echo ""
  echo -e "  \e[1;37m🔥 IMPACTO AL NEGOCIO:\e[0m"
  echo -e "  Riesgo de compromiso del jump-host y acceso a infraestructura interna."
  echo ""
  echo -e "  \e[1;37m🎯 TAREA ESPERADA:\e[0m"
  echo -e "  Analizar el log de autenticación usando \e[1mgrep y awk\e[0m, identificar IPs"
  echo -e "  con más de 5 intentos fallidos y bloquearlas con \e[1miptables\e[0m."
  echo -e "  Documentar cada bloqueo en el log de auditoría."
  echo ""
  echo -e "  \e[1;37m📝 NOTA DEL L3:\e[0m"
  echo -e "  \e[3m\"El script tiene TODOs marcados. Concéntrate en usar AWK para extraer"
  echo -e "  las IPs de forma eficiente. Asegúrate de no duplicar reglas.\"\e[0m"

  # ==============================================================================
  # Crear script con TODOs para completar
  # ==============================================================================
  cat > "$SCRIPT_TARGET" << 'EOF_INNER'
  #!/bin/bash
  # ==============================================================================
  # TICKET: INC-4521
  # Severidad: SEV-3
  # Script: cazador_de_logs.sh
  # ==============================================================================

  LOG_FILE="$HOME/lab-bash-004/bloqueos.log"
  SAMPLE_LOG="$HOME/lab-bash-004/sample_auth.log"
  THRESHOLD=5

  # Función para logging
  log_msg() {
      local level=$1
      local msg=$2
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" | tee -a "$LOG_FILE"
  }

  log_msg "INFO" "Iniciando análisis de intentos fallidos SSH..."

  # ============================================================
  # PASO 1: IDENTIFICAR LOG SOURCE
  # ============================================================
  # Usa if/elif para detectar auth.log o secure

  if [ -f /var/log/auth.log ]; then
      # >>> COMPLETA: Asigna /var/log/auth.log a LOG_SOURCE
      LOG_SOURCE="/var/log/auth.log"
  elif [ -f /var/log/secure ]; then
      # >>> COMPLETA: Asigna /var/log/secure a LOG_SOURCE
      LOG_SOURCE="/var/log/secure"
  elif [ -f "$SAMPLE_LOG" ]; then
      LOG_SOURCE="$SAMPLE_LOG"
      log_msg "WARN" "Usando sample de prueba (sin log real)"
  else
      # >>> COMPLETA: Registra ERROR y sale con exit 1
      log_msg "ERROR" "No se encontró ninguna fuente de logs"
      exit 1
  fi

  log_msg "INFO" "Usando log: $LOG_SOURCE"

  # ============================================================
  # PASO 2: EXTRAER Y CONTAR IPs CON AWK
  # ============================================================
  # 📖 AYUDA PARA AWK:
  #   awk '{print $N}'  →  imprime la columna N
  #   Las IPs están en diferentes posiciones según el formato:
  #   auth.log (Debian): "... from 203.0.113.45 port ..." → IP en $10
  #   secure (RHEL): "... rhost=203.0.113.45 ..." → IP después de "rhost="
  #
  #   Pipeline completo:
  #   grep "Failed password" | awk '{print $10}' | sort | uniq -c | sort -nr
  #
  #   Nota: En Debian, la IP está en el campo 10
  #   En RHEL, necesitas extraer con awk -F"rhost=" '{print $2}' | awk '{print $1}'

  # >>> COMPLETA: Construye el pipeline para extraer y contar IPs
  # Pista: Usa grep + awk + sort + uniq -c + sort -nr
  IPS_ATACANTES=$(grep "Failed password" "$LOG_SOURCE" | awk '{print $10}' | sort | uniq -c | sort -nr)

  if [ -z "$IPS_ATACANTES" ]; then
      log_msg "INFO" "No se detectaron intentos fallidos"
      exit 0
  fi

  # ============================================================
  # PASO 3: PROCESAR CADA IP Y BLOQUEAR
  # ============================================================
  # Recorre cada línea: "N IP" (ej: "12 203.0.113.45")
  echo "$IPS_ATACANTES" | while read -r count ip; do
      # >>> COMPLETA: Verifica si count >= THRESHOLD
      if [ "$count" -ge "$THRESHOLD" ]; then
          log_msg "INFO" "IP $ip tiene $count intentos (umbral: $THRESHOLD)"
          
          # --------------------------------------------
          # IDEMPOTENCIA: Verificar si ya está bloqueada
          # --------------------------------------------
          # >>> COMPLETA: Usa iptables -C para verificar
          if iptables -C INPUT -s "$ip" -j DROP 2>/dev/null; then
              log_msg "INFO" "IP $ip ya estaba bloqueada"
          else
              # ------------------------------------------
              # BLOQUEAR IP CON IPTABLES
              # ------------------------------------------
              # >>> COMPLETA: Bloquea la IP y verifica el resultado
              if iptables -A INPUT -s "$ip" -j DROP; then
                  log_msg "INFO" "✅ IP $ip bloqueada exitosamente"
              else
                  log_msg "ERROR" "❌ Falló el bloqueo de IP $ip"
              fi
          fi
      else
          log_msg "DEBUG" "IP $ip tiene solo $count intentos (ignorando)"
      fi
  done

  log_msg "INFO" "✅ Análisis completado. Revisa $LOG_FILE"
  exit 0
  EOF_INNER

  chmod +x "$SCRIPT_TARGET"

  echo -e "\e[1;32m✔ Entorno configurado exitosamente.\e[0m"
  echo -e "📂 Ingresa al directorio de trabajo: \e[1;33mcd $WORK_DIR\e[0m"
  echo -e "📝 Edita el script: \e[1;33mnano $SCRIPT_TARGET\e[0m"
  echo ""
  echo -e "\e[1;36m🎯 EJERCICIO CON AWK:\e[0m"
  echo -e "  En el PASO 2, usa \e[1mAWK\e[0m para extraer la IP correctamente:"
  echo -e "  • Debian/Ubuntu: \e[33mawk '{print \$10}'\e[0m"
  echo -e "  • RHEL/CentOS: \e[33mawk -F'rhost=' '{print \$2}' | awk '{print \$1}'\e[0m"
  echo ""
  echo -e "\e[1;33m💡 Pista: El log sample tiene formato Debian (IP en campo 10)\e[0m"
  echo -e "\e[1;36m¡Buena suerte, Sysadmin en formación!\e[0m"
  EOF

  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - LFCS
  - RHCSA
  - Awk
  - Grep
---

[[Laboratorios del LFCS]]

---
