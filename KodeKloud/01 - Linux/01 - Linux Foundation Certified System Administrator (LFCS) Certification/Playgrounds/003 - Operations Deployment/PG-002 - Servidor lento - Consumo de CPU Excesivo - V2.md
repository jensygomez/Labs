---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-002-v2
Titulo: Servidor lento - Consumo de CPU Excesivo - V2
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
Ticket: |-
  INC-2567

  Los usuarios y el equipo de aplicaciones reportan alta latencia en la plataforma de e-commerce.
  Prometheus alerta de CPU sostenida >85% en el nodo de aplicaciones durante los últimos 40 minutos.

  El servicio principal 'ecom-worker.service' debe continuar funcionando normalmente.
  Identifique el proceso causante del consumo excesivo, termínelo de forma controlada y genere
  un reporte de diagnóstico completo para el equipo de SRE.

  Nota: No reinicie el servidor ni use comandos que afecten el servicio legítimo.
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
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  # 1. Crear servicio legítimo de la aplicación
  cat << 'WORKER' > /usr/local/bin/ecom-worker
  #!/bin/bash
  echo "E-commerce Worker started successfully"
  while true; do
      sleep 12
  done
  WORKER
  chmod 755 /usr/local/bin/ecom-worker

  cat << 'SERVICE' > /etc/systemd/system/ecom-worker.service
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

  # 2. Crear proceso runaway (más realista y menos agresivo)
  cat << 'ROGUE' > /usr/local/bin/rogue-monitor
  #!/bin/bash
  # Simula un agente de monitoreo defectuoso con bucle CPU intensivo
  while true; do
      # Cálculo matemático simple pero constante (más estable que dd)
      for i in {1..10000}; do
          echo "scale=10; $i * 1.137 / 3.14159" | bc -l > /dev/null 2>&1
      done
      sleep 0.08
  done
  ROGUE
  chmod 755 /usr/local/bin/rogue-monitor

  # Lanzar el proceso rogue en background (simulando un agente mal desplegado)
  nohup /usr/local/bin/rogue-monitor >/dev/null 2>&1 &

  # Crear un segundo proceso ligero para añadir ruido
  nohup bash -c 'while true; do ps aux > /dev/null; sleep 2; done' >/dev/null 2>&1 &

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO PG-002-v2 CONFIGURADO - ALTO CONSUMO DE CPU\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET: INC-2567\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Consumo elevado sostenido de CPU en nodo de producción"
  echo -e " \e[1mSeveridad:\e[0m Alta - Degradación de servicio e-commerce"
  echo -e ""
  echo -e " \e[1mTarea:\e[0m"
  echo -e " Use top, ps, pidof, journalctl y herramientas de diagnóstico para identificar"
  echo -e " el proceso runaway, mátelo de forma limpia y documente todo."
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Proceso rogue-monitor detenido                          → 25%"
  echo -e "  [ ] CPU usage normalizada (<40% user space)                 → 25%"
  echo -e "  [ ] ecom-worker.service sigue running                       → 20%"
  echo -e "  [ ] Reporte completo en /root/cpu_diagnostic_report.txt     → 30%"
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

  echo "=== EVALUANDO DIAGNÓSTICO DE ALTO CONSUMO DE CPU - L2/L3 ==="

  # 1. Proceso rogue detenido
  if ! pgrep -f "rogue-monitor" > /dev/null; then
      echo "✔ [25%] Proceso infractor 'rogue-monitor' eliminado correctamente."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El proceso rogue-monitor sigue consumiendo CPU."
  fi

  # 2. Consumo de CPU normalizado (más tolerante)
  CPU_USAGE=$(top -bn2 | grep "^%Cpu" | tail -1 | awk '{print $2}' | cut -d. -f1)
  if [ "$CPU_USAGE" -lt 45 ]; then
      echo "✔ [25%] Consumo de CPU normalizado (~${CPU_USAGE}%)."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] Alto consumo de CPU persistente."
  fi

  # 3. Servicio legítimo activo
  if systemctl is-active --quiet ecom-worker.service; then
      echo "✔ [20%] Servicio ecom-worker.service operativo."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El servicio principal fue afectado."
  fi

  # 4. Reporte de diagnóstico
  REPORT="/root/cpu_diagnostic_report.txt"
  if [ -f "$REPORT" ] && [ -s "$REPORT" ] && grep -q "CPU" "$REPORT" && grep -q "rogue" "$REPORT" 2>/dev/null; then
      echo "✔ [30%] Reporte forense generado correctamente."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] Falta o incompleto el archivo /root/cpu_diagnostic_report.txt"
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
