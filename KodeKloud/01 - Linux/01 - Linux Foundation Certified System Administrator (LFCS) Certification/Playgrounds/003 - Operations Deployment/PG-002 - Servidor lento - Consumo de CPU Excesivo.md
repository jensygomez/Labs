---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-002
Titulo: Servidor lento - Consumo de CPU Excesivo
Fecha de Inicio: 2026-06-03
Dificultad: 3/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Services
  - Logs
  - Processes
Competencias:
  - Gestionar procesos Linux (ps, top, kill)
  - Analizar consumo de recursos del sistema
  - Interpretar logs con journalctl
Ticket: |-
  INC-1002

  Los usuarios reportan una lentitud extrema en el servidor de aplicaciones. El acceso por SSH se siente pesado y los tiempos de respuesta son inaceptables.

  Investigue la causa raíz del consumo, elimine o controle el proceso infractor sin dar de baja el servicio legítimo "app-worker", y normalice el rendimiento del sistema.
Validacion:
  - Objetivo: El proceso infractor 'cpu-hog' ha sido terminado (killed).
    Peso: 30 %
  - Objetivo: El consumo total de CPU en el espacio de usuario se ha normalizado.
    Peso: 30 %
  - Objetivo: El servicio principal 'app-worker.service' sigue activo y ejecutándose.
    Peso: 20 %
  - Objetivo: Se ha generado el reporte de diagnóstico solicitado en /root/diagnostic.txt.
    Peso: 20 %
Calificacion Final: 50 %
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # 1. Crear el servicio legítimo
  cat << 'WORKER' > /usr/local/bin/app-worker
  #!/bin/bash
  echo "App Worker iniciada correctamente..."
  while true; do
      sleep 10
  done
  WORKER
  chmod 755 /usr/local/bin/app-worker

  cat << 'SERVICE' > /etc/systemd/system/app-worker.service
  [Unit]
  Description=Legitimate Application Worker
  After=network.target

  [Service]
  Type=simple
  ExecStart=/usr/local/bin/app-worker
  User=root
  Restart=always

  [Install]
  WantedBy=multi-user.target
  SERVICE

  systemctl daemon-reload
  systemctl enable --now app-worker.service

  # 2. Crear y lanzar el proceso infractor con consumo controlado (~60-80% CPU)
  cat << 'HOG' > /usr/local/bin/cpu-hog
  #!/bin/bash
  while true; do
      dd if=/dev/zero of=/dev/null bs=1M count=200 2>/dev/null
      sleep 0.05
  done
  HOG
  chmod 755 /usr/local/bin/cpu-hog

  # Lanzar el devorador de CPU en segundo plano desvinculado del shell
  nohup /usr/local/bin/cpu-hog >/dev/null 2>&1 &

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🚀 ESCENARIO PG-002 CONFIGURADO - EL SISTEMA SE SIENTE LENTO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-1002\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Lentitud general en el servidor"
  echo -e " \e[1mSeveridad:\e[0m Alta / Degradación de Servicio"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " El servidor web experimenta alta latencia. Los comandos tardan en responder."
  echo -e " El equipo de monitoreo indica que un núcleo de CPU está bajo estrés crítico."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Proceso infractor 'cpu-hog' terminado (pkill/kill)          --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Carga de CPU normalizada en el host                          --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Servicio 'app-worker.service' permanece Running              --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Guardar el PID del proceso infractor en /root/diagnostic.txt --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;31mADVERTENCIA:\e[0m No mates procesos bash indiscriminadamente."
  echo -e " \e[1;32mMisión:\e[0m Use 'top' o 'ps' para cazar el problema, elimínelo y salve el día.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash

  PUNTOS=0

  echo "=== EVALUANDO DIAGNÓSTICO DE PROCESOS ==="

  # 1. Validar si cpu-hog sigue vivo
  if ! pgrep -f "cpu-hog" > /dev/null; then
      echo "✔ [30%] Proceso infractor 'cpu-hog' mitigado con éxito."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El proceso 'cpu-hog' sigue activo consumiendo recursos."
  fi

  # 2. Validar consumo general de CPU — sin bc, usando awk para todo
  CPU_IDLE=$(top -bn2 | grep "Cpu(s)" | tail -1 | awk '{for(i=1;i<=NF;i++) if($i ~ /id,/) print $(i-1)}' | cut -d. -f1)
  CPU_USAGE=$((100 - CPU_IDLE))
  if [ "$CPU_IDLE" -gt 50 ]; then
      echo "✔ [30%] Consumo de CPU estabilizado (Carga actual: ~${CPU_USAGE}%)."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] La CPU sigue bajo estrés crítico (Carga actual: ~${CPU_USAGE}%)."
  fi

  # 3. Validar que app-worker siga vivo
  if systemctl is-active --quiet app-worker.service; then
      echo "✔ [20%] Servicio 'app-worker.service' a salvo y operativo."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El servicio legítimo 'app-worker.service' está caído."
  fi

  # 4. Validar entregable (El archivo de diagnóstico de auditoría)
  if [ -f /root/diagnostic.txt ] && [ -s /root/diagnostic.txt ]; then
      echo "✔ [20%] Archivo /root/diagnostic.txt creado con la evidencia."
      PUNTOS=$((PUNTOS + 20))
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]

---
The ticket was a classic degraded-performance scenario: a server running slow, SSH feeling heavy, one CPU core pegged at 100%. The mission was to identify the offending process, kill it without touching the legitimate app-worker.service, and leave a diagnostic report.

I opened top and immediately identified cpu-hog sitting at the top with the PID. Diagnosis was correct and fast. That part worked.

**Where it broke down.** I knew I needed `kill`, but I was guessing at the syntax — trying `--pid`, `--signal`, flags that don't exist. `kill` is one of the most minimal commands in Linux: `kill <PID>` sends SIGTERM, `kill -9 <PID>` sends SIGKILL. No long flags, no named options. I spent several minutes in `man kill` and `--help` loops instead of just running the two-word command. The platform eventually killed the process on its own, which gave me the CPU normalization points — but not because of anything I did.

I also had a typo in the diagnostic file: diagnosticc.txt instead of diagnostic.txt. The validator checks for the exact path — one extra character and that's 20 points gone. In production, a misnamed audit log is the same as no audit log.

**What I'm taking away.** Two things. First: know your kill signals cold — `kill <PID>`, `kill -9 <PID>`, `pkill -9 process-name`. No flags to look up, no man page needed under pressure. Second: when writing files as deliverables, double-check the filename before hitting enter. Tab completion exists for a reason.

50/100. The investigation was right. The execution failed on the simplest possible command. That's the most useful kind of failure — it points exactly at the gap to close.