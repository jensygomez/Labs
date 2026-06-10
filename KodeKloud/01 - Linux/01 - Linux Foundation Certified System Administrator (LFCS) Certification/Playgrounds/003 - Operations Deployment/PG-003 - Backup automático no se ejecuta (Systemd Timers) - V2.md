---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-003-v2
Titulo: Backup automático no se ejecuta (Systemd Timers) - V2
Fecha de Inicio: 2026-06-05
Dificultad: 6/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Systemd Timers
  - Services (oneshot)
  - Permissions & Ownership
  - Journalctl & Troubleshooting
Competencias:
  - Diagnosticar y corregir fallos en cadenas completas de systemd timer + service
  - Gestionar usuarios de servicio y permisos en automatizaciones críticas
  - Verificar ejecución programada y persistencia
Validacion:
  - Objetivo: La unidad 'prod-db-backup.timer' está activa, habilitada y correctamente configurada
    Peso: 30 %
  - Objetivo: La unidad 'prod-db-backup.service' se ejecuta sin errores
    Peso: 25 %
  - Objetivo: El script de backup tiene permisos correctos y se ejecuta como usuario 'backupuser'
    Peso: 20 %
  - Objetivo: Se genera backup reciente en /var/backups/ y log sin errores de permisos
    Peso: 25 %
