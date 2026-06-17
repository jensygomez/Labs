---
Curso: Prep Course - LFCS Certification
Modulo: Users, Groups & Resource Management
Playground: USR-003-MN
Titulo: La Bomba de Tenedores (Fork Bomb) – Límites de Recursos de Usuario - V1.0
Fecha de Inicio: 2026-06-15
Dificultad: 8/10
Level Escalation: L3
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes (entender la base de cgroups, requests y limits)
Temas: |-
  - Configure User Resource Limits (/etc/security/limits.conf, /etc/security/limits.d/)
  - Límites de procesos (nproc) y descriptores de archivo (nofile)
  - Diferenciación entre límites soft y hard
  - Ejecución remota y pipeline de datos (node01 -> node02 -> node03)
Competencias: |-
  - Identificar y mitigar riesgos de agotamiento de recursos del sistema operativo (Fork Bombs, FD leaks).
  - Aplicar el principio de menor privilegio a nivel de recursos, restringiendo nproc y nofile exclusivamente a un usuario o grupo específico.
  - Garantizar que las restricciones de recursos no afecten a root ni a servicios críticos del sistema (como sshd o systemd).
  - Validar la aplicación de los límites consultando los valores activos (ulimit) y enviar la evidencia a node03 vía pipeline SSH, sin dejar rastros en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_usr003.sh

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
      echo $PASS | sudo -S apt-get install -y sshpass -qq
  fi

  echo -e "\e[1;33m⏳ Instalando sshpass en nodos remotos...\e[0m"
  $SSH2 "echo $PASS | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"
  $SSH3 "echo $PASS | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Inyectando escenario de límites de recursos en node02...\e[0m"
  # NOTA CRÍTICA PARA INCIDENTES FUTUROS:
  # Cuando inyectes comandos multi-línea vía SSH desde un script heredado (cat << 'EOF'),
  # NO usares 'bash -c "..."` con comillas dobles escapadas, porque el escaping se rompe
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

  $SSH2 "echo $PASS | sudo --stdin bash << 'INNEREOF'
      # 1. Crear infraestructura de identidad local
      groupadd -f batch-jobs
      if ! id batch-processor &>/dev/null; then
          useradd -m -G batch-jobs -s /bin/bash batch-processor
          echo 'batch-processor:BatchProc!2024' | chpasswd
      fi

      # 2. Simular estado 'roto': Asegurar que NO existan límites restrictivos previos
      # (Esto simula que el admin anterior nunca configuró límites, heredando valores altos/unlimited)
      rm -f /etc/security/limits.d/99-batch-processor.conf
      rm -f /etc/security/limits.d/batch-jobs.conf
      
      # 3. Dejar un rastro en los logs que simule el incidente pasado
      echo \"\$(date): WARNING: Process limit exceeded for batch-processor (Fork Bomb detected)\" >> /var/log/syslog 2>/dev/null || true
      
      echo '[USR-003] Escenario de límites de recursos inyectado correctamente.'
      exit 0
  INNEREOF" || echo -e "\e[1;33m  [!] Advertencia: La inyección en node02 tuvo un detalle, pero continuamos.\e[0m"

  echo -e "\e[1;33m⏳ Preparando bóveda en node03...\e[0m"
  $SSH3 "echo $PASS | sudo --stdin bash << 'INNEREOF'
      rm -rf /opt/ops-compliance/od-003/
      mkdir -p /opt/ops-compliance/od-003/
      chown -R ${USER_NET}:${USER_NET} /opt/ops-compliance/od-003/
      chmod 750 /opt/ops-compliance/od-003/
      echo '[USR-003] Bóveda de evidencia en node03 preparada correctamente.'
      exit 0
  INNEREOF" || echo -e "\e[1;33m  [!] Advertencia: La preparación de node03 tuvo un detalle, pero continuamos.\e[0m"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m USR-003-v1 | La Bomba de Tenedores (Límites de Recursos) | Dificultad: 8.0/10 | L3\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/od-003/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El equipo de monitoreo ha reportado que el nodo 'node02' se congela"
  echo -e " periódicamente. La investigación revela que el usuario 'batch-processor'"
  echo -e " (grupo 'batch-jobs') ejecuta scripts de procesamiento de datos mal optimizados"
  echo -e " que agotan los descriptores de archivo (nofile) y los procesos (nproc),"
  echo -e " provocando un efecto de 'Fork Bomb' que afecta la estabilidad de todo el sistema."
  echo -e ""
  echo -e " Actualmente, no existen políticas de límites de recursos (Resource Limits)"
  echo -e " configuradas para este usuario, por lo que hereda los valores por defecto"
  echo -e " (a menudo 'unlimited' o excesivamente altos) del sistema operativo."
  echo -e ""
  echo -e " Se le asigna esta incidencia como Ingeniero de Sistemas Senior. Su misión es"
  echo -e " endurecer (harden) la configuración del sistema para restringir el consumo de"
  echo -e " recursos de este usuario/grupo específico, garantizando que 'root' y los"
  echo -e " servicios críticos del sistema no se vean afectados."
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
  echo -e " 1. Diagnóstico Inicial:"
  echo -e "    - Conéctate a node02 y verifica los límites actuales (nproc, nofile) del"
  echo -e "      usuario 'batch-processor'."
  echo -e ""
  echo -e " 2. Ingeniería de Límites (Resource Hardening):"
  echo -e "    - Crea o modifica la configuración en el directorio /etc/security/limits.d/."
  echo -e "    - Establece límites estrictos pero funcionales: nproc=50 y nofile=1024"
  echo -e "      (tanto soft como hard)."
  echo -e "    - REGLA CRÍTICA: La restricción debe aplicarse exclusivamente al usuario"
  echo -e "      o grupo específico, sin afectar los límites de root ni del usuario por"
  echo -e "      defecto (*)."
  echo -e ""
  echo -e " 3. Despliegue y Validación:"
  echo -e "    - Valida que el usuario 'batch-processor' herede correctamente los nuevos"
  echo -e "      límites al iniciar una sesión de login (recuerda la diferencia entre"
  echo -e "      shell de login y no-login para la aplicación correcta de PAM limits)."
  echo -e ""
  echo -e " 4. Pipeline de Evidencia a node03:"
  echo -e "    - Destino: /opt/ops-compliance/od-003/resource_evidence.txt"
  echo -e "    - Debe contener la salida de la verificación de límites (ulimit -u y"
  echo -e "      ulimit -n) ejecutada en nombre del usuario afectado, enviada directamente"
  echo -e "      vía SSH sin guardar nada en node01."
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Límites nproc=50 y nofile=1024 aplicados a batch-processor/batch-jobs  40%"
  echo -e "  [ ] Los límites de root y * (default) NO se ven afectados negativamente      20%"
  echo -e "  [ ] Validación exitosa de los límites mediante sesión de login (su -)        20%"
  echo -e "  [ ] Evidencia (resource_evidence.txt) presente en la bóveda node03           20%"
  echo -e "  [ ] CERO archivos de resultados almacenados en node01  \e[1;31m(DESCALIFICA)\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_usr003.sh && rm -f /tmp/setup_usr003.sh
tags:
  - Laboratorios-del-LFCS
  - Users-and-Groups
  - Resource-Limits
  - cgroups-basics
Escenario: |-
  - Situación: En node02, el usuario batch-processor (perteneciente al grupo batch-jobs) ejecuta scripts de procesamiento de datos. Recientemente, un script mal optimizado provocó un leak de descriptores de archivo y procesos, consumiendo los PIDs disponibles y congelando parcialmente el nodo. Actualmente, no existen límites de recursos configurados para este usuario, heredando los valores ilimitados o excesivamente altos del sistema.

  Tu misión desde node01:
  1. Conectarte a node02 y verificar los límites actuales del usuario batch-processor (deben ser altos o 'unlimited').
  2. Crear o modificar un archivo en /etc/security/limits.d/ (ej. 99-batch-processor.conf) para establecer límites estrictos pero funcionales: nproc máximo de 50 y nofile máximo de 1024 (hard y soft) SOLO para el usuario batch-processor o el grupo @batch-jobs.
  3. Asegurar explícitamente que el usuario root y el default (*) no se vean afectados negativamente por esta regla.
  4. Validar los cambios: Simular el entorno del usuario (ej. su - batch-processor -c "ulimit -u && ulimit -n") para confirmar que los límites se aplican correctamente.

  Regla de Oro: Enviar la salida de esa verificación (los valores de ulimit -u y ulimit -n) directamente a node03 mediante un pipeline SSH, sin dejar archivos de evidencia locales en node01.
---
[[Laboratorios del LFCS]]


---
Recently, I was assigned a high-priority incident on one of our production nodes that was experiencing periodic freezes. The root cause turned out to be a service account called `batch-processor` running poorly optimized data processing scripts with virtually no resource constraints — over one million processes available, which created the conditions for a classic fork bomb scenario.

My intervention had to be surgical. I couldn't touch the default system limits or affect root, so I created a dedicated configuration file under `/etc/security/limits.d/` that applied strict hard and soft limits exclusively to that user — fifty processes and one thousand and twenty-four file descriptors. Setting both soft and hard to the same value was a deliberate choice: leaving headroom between them would have allowed the user to escalate back up to the hard limit, which defeats the purpose of the hardening.

One thing I had to be precise about was how PAM applies these limits. They only take effect in login shell sessions, so my validation used `su --login` to simulate a real login — not just a subshell, which would have given me a false positive.

Finally, the operational policy required that no intermediate files be stored on the control node. So I piped the evidence output directly from the affected node to the compliance vault on a third node in a single pipeline — node01 to node02 to node03 — keeping the audit trail clean and the intervention fully traceable.