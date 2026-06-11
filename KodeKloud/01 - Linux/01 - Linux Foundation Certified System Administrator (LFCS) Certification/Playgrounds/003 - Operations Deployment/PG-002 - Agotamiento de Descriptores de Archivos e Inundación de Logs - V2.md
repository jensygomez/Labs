---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-002-v2
Titulo: Agotamiento de Descriptores de Archivos e Inundación de Logs - V2
Fecha de Inicio: 2026-06-05
Dificultad: 5/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Process Management
  - Performance Troubleshooting
  - Systemd Services
  - Forensic Analysis
Competencias:
  - Diagnosticar consumo elevado de CPU con herramientas avanzadas
  - Identificar y detener procesos runaway sin afectar servicios críticos
  - Generar reportes de diagnóstico forense
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

  echo -e "\e[1;33m⏳ [node01 → node02] Desplegando fuga de descriptores y saturación de I/O...\e[0m"
  # ── 0. Instalar dependencias en todos los nodos ─────────────────────────────
  echo -e "\e[1;33m⏳ Instalando dependencias en el clúster...\e[0m"

  # Instalar sshpass localmente en node01
  if ! command -v sshpass &>/dev/null; then
      sudo apt-get install -y sshpass -q >/dev/null 2>&1 || \
      sudo yum install -y sshpass -q    >/dev/null 2>&1
  fi

  # Instalar sshpass en node02 (usando SSH con contraseña interactiva — solo esta vez)
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 bob@node02 \
      "echo caleston123 | sudo -S apt-get install -y sshpass -q >/dev/null 2>&1 || \
       echo caleston123 | sudo -S yum install -y sshpass -q >/dev/null 2>&1; echo ok"

  # Instalar sshpass en node03
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 bob@node03 \
      "echo caleston123 | sudo -S apt-get install -y sshpass -q >/dev/null 2>&1 || \
       echo caleston123 | sudo -S yum install -y sshpass -q >/dev/null 2>&1; echo ok"

  echo -e "\e[1;32m✔ Dependencias listas en el clúster.\e[0m"
  # ── 1. Configuración del escenario en node02 ─────────────────────────────────
  $SSH ${USER_NET}@${NODE_TARGET} "sudo bash -c '

      pkill -9 -f rogue-logger || true
      rm -rf /var/log/ecom-app/ /usr/local/bin/rogue-logger

      cat << \"WORKER\" > /usr/local/bin/ecom-worker
  #!/bin/bash
  echo \"E-commerce Worker started successfully\"
  while true; do
      sleep 12
  done
  WORKER
      chmod 755 /usr/local/bin/ecom-worker

      cat << \"SERVICE\" > /etc/systemd/system/ecom-worker.service
  [Unit]
  Description=E-commerce Background Worker
  After=network.target

  [Service]
  Type=simple
  ExecStart=/usr/local/bin/ecom-worker
  Restart=always
  User=root

  [Install]
  WantedBy=multi-user.target
  SERVICE

      systemctl daemon-reload
      systemctl enable --now ecom-worker.service

      mkdir -p /var/log/ecom-app
      cat << \"ROGUE\" > /usr/local/bin/rogue-logger
  #!/bin/bash
  exec 3>>/var/log/ecom-app/rogue_leak.log
  exec 4>>/var/log/ecom-app/rogue_leak_debug.log
  exec 5>>/var/log/ecom-app/rogue_audit.log

  while true; do
      echo \"[\$(date \"+%Y-%m-%d %H:%M:%S\")] [DEBUG] [PID=\$\$] Runaway process loop spilling logs indefinitely\" >&3
      echo \"[\$(date \"+%Y-%m-%d %H:%M:%S\")] [TRACE] Leak descriptor active on fd 4\" >&4
      echo \"[\$(date \"+%Y-%m-%d %H:%M:%S\")] [WARN] System resource warning mock\" >&5
      sleep 0.02
  done
  ROGUE
      chmod 755 /usr/local/bin/rogue-logger

      nohup /usr/local/bin/rogue-logger >/dev/null 2>&1 &
  '"

  echo -e "\e[1;33m⏳ [node01 → node03] Preparando bóveda de evidencias SRE...\e[0m"

  # ── 2. Preparar bóveda en node03 ─────────────────────────────────────────────
  $SSH ${USER_NET}@${NODE_VAULT} "sudo bash -c '
      rm -rf /opt/sre-vault/*
      mkdir -p /opt/sre-vault/
      chown -R bob:bob /opt/sre-vault/
  '"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-2567  │  Severidad: ALTA  │  Ambiente: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  🔍 PG-002-MN — Fuga de Descriptores y Saturación de I/O (Procesos)\e[0m"
  echo -e "\e[1;36m  Módulo: Operations & Deployment  │  Dificultad: 6/10  │  Nivel: L2/L3\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m     node02 (Servidor con fuga de descriptores activa)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Bóveda de Evidencias SRE — \e[1;35m/opt/sre-vault/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Durante los últimos 40 minutos, los sistemas de monitoreo detectaron una"
  echo -e "  degradación crítica en el almacenamiento del nodo de producción \e[1mnode02\e[0m."
  echo -e "  Un proceso descontrolado realiza escrituras masivas y retiene descriptores"
  echo -e "  de archivos activos sin cerrarlos, poniendo en riesgo el espacio en disco"
  echo -e "  y los límites de la tabla de descriptores del sistema operativo."
  echo -e ""
  echo -e " \e[1mParámetros Técnicos Obligatorios (SSH desde node01 hacia node02):\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Identificación del Proceso Rebelde (Remoto en node02)\e[0m"
  echo -e "     Localice quirúrgicamente el PID del proceso ejecutor de"
  echo -e "     \e[1m/usr/local/bin/rogue-logger\e[0m usando \e[1mlsof\e[0m, \e[1mps aux\e[0m o \e[1mpidof\e[0m."
  echo -e ""
  echo -e "  \e[1;31m2. Terminación Selectiva del Proceso (Remoto en node02)\e[0m"
  echo -e "     Elimine el proceso rebelde sin afectar bajo ninguna circunstancia"
  echo -e "     el servicio legítimo \e[1mecom-worker.service\e[0m."
  echo -e ""
  echo -e "  \e[1;31m3. Reporte Forense en Bóveda (node01 → node03)\e[0m"
  echo -e "     Genere y deposite el informe en \e[1mnode03:/opt/sre-vault/io_diagnostic_report.txt\e[0m"
  echo -e "     con el formato exacto:"
  echo -e "       Línea 1: METRIC: DESCRIPTORS LEAK DETECTED"
  echo -e "       Línea 2: RECOVERY: PROCESS TERMINATED SUCCESSFULLY"
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Proceso rogue-logger terminado en node02                      --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Inundación de logs contenida en /var/log/ecom-app/            --> \e[1;35m20%\e[0m"
  echo -e "  [ ] ecom-worker.service sigue activo (running) en node02          --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Reporte forense estructurado y validado en node03             --> \e[1;35m30%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m Use pkill -f rogue-logger para no afectar otros procesos."
  echo -e "               Diagnóstico: ssh bob@node02 'ps aux | grep rogue' y 'lsof -p <PID>'"
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

  if ! command -v sshpass &>/dev/null; then
      sudo yum install -y sshpass -q >/dev/null 2>&1 || \
      sudo apt-get install -y sshpass   >/dev/null 2>&1
  fi

  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  AUDITORÍA DE PROCESOS DISTRIBUIDOS — INC-2567 (PG-002-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # ── 1. Proceso rogue-logger terminado en node02 ───────────────────────────────
  echo -e "\n\e[1;37m⏳ [1/4] Verificando eliminación del proceso rebelde en node02...\e[0m"

  IS_ROGUE_ALIVE=$($SSH2 "pgrep -f rogue-logger" 2>/dev/null || true)

  if [ -z "$IS_ROGUE_ALIVE" ]; then
      echo -e "\e[1;32m  ✔ [30%] Proceso rogue-logger identificado y eliminado correctamente en node02.\e[0m"
      PUNTOS=$((PUNTOS + 30))
  else
      echo -e "\e[1;31m  ❌ [0%] El proceso rogue-logger sigue activo en node02.\e[0m"
      echo -e "       → PID activo: \e[1;31m$IS_ROGUE_ALIVE\e[0m"
      echo -e "       → Corrección: ssh bob@node02 'sudo pkill -f rogue-logger'"
  fi

  # ── 2. Inundación de logs contenida (archivo deja de crecer) ─────────────────
  echo -e "\n\e[1;37m⏳ [2/4] Verificando contención de la inundación de logs en node02...\e[0m"

  LOG_SIZE_1=$($SSH2 "wc -l /var/log/ecom-app/rogue_leak.log 2>/dev/null" | awk '{print $1}' || true)
  sleep 1.5
  LOG_SIZE_2=$($SSH2 "wc -l /var/log/ecom-app/rogue_leak.log 2>/dev/null" | awk '{print $1}' || true)

  if [ -n "$LOG_SIZE_1" ] && [ "$LOG_SIZE_1" -eq "$LOG_SIZE_2" ]; then
      echo -e "\e[1;32m  ✔ [20%] Fuga de descriptores contenida — el archivo de logs dejó de crecer.\e[0m"
      PUNTOS=$((PUNTOS + 20))
  else
      echo -e "\e[1;31m  ❌ [0%] El archivo rogue_leak.log sigue acumulando líneas activamente.\e[0m"
      echo -e "       → Líneas antes: \e[1;31m$LOG_SIZE_1\e[0m  │  Líneas después: \e[1;31m$LOG_SIZE_2\e[0m"
      echo -e "       → El proceso sigue corriendo o fue relanzado — verifique con pgrep -f rogue-logger"
  fi

  # ── 3. ecom-worker.service sigue activo en node02 ────────────────────────────
  echo -e "\n\e[1;37m⏳ [3/4] Verificando integridad del servicio legítimo en node02...\e[0m"

  IS_WORKER_ACTIVE=$($SSH2 "systemctl is-active ecom-worker.service" 2>/dev/null || true)

  if [ "$IS_WORKER_ACTIVE" = "active" ]; then
      echo -e "\e[1;32m  ✔ [20%] Servicio legítimo ecom-worker.service activo e intacto en node02.\e[0m"
      PUNTOS=$((PUNTOS + 20))
  else
      echo -e "\e[1;31m  ❌ [0%] ecom-worker.service fue detenido o afectado durante la intervención.\e[0m"
      echo -e "       → Estado actual: \e[1;31m$IS_WORKER_ACTIVE\e[0m  (se espera: active)"
      echo -e "       → Restaure con: ssh bob@node02 'sudo systemctl start ecom-worker.service'"
  fi

  # ── 4. Reporte forense en bóveda node03 ──────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [4/4] Auditando reporte forense en node03:/opt/sre-vault/...\e[0m"

  if $SSH3 "test -f /opt/sre-vault/io_diagnostic_report.txt" 2>/dev/null; then
      REPORT_CONTENT=$($SSH3 "cat /opt/sre-vault/io_diagnostic_report.txt" 2>/dev/null || true)

      if echo "$REPORT_CONTENT" | grep -q "METRIC: DESCRIPTORS LEAK DETECTED" && \
         echo "$REPORT_CONTENT" | grep -q "RECOVERY: PROCESS TERMINATED SUCCESSFULLY"; then
          echo -e "\e[1;32m  ✔ [30%] Reporte forense estructurado y validado correctamente en node03.\e[0m"
          PUNTOS=$((PUNTOS + 30))
      else
          echo -e "\e[1;33m  ⚠️  [10%] Reporte presente en node03 pero el formato no coincide exactamente.\e[0m"
          echo -e "       → Se esperan estas líneas exactas:"
          echo -e "         METRIC: DESCRIPTORS LEAK DETECTED"
          echo -e "         RECOVERY: PROCESS TERMINATED SUCCESSFULLY"
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo -e "\e[1;31m  ❌ [0%] Falta io_diagnostic_report.txt en node03:/opt/sre-vault/\e[0m"
      echo -e "       → Genere con: printf 'METRIC: DESCRIPTORS LEAK DETECTED\nRECOVERY: PROCESS TERMINATED SUCCESSFULLY\n' | sshpass -p caleston123 ssh bob@node03 'cat > /opt/sre-vault/io_diagnostic_report.txt'"
  fi

  # ── Resultado Final ────────────────────────────────────────────────────────────
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
      echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — Manejo forense de procesos distribuidos dominado."
  elif [ $PUNTOS -ge 55 ]; then
      echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los ❌."
  else
      echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Revise la eliminación del proceso y el reporte en node03."
  fi
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh && rm -f /tmp/validador.sh
---

[[Laboratorios del LFCS]]
---