Script: |-
  cat << 'EOF' > /tmp/setup.sh

  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

  echo -e "\e[1;33m⏳ [node01 → node02] Creando entorno roto de Systemd Timers...\e[0m"

  # ── 1. Configuración del escenario roto en node02 ───────────────────────────
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_TARGET} "sudo bash -c '

      # Usuario dedicado para backups
      useradd -r -s /sbin/nologin backupuser 2>/dev/null || true

      # Directorio de backups con permisos incorrectos (backupuser no puede escribir)
      mkdir -p /var/backups
      chown root:root /var/backups
      chmod 700 /var/backups

      # Script de backup: sin permiso de ejecución + pequeño error deliberado
      cat << BKP > /usr/local/bin/prod-db-backup.sh
  #!/bin/bash
  echo \"[\$(date \"+%Y-%m-%d %H:%M:%S\")] === INICIO DE BACKUP DIARIO ===\" >> /var/backups/backup.log
  tar -czf /var/backups/prod_db_backup_\$(date +%F_%H%M).tar.gz /etc/hosts /etc/resolv.conf /etc/passwd 2>/dev/null || true
  echo \"[\$(date \"+%Y-%m-%d %H:%M:%S\")] Backup completado correctamente.\" >> /var/backups/backup.log
  BKP

      chmod 640 /usr/local/bin/prod-db-backup.sh

      # Servicio con problemas (falta User=backupuser)
      cat << SERVICE > /etc/systemd/system/prod-db-backup.service
  [Unit]
  Description=Production Database Daily Backup
  After=network.target

  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/prod-db-backup.sh
  User=root
  SERVICE

      # Timer con WantedBy incorrecto
      cat << TIMER > /etc/systemd/system/prod-db-backup.timer
  [Unit]
  Description=Daily Production Database Backup Timer

  [Timer]
  OnCalendar=*-*-* 03:00:00
  Persistent=true
  RandomizedDelaySec=300

  [Install]
  WantedBy=wrong.target
  TIMER

      systemctl daemon-reload
      systemctl stop prod-db-backup.timer 2>/dev/null || true
      systemctl disable prod-db-backup.timer 2>/dev/null || true
  '"

  echo -e "\e[1;33m⏳ [node01 → node03] Preparando bóveda de custodia de evidencias...\e[0m"

  # ── 2. Preparar bóveda en node03 ─────────────────────────────────────────────
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_VAULT} "sudo bash -c '
      rm -rf /opt/ops-compliance/*
      mkdir -p /opt/ops-compliance/
      chown -R bob:bob /opt/ops-compliance/
  '"

  clear

  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-3192  │  Severidad: CRÍTICA  │  Ambiente: PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  🕐 PG-003-MN — Backup Automático No Se Ejecuta (Systemd Timers)\e[0m"
  echo -e "\e[1;36m  Módulo: Operations & Deployment  │  Dificultad: 6/10  │  Nivel: L2/L3\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m     node02 (Servidor de Producción con Backups Rotos)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Repositorio de Custodia — \e[1;35m/opt/ops-compliance/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Desde que el equipo de infraestructura migró el sistema de backups de"
  echo -e "  \e[1mcron\e[0m a \e[1msystemd timers\e[0m, los respaldos diarios de la base de datos"
  echo -e "  \e[1mPostgreSQL\e[0m han dejado de ejecutarse. El equipo de DBA y SRE confirmó"
  echo -e "  la ausencia de archivos recientes en el directorio de destino."
  echo -e ""
  echo -e "  El RPO establecido es de 24 horas. Cada día sin backups amplía la"
  echo -e "  ventana de pérdida potencial de datos a niveles inaceptables para el"
  echo -e "  negocio y el cumplimiento normativo. Usted debe diagnosticar y corregir"
  echo -e "  la cadena completa de forma remota desde \e[1mnode01\e[0m."
  echo -e ""
  echo -e " \e[1mParámetros Técnicos Obligatorios (ejecutar remotamente desde node01):\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Corrección del Timer Systemd (Remoto en node02)\e[0m"
  echo -e "     El archivo '/etc/systemd/system/prod-db-backup.timer' tiene un"
  echo -e "     'WantedBy' incorrecto. Corrija la sección [Install] para que el"
  echo -e "     timer quede habilitado al boot bajo 'timers.target'."
  echo -e ""
  echo -e "  \e[1;31m2. Corrección del Service Systemd (Remoto en node02)\e[0m"
  echo -e "     El servicio corre como root en lugar del usuario dedicado."
  echo -e "     Cambie 'User=' a 'backupuser' en el archivo .service."
  echo -e ""
  echo -e "  \e[1;31m3. Permisos del Script y Directorio (Remoto en node02)\e[0m"
  echo -e "     El script '/usr/local/bin/prod-db-backup.sh' no tiene permiso de"
  echo -e "     ejecución. Corrija los permisos. Además, 'backupuser' debe poder"
  echo -e "     escribir en '/var/backups/' — ajuste owner y/o permisos."
  echo -e ""
  echo -e "  \e[1;31m4. Activación y Validación del Timer (Remoto en node02)\e[0m"
  echo -e "     Recargue el daemon, habilite y arranque el timer. Verifique con"
  echo -e "     'systemctl list-timers' y dispare manualmente el servicio para"
  echo -e "     confirmar que se genera el archivo de backup y el log es correcto."
  echo -e ""
  echo -e "  \e[1;31m5. Centralización de Evidencias (node02 → node03)\e[0m"
  echo -e "     Copie los archivos corregidos desde node02 hacia la bóveda en node03."
  echo -e "     Renómbrelos como:"
  echo -e "     - 'timer.evidence'   (prod-db-backup.timer)"
  echo -e "     - 'service.evidence' (prod-db-backup.service)"
  echo -e "     - 'backup.evidence'  (prod-db-backup.sh)"
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación Remota:\e[0m"
  echo -e "  [ ] Timer activo y habilitado correctamente al boot               --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Service ejecuta sin errores como backupuser                   --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Script ejecutable + /var/backups/ accesible por backupuser    --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Backup generado en /var/backups/ con log correcto             --> \e[1;35m25%\e[0m  (bonus)"
  echo -e "  [ ] Las 3 evidencias centralizadas en node03:/opt/ops-compliance/ --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m Use 'systemctl daemon-reload' tras cada edición remota."
  echo -e "               Diagnóstico: journalctl -u prod-db-backup.service -xe"
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

  NODE_TARGET="node02"
  NODE_VAULT="node03"
  USER_NET="bob"
  PASS="caleston123"
  VAULT_DIR="/opt/ops-compliance"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  AUDITORÍA DE RESTAURACIÓN — INC-3192 (Systemd Timers / PG-003-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # ── 1. Timer activo y habilitado correctamente ────────────────────────────────
  echo -e "\n\e[1;37m⏳ [1/5] Verificando estado del timer en node02...\e[0m"

  TIMER_ENABLED=$($SSH ${USER_NET}@${NODE_TARGET} \
      "systemctl is-enabled prod-db-backup.timer 2>/dev/null" || true)

  TIMER_ACTIVE=$($SSH ${USER_NET}@${NODE_TARGET} \
      "systemctl is-active prod-db-backup.timer 2>/dev/null" || true)

  TIMER_TARGET=$($SSH ${USER_NET}@${NODE_TARGET} \
      "grep 'WantedBy' /etc/systemd/system/prod-db-backup.timer 2>/dev/null" || true)

  if [ "$TIMER_ENABLED" = "enabled" ] && [ "$TIMER_ACTIVE" = "active" ] && echo "$TIMER_TARGET" | grep -q "timers.target"; then
      echo -e "\e[1;32m  ✔ [30%] Timer habilitado al boot (timers.target) y activo en node02.\e[0m"
      PUNTOS=$((PUNTOS + 30))
  else
      echo -e "\e[1;31m  ❌ [0%] El timer no está activo/habilitado o WantedBy sigue incorrecto.\e[0m"
      [ "$TIMER_ENABLED" != "enabled" ] && echo -e "       → is-enabled: \e[1;31m$TIMER_ENABLED\e[0m  (se espera: enabled)"
      [ "$TIMER_ACTIVE"  != "active"  ] && echo -e "       → is-active:  \e[1;31m$TIMER_ACTIVE\e[0m   (se espera: active)"
      echo "$TIMER_TARGET" | grep -qv "timers.target" && echo -e "       → WantedBy:   \e[1;31m$TIMER_TARGET\e[0m  (se espera: timers.target)"
  fi

  # ── 2. Service ejecuta sin errores como backupuser ────────────────────────────
  echo -e "\n\e[1;37m⏳ [2/5] Verificando configuración del service en node02...\e[0m"

  SERVICE_USER=$($SSH ${USER_NET}@${NODE_TARGET} \
      "grep '^User=' /etc/systemd/system/prod-db-backup.service 2>/dev/null" || true)

  $SSH ${USER_NET}@${NODE_TARGET} \
      "sudo systemctl start prod-db-backup.service" 2>/dev/null || true

  EXEC_STATUS=$($SSH ${USER_NET}@${NODE_TARGET} \
      "systemctl show prod-db-backup.service --property=ExecMainStatus 2>/dev/null | cut -d= -f2" || true)

  if echo "$SERVICE_USER" | grep -q "backupuser" && [ "$EXEC_STATUS" = "0" ]; then
      echo -e "\e[1;32m  ✔ [25%] Service configurado con User=backupuser y ejecuta sin errores.\e[0m"
      PUNTOS=$((PUNTOS + 25))
  else
      echo -e "\e[1;31m  ❌ [0%] El service tiene errores de usuario o falla al ejecutarse.\e[0m"
      echo "$SERVICE_USER" | grep -qv "backupuser" && echo -e "       → User actual: \e[1;31m$SERVICE_USER\e[0m  (se espera: User=backupuser)"
      [ "$EXEC_STATUS" != "0" ] && echo -e "       → ExecMainStatus: \e[1;31m$EXEC_STATUS\e[0m  (se espera: 0)"
      echo -e "       → Diagnóstico: ssh bob@node02 'journalctl -u prod-db-backup.service -n 20'"
  fi

  # ── 3. Permisos del script y acceso de backupuser a /var/backups/ ─────────────
  echo -e "\n\e[1;37m⏳ [3/5] Verificando permisos del script y directorio de backups en node02...\e[0m"

  SCRIPT_EXEC=$($SSH ${USER_NET}@${NODE_TARGET} \
      "test -x /usr/local/bin/prod-db-backup.sh && echo ok" 2>/dev/null || true)

  DIR_WRITABLE=$($SSH ${USER_NET}@${NODE_TARGET} \
      "sudo -u backupuser test -w /var/backups && echo ok" 2>/dev/null || true)

  if [ "$SCRIPT_EXEC" = "ok" ] && [ "$DIR_WRITABLE" = "ok" ]; then
      echo -e "\e[1;32m  ✔ [20%] Script tiene permiso +x y backupuser puede escribir en /var/backups/.\e[0m"
      PUNTOS=$((PUNTOS + 20))
  else
      echo -e "\e[1;31m  ❌ [0%] Problemas de permisos detectados en node02.\e[0m"
      [ "$SCRIPT_EXEC"  != "ok" ] && echo -e "       → /usr/local/bin/prod-db-backup.sh no tiene permiso de ejecución (+x)"
      [ "$DIR_WRITABLE" != "ok" ] && echo -e "       → backupuser no puede escribir en /var/backups/ — revise owner/chmod"
  fi

  # ── 4. Backup generado y log correcto en node02 ───────────────────────────────
  echo -e "\n\e[1;37m⏳ [4/5] Verificando generación de backup y log en node02...\e[0m"

  BACKUP_EXISTS=$($SSH ${USER_NET}@${NODE_TARGET} \
      "ls /var/backups/prod_db_backup_*.tar.gz 2>/dev/null | head -1" || true)

  LOG_OK=$($SSH ${USER_NET}@${NODE_TARGET} \
      "grep -c 'Backup completado correctamente' /var/backups/backup.log 2>/dev/null" || true)

  if [ -n "$BACKUP_EXISTS" ] && [ "${LOG_OK:-0}" -ge 1 ]; then
      echo -e "\e[1;32m  ✔ [25%] Archivo de backup generado y log registra ejecución exitosa.\e[0m"
      echo -e "         → Último backup: \e[1;37m$BACKUP_EXISTS\e[0m"
      PUNTOS=$((PUNTOS + 25))
  else
      echo -e "\e[1;31m  ❌ [0%] No se encontró archivo de backup o el log no registra éxito.\e[0m"
      [ -z "$BACKUP_EXISTS" ]  && echo -e "       → No existe ningún prod_db_backup_*.tar.gz en /var/backups/"
      [ "${LOG_OK:-0}" -lt 1 ] && echo -e "       → /var/backups/backup.log no contiene entrada de éxito"
      echo -e "       → Dispare manualmente: sshpass -p caleston123 ssh bob@node02 'sudo systemctl start prod-db-backup.service'"
  fi

  # ── 5. Evidencias centralizadas en node03 ─────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [5/5] Auditando custodia de evidencias en node03:$VAULT_DIR...\e[0m"

  EVIDENCE_CHECK=$($SSH ${USER_NET}@${NODE_VAULT} \
      "[ -f $VAULT_DIR/timer.evidence ] && \
       [ -f $VAULT_DIR/service.evidence ] && \
       [ -f $VAULT_DIR/backup.evidence ] && echo ok" 2>/dev/null || true)

  if [ "$EVIDENCE_CHECK" = "ok" ]; then
      echo -e "\e[1;32m  ✔ [20%] Las 3 evidencias centralizadas correctamente en node03.\e[0m"
      PUNTOS=$((PUNTOS + 20))
      [ $PUNTOS -gt 100 ] && PUNTOS=100
  else
      echo -e "\e[1;31m  ❌ [0%] Faltan archivos de evidencia en node03:$VAULT_DIR/\e[0m"
      echo -e "       → Se esperan: timer.evidence | service.evidence | backup.evidence"
  fi

  # ── Resultado Final ────────────────────────────────────────────────────────────
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
      echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — Cadena de backup restaurada con éxito."
  elif [ $PUNTOS -ge 55 ]; then
      echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los ❌."
  else
      echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Revise la cadena completa en node02."
  fi
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh
---

[[Laboratorios del LFCS]]
---
