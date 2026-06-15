---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: USR-002-MN
Titulo: El Entorno Roto – Perfiles de Sistema y Plantillas de Usuario (/etc/skel)
Fecha de Inicio: 2026-06-15
Dificultad: 7/10
Level Escalation: L2/L3
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Manage System-Wide Environment Profiles (/etc/profile, /etc/profile.d/)
  - Manage Template User Environment (/etc/skel)
  - Default file creation permissions (umask)
  - Ejecución remota y pipeline de datos (node01 -> node02 -> node03)
Competencias: |-
  - Estandarizar entornos de usuario nuevos garantizando consistencia (Infraestructura como Código a nivel de SO).
  - Reparar y asegurar scripts de inicialización globales (/etc/profile.d/) evitando errores de sintaxis que rompan el shell al hacer login.
  - Configurar plantillas de usuario (/etc/skel) con variables de entorno, alias de seguridad y umask restrictivo (027) por defecto.
  - Validar la creación de un usuario de prueba y enviar la evidencia de su entorno (env, alias, umask) a node03 vía pipeline SSH, sin guardar archivos locales en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_usr002.sh

  #!/bin/bash
  set -e
  PASS="caleston123"
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT}"

  echo -e "\e[1;33m⏳ Verificando e instalando sshpass en los nodos...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      echo $PASS | sudo -S apt-get install -y sshpass -qq
  fi
  $SSH2 "echo $PASS | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"
  $SSH3 "echo $PASS | sudo -S apt-get install -y sshpass -qq 2>/dev/null || true"

  echo -e "\e[1;33m⏳ Preparando bóveda de evidencia en node03...\e[0m"
  $SSH3 "echo $PASS | sudo -S bash -c '
  rm -rf /opt/ops-compliance/USR-002-MN/
  mkdir -p /opt/ops-compliance/USR-002-MN/
  chmod 750 /opt/ops-compliance/USR-002-MN/
  chown -R root:root /opt/ops-compliance/USR-002-MN/
  '"

  echo -e "\e[1;33m⏳ Limpiando estado anterior en node02...\e[0m"
  $SSH2 "echo $PASS | sudo -S bash -c '
  if id test_user &>/dev/null; then
      userdel -rf test_user 2>/dev/null || true
  fi
  rm -f /etc/profile.d/broken-alias.sh
  rm -f /etc/profile.d/corp-umask.sh
  if [ ! -f /etc/skel/.bashrc ]; then
      echo \"# Default empty .bashrc\" > /etc/skel/.bashrc
  fi
  '"

  echo -e "\e[1;33m⏳ Inyectando incidente en node02...\e[0m"
  $SSH2 "echo $PASS | sudo -S bash -c '
  cat > /etc/profile.d/broken-alias.sh <<'"'"'BROKEN'"'"'
  # alias de bienvenida corporativo (ROTO)
  alias welcome=\"echo Bienvenido al sistema, \$USER    # <-- comilla sin cerrar
  export CORP_ENV=PRODUCTION
  BROKEN
  chmod 644 /etc/profile.d/broken-alias.sh

  cat > /etc/profile.d/corp-umask.sh <<'"'"'UMASK'"'"'
  # Politica de umask corporativa (MAL CONFIGURADA)
  umask 000
  UMASK
  chmod 644 /etc/profile.d/corp-umask.sh

  rm -f /etc/skel/.bashrc
  rm -f /etc/skel/.bash_profile
  '"

  clear
  echo -e  "\e[1;36m================================================================================\e[0m "
  echo -e  "\e[1;32m USR-002-MN | El Entorno Roto | Dificultad: 7/10 | L2/L3\e[0m "
  echo -e  "\e[1;36m================================================================================\e[0m "
  echo -e  " Contraseña del cluster: \e[1mcaleston123\e[0m "
  echo -e  " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/USR-002-MN/ "
  echo -e  "\e[1;36m--------------------------------------------------------------------------------\e[0m "
  echo -e  " "
  echo -e  " El equipo de operaciones ha detectado un comportamiento anómalo en node02, "
  echo -e  " donde los nuevos usuarios no pueden iniciar sesión correctamente y los "
  echo -e  " permisos de los archivos recién creados son inseguros. "
  echo -e  " "
  echo -e  " Tras una revisión preliminar, se determinó que un script de perfil de "
  echo -e  " sistema (/etc/profile.d/broken-alias.sh) contiene un error de sintaxis "
  echo -e  " (comillas sin cerrar) que interrumpe el shell en el login. Además, existe "
  echo -e  " una política de umask peligrosa (000) en /etc/profile.d/corp-umask.sh, "
  echo -e  " y la plantilla de usuario por defecto (/etc/skel/.bashrc) ha sido eliminada. "
  echo -e  " "
  echo -e  " Se le asigna esta incidencia como ingeniero de turno. Su intervención debe "
  echo -e  " realizarse de manera remota desde node01, corrigiendo los scripts de perfil, "
  echo -e  " restaurando la plantilla de usuario, creando un usuario de prueba y enviando "
  echo -e  " la evidencia a la bóveda de cumplimiento operacional. "
  echo -e  " "
  echo -e  "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m "
  echo -e  "\e[1;36m--------------------------------------------------------------------------------\e[0m "
  echo -e  " \e[1m >\e[0m Toda la intervención debe realizarse desde node01 vía SSH. "
  echo -e  " \e[1m >\e[0m No se permite materializar archivos intermedios en node01. "
  echo -e  " \e[1m >\e[0m La evidencia debe fluir directamente de node02 hacia node03 mediante pipeline. "
  echo -e  " "
  echo -e  "\e[1;33m PROCEDIMIENTO REQUERIDO\e[0m "
  echo -e  "\e[1;36m--------------------------------------------------------------------------------\e[0m "
  echo -e  " "
  echo -e  " 1. Conectarse a node02 y diagnosticar el error de sintaxis: "
  echo -e  "    ssh bob@node02 "
  echo -e  "    bash -n /etc/profile.d/broken-alias.sh "
  echo -e  " "
  echo -e  " 2. Corregir o eliminar el script defectuoso y ajustar el umask a 027: "
  echo -e  "    sudo rm /etc/profile.d/broken-alias.sh  (o corregir la comilla) "
  echo -e  "    sudo sed -i 's/umask 000/umask 027/' /etc/profile.d/corp-umask.sh "
  echo -e  " "
  echo -e  " 3. Reconstruir la plantilla de usuario por defecto: "
  echo -e  "    sudo bash -c 'echo -e \"umask 027\\nalias ll=\\\"ls -la\\\"\" > /etc/skel/.bashrc' "
  echo -e  " "
  echo -e  " 4. Crear usuario de prueba y validar su entorno: "
  echo -e  "    sudo useradd -m test_user "
  echo -e  "    su - test_user -c 'umask && alias ll' "
  echo -e  " "
  echo -e  " 5. Enviar evidencia de node02 directamente a node03 sin archivos en node01: "
  echo -e  "    Destino: /opt/ops-compliance/USR-002-MN/evidence.txt "
  echo -e  " "
  echo -e  "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m "
  echo -e  "\e[1;36m--------------------------------------------------------------------------------\e[0m "
  echo -e  "  [ ] Script broken-alias.sh corregido o eliminado en node02      30% "
  echo -e  "  [ ] Umask seguro (027) configurado en node02                    30% "
  echo -e  "  [ ] /etc/skel/.bashrc restaurado con umask 027 y alias útil     20% "
  echo -e  "  [ ] Evidencia presente en node03 bóveda USR-002-MN              20% "
  echo -e  " "
  echo -e  "\e[1;36m================================================================================\e[0m "
  OUTEREOF

  bash /tmp/setup_usr002.sh && rm -f /tmp/setup_usr002.sh
