---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-001
Titulo: db-backup.service no inicia
Fecha de Inicio: 2026-06-03
Dificultad: 2/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Scripting
  - Services
  - Logs
Competencias:
  - Gestionar servicios systemd
  - Analizar logs con journalctl
  - Crear scripts Bash básicos
Ticket: |-
  INC-1024

  El equipo de DBA ha desplegado una nueva herramienta interna de respaldo automático llamada "db-backup".

  La aplicación debe ejecutarse de forma persistente como un servicio del sistema.

  Actualmente los sistemas de monitoreo reportan fallos críticos al arrancar la unidad.

  Investigue el problema y deje el servicio funcionando correctamente.
Validacion:
  - Objetivo: El servicio db-backup.service está activo y en ejecución (running)
    Peso: 35 %
  - Objetivo: El servicio está configurado para iniciar automáticamente tras el arranque (enabled).
    Peso: 20 %
  - Objetivo: El proceso del servicio es propiedad del usuario del sistema dbadmin.
    Peso: 20 %
  - Objetivo: Los logs de la aplicación se registran correctamente en la ruta designada sin errores de permisos.
    Peso: 25 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  # 1. Crear usuario y entorno
  useradd -s /sbin/nologin dbadmin 2>/dev/null || true
  mkdir -p /var/log/dbdata
  chown -R root:root /var/log/dbdata

  # 2. Crear binario mal configurado
  cat << 'APP' > /usr/local/bin/db-backup
  #!/bin/bash
  if [ "$USER" != "dbadmin" ]; then
      echo "Error: Este servicio SOLO debe ejecutarse como el usuario dbadmin" >&2
      exit 1
  fi
  touch /var/log/dbdata/backup.log 2>/dev/null || { echo "Error: Sin permisos para escribir en /var/log/dbdata/" >&2; exit 1; }
  while true; do
      echo "[$(date +'%Y-%m-%d %H:%M:%S')] Database backup process idle..." >> /var/log/dbdata/backup.log
      sleep 5
  done
  APP
  chmod 755 /usr/local/bin/db-backup

  # 3. Crear servicio systemd con errores
  cat << 'SERVICE' > /etc/systemd/system/db-backup.service
  [Unit]
  Description=Database Automated Backup Service
  After=network.target

  [Service]
  Type=simple
  ExecStart=/usr/local/bin/db-backup
  User=root
  Restart=no

  [Install]
  WantedBy=multi-user.target
  SERVICE

  # 4. Aplicar cambios y asegurar estado roto
  systemctl daemon-reload
  systemctl stop db-backup.service 2>/dev/null || true
  systemctl disable db-backup.service 2>/dev/null || true

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ESCENARIO PG-001 (VARIACIÓN) CONFIGURADO CORRECTAMENTE\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-1024\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m db-backup.service no inicia"
  echo -e " \e[1mSeveridad:\e[0m Alta"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " El equipo de DBA ha entregado una nueva aplicación interna llamada"
  echo -e " \"db-backup\". La aplicación debe ejecutarse como servicio del sistema."
  echo -e " Actualmente los sistemas de monitoreo reportan fallos críticos al arrancar."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Servicio 'db-backup.service' activo y en ejecución (running) --> \e[1;35m35%\e[0m"
  echo -e "  [ ] Servicio configurado para iniciar tras el arranque (enabled) --> \e[1;35m20%\e[0m"
  echo -e "  [ ] El proceso del servicio debe ser propiedad del usuario 'dbadmin'-> \e[1;35m20%\e[0m"
  echo -e "  [ ] Logs registrándose correctamente sin errores de permisos     --> \e[1;35m25%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;31mMisión:\e[0m Investigue el problema usando journalctl, arregle y deje todo operativo."
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup.sh && rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO TU TRABAJO ==?"

  # Validación 1: ¿Está activo?
  if systemctl is-active --quiet db-backup.service; then
      echo "✔ [35%] Servicio activo y en ejecución."
      PUNTOS=$((PUNTOS + 35))
  else
      echo "❌ [0%] El servicio no está corriendo."
  fi

  # Validación 2: ¿Está habilitado?
  if systemctl is-enabled --quiet db-backup.service; then
      echo "✔ [20%] Servicio habilitado al arranque."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El servicio está disabled."
  fi

  # Validación 3: ¿El usuario es dbadmin?
  USER_CHECK=$(systemctl show -p User db-backup.service | cut -d= -f2)
  if [ "$USER_CHECK" = "dbadmin" ]; then
      echo "✔ [20%] Configurado correctamente para el usuario dbadmin."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El servicio sigue configurado como root u otro usuario."
  fi

  # Validación 4: ¿El directorio de logs es del usuario dbadmin?
  if [ -d /var/log/dbdata ] && [ "$(stat -c '%U' /var/log/dbdata)" = "dbadmin" ]; then
      echo "✔ [25%] Permisos de logs corregidos."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] Error de permisos en el directorio de logs."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]

---
