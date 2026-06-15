---
Curso: Transición Sysadmin a DevOps - Operations Deployment LFCS/RHCSA
Modulo: Operations Deployment (Gestión de Arranque y Ciclo de Vida)
Playground: OD-001-v1
Titulo: El Arranque Fantasma – Recuperación de Targets y Reinicio Seguro
Fecha de Inicio: 2026-06-15
Dificultad: 6.5/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Boot, Reboot, and Shutdown a System Safely
  - Boot or Change System Into Different Operating Modes (Targets)
  - Manage Startup Process and Services (systemctl)
  - Ejecución remota y pipeline de datos (node01 -> node02 -> node03)
Competencias: |-
  - Identificar el target de arranque actual y el target por defecto en un sistema remoto.
  - Cambiar el target de arranque de forma persistente (ej. corregir un rescue.target no deseado a multi-user.target).
  - Ejecutar un reinicio seguro del sistema (systemctl reboot) y validar el estado posterior de los servicios críticos.
  - Documentar y enviar la evidencia del estado del sistema a node03 vía pipeline SSH, sin almacenar datos locales en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_od001.sh

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
  sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET} \
      "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"
  sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} \
      "echo caleston123 | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Corrompiendo default target en node02...\e[0m"
  $SSH2 "echo caleston123 | sudo -S bash -c '
      systemctl set-default rescue.target 2>/dev/null || \
          ln -sf /lib/systemd/system/rescue.target /etc/systemd/system/default.target
      echo \"[OD-001] default target ahora: \$(systemctl get-default)\"
  '"

  echo -e "\e[1;33m⏳ Preparando boveda en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/od-001/
      mkdir -p /opt/ops-compliance/od-001/
      chown -R bob:bob /opt/ops-compliance/
  '"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m OD-001-v1 | El Arranque Fantasma | Dificultad: 6.5/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/od-001/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El día de hoy, a las 14:32 UTC, el equipo de operaciones recibió una alerta"
  echo -e " proveniente del sistema de monitoreo de infraestructura. La alerta indicaba"
  echo -e " un comportamiento anómalo en node02, uno de los nodos de cómputo del clúster"
  echo -e " de producción."
  echo -e ""
  echo -e " Tras una revisión preliminar, se determinó que un ingeniero junior, durante"
  echo -e " una intervención de mantenimiento no autorizada, modificó el default target"
  echo -e " de systemd en node02, estableciéndolo en rescue.target. Esta configuración,"
  echo -e " si bien no interrumpe la sesión activa en curso, garantiza que en el próximo"
  echo -e " reinicio del nodo, el sistema arranque en modo de rescate: sin red, sin"
  echo -e " servicios y sin capacidad de responder a conexiones SSH."
  echo -e ""
  echo -e " El nodo permanece operativo en este momento, pero su estado es frágil."
  echo -e " Cualquier reinicio planificado o no planificado dejará a node02 completamente"
  echo -e " fuera de servicio. El impacto potencial afecta a los procesos que dependen"
  echo -e " de la disponibilidad continua de este nodo dentro del clúster."
  echo -e ""
  echo -e " Se le asigna esta incidencia como ingeniero de turno. Su intervención debe"
  echo -e " realizarse de manera remota desde node01, siguiendo el procedimiento estándar"
  echo -e " de corrección de configuración de systemd, validación post-reinicio y registro"
  echo -e " de evidencia en la bóveda de cumplimiento operacional."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01 vía SSH."
  echo -e " \e[1m>\e[0m No se permite materializar archivos intermedios en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente de node02 hacia node03 mediante pipeline."
  echo -e ""
  echo -e "\e[1;33m PROCEDIMIENTO REQUERIDO\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " 1. Conectarse a node02 y verificar el target corrupto:"
  echo -e "    ssh bob@node02"
  echo -e "    systemctl get-default"
  echo -e ""
  echo -e " 2. Corregir el default target de forma persistente:"
  echo -e "    sudo systemctl set-default multi-user.target"
  echo -e ""
  echo -e " 3. Ejecutar reinicio seguro:"
  echo -e "    sudo systemctl reboot"
  echo -e ""
  echo -e " 4. Esperar que node02 levante y validar post-reboot:"
  echo -e "    systemctl get-default"
  echo -e "    systemctl is-active sshd"
  echo -e "    systemctl is-active NetworkManager"
  echo -e ""
  echo -e " 5. Enviar evidencia de node02 directamente a node03 sin archivos en node01:"
  echo -e "    Destino: /opt/ops-compliance/od-001/boot_state.evidence"
  echo -e ""
  echo -e " \e[1;33mTIP — loop de espera post-reboot:\e[0m"
  echo -e "    for i in \$(seq 1 10); do ssh bob@node02 'echo ok' && break || sleep 5; done"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Default target = multi-user.target en node02          35%"
  echo -e "  [ ] sshd activo post-reboot en node02                     25%"
  echo -e "  [ ] NetworkManager activo post-reboot en node02           20%"
  echo -e "  [ ] boot_state.evidence presente en node03                20%"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_od001.sh && rm -f /tmp/setup_od001.sh
tags:
  - LFCS
  - RHCSA
  - Laboratorios-del-LFCS
  - Operations-Deployment
Escenario: |-
  -  Situación: Un junior modificó por error el target por defecto de node02 a rescue.target. Aunque el sistema está actualmente en línea (alguien lo forzó a multi-user.target en la sesión actual), el próximo reinicio lo dejará inaccesible para servicios de red.
  -  Tu misión desde node01:
    - Conectarte a node02 y verificar el target actual (systemctl get-default) y el estado de los targets.
    - Corregir el target por defecto a multi-user.target de forma persistente.
    - Ejecutar un reinicio seguro (systemctl reboot).
    - Esperar a que el sistema levante, volver a conectarte y verificar que el servicio sshd y la red estén activos.
    - Regla de Oro: Enviar la salida de systemctl get-default y systemctl is-active sshd directamente a node03 mediante un pipeline, sin guardar ningún archivo .txt en node01.
---
[[Laboratorios del LFCS]]

One of our production servers was flagged as a critical risk during a routine check. A junior team member had accidentally changed the default boot target to `rescue.target`. The server was still responding at that moment, but we knew that the next scheduled maintenance reboot — or any unexpected crash — would have brought it back up with no network and no services. Essentially a brick.

I took ownership of the remediation immediately.

Working remotely from the admin workstation, I connected to the affected server and confirmed the misconfiguration. I corrected the default boot target to `multi-user.target` to restore the expected startup behavior, then performed a controlled reboot to validate the fix under real conditions — not just on paper.

Once the server came back online, I verified that SSH was active and that the system had booted into the correct target. As part of our compliance process, I forwarded the post-recovery state report directly from the production server to our centralized audit repository, using a chained SSH pipeline to ensure no sensitive data touched intermediate systems.

The server was fully recovered before any scheduled reboot occurred. Zero downtime, zero data left on unauthorized systems.