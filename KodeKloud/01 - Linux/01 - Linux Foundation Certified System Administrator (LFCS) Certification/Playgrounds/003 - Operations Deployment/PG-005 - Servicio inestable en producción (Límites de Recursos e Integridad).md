---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-005
Titulo: Servicio inestable en producción (Límites de Recursos e Integridad)
Fecha de Inicio: 2026-06-03
Dificultad: 6/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Services
  - Logs
  - Verify Integrity and Availability
Competencias:
  - Modificar límites de recursos en Systemd (LimitNOFILE / ulimit)
  - Configurar políticas de reinicio estables (Restart, RestartSec, StartLimitIntervalSec)
  - Diagnosticar caídas intermitentes usando journalctl en tiempo real
Ticket: |-
  INC-1005

  Los usuarios reportan interrupciones intermitentes en la API de producción ("prod-api"). El servicio funciona por unos momentos y luego arroja errores de conexión antes de reiniciarse solo.

  Investigue los logs del sistema, identifique la causa del colapso intermitente (causa raíz de la falta de disponibilidad), ajuste las restricciones de recursos necesarias en la unidad de Systemd y estabilice el comportamiento del servicio.
Validacion:
  - Objetivo: Parámetro LimitNOFILE configurado en la unidad del servicio (mínimo 4096).
    Peso: 30 %
  - Objetivo: Configuración de políticas de reinicio de Systemd estabilizadas (RestartSec=5 o superior).
    Peso: 30 %
  - Objetivo: Servicio 'prod-api.service' activo, corriendo y estable (sin caídas recientes).
    Peso: 25 %
  - Objetivo: Evidencia de verificación guardada en /root/status_report.txt.
    Peso: 15 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # 1. Crear el binario de la API simulada que agota descriptores de archivos deliberadamente
  mkdir -p /opt/prod-api
  cat << 'API' > /opt/prod-api/api-engine
  #!/bin/bash
  echo "PROD-API Engine Iniciado..."
  declare -a fds
  # Bucle para abrir descriptores hasta reventar el límite por defecto (1024)
  for i in {1..1050}; do
      exec {fd}>/dev/null 2>/dev/null
      fds+=($fd)
      if [ $? -ne 0 ]; then
          echo "[$(date +'%T')] CRITICAL: Too many open files. Crash inminente." >&2
          exit 1
      fi
  done
  # Mantenerse vivo si no revienta (no llegará aquí debido al límite inicial)
  while true; do sleep 1; done
  API
  chmod 755 /opt/prod-api/api-engine

  # 2. Crear la unidad de servicio inestable (Se cae y se reinicia infinitamente al instante)
  cat << 'SER' > /etc/systemd/system/prod-api.service
  [Unit]
  Description=Production Core API Service
  After=network.target

  [Service]
  Type=simple
  ExecStart=/opt/prod-api/api-engine
  Restart=always
  RestartSec=0
  User=root

  [Install]
  WantedBy=multi-user.target
  SERVICE

  # 3. Cargar configuraciones y forzar el estado inestable
  systemctl daemon-reload
  systemctl enable --now prod-api.service

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🚀 ESCENARIO PG-005 CONFIGURADO - SERVICIO INESTABLE EN PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-1005\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Interrupciones intermitentes del servicio principal"
  echo -e " \e[1mSeveridad:\e[0m Crítica / Pérdida de Disponibilidad"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " El servicio 'prod-api.service' experimenta micro-caídas constantes."
  echo -e " Revise la causa raíz con 'journalctl -u prod-api.service -n 50' y observe"
  echo -e " el error que provoca la salida del proceso ejecutor."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Añadir 'LimitNOFILE=4096' (o superior) en la sección [Service] -> \e[1;35m30%\e[0m"
  echo -e "  [ ] Modificar 'RestartSec=5' (o superior) para dar respiro al OS   --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Mantener el servicio en estado operativo continuo (Running)   --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Guardar la salida de 'systemctl show' en /root/status_report.txt-> \e[1;35m15%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Modifique el archivo de la unidad, aplique daemon-reload y devuelva la estabilidad.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO DISPONIBILIDAD E INTEGRIDAD DEL SERVICIO ==="

  # 1. Validar si se aplicó el límite de descriptores de archivos en systemd
  LIMIT_NOFILE=$(systemctl show -p LimitNOFILE prod-api.service | cut -d= -f2)
  if [ "$LIMIT_NOFILE" != "infinity" ] && [ "$LIMIT_NOFILE" -ge 4096 ] 2>/dev/null; then
      echo "✔ [30%] Parámetro LimitNOFILE incrementado correctamente ($LIMIT_NOFILE)."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El servicio sigue limitado por el defecto del sistema (1024 o menor)."
  fi

  # 2. Validar si se configuró un tiempo de espera de reinicio prudente
  RESTART_SEC=$(systemctl show -p RestartUSec prod-api.service | cut -d= -f2)
  # 5 segundos = 5000000 microsegundos
  if [ "$RESTART_SEC" -ge 5000000 ] 2>/dev/null; then
      echo "✔ [30%] Configuración de RestartSec suavizada para mitigar bucles agresivos."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El RestartSec es demasiado bajo o inmediato (0s), estresando el sistema."
  fi

  # 3. Validar si el servicio está corriendo de forma estable
  if systemctl is-active --quiet prod-api.service; then
      # Doble verificación rápida para asegurar que no está en un ciclo continuo de muertes
      sleep 2
      if systemctl is-active --quiet prod-api.service; then
          echo "✔ [25%] El servicio 'prod-api.service' se encuentra activo y estable."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] El servicio está activo pero sigue cayéndose de manera intermitente."
      fi
  else
      echo "❌ [0%] El servicio 'prod-api.service' está caído o fallido."
  fi

  # 4. Validar el reporte técnico entregable
  if [ -f /root/status_report.txt ] && grep -q "prod-api.service" /root/status_report.txt; then
      echo "✔ [15%] Archivo de reporte generado con la información del estado de la unidad."
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ [0%] Falta generar el archivo /root/status_report.txt con el vuelco del servicio."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