tags:
  - Laboratorios-del-LFCS
  - Users-and-Groups
  - Environment-Profiles
  - etc-skel
Escenario: |-
  - Situación: En node02, un administrador anterior dejó un archivo llamado /etc/profile.d/broken-alias.sh con una comilla sin cerrar o un comando inexistente. Esto hace que cualquier usuario nuevo que intente hacer login reciba un error y sea expulsado del shell, o que su umask sea 000 (peligroso). Además, /etc/skel/.bashrc fue borrado.
  Tu misión desde node01:
  Conectarte a node02 y diagnosticar el error de sintaxis en /etc/profile.d/.
  Corregir o eliminar el script defectuoso.
  Reconstruir /etc/skel/.bashrc (o .bash_profile) para incluir un umask 027 y al menos un alias de utilidad (ej. alias ll='ls -la').
  Crear un usuario de prueba (ej. test_user) y simular su entorno (puedes usar su - test_user -c "umask && alias ll && env | grep PATH").
  Regla de Oro: Enviar la salida de esa verificación directamente a node03 mediante un pipeline, sin dejar rastros en node01.
---
[[Laboratorios del LFCS]]


---
Recently, I handled a high-priority incident where a broken system environment was completely blocking new users from logging in and creating a major security risk. The issue was caused by a couple of bad configurations on a production server: a system-wide script had a typo with an unclosed quote that immediately crashed the shell upon login, a dangerous global permission policy was active, and the default user profile template had been accidentally deleted. To make things more interesting, the ticket came with strict operational rules. I had to fix everything remotely from a control machine without creating any temporary or intermediate files on it, and the final evidence had to be sent directly to a separate secure compliance vault using network pipelines.

To resolve this, I connected via SSH and took a very clean, automated approach. First, I fixed the broken script and corrected the typo, and then I surgically updated the system permissions to a highly secure standard. After that, I rebuilt the missing default user profile template from scratch so that any new account created in the future would automatically inherit the right settings and helpful command shortcuts.

During the validation phase, I created a test user to make sure everything worked. I ran into a common quirk where command shortcuts don't load automatically in background testing environments, so I forced the shell to simulate a real, interactive user session to guarantee a thorough check. Once I confirmed that the user environment was completely restored and secure, I streamed the diagnostic data directly across the network into the compliance vault, successfully bypassing a few privilege restrictions along the way. In the end, the environment was fully restored, security standards were met, and I closed the ticket with a perfect compliance score without leaving any digital clutter on the control server.