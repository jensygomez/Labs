---
Curso: Transición Sysadmin a DevOps - Operations Deployment LFCS/RHCSA
Modulo: Operations Deployment (Parámetros del Kernel y Análisis de Logs)
Playground: OD-003
Titulo: Sintonizando el Núcleo – Parámetros del Kernel y Análisis Forense de Logs
Fecha de Inicio: 2026-06-16
Dificultad: 7.5/10
Level Escalation: L3
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes (donde el tuning de kernel en nodos worker es crítico)
Temas: |-
  - Locate and Analyze System Log Files (journalctl -k, dmesg -T, /var/log/messages o /var/log/syslog)
  - Change Kernel Runtime Parameters Non-Persistent (sysctl -w)
  - Change Kernel Runtime Parameters Persistent (/etc/sysctl.d/*.conf, sysctl --system)
  - Refresco: Ejecución remota y pipeline de datos (node01 -> node02 -> node03)
Competencias: |-
  - Analizar logs del kernel y del sistema para identificar causas raíz de fallos críticos (como intervenciones del OOM Killer o fallos de red).
  - Modificar parámetros del kernel en tiempo de ejecución (runtime) para aplicar mitigaciones inmediatas sin necesidad de reiniciar el servidor.
  - Persistir configuraciones del kernel de forma segura, modular y estructurada utilizando el directorio /etc/sysctl.d/, evitando la modificación directa y desordenada de /etc/sysctl.conf.
  - Validar los cambios aplicados y enviar la evidencia forense (logs filtrados) junto con la configuración activa a node03 vía pipeline SSH, sin materializar archivos en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_od003.sh

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

  echo -e "\e[1;33m⏳ Inyectando escenario de inestabilidad de Kernel en node02...\e[0m"
  # NOTA: Usamos la técnica de heredoc por stdin (INNEREOF) para evitar problemas de escaping 
  # y garantizar que los comandos multi-línea se ejecuten limpiamente con privilegios de root.
  $SSH2 "echo caleston123 | sudo --stdin bash << 'INNEREOF'
      # 1. Establecer un estado inicial del kernel propenso a fallos (simulando mala configuración)
      sysctl -w vm.panic_on_oom=1
      sysctl -w vm.swappiness=60
      sysctl -w net.ipv4.ip_forward=0

      # 2. Inyectar registros forenses realistas en el buffer del kernel (dmesg/journalctl)
      # Esto simula que el OOM Killer ya ha actuado y hay problemas de red/conexiones.
      logger -p kern.err -t kernel 'Out of memory: Killed process 14523 (java-worker) total-vm:2048000kB, anon-rss:1500000kB, file-rss:0kB, shmem-rss:0kB'
      logger -p kern.err -t kernel 'Out of memory: Killed process 14890 (node-app) total-vm:1048000kB, anon-rss:800000kB, file-rss:0kB, shmem-rss:0kB'
      logger -p kern.warning -t kernel 'nf_conntrack: table full, dropping packet'
      logger -p kern.warning -t kernel 'TCP: time wait bucket table overflow'

      # 3. Dejar un proceso inofensivo pero visible que el ingeniero podría investigar como 'sospechoso'
      mkdir -p /opt/suspicious-app
      printf '#!/bin/bash\nwhile true; do sleep 300; done\n' > /opt/suspicious-app/daemon.sh
      chmod +x /opt/suspicious-app/daemon.sh
      setsid /opt/suspicious-app/daemon.sh </dev/null >/dev/null 2>&1 &

      echo '[OD-003] Escenario de Kernel y Logs inyectado correctamente en node02.'
      exit 0
  INNEREOF" || echo -e "\e[1;33m  [!] Advertencia: La inyección en node02 tuvo un detalle, pero continuamos.\e[0m"

  echo -e "\e[1;33m⏳ Preparando bóveda de evidencia en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/od-003/
      mkdir -p /opt/ops-compliance/od-003/
      chown -R bob:bob /opt/ops-compliance/od-003/
      chmod 750 /opt/ops-compliance/od-003/
      exit 0
  '" || echo -e "\e[1;33m  [!] Advertencia: La preparación de node03 tuvo un detalle, pero continuamos.\e[0m"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m OD-003-v1 | Sintonizando el Núcleo | Dificultad: 7.5/10 | L3\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/od-003/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El equipo de SRE ha reportado inestabilidad severa en node02: caídas intermitentes"
  echo -e " de conectividad de red y la terminación abrupta de procesos críticos de la aplicación."
  echo -e " Se sospecha fuertemente de una configuración agresiva del Kernel (OOM Killer) y"
  echo -e " parámetros de red subóptimos para la carga de trabajo actual."
  echo -e ""
  echo -e " Como Ingeniero de Sistemas L3, su misión es realizar un análisis forense de los"
  echo -e " logs del kernel para confirmar la causa raíz, aplicar una mitigación inmediata en"
  echo -e " tiempo de ejecución (runtime) y, finalmente, persistir la corrección de forma"
  echo -e " modular y profesional."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01 vía SSH."
  echo -e " \e[1m>\e[0m NO se permite materializar archivos de reporte, logs o scripts temporales en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente de node02 hacia node03 mediante pipeline SSH."
  echo -e ""
  echo -e "\e[1;33m PARÁMETROS TÉCNICOS OBLIGATORIOS (TICKET DE REMEDIACIÓN - NIVEL L3)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Análisis Forense de Logs del Kernel\e[0m"
  echo -e "    Objetivo: Confirmar la hipótesis de OOM Killer o fallos de red."
  echo -e "    \e[1;33mRestricción:\e[0m Debes utilizar herramientas nativas de diagnóstico de kernel"
  echo -e "    (ej. journalctl -k, dmesg -T) y filtrar la salida para mostrar únicamente"
  echo -e "    los eventos críticos (err, warning, o la palabra clave 'Out of memory')."
  echo -e ""
  echo -e " \e[1m2. Mitigación en Runtime (No Persistente)\e[0m"
  echo -e "    Estado actual: vm.panic_on_oom=1 (Peligroso), vm.swappiness=60 (Alto), ip_forward=0."
  echo -e "    Objetivo: Ajustar los parámetros en tiempo real para estabilizar el nodo sin reiniciar."
  echo -e "    \e[1;33mRestricción:\e[0m Aplica cambios seguros (ej. vm.panic_on_oom=0, vm.swappiness=10,"
  echo -e "    net.ipv4.ip_forward=1) y verifica su aplicación inmediata con sysctl."
  echo -e ""
  echo -e " \e[1m3. Persistencia Modular del Kernel\e[0m"
  echo -e "    Objetivo: Garantizar que los cambios sobrevivan a un reinicio."
  echo -e "    \e[1;33mRestricción CRÍTICA:\e[0m NO edites directamente /etc/sysctl.conf. Debes crear"
  echo -e "    un archivo de configuración nuevo y modular dentro de /etc/sysctl.d/ (ej."
  echo -e "    99-od003-tuning.conf) y aplicar los cambios usando el método adecuado."
  echo -e ""
  echo -e " \e[1m4. Pipeline de Evidencia a node03\e[0m"
  echo -e "    Destino: /opt/ops-compliance/od-003/kernel_evidence.txt"
  echo -e "    Debe contener, en este orden:"
  echo -e "    a) La salida filtrada de los logs del kernel (ej. journalctl -k -p err..warning)."
  echo -e "    b) La verificación de que los parámetros persisten y están activos (sysctl <param>). "
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Logs del kernel analizados y filtrados correctamente                20%"
  echo -e "  [ ] Parámetros del kernel modificados en runtime con valores seguros    30%"
  echo -e "  [ ] Configuración persistente creada en /etc/sysctl.d/ (NO en sysctl.conf) 30%"
  echo -e "  [ ] Evidencia (kernel_evidence.txt) presente en la bóveda node03        20%"
  echo -e "  [ ] CERO archivos de resultados almacenados en node01  \e[1;31m(DESCALIFICA)\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_od003.sh && rm -f /tmp/setup_od003.sh
tags:
  - LFCS
  - RHCSA
  - Laboratorios-del-LFCS
  - Operations-Deployment
  - Kernel-Tuning
  - Log-Analysis
  - Sysctl
Escenario: |-
  - Situación: El servidor node02 está experimentando inestabilidad severa: caídas intermitentes de red y terminación abrupta de procesos críticos. Existe una alta sospecha de que el "OOM Killer" (Out of Memory) está actuando agresivamente o que el reenvío de paquetes (IP forwarding) está mal configurado, afectando la conectividad de los contenedores/servicios.
  - Tu misión desde node01:
    1. Conectarte a node02 y realizar un análisis forense de los logs del kernel (usando journalctl -k, dmesg -T o revisando /var/log/messages) para confirmar la presencia de mensajes "Out of memory: Killed process" o errores de red.
    2. Aplicar un ajuste de parámetros del kernel de forma no persistente (ej. sysctl -w vm.swappiness=10, vm.panic_on_oom=0, o net.ipv4.ip_forward=1) para validar que la mitigación funciona en tiempo real.
    3. Una vez validado, crear un archivo de configuración persistente en /etc/sysctl.d/ (ej. 99-custom-tuning.conf) con los parámetros corregidos y aplicar los cambios de forma limpia (sysctl --system o sysctl -p /etc/sysctl.d/99-custom-tuning.conf).
    4. Verificar que los valores se hayan aplicado correctamente y persisten (sysctl <parametro>).
    - Regla de Oro: Enviar la salida de los logs filtrados (ej. journalctl -k -p err) y la verificación del parámetro aplicado (sysctl <parametro>) directamente a node03 mediante un pipeline SSH, sin guardar ningún archivo .txt local en node01.
---
[[Laboratorios del LFCS]]
---
