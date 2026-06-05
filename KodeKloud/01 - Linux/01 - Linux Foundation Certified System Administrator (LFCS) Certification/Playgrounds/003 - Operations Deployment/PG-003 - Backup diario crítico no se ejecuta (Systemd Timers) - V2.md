---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-003-v2
Titulo: Backup diario crítico no se ejecuta (Systemd Timers)
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

Ticket: |-
  INC-3192

  El equipo de DBA y SRE reporta que los backups diarios completos de la base de datos PostgreSQL
  han dejado de generarse desde la migración de cron a systemd timers.

  Esto está afectando la estrategia de recuperación ante desastres (RPO de 24h). 
  El servicio crítico 'prod-db-backup.timer' debe ejecutarse diariamente a las 03:00 AM.

  Por favor, realice un diagnóstico completo, corrija todos los problemas encontrados en la cadena
  (timer, service, script y permisos) y verifique que los backups se generen correctamente.

Validacion:
  - Objetivo: La unidad 'prod-db-backup.timer' está activa, habilitada y correctamente configurada
    Peso: 30 %
  - Objetivo: La unidad 'prod-db-backup.service' se ejecuta sin errores
    Peso: 25 %
  - Objetivo: El script de backup tiene permisos correctos y se ejecuta como usuario 'backupuser'
    Peso: 20 %
  - Objetivo: Se genera backup reciente en /var/backups/ y log sin errores de permisos
    Peso: 25 %

Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  # Crear usuario dedicado para backups
  useradd -r -s /sbin/nologin backupuser 2>/dev/null || true

  # Estructura de backups con permisos incorrectos
  mkdir -p /var/backups
  chown root:root /var/backups
  chmod 700 /var/backups

  # Script de backup (sin permisos de ejecución + pequeño error)
  cat << 'BKP' > /usr/local/bin/prod-db-backup.sh
  #!/bin/bash
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] === INICIO DE BACKUP DIARIO ===" >> /var/backups/backup.log

  # Simulación de backup PostgreSQL (copiando configs críticas)
  tar -czf /var/backups/prod_db_backup_$(date +%F_%H%M).tar.gz /etc/postgresql /etc/hosts /etc/resolv.conf 2>/dev/null || true

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completado correctamente." >> /var/backups/backup.log
  BKP

  chmod 640 /usr/local/bin/prod-db-backup.sh   # Error: sin +x

  # Servicio con problemas
  cat << 'SERVICE' > /etc/systemd/system/prod-db-backup.service
  [Unit]
  Description=Production Database Daily Backup
  After=network.target

  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/prod-db-backup.sh
  User=root
  # Falta WorkingDirectory y Environment
  SERVICE

  # Timer con múltiples errores
  cat << 'TIMER' > /etc/systemd/system/prod-db-backup.timer
  [Unit]
  Description=Daily Production Database Backup Timer

  [Timer]
  OnCalendar=*-*-* 03:00:00
  Persistent=true
  RandomizedDelaySec=300

  [Install]
  WantedBy=wrong.target
  TIMER

  # Estado inicial roto
  systemctl daemon-reload
  systemctl stop prod-db-backup.timer 2>/dev/null || true
  systemctl disable prod-db-backup.timer 2>/dev/null || true

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🛠️  ESCENARIO PG-003-v2 CONFIGURADO - BACKUPS CRÍTICOS CAÍDOS\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET: INC-3192\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Backups diarios PostgreSQL no se están ejecutando"
  echo -e " \e[1mSeveridad:\e[0m Crítica - Impacto en DR y cumplimiento"
  echo -e ""
  echo -e " \e[1mTarea L2/L3:\e[0m"
  echo -e " Diagnostique con journalctl, list-timers, status, permisos y ownership."
  echo -e " Corrija timer, service, script y permisos del filesystem."
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Timer activo + enabled correctamente                          → 30%"
  echo -e "  [ ] Service ejecuta sin errores                                    → 25%"
  echo -e "  [ ] Script con permisos + running como backupuser                 → 20%"
  echo -e "  [ ] Backup generado en /var/backups/ + logs correctos             → 25%"
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup.sh && rm -f /tmp/setup.sh

tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO SYSTEMD TIMERS - L2/L3 ==="

  # 1. Timer activo y habilitado correctamente
  if systemctl is-active --quiet prod-db-backup.timer && systemctl is-enabled --quiet prod-db-backup.timer; then
      echo "✔ [30%] Timer 'prod-db-backup.timer' activo y habilitado."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] Timer no está activo o habilitado correctamente."
  fi

  # 2. Servicio funciona
  if systemctl is-active --quiet prod-db-backup.service || journalctl -u prod-db-backup.service -n 10 2>/dev/null | grep -q "Backup completado"; then
      echo "✔ [25%] Service 'prod-db-backup.service' ejecutado sin errores."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El service tiene errores de ejecución."
  fi

  # 3. Permisos y usuario
  if [ -x /usr/local/bin/prod-db-backup.sh ] && [ "$(stat -c '%U' /var/backups)" = "backupuser" ]; then
      echo "✔ [20%] Permisos y ownership correctos (backupuser)."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Problemas de permisos o usuario en script/directorio."
  fi

  # 4. Backup generado
  if ls /var/backups/prod_db_backup_*.tar.gz >/dev/null 2>&1 && [ -s /var/backups/backup.log ]; then
      echo "✔ [25%] Backup generado correctamente en /var/backups/."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] No se encontró backup reciente."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
