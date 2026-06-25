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
  LAB_NAME="El Cazador de Logs"
  USER_CURRENT=$(whoami)
  WORK_DIR="$HOME/lab-bash-004"
  LOG_FILE="$WORK_DIR/bloqueos.log"
  SAMPLE_LOG="$WORK_DIR/sample_auth.log"
  SCRIPT_TARGET="$WORK_DIR/cazador_de_logs.sh"

  echo -e "\e[1;33m⏳ Preparando entorno de laboratorio...\e[0m"
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"

  # ==============================================================================
  # Generar log de autenticación falso con ~120 líneas realistas
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
  Jun 25 03:32:01 jump-host sshd[12420]: Failed password for alice from 172.16.0.12 port 54400 ssh2
  Jun 25 03:32:03 jump-host sshd[12421]: Failed password for alice from 172.16.0.12 port 54401 ssh2
  Jun 25 03:34:01 jump-host sshd[12430]: Failed password for charlie from 192.168.1.50 port 54410 ssh2
  Jun 25 03:40:01 jump-host sshd[12440]: Accepted password for bob from 10.0.0.100 port 54500 ssh2
  Jun 25 03:40:05 jump-host sshd[12441]: pam_unix(sshd:session): session opened for user bob
  Jun 25 03:41:01 jump-host sshd[12450]: Accepted password for alice from 10.0.0.101 port 54510 ssh2
  Jun 25 03:41:05 jump-host sshd[12451]: pam_unix(sshd:session): session opened for user alice
  Jun 25 03:42:01 jump-host sshd[12460]: Accepted password for charlie from 10.0.0.102 port 54520 ssh2
  Jun 25 03:42:05 jump-host sshd[12461]: pam_unix(sshd:session): session opened for user charlie
  Jun 25 03:43:01 jump-host sshd[12470]: Accepted password for dave from 10.0.0.103 port 54530 ssh2
  Jun 25 03:43:05 jump-host sshd[12471]: pam_unix(sshd:session): session opened for user dave
  Jun 25 03:44:01 jump-host sshd[12480]: Accepted password for eve from 10.0.0.104 port 54540 ssh2
  Jun 25 03:44:05 jump-host sshd[12481]: pam_unix(sshd:session): session opened for user eve
  Jun 25 03:45:01 jump-host sshd[12490]: Accepted password for frank from 10.0.0.105 port 54550 ssh2
  Jun 25 03:45:05 jump-host sshd[12491]: pam_unix(sshd:session): session opened for user frank
  Jun 25 03:46:01 jump-host sshd[12500]: Accepted password for grace from 10.0.0.106 port 54560 ssh2
  Jun 25 03:46:05 jump-host sshd[12501]: pam_unix(sshd:session): session opened for user grace
  Jun 25 03:47:01 jump-host sshd[12510]: Accepted password for henry from 10.0.0.107 port 54570 ssh2
  Jun 25 03:47:05 jump-host sshd[12511]: pam_unix(sshd:session): session opened for user henry
  Jun 25 03:48:01 jump-host sshd[12520]: Accepted password for irene from 10.0.0.108 port 54580 ssh2
  Jun 25 03:48:05 jump-host sshd[12521]: pam_unix(sshd:session): session opened for user irene
  Jun 25 03:49:01 jump-host sshd[12530]: Accepted password for jack from 10.0.0.109 port 54590 ssh2
  Jun 25 03:49:05 jump-host sshd[12531]: pam_unix(sshd:session): session opened for user jack
  Jun 25 03:50:01 jump-host sudo: bob : TTY=pts/0 ; PWD=/home/bob ; USER=root ; COMMAND=/bin/systemctl restart nginx
  Jun 25 03:50:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:51:01 jump-host sudo: alice : TTY=pts/1 ; PWD=/home/alice ; USER=root ; COMMAND=/bin/journalctl -u ssh
  Jun 25 03:51:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:52:01 jump-host sudo: charlie : TTY=pts/2 ; PWD=/home/charlie ; USER=root ; COMMAND=/bin/cat /var/log/syslog
  Jun 25 03:52:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:53:01 jump-host sudo: dave : TTY=pts/3 ; PWD=/home/dave ; USER=root ; COMMAND=/bin/iptables -L
  Jun 25 03:53:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:54:01 jump-host sudo: eve : TTY=pts/4 ; PWD=/home/eve ; USER=root ; COMMAND=/bin/ps aux
  Jun 25 03:54:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:55:01 jump-host sudo: frank : TTY=pts/5 ; PWD=/home/frank ; USER=root ; COMMAND=/bin/top -b -n 1
  Jun 25 03:55:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:56:01 jump-host sudo: grace : TTY=pts/6 ; PWD=/home/grace ; USER=root ; COMMAND=/bin/df -h
  Jun 25 03:56:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:57:01 jump-host sudo: henry : TTY=pts/7 ; PWD=/home/henry ; USER=root ; COMMAND=/bin/free -m
  Jun 25 03:57:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:58:01 jump-host sudo: irene : TTY=pts/8 ; PWD=/home/irene ; USER=root ; COMMAND=/bin/netstat -tuln
  Jun 25 03:58:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 03:59:01 jump-host sudo: jack : TTY=pts/9 ; PWD=/home/jack ; USER=root ; COMMAND=/bin/ss -tuln
  Jun 25 03:59:05 jump-host sudo: pam_unix(sudo:session): session opened for user root
  Jun 25 04:00:01 jump-host CRON[12600]: pam_unix(cron:session): session opened for user root
  Jun 25 04:00:05 jump-host CRON[12600]: pam_unix(cron:session): session closed for user root
  Jun 25 04:01:01 jump-host CRON[12610]: pam_unix(cron:session): session opened for user root
  Jun 25 04:01:05 jump-host CRON[12610]: pam_unix(cron:session): session closed for user root
  Jun 25 04:02:01 jump-host CRON[12620]: pam_unix(cron:session): session opened for user root
  Jun 25 04:02:05 jump-host CRON[12620]: pam_unix(cron:session): session closed for user root
  Jun 25 04:03:01 jump-host CRON[12630]: pam_unix(cron:session): session opened for user root
  Jun 25 04:03:05 jump-host CRON[12630]: pam_unix(cron:session): session closed for user root
  Jun 25 04:04:01 jump-host CRON[12640]: pam_unix(cron:session): session opened for user root
  Jun 25 04:04:05 jump-host CRON[12640]: pam_unix(cron:session): session closed for user root
  Jun 25 04:05:01 jump-host CRON[12650]: pam_unix(cron:session): session opened for user root
  Jun 25 04:05:05 jump-host CRON[12650]: pam_unix(cron:session): session closed for user root
  Jun 25 04:06:01 jump-host CRON[12660]: pam_unix(cron:session): session opened for user root
  Jun 25 04:06:05 jump-host CRON[12660]: pam_unix(cron:session): session closed for user root
  Jun 25 04:07:01 jump-host CRON[12670]: pam_unix(cron:session): session opened for user root
  Jun 25 04:07:05 jump-host CRON[12670]: pam_unix(cron:session): session closed for user root
  Jun 25 04:08:01 jump-host CRON[12680]: pam_unix(cron:session): session opened for user root
  Jun 25 04:08:05 jump-host CRON[12680]: pam_unix(cron:session): session closed for user root
  Jun 25 04:09:01 jump-host CRON[12690]: pam_unix(cron:session): session opened for user root
  Jun 25 04:09:05 jump-host CRON[12690]: pam_unix(cron:session): session closed for user root
  LOGEOF

  clear

  # ==============================================================================
  # Mostrar ticket de incidente en pantalla
  # ==============================================================================
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;36m  TICKET INC-4521  │  Severidad: SEV-3  │  Ambiente: PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  ⏱️  $LAB_ID — $LAB_NAME\e[0m"
  echo -e "  Módulo: Tuberías y Filtrado  │  Dificultad: \e[1;32m3/10\e[0m (Junior friendly)  │  Nivel: L1"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Jump-Host — \e[1;32m$USER_CURRENT\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  \e[1;37m📋 SÍNTOMA REPORTADO:\e[0m"
  echo -e "  Múltiples alertas de intentos de fuerza bruta SSH contra el bastión."
  echo -e "  Se requiere una solución automatizada para mitigar los ataques."
  echo ""
  echo -e "  \e[1;37m🎯 TAREA ESPERADA:\e[0m"
  echo -e "  El ingeniero L3 dejó el script \e[1mcasi terminado\e[0m. Solo tienes que"
  echo -e "  completar \e[1m4 huecos\e[0m marcados con '>>> COMPLETA'. Cada hueco tiene"
  echo -e "  una pista clara y un ejemplo de lo que debes escribir."
  echo ""
  echo -e "  \e[1;37m📝 NOTA DEL INGENIERO L3:\e[0m"
  echo -e "  \e[3m\"Dejé el 80% del trabajo hecho. Los huecos son pequeños y están bien\e[0m"
  echo -e "  \e[3mdocumentados. Si te atoras, lee las pistas al final del briefing.\" \e[0m"

  # ==============================================================================
  # Crear el script INCOMPLETO (nivel 3/10 - muy guiado)
  # ==============================================================================
  cat > "$SCRIPT_TARGET" << 'INNEREOF'
  #!/bin/bash
  # ==============================================================================
  # TICKET: INC-4521  |  Dificultad: 3/10
  # Script: cazador_de_logs.sh
  # Autor original: Carlos (L3) - dejó el 80% listo, solo faltan 4 huecos.
  # ==============================================================================

  LOG_FILE="$HOME/lab-bash-004/bloqueos.log"
  SAMPLE_LOG="$HOME/lab-bash-004/sample_auth.log"
  THRESHOLD=5

  # Función para logging con timestamp y nivel (YA ESTÁ LISTA, no tocar)
  log_msg() {
      local level=$1
      local msg=$2
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" | tee -a "$LOG_FILE"
  }

  log_msg "INFO" "Iniciando análisis de intentos fallidos de SSH..."

  # ==============================================================================
  # PASO 1: Detectar qué log del sistema usar
  # ==============================================================================
  # En Debian/Ubuntu el log es /var/log/auth.log
  # En RHEL/CentOS/Fedora el log es /var/log/secure
  # Si ninguno existe, usamos el sample de prueba que está en el directorio.
  # ==============================================================================
  if [ -f /var/log/auth.log ]; then
      # >>> COMPLETA AQUÍ (1 línea) <<<
      # Asigna la ruta "/var/log/auth.log" a la variable LOG_SOURCE
      # Ejemplo:   LOG_SOURCE="..."
      LOG_SOURCE=

  elif [ -f /var/log/secure ]; then
      # >>> COMPLETA AQUÍ (1 línea) <<<
      # Asigna la ruta "/var/log/secure" a la variable LOG_SOURCE
      LOG_SOURCE=

  elif [ -f "$SAMPLE_LOG" ]; then
      LOG_SOURCE="$SAMPLE_LOG"
      log_msg "WARN" "No se encontró log real del sistema, usando sample de prueba"
  else
      # >>> COMPLETA AQUÍ (2 líneas) <<<
      # 1) Registra un error: log_msg "ERROR" "mensaje"
      # 2) Aborta el script con: exit 1
      log_msg

      exit
  fi

  log_msg "INFO" "Usando fuente de log: $LOG_SOURCE"

  # ==============================================================================
  # PASO 2: Extraer las IPs de los intentos fallidos y contarlas
  # ==============================================================================
  # El pipeline hace esto (en orden):
  #   1) grep "Failed password"       → filtra solo las líneas de fallos
  #   2) grep -oE "REGEX"             → extrae solo las IPs (una por línea)
  #   3) sort                         → ordena las IPs (necesario para uniq)
  #   4) uniq -c                      → cuenta cuántas veces aparece cada IP
  #   5) sort -rn                     → ordena de mayor a menor por contador
  #
  # Resultado esperado (ejemplo):
  #      14 203.0.113.45
  #      11 198.51.100.23
  #       8 192.0.2.99
  #       8 45.33.32.156
  #       7 185.220.101.34
  #       3 10.0.0.5
  #       ...
  # ==============================================================================
  # >>> COMPLETA AQUÍ <<<
  # Solo falta la REGEX dentro de grep -oE para extraer una IPv4.
  # Pista: una IPv4 son 4 grupos de 1 a 3 dígitos separados por puntos.
  # Regex sugerida: '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
  IPS_ATACANTES=$(grep "Failed password" "$LOG_SOURCE" | grep -oE "AQUÍ_VA_TU_REGEX" | sort | uniq -c | sort -rn)

  if [ -z "$IPS_ATACANTES" ]; then
      log_msg "INFO" "No se detectaron intentos fallidos. Nada que bloquear."
      exit 0
  fi

  log_msg "INFO" "IPs detectadas con intentos fallidos:"
  echo "$IPS_ATACANTES"

  # ==============================================================================
  # PASO 3: Recorrer cada IP y bloquear las que superen el THRESHOLD
  # ==============================================================================
  # Cada línea de $IPS_ATACANTES tiene el formato: "  COUNT IP"
  # Ejemplo: "     14 203.0.113.45"
  # Con 'read -r count ip' bash separa automáticamente esos dos campos.
  # ==============================================================================
  echo "$IPS_ATACANTES" | while read -r count ip; do

      # >>> COMPLETA AQUÍ (1 línea) <<<
      # Si $count es MENOR que $THRESHOLD, saltamos esta IP con 'continue'
      # Pista: usa [ "$count" -lt $THRESHOLD ] && continue
      # O también: if [ ... ]; then continue; fi


      # ------------------------------------------------------------------
      # PASO 4: Verificar si la IP ya está bloqueada (idempotencia)
      # ------------------------------------------------------------------
      # Antes de agregar una regla, revisamos si ya existe para no duplicar.
      # Usamos 'iptables -L -n' y buscamos la IP con grep -q (silencioso).
      # Si grep -q encuentra la IP, el exit code es 0 → ya está bloqueada.
      # ------------------------------------------------------------------
      if iptables -L INPUT -n 2>/dev/null | grep -q "$ip"; then
          log_msg "INFO" "IP $ip ya está bloqueada. Se omite (idempotencia)."
          continue
      fi

      # Si llegamos aquí, la IP NO está bloqueada → la bloqueamos
      if iptables -A INPUT -s "$ip" -j DROP 2>/dev/null; then
          log_msg "INFO" "✅ IP $ip bloqueada ($count intentos fallidos)"
      else
          log_msg "ERROR" "❌ No se pudo bloquear la IP $ip (¿faltan permisos root?)"
      fi

  done

  log_msg "INFO" "Análisis completado. Revisa $LOG_FILE para el detalle."
  exit 0
  INNEREOF

  chmod 644 "$SCRIPT_TARGET"

  echo ""
  echo -e "\e[1;32m✔ Entorno de laboratorio listo.\e[0m"
  echo -e "📂 Ruta de trabajo: \e[1;33mcd $WORK_DIR\e[0m"
  echo -e "📝 Resuelve el script con: \e[1;33mnano $SCRIPT_TARGET\e[0m"
  echo -e "📄 Datos de entrada: \e[1;33m$SAMPLE_LOG\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  echo -e "\e[1;37m📋 DEFINICIÓN DE 'RESUELTO' (Definition of Done):\e[0m"
  echo -e "  ☐ El script detecta el log correcto según la distribución (Paso 1)"
  echo -e "  ☐ La regex extrae correctamente las IPs (Paso 2)"
  echo -e "  ☐ Se bloquean con iptables las IPs con más de 5 intentos (Pasos 3 y 4)"
  echo -e "  ☐ El log $LOG_FILE registra cada acción con timestamp"
  echo ""
  echo -e "\e[1;33m💡 PISTAS PROGRESIVAS (si te trabas):\e[0m"
  echo -e ""
  echo -e "  \e[1mPaso 1 — Asignar variable:\e[0m"
  echo -e "     LOG_SOURCE=\"/var/log/auth.log\""
  echo -e ""
  echo -e "  \e[1mPaso 2 — Regex para IPv4:\e[0m"
  echo -e "     grep -oE '[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}'"
  echo -e ""
  echo -e "  \e[1mPaso 3 — Saltar IPs con pocos intentos:\e[0m"
  echo -e "     [ \"\$count\" -lt \$THRESHOLD ] && continue"
  echo -e ""
  echo -e "  \e[1mPaso 4 — Ya está resuelto en el script (idempotencia).\e[0m"
  echo -e "     Solo asegúrate de ejecutar con \e[1msudo bash cazador_de_logs.sh\e[0m"
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
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
