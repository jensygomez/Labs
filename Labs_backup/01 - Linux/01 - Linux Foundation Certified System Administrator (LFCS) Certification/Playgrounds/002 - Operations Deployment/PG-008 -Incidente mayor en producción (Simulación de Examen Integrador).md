---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-008
Titulo: Incidente mayor en producción (Simulación de Examen Integrador)
Fecha de Inicio: 2026-06-03
Dificultad: 9/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Services
  - Logs
  - Processes
  - Schedule Tasks
  - Software and Repositories
  - Verify Integrity and Availability
  - Kernel Runtime Parameters
  - SELinux/AppArmor
  - Containers and VMs
Competencias:
  - Triage y resolución de incidentes complejos bajo presión
  - Orquestación combinada de Systemd, Podman, Firewalld y SELinux
  - Auditoría forense de infraestructura mediante logs correlacionados
Ticket: |-
  INC-9001

  Luego de una ventana de mantenimiento y actualización crítica en el servidor central, el sistema ha entrado en degradación severa. El equipo de monitoreo reporta los siguientes síntomas:
  1. El servicio local de procesamiento secundario no inicia.
  2. Los respaldos diarios automatizados han dejado de dispararse.
  3. El cortafuegos y las políticas AVC de SELinux registran denegaciones masivas.
  4. El contenedor web principal no responde a las solicitudes externas.

  Misión: Realice un diagnóstico estructurado, no desactive las directivas globales de seguridad, repare cada eslabón de la cadena y restaure la operación al 100%.
