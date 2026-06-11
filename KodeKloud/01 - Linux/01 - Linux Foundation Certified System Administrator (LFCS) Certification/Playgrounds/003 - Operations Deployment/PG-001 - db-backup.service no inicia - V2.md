---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-001-v2
Titulo: db-backup.service no inicia - V2
Fecha de Inicio: 2026-06-11
Dificultad: 6/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Systemd Services
  - Permissions & Ownership
  - Journalctl & Logging
  - Bash Scripting
Competencias:
  - Diagnosticar y corregir unidades systemd en entornos productivos
  - Gestionar usuarios de servicio dedicados y permisos estrictos
  - Identificar problemas de configuración en múltiples capas (unidad + script + filesystem)
Script: |-
  cat << 'EOF' > /tmp/setup.sh

  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  echo -e "\e[1;33m⏳ [node01 → node02] Inyectando fallos de Systemd y permisos...\e[0m"

  # ── 1. Configuración del escenario roto en node02 ───────────────────────────
  $SSH -t ${USER_NET}@${NODE_TARGET} "sudo bash -c '

      useradd -r -s /sbin/nologin syncuser 2>/dev/null || true

      rm -rf /var/log/data-sync
      mkdir -p /var/log/data-sync
      chown root:root /var/log/data-sync
      chmod 755 /var/log/data-sync

      cat << \"APP\" > /usr/local/bin/data-sync
  #!/bin/bash
  if [ \"\$(id -u)\" -ne \"\$(id -u syncuser)\" ]; then
      echo \"ERROR: Este servicio debe ejecutarse como usuario syncuser\" >&2
      exit 1
  fi

  if [ -z \"\$DATA_SYNC_DIR\" ]; then
      echo \"ERROR: Variable DATA_SYNC_DIR no configurada\" >&2
      exit 1
  fi

  mkdir -p \"\$DATA_SYNC_DIR\" 2>/dev/null || { echo \"ERROR: No se puede crear directorio de trabajo\" >&2; exit 1; }
  touch /var/log/data-sync/sync.log 2>/dev/null || { echo \"ERROR: Sin permisos para escribir logs\" >&2; exit 1; }

  while true; do
      echo \"[\$(date \"+%Y-%m-%d %H:%M:%S\")] [INFO] Data synchronization cycle completed\" >> /var/log/data-sync/sync.log
      sleep 8
  done
  APP
      chmod 755 /usr/local/bin/data-sync

      cat << \"SERVICE\" > /etc/systemd/system/data-sync.service
  [Unit]
  Description=Data Synchronization Service
  After=network.target

  [Service]
  Type=simple
  ExecStart=/usr/local/bin/data-sync
  User=root
  Restart=no

  [Install]
  WantedBy=multi-user.target
  SERVICE

      systemctl daemon-reload
      systemctl stop data-sync.service 2>/dev/null || true
      systemctl disable data-sync.service 2>/dev/null || true
  '"

  echo -e "\e[1;33m⏳ [node01 → node03] Preparando bóveda de gobernancia...\e[0m"

  # ── 2. Preparar bóveda en node03 ─────────────────────────────────────────────
  $SSH -t ${USER_NET}@${NODE_VAULT} "sudo bash -c '
      rm -rf /opt/backup-vault/*
      mkdir -p /opt/backup-vault/
      chown -R bob:bob /opt/backup-vault/
  '"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-2789  │  Severidad: ALTA  │  Ambiente: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  ⚙️  PG-001-MN — db-backup.service No Inicia (Systemd)\e[0m"
  echo -e "\e[1;36m  Módulo: Operations & Deployment  │  Dificultad: 6/10  │  Nivel: L2/L3\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m     node02 (Servidor con unidad Systemd degradada)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Bóveda de Gobernancia — \e[1;35m/opt/backup-vault/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  El equipo de Data Engineering desplegó el servicio \e[1mdata-sync\e[0m en node02."
  echo -e "  Desde su implementación, las alertas de Prometheus indican que la unidad"
  echo -e "  entra en estado \e[1;31mfailed\e[0m de forma continua. Debe resolver todas las"
  echo -e "  causas raíz operando de forma remota desde node01."
  echo -e ""
  echo -e " \e[1mParámetros Técnicos Obligatorios (SSH desde node01 hacia node02):\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Corrección de Permisos de Logs (Remoto en node02)\e[0m"
  echo -e "     Corrija '/var/log/data-sync/' para que syncuser pueda escribir"
  echo -e "     de forma persistente. No use chmod 777."
  echo -e ""
  echo -e "  \e[1;31m2. Reconfiguración de la Unidad Systemd (Remoto en node02)\e[0m"
  echo -e "     Edite '/etc/systemd/system/data-sync.service':"
  echo -e "     - User=\e[1msyncuser\e[0m"
  echo -e "     - Environment=\e[1mDATA_SYNC_DIR=/var/run/data-sync/work\e[0m"
  echo -e "     - WorkingDirectory=\e[1m/var/run/data-sync\e[0m"
  echo -e "     - Restart=\e[1malways\e[0m"
  echo -e ""
  echo -e "  \e[1;31m3. Estabilización del Servicio (Remoto en node02)\e[0m"
  echo -e "     Recargue el daemon, inicie y habilite la unidad para persistir"
  echo -e "     tras reinicios. Verifique con 'systemctl status data-sync'."
  echo -e ""
  echo -e "  \e[1;31m4. Resguardo en Bóveda (node02 → node03)\e[0m"
  echo -e "     Transfiera el script funcional desde node02:/usr/local/bin/data-sync"
  echo -e "     hacia \e[1mnode03:/opt/backup-vault/data-sync.bak\e[0m"
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Servicio data-sync activo (running) en node02                --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Unidad habilitada (enabled) al arranque en node02            --> \e[1;35m15%\e[0m"
  echo -e "  [ ] syncuser + WorkingDirectory + Restart=always configurados    --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Logs escritos correctamente en /var/log/data-sync/           --> \e[1;35m15%\e[0m"
  echo -e "  [ ] Copia íntegra de data-sync.bak en node03:/opt/backup-vault/  --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m Ejecute 'systemctl daemon-reload' tras cada edición remota."
  echo -e "               Diagnóstico: ssh bob@node02 'journalctl -u data-sync -n 30 --no-pager'"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup.sh && rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  cat > /tmp/validador.sh << 'EOF'

  #!/bin/bash
  PUNTOS=0

  USER="bob"
  PASS="caleston123"
  TARGET_NODE="node02"
  VAULT_NODE="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER}@${TARGET_NODE}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER}@${VAULT_NODE}"

  # Asegurar sshpass disponible de forma silenciosa
  if ! command -v sshpass &>/dev/null; then
      sudo yum install -y sshpass -q >/dev/null 2>&1 || \
      sudo apt-get install -y sshpass   >/dev/null 2>&1
  fi

  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  AUDITORÍA SYSTEMD DISTRIBUIDA — INC-2789 (PG-001-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # ── 1. Servicio activo (running) en node02 ────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [1/5] Verificando estado activo del servicio en node02...\e[0m"

  IS_ACTIVE=$($SSH2 "systemctl is-active data-sync.service" 2>/dev/null || true)

  if [ "$IS_ACTIVE" = "active" ]; then
      echo -e "\e[1;32m  ✔ [30%] Servicio data-sync.service activo (running) en node02.\e[0m"
      PUNTOS=$((PUNTOS + 30))
  else
      echo -e "\e[1;31m  ❌ [0%] El servicio está inactivo o en estado failed en node02.\e[0m"
      echo -e "       → Estado actual: \e[1;31m$IS_ACTIVE\e[0m"
      echo -e "       → Diagnóstico: ssh bob@node02 'journalctl -u data-sync -n 30 --no-pager'"
  fi

  # ── 2. Servicio habilitado al arranque en node02 ──────────────────────────────
  echo -e "\n\e[1;37m⏳ [2/5] Verificando persistencia al arranque en node02...\e[0m"

  IS_ENABLED=$($SSH2 "systemctl is-enabled data-sync.service" 2>/dev/null || true)

  if [ "$IS_ENABLED" = "enabled" ]; then
      echo -e "\e[1;32m  ✔ [15%] Servicio habilitado al arranque (enabled) en node02.\e[0m"
      PUNTOS=$((PUNTOS + 15))
  else
      echo -e "\e[1;31m  ❌ [0%] El servicio no está habilitado para iniciar tras reinicios.\e[0m"
      echo -e "       → Estado actual: \e[1;31m$IS_ENABLED\e[0m  (se espera: enabled)"
      echo -e "       → Corrección: ssh bob@node02 'sudo systemctl enable data-sync.service'"
  fi

  # ── 3. syncuser + WorkingDirectory + Restart=always ──────────────────────────
  echo -e "\n\e[1;37m⏳ [3/5] Verificando directivas de identidad y resiliencia en node02...\e[0m"

  SERVICE_USER=$($SSH2 "systemctl show -p User data-sync.service" 2>/dev/null || true)
  RESTART_RULE=$($SSH2 "systemctl show -p Restart data-sync.service" 2>/dev/null || true)
  WORK_DIR=$(    $SSH2 "systemctl show -p WorkingDirectory data-sync.service" 2>/dev/null || true)

  if echo "$SERVICE_USER" | grep -q "syncuser" && \
     echo "$RESTART_RULE" | grep -q "always"   && \
     echo "$WORK_DIR"     | grep -q "data-sync"; then
      echo -e "\e[1;32m  ✔ [20%] syncuser, WorkingDirectory y Restart=always configurados correctamente.\e[0m"
      PUNTOS=$((PUNTOS + 20))
  else
      echo -e "\e[1;31m  ❌ [0%] La unidad retiene errores de configuración.\e[0m"
      echo "$SERVICE_USER" | grep -qv "syncuser"  && echo -e "       → User actual: \e[1;31m$SERVICE_USER\e[0m  (se espera: syncuser)"
      echo "$RESTART_RULE" | grep -qv "always"    && echo -e "       → Restart actual: \e[1;31m$RESTART_RULE\e[0m  (se espera: always)"
      echo "$WORK_DIR"     | grep -qv "data-sync" && echo -e "       → WorkingDirectory: \e[1;31m$WORK_DIR\e[0m  (se espera: /var/run/data-sync)"
  fi

  # ── 4. Logs escritos correctamente por syncuser ───────────────────────────────
  echo -e "\n\e[1;37m⏳ [4/5] Verificando escritura de logs en node02...\e[0m"

  if $SSH2 "sudo test -f /var/log/data-sync/sync.log" 2>/dev/null; then
      LOG_USER=$($SSH2  "sudo stat -c '%U' /var/log/data-sync/sync.log" 2>/dev/null || true)
      LOG_SAMPLE=$($SSH2 "sudo tail -n 1 /var/log/data-sync/sync.log"  2>/dev/null || true)

      if [ "$LOG_USER" = "syncuser" ] && \
         echo "$LOG_SAMPLE" | grep -q "Data synchronization cycle completed"; then
          echo -e "\e[1;32m  ✔ [15%] Logs escritos correctamente por syncuser en /var/log/data-sync/.\e[0m"
          PUNTOS=$((PUNTOS + 15))
      else
          echo -e "\e[1;31m  ❌ [0%] Log encontrado pero propietario o contenido incorrecto.\e[0m"
          [ "$LOG_USER" != "syncuser" ] && \
              echo -e "       → Propietario actual: \e[1;31m$LOG_USER\e[0m  (se espera: syncuser)"
          echo "$LOG_SAMPLE" | grep -qv "Data synchronization" && \
              echo -e "       → El log no registra el ciclo esperado — verifique que el servicio corre"
      fi
  else
      echo -e "\e[1;31m  ❌ [0%] No existe /var/log/data-sync/sync.log — el servicio no ha podido escribir.\e[0m"
      echo -e "       → Verifique permisos de /var/log/data-sync/ con: ssh bob@node02 'ls -la /var/log/data-sync/'"
  fi

  # ── 5. Resguardo íntegro en bóveda node03 ────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [5/5] Auditando custodia del script en node03...\e[0m"

  if $SSH3 "test -f /opt/backup-vault/data-sync.bak" 2>/dev/null; then
      BAK_CONTENT=$($SSH3 "cat /opt/backup-vault/data-sync.bak" 2>/dev/null || true)

      if echo "$BAK_CONTENT" | grep -q "syncuser" && \
         echo "$BAK_CONTENT" | grep -q "DATA_SYNC_DIR"; then
          echo -e "\e[1;32m  ✔ [20%] Copia íntegra de data-sync.bak custodiada correctamente en node03.\e[0m"
          PUNTOS=$((PUNTOS + 20))
      else
          echo -e "\e[1;33m  ⚠️  [5%] Archivo presente en node03 pero contenido no coincide con el script funcional.\e[0m"
          echo -e "       → Verifique que copió el script ya corregido, no el original roto"
          PUNTOS=$((PUNTOS + 5))
      fi
  else
      echo -e "\e[1;31m  ❌ [0%] No se encontró data-sync.bak en node03:/opt/backup-vault/\e[0m"
      echo -e "       → Transfiera con: sshpass -p caleston123 scp bob@node02:/usr/local/bin/data-sync bob@node03:/opt/backup-vault/data-sync.bak"
  fi

  # ── Resultado Final ────────────────────────────────────────────────────────────
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
      echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — Dominio completo de Daemons Systemd remotos."
  elif [ $PUNTOS -ge 55 ]; then
      echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los ❌."
  else
      echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Revise las directivas Systemd y permisos en node02."
  fi
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh && rm -f /tmp/validador.sh
---

[[Laboratorios del LFCS]]
---
During a production incident, I was assigned a high-priority ticket related to a distributed Linux environment. The issue involved a systemd service called "data-sync" running on a remote server. Monitoring alerts indicated that the service was repeatedly failing, affecting the synchronization of operational data between systems.

My first step was to perform a structured diagnosis instead of immediately restarting the service. I connected remotely to the affected server and reviewed the systemd unit configuration, service logs, file permissions, and runtime directories. While investigating, I discovered several root causes.

The service was configured to run as the root user, but the application script was designed to run only under a dedicated service account called "syncuser". In addition, a required environment variable was missing, the working directory defined by the application did not exist, and the log directory permissions prevented the service account from writing operational logs.

To resolve the issue, I created the required runtime directory structure, assigned the correct ownership to the service account, and corrected the permissions following security best practices without using overly permissive settings. I then modified the systemd unit file to use the correct service account, configured the required environment variable, defined the proper working directory, and enabled automatic restart capabilities to improve service resilience.

After reloading the systemd configuration, I started the service and validated its operational status. I confirmed that the service was running successfully, generating logs correctly, and configured to start automatically after server reboots.

As part of the incident closure process, I also created a backup of the production script and securely transferred it to a centralized backup repository located on a separate server. Finally, I verified the integrity of the copied file and documented the remediation steps.

The incident was fully resolved, all audit controls passed successfully, and the service availability was restored without requiring application code changes. This exercise demonstrated my troubleshooting approach in Linux environments, including systemd administration, permissions management, service recovery, remote operations, and operational validation in a distributed infrastructure.