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
Ticket: |-
  INC-2789

  El equipo de Data Engineering desplegó una nueva herramienta de sincronización interna llamada "data-sync".
  El servicio debe ejecutarse continuamente como parte del pipeline de datos crítico.

  Desde el despliegue, los sistemas de monitoreo (Prometheus + Alertmanager) están reportando que el servicio
  entra en estado "failed" constantemente. Los DBA y DEs necesitan que el servicio esté estable antes de 
  la ventana de mantenimiento de esta noche.

  Por favor, analice los logs, identifique todas las causas de fallo y deje el servicio en estado operativo.
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
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  # 1. Crear usuario de servicio dedicado
  useradd -r -s /sbin/nologin syncuser 2>/dev/null || true

  # 2. Crear estructura de logs con permisos incorrectos
  mkdir -p /var/log/data-sync
  chown root:root /var/log/data-sync
  chmod 755 /var/log/data-sync

  # 3. Crear script de sincronización con validaciones
  cat << 'APP' > /usr/local/bin/data-sync
  #!/bin/bash
  if [ "$(id -u)" -ne "$(id -u syncuser)" ]; then
      echo "ERROR: Este servicio debe ejecutarse como usuario syncuser" >&2
      exit 1
  fi

  if [ -z "$DATA_SYNC_DIR" ]; then
      echo "ERROR: Variable DATA_SYNC_DIR no configurada" >&2
      exit 1
  fi

  mkdir -p "$DATA_SYNC_DIR" 2>/dev/null || { echo "ERROR: No se puede crear directorio de trabajo" >&2; exit 1; }

  touch /var/log/data-sync/sync.log 2>/dev/null || { echo "ERROR: Sin permisos para escribir logs" >&2; exit 1; }

  while true; do
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Data synchronization cycle completed" >> /var/log/data-sync/sync.log
      sleep 8
  done
  APP
  chmod 755 /usr/local/bin/data-sync

  # 4. Crear unidad systemd con múltiples problemas
  cat << 'SERVICE' > /etc/systemd/system/data-sync.service
  [Unit]
  Description=Data Synchronization Service
  After=network.target

  [Service]
  Type=simple
  ExecStart=/usr/local/bin/data-sync
  User=root
  Restart=no
  # WorkingDirectory y Environment faltantes intencionalmente

  [Install]
  WantedBy=multi-user.target
  SERVICE

  # 5. Estado inicial roto
  systemctl daemon-reload
  systemctl stop data-sync.service 2>/dev/null || true
  systemctl disable data-sync.service 2>/dev/null || true

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔧 ESCENARIO PG-001-v2 CONFIGURADO - L2/L3 LEVEL\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET: INC-2789\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m data-sync.service fallando en producción"
  echo -e " \e[1mSeveridad:\e[0m Alta - Afecta pipeline crítico de datos"
  echo -e ""
  echo -e " \e[1mInstrucciones:\e[0m"
  echo -e " Analice con journalctl, identifique TODOS los problemas (usuario, permisos,"
  echo -e " variables de entorno, configuración de servicio) y deje el servicio estable."
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación (100%):\e[0m"
  echo -e "  [ ] Servicio running                                      → 30%"
  echo -e "  [ ] Enabled al boot                                       → 15%"
  echo -e "  [ ] Ejecutándose como syncuser                            → 20%"
  echo -e "  [ ] Logs escribiéndose en /var/log/data-sync/             → 20%"
  echo -e "  [ ] Restart=always + WorkingDirectory correcto            → 15%"
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

  echo "=== EVALUANDO data-sync.service - L2/L3 ==="

  # 1. Servicio activo
  if systemctl is-active --quiet data-sync.service; then
      echo "✔ [30%] Servicio en ejecución (running)"
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El servicio no está activo"
  fi

  # 2. Habilitado
  if systemctl is-enabled --quiet data-sync.service; then
      echo "✔ [15%] Servicio habilitado al arranque"
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ [0%] Servicio no está enabled"
  fi

  # 3. Usuario correcto
  USER_CHECK=$(systemctl show -p User data-sync.service | cut -d= -f2)
  if [ "$USER_CHECK" = "syncuser" ]; then
      echo "✔ [20%] Ejecutándose como usuario syncuser"
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Usuario incorrecto en la unidad"
  fi

  # 4. Logs y permisos
  if [ -d /var/log/data-sync ] && [ "$(stat -c '%U' /var/log/data-sync)" = "syncuser" ] && [ -f /var/log/data-sync/sync.log ]; then
      echo "✔ [20%] Logs y permisos correctos"
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Problemas de permisos en logs"
  fi

  # 5. Configuración avanzada
  if grep -q "Restart=always" /etc/systemd/system/data-sync.service && \
     grep -q "WorkingDirectory" /etc/systemd/system/data-sync.service; then
      echo "✔ [15%] Restart y WorkingDirectory configurados"
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ [0%] Falta Restart=always o WorkingDirectory"
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
