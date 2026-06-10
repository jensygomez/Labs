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
Validacion:
  - Objetivo: El proceso infractor ha sido detenido correctamente
    Peso: 25 %
  - Objetivo: El consumo general de CPU ha bajado significativamente (<40% user)
    Peso: 25 %
  - Objetivo: El servicio 'ecom-worker.service' sigue activo y running
    Peso: 20 %
  - Objetivo: Reporte forense completo generado en /root/cpu_diagnostic_report.txt
    Peso: 30 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Variables de Red del Playground (Usuario bob / Contraseña caleston123 nativa)
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

  echo -e "\e[1;33m⏳ Desplegando escenario seguro de fuga de Descriptores y Saturation de I/O...\e[0m"

  # 1. Configuración del escenario en el nodo afectado (node02)
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_TARGET} "sudo bash -c '
      # Limpieza preventiva
      pkill -9 -f rogue-logger || true
      rm -rf /var/log/ecom-app/ /usr/local/bin/rogue-logger

      # Crear servicio legítimo de la aplicación (Ecom Worker)
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

      # Crear Proceso Rogue de Inundación de I/O y Descriptores (Seguro para CPU)
      mkdir -p /var/log/ecom-app
      cat << \"ROGUE\" > /usr/local/bin/rogue-logger
  #!/bin/bash
  # Simula un agente defectuoso que abre múltiples descriptores de archivos y satura el disco
  exec 3>>/var/log/ecom-app/rogue_leak.log
  exec 4>>/var/log/ecom-app/rogue_leak_debug.log
  exec 5>>/var/log/ecom-app/rogue_audit.log

  while true; do
      echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] [PID=\$\$] Runaway process loop spilling logs indefinitely\" >&3
      echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] [TRACE] Leak descriptor active on fd 4\" >&4
      echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] [WARN] System resource warning mock\" >&5
      sleep 0.02
  done
  ROGUE
      chmod 755 /usr/local/bin/rogue-logger

      # Lanzar el proceso rebelde en background de forma persistente
      nohup /usr/local/bin/rogue-logger >/dev/null 2>&1 &
  '"

  # 2. Preparación y limpieza de la Bóveda en node03
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_VAULT} "sudo rm -rf /opt/sre-vault/* && sudo mkdir -p /opt/sre-vault/ && sudo chown -R bob:bob /opt/sre-vault/"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-2567  │  Severidad: ALTA  │  AMBIENTE: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  echo -e "  Durante los últimos 40 minutos, los sistemas de monitoreo han detectado una"
  echo -e "  degradación crítica en el rendimiento del almacenamiento e inundación de logs"
  echo -e "  en el nodo de producción \e[1mnode02\e[0m, afectando la latencia del e-commerce."
  echo ""
  echo -e "  Un proceso descontrolado está realizando escrituras masivas y reteniendo"
  echo -e "  descriptores de archivos activos sin cerrarlos, poniendo en riesgo el espacio"
  echo -e "  en disco y los límites de la tabla de descriptores de archivos abiertos."
  echo ""
  echo -e " \e[1mUbicaciones del Clúster:\e[0m"
  echo -e "  - \e[1;35mnode01\e[0m: Tu estación central de control administrativo (usuario \e[1;32mbob\e[0m)."
  echo -e "  - \e[1;35mnode02\e[0m: Servidor afectado con la fuga de descriptores y escrituras agresivas."
  echo -e "  - \e[1;35mnode03\e[0m: Bóveda de Evidencias SRE (\e[1;33m/opt/sre-vault/\e[0m)."
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  PARÁMETROS TÉCNICOS EXIGIDOS (A RESOLVER DESDE NODE01 VIA SSH REMOTO)\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "  \e[1;31m1.\e[0m Identifique quirúrgicamente el PID del proceso rebelde ejecutor del script"
  echo -e "     \e[1m/usr/local/bin/rogue-logger\e[0m en \e[1mnode02\e[0m utilizando herramientas como"
  echo -e "     \e[1m lsof\e[0m, \e[1mps aux\e[0m, o \e[1mpidof\e[0m."
  echo ""
  echo -e "  \e[1;31m2.\e[0m Termine (\e[1mkill\e[0m) de forma limpia el proceso responsable sin afectar ni"
  echo -e "     interrumpir bajo ninguna circunstancia el servicio legítimo \e[1mecom-worker.service\e[0m."
  echo ""
  echo -e "  \e[1;31m3.\e[0m Genere un informe forense técnico localmente y súbalo directamente a la ruta"
  echo -e "     de la bóveda en \e[1mnode03:/opt/sre-vault/io_diagnostic_report.txt\e[0m."
  echo -e "     El archivo debe contener textualmente el siguiente formato:"
  echo -e "       Línea 1 -> METRIC: DESCRIPTORS LEAK DETECTED"
  echo -e "       Línea 2 -> RECOVERY: PROCESS TERMINATED SUCCESSFULLY"
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "   [ ] Proceso rogue-logger terminado (kill) en node02                  \e[0;32m→ 30%\e[0m"
  echo -e "   [ ] Inundación de logs contenida en /var/log/ecom-app/               \e[0;32m→ 20%\e[0m"
  echo -e "   [ ] Servicio legítimo ecom-worker.service sigue intacto e intacto (running) \e[0;32m→ 20%\e[0m"
  echo -e "   [ ] Reporte de diagnóstico forense estructurado y validado en node03 \e[0;32m→ 30%\e[0m"
  echo "--------------------------------------------------------------------------------"
  echo -e "  \e[1;32mCredenciales de Acceso:\e[0m Usuario: \e[1mbob\e[0m | Contraseña: \e[1mcaleston123\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  cat << 'EOF' > /tmp/validador.sh
  #!/bin/bash

  # =============================================================================
  # VALIDADOR AUTOMATIZADO MULTI-NODO — TICKET INC-2567 (V2 RE-DISEÑADO)
  # Ejecutar desde: node01
  # =============================================================================

  PUNTOS=0
  USER="bob"
  PASS="caleston123"
  TARGET_NODE="node02"
  VAULT_NODE="node03"

  # Conexiones remotas seguras con sshpass
  SSH2="sshpass -p $PASS ssh -o StrictHostKeyChecking=no ${USER}@${TARGET_NODE}"
  SSH3="sshpass -p $PASS ssh -o StrictHostKeyChecking=no ${USER}@${VAULT_NODE}"

  # Instalar sshpass silenciosamente si falta en el entorno
  if ! command -v sshpass &>/dev/null; then
      sudo yum install -y sshpass -q >/dev/null 2>&1 || sudo apt-get install -y sshpass -y >/dev/null 2>&1
  fi

  echo -e "\n=== 🕵️  AUDITANDO CONTROL DE OPERACIONES Y PROCESOS DESDE NODE01 ==="
  echo "⏳ Verificando procesos activos en $TARGET_NODE..."

  # ------------------------------------------------------------------------------
  # 1. Validar que el proceso rebelde (rogue-logger) fue finalizado
  # ------------------------------------------------------------------------------
  IS_ROGUE_ALIVE=$($SSH2 "pgrep -f rogue-logger" 2>/dev/null || true)

  if [ -z "$IS_ROGUE_ALIVE" ]; then
      echo "✔ [30%] Proceso descontrolado rogue-logger identificado y destruido con éxito."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] Operación fallida: El proceso rogue-logger sigue activo en el PID: $IS_ROGUE_ALIVE."
  fi

  # ------------------------------------------------------------------------------
  # 2. Validar que el servicio legítimo sigue operando intacto
  # ------------------------------------------------------------------------------
  IS_WORKER_ACTIVE=$($SSH2 "systemctl is-active ecom-worker.service" 2>/dev/null || true)

  if [ "$IS_WORKER_ACTIVE" = "active" ]; then
      echo "✔ [20%] Continuidad del negocio validada: ecom-worker.service está activo (running)."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Error crítico: El servicio legítimo ecom-worker.service fue detenido o afectado."
  fi

  # ------------------------------------------------------------------------------
  # 3. Validar contención de la inundación de logs en el File System
  # ------------------------------------------------------------------------------
  # Tomamos una muestra de líneas actuales, esperamos un segundo y verificamos que el archivo ya no crezca.
  LOG_SIZE_1=$($SSH2 "wc -l /var/log/ecom-app/rogue_leak.log 2>/dev/null" | awk '{print $1}' || true)
  sleep 1.2
  LOG_SIZE_2=$($SSH2 "wc -l /var/log/ecom-app/rogue_leak.log 2>/dev/null" | awk '{print $1}' || true)

  if [ -n "$LOG_SIZE_1" ] && [ "$LOG_SIZE_1" -eq "$LOG_SIZE_2" ]; then
      echo "✔ [20%] Mitigación de almacenamiento exitosa: Fuga de descriptores contenida."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El archivo de logs sigue acumulando líneas en caliente. El leak continúa activo."
  fi

  # ------------------------------------------------------------------------------
  # 4. Validar Reporte de Diagnóstico Forense en la Bóveda (node03)
  # ------------------------------------------------------------------------------
  echo "⏳ Conectando a $VAULT_NODE para verificar cumplimiento de reporte forense..."
  if $SSH3 "test -f /opt/sre-vault/io_diagnostic_report.txt" 2>/dev/null; then
      REPORT_CONTENT=$($SSH3 "cat /opt/sre-vault/io_diagnostic_report.txt" 2>/dev/null || true)
      
      if echo "$REPORT_CONTENT" | grep -q "METRIC: DESCRIPTORS LEAK DETECTED" && \
         echo "$REPORT_CONTENT" | grep -q "RECOVERY: PROCESS TERMINATED SUCCESSFULLY"; then
          echo "✔ [30%] Reporte forense de incidentes validado estructuralmente en la bóveda de node03."
          PUNTOS=$((PUNTOS + 30))
      else
          echo "❌ [10%] El reporte existe en la bóveda pero la metadata o el formato no coinciden."
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo "❌ [0%] Incumplimiento: Falta el reporte técnico io_diagnostic_report.txt en node03."
  fi

  # ------------------------------------------------------------------------------
  # Métrica Global de Calificación
  # ------------------------------------------------------------------------------
  echo -e "\n======================================================="
  if [ $PUNTOS -eq 100 ]; then
      echo -e "🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m"
      echo -e "Excelente manejo forense de procesos distribuidos a nivel Pleno."
  else
      echo -e "⚠️  CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m"
      echo -e "Asegúrese de matar el proceso correcto con pkill/kill o verifique el contenido del reporte."
  fi
  echo "======================================================="
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh && rm -f /tmp/validador.sh
---

[[Laboratorios del LFCS]]
---
