---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-001-v2
Titulo: db-backup.service no inicia - V2
Fecha de Inicio: 2026-06-05
Dificultad: 4/10
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
Validacion:
  - Objetivo: El servicio data-sync.service está activo y en ejecución (running)
    Peso: 30 %
  - Objetivo: El servicio está configurado para iniciar automáticamente (enabled)
    Peso: 15 %
  - Objetivo: El proceso se ejecuta bajo el usuario dedicado 'syncuser'
    Peso: 20 %
  - Objetivo: Los logs se escriben correctamente en /var/log/data-sync/ sin errores de permisos
    Peso: 20 %
  - Objetivo: El servicio tiene Restart=always y WorkingDirectory configurado correctamente
    Peso: 15 %
Calificacion Final: 100 %
Script: |-
  cat << 'EOF' > /tmp/setup_sh

  #!/bin/bash
  set -e

  # Variables de Red del Playground (Usuario bob / Contraseña caleston123 nativa)
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

  echo -e "\e[1;33m⏳ Desplegando e inyectando fallos de Systemd y Permisos en node02...\e[0m"

  # 1. Configuración del escenario roto de forma remota en node02
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_TARGET} "sudo bash -c '
      # Crear usuario de servicio dedicado si no existe
      useradd -r -s /sbin/nologin syncuser 2>/dev/null || true

      # Forzar estado inicial corrupto en el sistema de archivos de logs
      rm -rf /var/log/data-sync
      mkdir -p /var/log/data-sync
      chown root:root /var/log/data-sync
      chmod 755 /var/log/data-sync

      # Inyección del script de sincronización con validaciones estrictas
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

      # Inyección de Unidad de Systemd con trampas de ingeniería
      cat << \"SERVICE\" > /etc/systemd/system/data-sync.service
  [Unit]
  Description=Data Synchronization Service
  After=network.target

  [Service]
  Type=simple
  ExecStart=/usr/local/bin/data-sync
  User=root
  Restart=no
  # WorkingDirectory y Environment faltantes intencionalmente para causar fallos lógicos

  [Install]
  WantedBy=multi-user.target
  SERVICE

      # Aplicar cambios y forzar el estado fallido (failed)
      systemctl daemon-reload
      systemctl stop data-sync.service 2>/dev/null || true
      systemctl disable data-sync.service 2>/dev/null || true
  '"

  # 2. Preparación y limpieza de la Bóveda de Resguardos en node03
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_VAULT} "sudo rm -rf /opt/backup-vault/* && sudo mkdir -p /opt/backup-vault/ && sudo chown -R bob:bob /opt/backup-vault/"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-2789  │  Severidad: ALTA  │  AMBIENTE: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  echo -e "  El equipo de Data Engineering desplegó recientemente un nuevo servicio"
  echo -e "  denominado \e[1mdata-sync\e[0m en el servidor de producción \e[1mnode02\e[0m."
  echo ""
  echo -e "  Desde su implementación, las alertas de Prometheus indican que la unidad"
  echo -e "  entra en estado \e[1;31mfailed\e[0m de forma continua. Al operar de forma remota"
  echo -e "  desde \e[1mnode01\e[0m, debe resolver la totalidad de las causas raíz del fallo."
  echo ""
  echo -e " \e[1mUbicaciones del Clúster:\e[0m"
  echo -e "  - \e[1;35mnode01\e[0m: Tu estación central de control administrativo (usuario \e[1;32mbob\e[0m)."
  echo -e "  - \e[1;35mnode02\e[0m: Servidor objetivo con la unidad Systemd degradada."
  echo -e "  - \e[1;35mnode03\e[0m: Bóveda de Gobernancia (\e[1;33m/opt/backup-vault/\e[0m) para resguardo del binario."
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  PARÁMETROS TÉCNICOS EXIGIDOS (A RESOLVER VÍA COMANDOS REMOTOS)\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "  \e[1;31m1.\e[0m Corrija los permisos de la estructura de logs en \e[1mnode02\e[0m (\e[1m/var/log/data-sync/\e[0m)"
  echo -e "     para que el usuario sin privilegios pueda escribir de manera persistente."
  echo ""
  echo -e "  \e[1;31m2.\e[0m Reconfigure la unidad \e[1m/etc/systemd/system/data-sync.service\e[0m en \e[1mnode02\e[0m:"
  echo -e "     - Debe ejecutarse bajo el usuario del sistema: \e[1msyncuser\e[0m."
  echo -e "     - Inyecte la variable de entorno obligatoria: \e[1mDATA_SYNC_DIR=/var/run/data-sync/work\e[0m"
  echo -e "     - Defina el directorio de trabajo: \e[1mWorkingDirectory=/var/run/data-sync\e[0m"
  echo -e "     - Asegure la resiliencia agregando la directiva de reinicio automático: \e[1mRestart=always\e[0m"
  echo ""
  echo -e "  \e[1;31m3.\e[0m Estabilice el servicio: recargue el demonio, inicie la unidad y déjela"
  echo -e "     habilitada para persistir tras reinicios del sistema (\e[1menabled\e[0m)."
  echo ""
  echo -e "  \e[1;31m4.\e[0m Resguardo de Infraestructura como Código: Transfiera una copia del script"
  echo -e "     funcional corregido desde \e[1mnode02:/usr/local/bin/data-sync\e[0m hacia la ruta"
  echo -e "     segura de la bóveda en \e[1mnode03:/opt/backup-vault/data-sync.bak\e[0m."
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN & CONFIGURACIÓN DE CRÉDITOS\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "   [ ] Servicio data-sync activo (running) en node02                    \e[0;32m→ 30%\e[0m"
  echo -e "   [ ] Unidad habilitada (enabled) al arranque en node02               \e[0;32m→ 15%\e[0m"
  echo -e "   [ ] Control de proceso bajo 'syncuser' y directivas de reinicio      \e[0;32m→ 20%\e[0m"
  echo -e "   [ ] Escritura exitosa de logs funcionales en node02                  \e[0;32m→ 15%\e[0m"
  echo -e "   [ ] Copia de respaldo verificada e íntegra en la bóveda de node03    \e[0;32m→ 20%\e[0m"
  echo "--------------------------------------------------------------------------------"
  echo -e "  \e[1;32mCredenciales de Autenticación:\e[0m Usuario: \e[1mbob\e[0m | Clave: \e[1mcaleston123\e[0m"
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
  # VALIDADOR AUTOMATIZADO MULTI-NODO — TICKET INC-2789
  # Ejecutar desde: node01
  # =============================================================================

  PUNTOS=0
  USER="bob"
  PASS="caleston123"
  TARGET_NODE="node02"
  VAULT_NODE="node03"

  # Alias de comandos remotos seguros con sshpass
  SSH2="sshpass -p $PASS ssh -o StrictHostKeyChecking=no ${USER}@${TARGET_NODE}"
  SSH3="sshpass -p $PASS ssh -o StrictHostKeyChecking=no ${USER}@${VAULT_NODE}"

  # Asegurar disponibilidad de sshpass de forma silenciosa
  if ! command -v sshpass &>/dev/null; then
      sudo yum install -y sshpass -q >/dev/null 2>&1 || sudo apt-get install -y sshpass -y >/dev/null 2>&1
  fi

  echo -e "\n=== 🕵️  AUDITANDO UNIDADES SYSTEMD DISTRIBUIDAS DESDE NODE01 ==="
  echo "⏳ Conectando a $TARGET_NODE para evaluar el daemon de telemetría..."

  # ------------------------------------------------------------------------------
  # 1. Validar estado ACTIVO (running) en node02
  # ------------------------------------------------------------------------------
  IS_ACTIVE=$($SSH2 "systemctl is-active data-sync.service" 2>/dev/null || true)
  if [ "$IS_ACTIVE" = "active" ]; then
      echo "✔ [30%] Estado del servicio verificado en $TARGET_NODE: active (running)."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El servicio data-sync.service está inactivo o en estado failed en $TARGET_NODE."
  fi

  # ------------------------------------------------------------------------------
  # 2. Validar estado HABILITADO (enabled) al arranque en node02
  # ------------------------------------------------------------------------------
  IS_ENABLED=$($SSH2 "systemctl is-enabled data-sync.service" 2>/dev/null || true)
  if [ "$IS_ENABLED" = "enabled" ]; then
      echo "✔ [15%] Persistencia de arranque validada en $TARGET_NODE: servicio enabled."
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ [0%] El servicio no está habilitado para iniciar tras reinicios en $TARGET_NODE."
  fi

  # ------------------------------------------------------------------------------
  # 3. Validar identidad operativa (syncuser) y directivas en la unidad
  # ------------------------------------------------------------------------------
  SERVICE_USER=$($SSH2 "systemctl show -p User data-sync.service" 2>/dev/null || true)
  RESTART_RULE=$($SSH2 "systemctl show -p Restart data-sync.service" 2>/dev/null || true)
  WORK_DIR=$($SSH2 "systemctl show -p WorkingDirectory data-sync.service" 2>/dev/null || true)

  if echo "$SERVICE_USER" | grep -q "syncuser" && \
     echo "$RESTART_RULE" | grep -q "always" && \
     echo "$WORK_DIR" | grep -q "data-sync"; then
      echo "✔ [20%] Hardening e ingeniería de resiliencia validados en la unidad Systemd de $TARGET_NODE."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] La unidad retiene fallas de configuración de usuario, directivas de reinicio o WorkingDirectory."
  fi

  # ------------------------------------------------------------------------------
  # 4. Validar escritura efectiva de logs e inyección de variables
  # ------------------------------------------------------------------------------
  if $SSH2 "sudo test -f /var/log/data-sync/sync.log" 2>/dev/null; then
      LOG_USER=$($SSH2 "sudo stat -c '%U' /var/log/data-sync/sync.log" 2>/dev/null || true)
      LOG_SAMPLE=$($SSH2 "sudo tail -n 1 /var/log/data-sync/sync.log" 2>/dev/null || true)
      
      if [ "$LOG_USER" = "syncuser" ] && echo "$LOG_SAMPLE" | grep -q "Data synchronization cycle completed"; then
          echo "✔ [15%] Rotación e inyección de logs funcionales bajo el propietario correcto en $TARGET_NODE."
          PUNTOS=$((PUNTOS + 15))
      else
          echo "❌ [0%] Archivo de logs localizado pero no registra el formato del ciclo o el propietario está corrupto."
      fi
  else
      echo "❌ [0%] El servicio no ha podido generar ni escribir en /var/log/data-sync/sync.log en $TARGET_NODE."
  fi

  # ------------------------------------------------------------------------------
  # 5. Validar existencia y replicación del resguardo en la Bóveda (node03)
  # ------------------------------------------------------------------------------
  echo "⏳ Conectando a $VAULT_NODE para verificar custodia del código de infraestructura..."
  if $SSH3 "test -f /opt/backup-vault/data-sync.bak" 2>/dev/null; then
      BAK_CONTENT=$($SSH3 "cat /opt/backup-vault/data-sync.bak" 2>/dev/null || true)
      if echo "$BAK_CONTENT" | grep -q "syncuser" && echo "$BAK_CONTENT" | grep -q "DATA_SYNC_DIR"; then
          echo "✔ [20%] Custodia de versiones: Copia íntegra de data-sync localizada de forma segura en $VAULT_NODE."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [5%] El archivo de backup existe en $VAULT_NODE pero su estructura interna está corrupta."
          PUNTOS=$((PUNTOS + 5))
      fi
  else
      echo "❌ [0%] Incumplimiento forense: No se localizó el resguardo en /opt/backup-vault/data-sync.bak dentro de $VAULT_NODE."
  fi

  # ------------------------------------------------------------------------------
  # Métrica y Calificación Final
  # ------------------------------------------------------------------------------
  echo -e "\n======================================================="
  if [ $PUNTOS -eq 100 ]; then
      echo -e "🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m"
      echo -e "Excelente desempeño. Dominas la gestión remota de Daemons de Systemd."
  else
      echo -e "⚠️  CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m"
      echo -e "Inspeccione las directivas de entorno de Systemd o los permisos de red hacia la bóveda."
  fi
  echo "======================================================="
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh && rm -f /tmp/validador.sh
---

[[Laboratorios del LFCS]]
---
