---
Curso: Transición Sysadmin a DevOps - Operations Deployment LFCS/RHCSA
Modulo: Operations Deployment (Diagnóstico de Procesos y Gestión de Servicios)
Playground: OD-002
Titulo: El Servicio Zombi – Diagnóstico de Procesos y Creación de Units systemd
Fecha de Inicio: 2026-06-16
Dificultad: 7.0/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Diagnose and Manage Processes (ps, top, kill, pkill, systemctl kill)
  - Create and Configure systemd Services (.service files, ExecStart, Restart policies)
  - Manage Startup Process and Services (systemctl enable, start, status)
  - Refresco: Ejecución remota y pipeline de datos (node01 -> node02 -> node03)
Competencias: |-
  - Identificar procesos huérfanos, zombis o bloqueados utilizando herramientas de diagnóstico y terminarlos de forma segura y controlada.
  - Diseñar y desplegar un archivo de unidad systemd (.service) desde cero, reemplazando scripts de inicio obsoletos o hacks manuales.
  - Configurar directivas de resiliencia en systemd (ej. Restart=on-failure, RestartSec) para garantizar la alta disponibilidad de la aplicación.
  - Validar el estado del servicio y enviar la evidencia de diagnóstico y configuración a node03 vía pipeline SSH, sin materializar archivos en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_od002.sh

  #!/bin/bash
  set -e

  PASS="caleston123"
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT}"

  echo -e "\e[1;33m⏳ Verificando sshpass en node01...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      echo caleston123 | sudo -S apt-get install -y sshpass -qq
  fi

  echo -e "\e[1;33m⏳ Instalando sshpass en nodos remotos...\e[0m"
  $SSH2 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"
  $SSH3 "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Inyectando escenario de procesos huérfanos en node02...\e[0m"
  # NOTA CRÍTICA PARA INCIDENTES FUTUROS:
  # Cuando inyectes comandos multi-línea vía SSH desde un script heredado (cat << 'EOF'),
  # NO usares 'bash -c "..."` con comillas dobles escRpadas, porque el escaping se rompe
  # cuando el script está dentro de un heredoc con comillas simples (OUTEREOF).
  #
  # SOLUCIÓN: Usa 'bash << 'INNEREOF' ... INNEREOF' (heredoc por stdin)
  # - El heredoc se pasa directo a sudo --stdin bash
  # - Dentro del heredoc, usa comillas simples para evitar escaping
  # - Esta técnica funciona tanto manualmente como desde scripts
  #
  # Ejemplo correcto:
  #   $SSH2 "echo PASS | sudo --stdin bash << 'INNEREOF'
  #       comando multi-línea
  #       más comandos
  #   INNEREOF"
  $SSH2 "echo caleston123 | sudo --stdin bash << 'INNEREOF'
      mkdir -p /opt/data-processor

      printf '#!/bin/bash\nwhile true; do sleep 120; done\n' > /opt/data-processor/worker.sh
      chmod +x /opt/data-processor/worker.sh

      pkill -f worker.sh 2>/dev/null || true

      setsid /opt/data-processor/worker.sh </dev/null >/dev/null 2>&1 &
      setsid /opt/data-processor/worker.sh </dev/null >/dev/null 2>&1 &
      setsid /opt/data-processor/worker.sh </dev/null >/dev/null 2>&1 &

      echo '[OD-002] Procesos inyectados correctamente.'
      exit 0
  INNEREOF" || echo -e "\e[1;33m  [!] Advertencia: La inyección en node02 tuvo un detalle, pero continuamos.\e[0m"

  echo -e "\e[1;33m⏳ Preparando bóveda en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/od-002/
      mkdir -p /opt/ops-compliance/od-002/
      chown -R bob:bob /opt/ops-compliance/od-002/
      chmod 750 /opt/ops-compliance/od-002/
      exit 0
  '" || echo -e "\e[1;33m  [!] Advertencia: La preparación de node03 tuvo un detalle, pero continuamos.\e[0m"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m OD-002-v1 | El Servicio Zombi | Dificultad: 7.0/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/od-002/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El equipo de monitoreo ha reportado un consumo anómalo de memoria y CPU"
  echo -e " en node02. La investigación revela que una aplicación crítica de procesamiento"
  echo -e " de datos ('data-processor') se está cerrando inesperadamente, dejando"
  echo -e " procesos huérfanos o 'zombis' que consumen recursos sin realizar trabajo útil."
  echo -e ""
  echo -e " Al revisar el servidor, se descubrió que el método de arranque actual es un"
  echo -e " 'hack' obsoleto: un script ejecutado manualmente en segundo plano o vía cron,"
  echo -e " sin ninguna gestión de ciclo de vida, sin logs centralizados y, lo que es"
  echo -e " peor, sin capacidad de reinicio automático ante fallos."
  echo -e ""
  echo -e " Se le asigna esta incidencia como ingeniero de turno. Su misión es limpiar"
  echo -e " el estado actual del sistema, erradicar el método de arranque obsoleto y"
  echo -e " desplegar una solución profesional basada en systemd que garantice la"
  echo -e " resiliencia y la observabilidad del servicio."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01 vía SSH."
  echo -e " \e[1m>\e[0m No se permite materializar archivos intermedios o scripts de diagnóstico en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente de node02 hacia node03 mediante pipeline."
  echo -e ""
  echo -e "\e[1;33m PROCEDIMIENTO REQUERIDO\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " 1. Diagnóstico y Limpieza:"
  echo -e "    - Identificar los procesos huérfanos/residuales asociados a la aplicación."
  echo -e "    - Terminar dichos procesos de forma controlada y segura."
  echo -e ""
  echo -e " 2. Ingeniería del Servicio (systemd):"
  echo -e "    - Crear un archivo de unidad personalizado (.service) en el directorio"
  echo -e "      adecuado de systemd para gestionar la aplicación."
  echo -e "    - La unidad debe incluir directivas de resiliencia (ej. Restart=on-failure,"
  echo -e "      RestartSec) y especificar correctamente el ExecStart."
  echo -e ""
  echo -e " 3. Despliegue y Validación:"
  echo -e "    - Recargar el demonio systemd, habilitar el servicio para el arranque"
  echo -e "      automático e iniciarlo."
  echo -e "    - Validar que el servicio esté en estado 'active (running)' y que los"
  echo -e "      procesos hijos estén correctamente agrupados bajo el control de systemd."
  echo -e ""
  echo -e " 4. Pipeline de Evidencia a node03:"
  echo -e "    - Destino: /opt/ops-compliance/od-002/service_evidence.txt"
  echo -e "    - Debe contener la salida de: 'systemctl status <nombre_servicio>' y"
  echo -e "      'ps -f --ppid \$(systemctl show -p MainPID <nombre_servicio> | cut -d= -f2)'"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Procesos huérfanos originales eliminados de node02            20%"
  echo -e "  [ ] Archivo .service creado con sintaxis correcta y Restart policy  30%"
  echo -e "  [ ] Servicio habilitado (enabled) y activo (running)              30%"
  echo -e "  [ ] Evidencia (service_evidence.txt) presente en la bóveda node03  20%"
  echo -e "  [ ] CERO archivos de resultados almacenados en node01  \e[1;31m(DESCALIFICA)\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_od002.sh && rm -f /tmp/setup_od002.sh
tags:
  - LFCS
  - RHCSA
  - Laboratorios-del-LFCS
  - Operations-Deployment
  - Process-Management
  - Systemd-Services
Escenario: |-
  - Situación: Una aplicación crítica de procesamiento de datos en node02 (simulada como 'data-processor') se cierra inesperadamente, dejando procesos huérfanos o "zombis" que consumen memoria y CPU. El método de arranque actual es un script bash obsoleto ejecutado manualmente o vía cron, sin gestión de ciclo de vida ni capacidad de reinicio automático.
  - Tu misión desde node01:
    1. Conectarte a node02 e identificar los procesos residuales/zombis asociados a la aplicación (usando ps, pgrep o pidof) y terminarlos limpiamente (kill, pkill o systemctl kill).
    2. Crear un archivo de unidad systemd personalizado (/etc/systemd/system/data-processor.service) que ejecute el binario o script de la aplicación correctamente.
    3. Configurar directivas de resiliencia en la unit (ej. Restart=on-failure, RestartSec=5) y habilitar el servicio para el arranque automático (systemctl enable --now).
    4. Verificar que el servicio esté activo (active/running) y que los procesos se gestionen correctamente bajo systemd.
    - Regla de Oro: Enviar la salida de ps aux | grep data-processor y systemctl status data-processor directamente a node03 mediante un pipeline SSH, sin guardar ningún archivo .txt local en node01.
---
[[Laboratorios del LFCS]]
---


**Tell me about a recent challenge you faced at work.**


Recently, I responded to an incident where our monitoring team flagged abnormal memory and CPU consumption on one of our production nodes. When I investigated, I found that a critical data processing application had been running through a legacy approach — basically a shell script launched manually in the background, with no lifecycle management, no centralized logging, and no automatic restart capability. On top of that, the application had crashed and left orphaned processes sitting idle, consuming resources without doing any useful work.

My first step was to identify and safely terminate those orphaned processes using SIGTERM, confirming clean removal before touching anything else. Then I engineered a proper systemd service unit from scratch, defining restart policies and the correct execution path, so the application would be fully supervised by the init system going forward. Once deployed, I reloaded the systemd daemon, enabled the service for automatic startup on boot, and confirmed it reached active running state with its child processes correctly grouped under the service's control group.

To close the incident properly, I captured the service status and process tree as compliance evidence and streamed it directly from the affected node to our secure vault server via SSH pipeline — without staging any intermediate files on the control node, which was an explicit operational constraint.

What I valued most about this incident was that it wasn't just about fixing a crash — it was about replacing a fragile, invisible workaround with something observable, resilient, and auditable. That's the kind of thinking I try to bring to every system I touch.