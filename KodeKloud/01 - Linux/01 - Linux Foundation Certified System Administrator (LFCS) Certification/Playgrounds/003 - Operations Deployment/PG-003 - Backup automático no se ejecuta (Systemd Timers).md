---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-003
Titulo: Backup automático no se ejecuta (Systemd Timers)
Fecha de Inicio: 2026-06-03
Dificultad: 4/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Services
  - Logs
  - Schedule Tasks
Competencias:
  - Configurar y diagnosticar Systemd Timers (.timer y .service)
  - Administrar permisos de ejecución en scripts automatizados
  - Analizar ejecuciones históricas con journalctl
Ticket: |-
  INC-1003

  El equipo de operaciones reporta que los respaldos automáticos diarios de la base de datos dejaron de generarse en la ruta habitual (/backup).

  Investigue la configuración de automatización del sistema, corrija el componente que impide el disparo de la tarea, y asegúrese de dejar el entorno programado operando correctamente de forma persistente.
Validacion:
  - Objetivo: La unidad 'db-backup.timer' está activa, habilitada y calendarizada.
    Peso: 35 %
  - Objetivo: La unidad 'db-backup.service' asociada ejecuta el script sin errores.
    Peso: 25 %
  - Objetivo: El script /usr/local/bin/backup-run.sh cuenta con los permisos de ejecución correctos.
    Peso: 20 %
  - Objetivo: Existe un archivo de respaldo válido generado en la ruta /backup/.
    Peso: 20 %
Calificacion Final: 25 %
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # 1. Crear estructura de almacenamiento
  mkdir -p /backup
  chown root:root /backup

  # 2. Crear el script de backup pero dejarlo SIN permisos de ejecución (Error 1)
  cat << 'BKP' > /usr/local/bin/backup-run.sh
  #!/bin/bash
  echo "[$(date)] Iniciando respaldo de base de datos..." >> /backup/backup.log
  tar -czf /backup/db_conf_$(date +%F).tar.gz /etc/hosts /etc/resolv.conf 2>/dev/null
  echo "[$(date)] Respaldo completado con éxito." >> /backup/backup.log
  BKP
  chmod 600 /usr/local/bin/backup-run.sh # Error: Solo lectura/escritura para root, no ejecutable

  # 3. Crear el servicio de systemd que llama al script
  cat << 'SER' > /etc/systemd/system/db-backup.service
  [Unit]
  Description=Run Database Automated Backup
  After=network.target

  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/backup-run.sh
  SER

  # 4. Crear el Timer con un error en la sección [Install] (Error 2) y dejarlo inactivo (Error 3)
  cat << 'TIM' > /etc/systemd/system/db-backup.timer
  [Unit]
  Description=Trigger Database Backup Daily

  [Timer]
  OnCalendar=*-*-* 02:00:00
  Persistent=true

  [Install]
  WantedBy=wrong-target.target
  TIM

  # 5. Cargar configuraciones y asegurar estado roto de los timers
  systemctl daemon-reload
  systemctl stop db-backup.timer 2>/dev/null || true
  systemctl disable db-backup.timer 2>/dev/null || true

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🚀 ESCENARIO PG-003 CONFIGURADO - TAREAS AUTOMÁTICAS CAÍDAS\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-1003\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Los respaldos diarios dejaron de ejecutarse"
  echo -e " \e[1mSeveridad:\e[0m Alta"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Se migró la tarea de backup de cron a systemd timers, pero desde entonces"
  echo -e " no se ha generado ningún respaldo en /backup. Investigue la cadena completa."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Unidad 'db-backup.timer' activa e instalada correctamente  --> \e[1;35m35%\e[0m"
  echo -e "  [ ] Unidad 'db-backup.service' funciona sin fallar           --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Script ejecutor cuenta con los permisos necesarios (chmod)--> \e[1;35m20%\e[0m"
  echo -e "  [ ] Existe al menos un respaldo .tar.gz válido en /backup/   --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Use 'systemctl list-timers', revise logs y restaure la automatización.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO AUTOMATIZACIÓN (SYSTEMD TIMERS) ==="

  # 1. Validar si el Timer está activo y corriendo
  if systemctl is-active --quiet db-backup.timer; then
      echo "✔ [35%] Systemd Timer 'db-backup.timer' se encuentra activo."
      PUNTOS=$((PUNTOS + 35))
  else
      echo "❌ [0%] El Timer está inactivo o no existe."
  fi

  # 2. Validar si el Timer está habilitado correctamente al arranque (Arreglado el wrong-target)
  if systemctl is-enabled --quiet db-backup.timer 2>/dev/null; then
      INSTALL_CHECK=$(grep "WantedBy=" /etc/systemd/system/db-backup.timer | cut -d= -f2)
      if [ "$INSTALL_CHECK" = "multi-user.target" ] || [ "$INSTALL_CHECK" = "timers.target" ]; then
          echo "✔ [20%] Timer habilitado de forma persistente para el arranque."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] El Timer está enabled pero apunta a un Target incorrecto."
      fi
  else
      echo "❌ [0%] El Timer está deshabilitado (disabled)."
  fi

  # 3. Validar permisos de ejecución del script
  if [ -x /usr/local/bin/backup-run.sh ]; then
      echo "✔ [20%] Script de respaldo cuenta con permisos de ejecución asignados."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El script no tiene permisos de ejecución (+x)."
  fi

  # 4. Validar ejecución exitosa y entregable en /backup
  if ls /backup/db_conf_*.tar.gz >/dev/null 2>&1; then
      echo "✔ [25%] Confirmada la existencia de respaldos comprimidos en /backup."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] No se encontraron archivos de respaldo generados en /backup/."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]

---
Today, I worked on fixing a critical automation issue where our daily database backups had stopped running. The team had recently migrated the backup job from cron to a systemd timer, but since then, no backups were being created in the `/backup` directory.

Here's what I did, step by step:

First, I investigated the systemd timer setup using `systemctl list-timers` and found that the `db-backup.timer` unit existed but was disabled and inactive. When I checked the timer configuration, I noticed it had an incorrect target in the install section (`WantedBy=wrong-target.target`), which prevented it from starting properly. I fixed that by changing it to the correct target (`timers.target`), reloaded systemd, and then started and enabled the timer so it would run automatically on boot.

Next, I looked at the backup service itself. The service was configured correctly, but when I checked the backup script at `/usr/local/bin/backup-run.sh`, I found it didn't have execute permissions—it was only readable by root. This meant systemd couldn't actually run it. I fixed this by setting the proper permissions with `chmod 755`, which allows the script to be executed.

After that, I manually triggered the service to test it, and it ran successfully. When I checked the `/backup` directory, I confirmed that a new backup file (`db_conf_2026-06-04.tar.gz`) was created along with an updated log file showing the backup completed successfully.

In summary, I restored the entire backup automation chain: I fixed the systemd timer configuration, enabled execute permissions on the backup script, verified the service runs without errors, and confirmed that backups are now being generated again. The system is now fully automated and will continue creating daily backups at 2 AM UTC without any manual intervention.