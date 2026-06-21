---
Curso: Transición Sysadmin a DevOps - Essential Commands LFCS/RHCSA
Modulo: Essential Commands (Búsqueda, Filtrado y Expresiones Regulares)
Playground: EC-004-v1
Titulo: La Aguja en el Pajar – Búsqueda, Filtrado y Expresiones Regulares
Fecha de Inicio: 2026-06-20
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - grep, egrep, fgrep y sus variantes
  - Basic Regular Expressions (BRE) y Extended Regular Expressions (ERE)
  - Grupos, cuantificadores, alternancia y anclajes en regex
  - find combinado con grep recursivo
  - locate para búsqueda rápida de archivos
  - Pipelines con grep -v, grep -c, grep -A/B/C para contexto
Competencias: |-
  - Construir expresiones regulares complejas para extraer patrones específicos de logs de seguridad (IPs, timestamps, códigos de error).
  - Combinar find con grep recursivo para auditar configuraciones del sistema en múltiples directorios.
  - Utilizar BRE y ERE según el contexto, aplicando grupos de captura, cuantificadores y alternancia para patrones avanzados.
  - Generar reportes de seguridad filtrados usando pipelines con contexto (grep -A/B/C) y conteo (grep -c).
  - Enviar evidencia de auditoría a node03 via pipeline SSH sin materializar archivos intermedios en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_ec004.sh

  #!/bin/bash
  set -e

  PASS="caleston123"
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT}"

  echo -e "\e[1;33m⏳ Verificando sshpass en node01...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      echo caleston123 | sudo -S apt-get install -y sshpass -qq
  fi

  echo -e "\e[1;33m⏳ Instalando sshpass en nodos remotos...\e[0m"
  $SSH2 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"
  $SSH3 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Inyectando logs y configuraciones comprometidas en node02...\e[0m"
  $SSH2 bash << 'NODE02_INJECT' || echo -e "\e[1;33m  [!] Detalle en node02, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'

      # 1. Auth.log con patrones de ataques de fuerza bruta
      mkdir -p /var/log
      cat > /var/log/auth.log << 'AUTHLOG'
  Jan 15 08:23:45 node02 sshd[1234]: Failed password for root from 203.0.113.45 port 54321 ssh2
  Jan 15 08:23:46 node02 sshd[1235]: Failed password for root from 203.0.113.45 port 54322 ssh2
  Jan 15 08:23:47 node02 sshd[1236]: Failed password for root from 203.0.113.45 port 54323 ssh2
  Jan 15 08:23:48 node02 sshd[1237]: Failed password for root from 203.0.113.45 port 54324 ssh2
  Jan 15 08:23:49 node02 sshd[1238]: Failed password for root from 203.0.113.45 port 54325 ssh2
  Jan 15 08:24:10 node02 sshd[1239]: Failed password for admin from 198.51.100.23 port 44556 ssh2
  Jan 15 08:24:11 node02 sshd[1240]: Failed password for admin from 198.51.100.23 port 44557 ssh2
  Jan 15 08:24:12 node02 sshd[1241]: Failed password for admin from 198.51.100.23 port 44558 ssh2
  Jan 15 08:25:30 node02 sshd[1242]: Accepted password for bob from 192.168.1.10 port 33445 ssh2
  Jan 15 08:26:15 node02 sshd[1243]: Failed password for invalid user test from 192.0.2.100 port 22334 ssh2
  Jan 15 08:26:16 node02 sshd[1244]: Failed password for invalid user guest from 192.0.2.100 port 22335 ssh2
  Jan 15 08:27:00 node02 sshd[1245]: Accepted publickey for deploy from 10.0.0.50 port 55667 ssh2
  Jan 15 08:28:30 node02 sshd[1246]: Failed password for root from 203.0.113.45 port 54400 ssh2
  Jan 15 08:28:31 node02 sshd[1247]: Failed password for root from 203.0.113.45 port 54401 ssh2
  Jan 15 08:29:00 node02 sshd[1248]: Failed password for ubuntu from 198.51.100.23 port 44600 ssh2
  Jan 15 08:30:15 node02 sshd[1249]: Failed password for root from 203.0.113.45 port 54500 ssh2
  Jan 15 08:30:16 node02 sshd[1250]: Failed password for root from 203.0.113.45 port 54501 ssh2
  Jan 15 08:31:00 node02 sshd[1251]: Accepted password for alice from 192.168.1.20 port 33500 ssh2
  Jan 15 08:32:45 node02 sshd[1252]: Failed password for invalid user oracle from 192.0.2.100 port 22400 ssh2
  Jan 15 08:33:00 node02 sshd[1253]: Failed password for root from 203.0.113.45 port 54600 ssh2
  AUTHLOG
      chmod 644 /var/log/auth.log

      # 2. Logs de aplicación con errores críticos
      mkdir -p /opt/app/logs
      cat > /opt/app/logs/app.log << 'APPLOG'
  2026-01-15T08:23:45.123Z [INFO] Application started successfully on port 8080
  2026-01-15T08:24:10.456Z [ERROR] Database connection timeout after 30000ms
  2026-01-15T08:24:15.789Z [WARNING] High memory usage detected: 85%
  2026-01-15T08:25:30.012Z [CRITICAL] OutOfMemoryError in worker thread pool-3
  2026-01-15T08:26:00.345Z [ERROR] Failed to authenticate user: invalid credentials
  2026-01-15T08:27:45.678Z [INFO] Request processed successfully in 125ms
  2026-01-15T08:28:20.901Z [FATAL] Unrecoverable disk I/O error on /dev/sda1
  2026-01-15T08:29:00.234Z [ERROR] Redis connection refused: ECONNREFUSED 127.0.0.1:6379
  2026-01-15T08:30:15.567Z [DEBUG] Cache hit ratio: 95.2%
  2026-01-15T08:31:00.890Z [ERROR] API rate limit exceeded for client 192.168.1.50
  2026-01-15T08:32:30.123Z [CRITICAL] Security breach: unauthorized access to /admin endpoint
  2026-01-15T08:33:00.456Z [INFO] Scheduled backup completed
  2026-01-15T08:34:15.789Z [ERROR] SSL certificate validation failed for api.external.com
  2026-01-15T08:35:00.012Z [FATAL] Kernel panic: unable to mount root filesystem
  2026-01-15T08:36:30.345Z [WARNING] Deprecated API endpoint /v1/users accessed
  2026-01-15T08:37:00.678Z [ERROR] Failed to write to audit log: permission denied
  APPLOG
      chmod 644 /opt/app/logs/app.log

      # 3. Archivos de configuración con contraseñas en texto plano
      cat > /etc/app.conf << 'APPCONF'
  # Configuración de aplicación principal
  database_host=localhost
  database_port=5432
  database_user=appadmin
  database_password=SuperSecret123!
  log_level=INFO
  max_connections=100
  deprecated_feature=enabled
  APPCONF

      cat > /etc/nginx.conf << 'NGINXCONF'
  worker_processes auto;
  events {
      worker_connections 1024;
  }
  http {
      server {
          listen 80;
          server_name example.com;
          root /var/www/html;
          # Password: AdminPass456
          location /api {
              proxy_pass http://localhost:8000;
          }
      }
  }
  NGINXCONF

      cat > /etc/redis.conf << 'REDICONF'
  bind 127.0.0.1
  port 6379
  requirepass RedisPass789!
  maxmemory 2gb
  REDICONF

      # 4. Directorio de configuraciones con formatos variados
      mkdir -p /opt/config
      cat > /opt/config/service1.yaml << 'YAML1'
  service:
    name: api-gateway
    port: 8080
    replicas: 3
    invalid line without colon
    health_check: /health
  YAML1

      cat > /opt/config/service2.conf << 'CONF2'
  SERVICE_NAME=cache-service
  SERVICE_PORT=6379
  MAX_MEMORY=2gb
  invalid=line=with=multiple=equals
  TIMEOUT=30
  CONF2

      cat > /opt/config/service3.env << 'ENV3'
  DB_HOST=localhost
  DB_PORT=5432
  DB_USER=appuser
  DB_PASSWORD=MyAppPassword789
  invalid line without equals
  API_KEY=sk-1234567890abcdef
  ENV3

      cat > /opt/config/service4.properties << 'PROP4'
  server.port=8080
  server.host=0.0.0.0
  database.url=jdbc:postgresql://localhost:5432/mydb
  database.password=DbPass2026!
  malformed.property
  logging.level=INFO
  PROP4

      # 5. Archivos de ruido para filtrar
      touch /var/log/auth.log.1 /var/log/auth.log.2
      touch /opt/app/logs/debug.log
      echo "DEBUG: This is a debug message" > /opt/app/logs/debug.log

      echo "[EC-004] Escenario forense inyectado correctamente."
  SUDO_INNER
  NODE02_INJECT

  echo -e "\e[1;33m⏳ Preparando bóveda de evidencia en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/ec-004/
      mkdir -p /opt/ops-compliance/ec-004/
      chown -R bob:bob /opt/ops-compliance/ec-004/
      chmod 750 /opt/ops-compliance/ec-004/
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en preparación de node03, continuando...\e[0m'"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m EC-004-v1 | La Aguja en el Pajar | Dificultad: 6/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/ec-004/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El Centro de Operaciones de Seguridad (SOC) ha detectado actividad anómala"
  echo -e " en el servidor node02 durante las últimas 48 horas. Los sistemas de detección"
  echo -e " de intrusos (IDS) han generado múltiples alertas relacionadas con intentos"
  echo -e " de acceso no autorizado y posibles brechas de configuración."
  echo -e ""
  echo -e " El CISO ha emitido una orden de auditoría forense inmediata. Se requiere"
  echo -e " analizar exhaustivamente los logs de autenticación, los registros de aplicación"
  echo -e " y los archivos de configuración del sistema para determinar el alcance del"
  echo -e " compromiso y generar evidencia para el proceso legal."
  echo -e ""
  echo -e " Como ingeniero L2 del equipo de respuesta a incidentes, se te asigna la"
  echo -e " tarea de extraer patrones específicos de seguridad, identificar indicadores"
  echo -e " de compromiso (IOCs) y consolidar los hallazgos en un reporte forense."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01 vía SSH hacia node02."
  echo -e " \e[1m>\e[0m No se permite materializar archivos de reporte o scripts temporales en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente de node02 hacia node03 mediante pipeline."
  echo -e " \e[1m>\e[0m El uso de herramientas de búsqueda avanzada (grep, egrep, find) es obligatorio."
  echo -e ""
  echo -e "\e[1;33m PARÁMETROS TÉCNICOS OBLIGATORIOS (TICKET DE AUDITORÍA FORENSE - NIVEL L2)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Análisis de Intentos de Acceso Fallidos (/var/log/auth.log)\e[0m"
  echo -e "    Estado actual: El archivo contiene miles de líneas con intentos de autenticación."
  echo -e "    Objetivo: Extraer todas las direcciones IP que han tenido intentos de login fallidos."
  echo -e "    \e[1;33mRestricción:\e[0m Debes construir una expresión regular que capture el formato de IP"
  echo -e "    desde las líneas que contengan 'Failed password'. Identifica las IPs con más de 3"
  echo -e "    intentos fallidos (posibles ataques de fuerza bruta)."
  echo -e ""
  echo -e " \e[1m2. Auditoría de Errores Críticos de Aplicación (/opt/app/logs/)\e[0m"
  echo -e "    Estado actual: Los logs de aplicación contienen mensajes de diferentes niveles."
  echo -e "    Objetivo: Consolidar todos los errores con niveles CRITICAL, FATAL o ERROR que"
  echo -e "    contengan timestamps en formato ISO 8601 (YYYY-MM-DDTHH:MM:SS)."
  echo -e "    \e[1;33mRestricción:\e[0m Usa expresiones regulares extendidas (ERE) con egrep para capturar"
  echo -e "    los timestamps y los niveles de severidad. Excluye mensajes de DEBUG y WARNING."
  echo -e ""
  echo -e " \e[1m3. Detección de Configuraciones Inseguras (/etc/)\e[0m"
  echo -e "    Estado actual: Se sospecha que existen contraseñas en texto plano en archivos de configuración."
  echo -e "    Objetivo: Buscar en /etc/ todas las líneas que contengan patrones de contraseñas"
  echo -e "    (palabras clave como 'password', 'passwd', 'secret', 'key' seguidas de valores)."
  echo -e "    \e[1;33mRestricción:\e[0m Usa find combinado con grep recursivo. Excluye archivos binarios"
  echo -e "    y directorios como /etc/ssl, /etc/pki."
  echo -e ""
  echo -e " \e[1m4. Validación de Formatos de Configuración (/opt/config/)\e[0m"
  echo -e "    Estado actual: Los archivos de configuración tienen formatos variados (.yaml, .conf, .env, .properties)."
  echo -e "    Objetivo: Identificar líneas mal formateadas que no sigan el patrón estándar"
  echo -e "    (key=value o key: value). Detecta líneas vacías, comentarios mal cerrados y"
  echo -e "    líneas con múltiples separadores."
  echo -e "    \e[1;33mRestricción:\e[0m Usa grep -v para filtrar líneas válidas y comentarios. Genera un"
  echo -e "    reporte con el nombre del archivo y la línea mal formateada."
  echo -e ""
  echo -e "\e[1;33m PIPELINE DE EVIDENCIA A NODE03\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " Destino: \e[1m/opt/ops-compliance/ec-004/forensic_audit.txt\e[0m"
  echo -e " Debe contener la salida concatenada de:"
  echo -e "  - IPs con intentos fallidos (ordenadas por frecuencia)"
  echo -e "  - Errores CRITICAL/FATAL/ERROR con timestamps"
  echo -e "  - Contraseñas detectadas en archivos de configuración"
  echo -e "  - Líneas mal formateadas en /opt/config/"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Regex válida para extraer IPs de auth.log                          15%"
  echo -e "  [ ] Identificación de IPs con >3 intentos fallidos                     15%"
  echo -e "  [ ] Consolidación de errores CRITICAL/FATAL/ERROR con timestamps       15%"
  echo -e "  [ ] Detección de contraseñas en texto plano en /etc/                   15%"
  echo -e "  [ ] Identificación de líneas mal formateadas en /opt/config/           15%"
  echo -e "  [ ] Uso de pipelines sin archivos intermedios en node01                10%"
  echo -e "  [ ] Evidencia (forensic_audit.txt) presente en bóveda node03           15%"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_ec004.sh && rm -f /tmp/setup_ec004.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - grep
  - Regular-Expressions
  - find
  - Security-Audit
Escenario: |-
  - Situación: Desde node01 te conectas a node02 donde se encuentra un servidor comprometido que requiere auditoría forense inmediata. Los logs de seguridad contienen miles de líneas con intentos de acceso, errores de aplicación y configuraciones sospechosas.

  Tu misión:
  1. Extraer todas las direcciones IP que han tenido intentos de login fallidos desde /var/log/auth.log, identificando patrones de ataques de fuerza bruta (múltiples intentos desde la misma IP en cortos períodos).

  2. Buscar en /var/log/ y /opt/app/logs/ todos los errores críticos de aplicación que contengan timestamps en formato ISO 8601 y códigos de error específicos (ERROR, CRITICAL, FATAL), generando un reporte consolidado.

  3. Auditar archivos de configuración en /etc/ buscando patrones inseguros: contraseñas en texto plano, permisos excesivos (chmod 777), y configuraciones deprecated que deben ser actualizadas.

  4. Validar que todos los archivos de configuración en /opt/config/ sigan el formato estándar (key=value) y detectar líneas mal formateadas que puedan causar fallos en el despliegue.

  5. Generar reportes filtrados que excluyan ruido (comentarios, líneas vacías, logs de debug) y enviar toda la evidencia de la auditoría a node03 via pipeline SSH.

  Regla de Oro: No puedes crear archivos de texto intermedios en node01. Todo el análisis debe realizarse mediante pipelines y la evidencia debe fluir directamente a node03.
---
[[Laboratorios del LFCS]]
---

_One recent challenge I faced involved a security incident review on a Linux server, where I had to investigate a suspected compromise within strict operational constraints. I wasn't allowed to create temporary files on the jump host — all the evidence had to flow directly from the target server to a secure storage location through a single pipeline, using only SSH and command-line tools._

_The task had four parts: detecting brute-force login attempts by extracting IP addresses from the authentication logs and filtering the ones with more than three failed attempts, consolidating critical and fatal application errors that included ISO 8601 timestamps, scanning configuration files across the system for hardcoded plaintext passwords, and identifying malformed lines in several configuration files with inconsistent formats, like YAML, conf, env, and properties files._

_What I found most challenging was building precise regular expressions that captured exactly what was needed without false positives — for example, distinguishing between a configuration line that legitimately contains a colon in its value versus one that's actually missing its key-value separator. I also ran into a subtle but important issue: when you nest a remote SSH command inside double quotes, the local shell tries to expand any dollar sign before sending the command, which broke my awk and grep filters until I escaped them properly. It was a good reminder that scripting for remote execution requires extra attention to how the shell parses quotes before anything even reaches the other server._

_In the end, I delivered a complete forensic report combining all four findings, fully respecting the no-intermediate-files constraint by piping everything directly between servers. It reinforced for me how important it is to validate assumptions step by step — testing each piece of a pipeline individually before chaining it all together — rather than trying to build a complex solution in one shot."_