Validacion:
  - Objetivo: Restaurar servicio local (webcheck) bajo el usuario y permisos correctos.
    Peso: 20 %
  - Objetivo: Corregir y activar la programación del Timer de respaldos (db-backup).
    Peso: 15 %
  - Objetivo: Resolver restricciones de seguridad manteniendo SELinux en modo Enforcing.
    Peso: 20 %
  - Objetivo: Restaurar contenedor Podman con su volumen reetiquetado correctamente.
    Peso: 20 %
  - Objetivo: Corregir reglas de red (Firewalld) para exponer el servicio final.
    Peso: 15 %
  - Objetivo: Generar reporte forense final de la causa raíz en /root/incident_resolved.txt.
    Peso: 10 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # PREPARACIÓN DE ENTORNOS ROTOS

  # 1. Romper Servicio Local (Falta usuario y directorio de logs con permisos de Root)
  useradd -s /sbin/nologin webapp 2>/dev/null || true
  mkdir -p /var/log/webcheck
  chown -R root:root /var/log/webcheck
  cat << 'APP1' > /usr/local/bin/webcheck
  #!/bin/bash
  if [ "$USER" != "webapp" ]; then echo "Error: Debe ser webapp" >&2; exit 1; fi
  touch /var/log/webcheck/access.log 2>/dev/null || { echo "Error: Sin permisos en logs" >&2; exit 1; }
  while true; do sleep 5; done
  APP1
  chmod 755 /usr/local/bin/webcheck

  cat << 'SER1' > /etc/systemd/system/webcheck.service
  [Unit]
  Description=Webcheck Internal Application
  [Service]
  Type=simple
  ExecStart=/usr/local/bin/webcheck
  User=root
  SER

  # 2. Romper Tareas Programadas (Timer deshabilitado y apuntando a Target erróneo)
  mkdir -p /backup
  cat << 'BKP' > /usr/local/bin/backup-run.sh
  #!/bin/bash
  tar -czf /backup/db_$(date +%F).tar.gz /etc/hosts 2>/dev/null
  BKP
  chmod 600 /usr/local/bin/backup-run.sh # Sin permisos de ejecución

  cat << 'SER2' > /etc/systemd/system/db-backup.service
  [Unit]
  Description=Run Database Backup
  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/backup-run.sh
  SER

  cat << 'TIM' > /etc/systemd/system/db-backup.timer
  [Unit]
  Description=Trigger Backup
  [Timer]
  OnCalendar=*-*-* 02:00:00
  [Install]
  WantedBy=broken-target.target
  TIM

  # 3. Romper Contenedor, SELinux y Redes (Podman sin :Z y Firewall cerrado)
  dnf install -y podman firewalld 2>/dev/null || true
  systemctl enable --now firewalld
  mkdir -p /opt/web_data
  echo "Sistema Restaurado al 100%" > /opt/web_data/index.html
  chcon -t sshd_key_t /opt/web_data
  setenforce 1 2>/dev/null || true

  cat << 'SER3' > /etc/systemd/system/container-webapp.service
  [Unit]
  Description=Container WebApp
  [Service]
  ExecStartPre=-/usr/bin/podman rm -f webapp-container
  ExecStart=/usr/bin/podman run --name webapp-container -p 8080:8080 -v /opt/web_data:/var/www/html:ro registry.access.redhat.com/ubi9/nginx-120:latest
  Restart=always
  Type=simple
  [Install]
  WantedBy=multi-user.target
  SER

  firewall-cmd --permanent --remove-port=8080/tcp 2>/dev/null || true
  firewall-cmd --reload

  # Aplicar caos generalizado
  systemctl daemon-reload
  systemctl stop webcheck.service db-backup.timer container-webapp.service 2>/dev/null || true
  systemctl disable webcheck.service db-backup.timer container-webapp.service 2>/dev/null || true

  clear
  echo -e "\e[1;31m================================================================================\e[0m"
  echo -e "\e[1;37;41m 🔥 ALERTA CRÍTICA: INCIDENTE MAYOR EN PRODUCCIÓN (PG-008) 🔥 \e[0m"
  echo -e "\e[1;31m================================================================================\e[0m"
  echo -e " El servidor central ha fallado tras la ventana de mantenimiento."
  echo -e " Múltiples servicios cruzados están caídos o bloqueados por seguridad."
  echo -e ""
  echo -e " \e[1mTu misión es aplicar todo lo aprendido en los laboratorios anteriores:\e[0m"
  echo -e "  1. Estabilizar servicios locales y corregir permisos de logs."
  echo -e "  2. Reparar y activar timers de automatización."
  echo -e "  3. Solucionar contextos de SELinux sin degradar la seguridad."
  echo -e "  4. Exponer los contenedores web y autorizar el tráfico en firewalld."
  echo -e " ------------------------------------------------------------------------------"
  echo -e " Ejecute sus herramientas de diagnóstico y demuestre su nivel como Sysadmin."
  echo -e "\e[1;31m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUACIÓN DEL SIMULACRO GENERAL DE INCIDENTE (PG-008) ==="

  # 1. Validar Servicio Local (webcheck)
  USER_CHECK=$(systemctl show -p User webcheck.service | cut -d= -f2)
  if systemctl is-active --quiet webcheck.service && [ "$USER_CHECK" = "webapp" ] && [ "$(stat -c '%U' /var/log/webcheck)" = "webapp" ]; then
      echo "✔ [20%] Objetivo 1: Servicio local 'webcheck' operativo y seguro."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Objetivo 1: El servicio local está caído o mal configurado."
  fi

  # 2. Validar Programación (Timer)
  if systemctl is-active --quiet db-backup.timer && [ -x /usr/local/bin/backup-run.sh ]; then
      echo "✔ [15%] Objetivo 2: Automatización de respaldos reestablecida."
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ [0%] Objetivo 2: El Timer o los permisos del script de backup siguen rotos."
  fi

  # 3. Validar Seguridad (SELinux Enforcing)
  if getenforce | grep -q "Enforcing"; then
      echo "✔ [20%] Objetivo 3: Seguridad corporativa mantenida en modo Enforcing."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Objetivo 3: SELinux fue desactivado. Violación de directiva de seguridad."
  fi

  # 4. Validar Contenedor Podman
  if systemctl is-active --quiet container-webapp.service && grep -E "\/opt\/web_data.*:(ro,Z|Z,ro|Z)" /etc/systemd/system/container-webapp.service >/dev/null 2>&1; then
      echo "✔ [20%] Objetivo 4: Contenedor web restaurado con aislamiento de volumen correcto."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Objetivo 4: El contenedor falla debido al almacenamiento compartido."
  fi

  # 5. Validar Red/Firewall
  if firewall-cmd --permanent --list-ports | grep -q "8080/tcp" && curl -s --connect-timeout 2 http://localhost:8080 >/dev/null; then
      echo "✔ [15%] Objetivo 5: Puerto de red abierto y entrega de servicio verificada."
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ [0%] Objetivo 5: Tráfico de red bloqueado o la app web no responde."
  fi

  # 6. Validar Entregable de Auditoría
  if [ -f /root/incident_resolved.txt ] && [ -s /root/incident_resolved.txt ]; then
      echo "✔ [10%] Objetivo 6: Reporte técnico forense guardado con éxito."
      PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ [0%] Objetivo 6: Falta el reporte técnico final en /root/incident_resolved.txt."
  fi

  echo "=========================================="
  echo "CALIFICACIÓN FINAL INTEGRAL: $PUNTOS / 100"
  echo "=========================================="
---

[[Laboratorios del LFCS]]
---
