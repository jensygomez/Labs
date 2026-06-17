---
Curso: Transición Sysadmin a DevOps - Essential Commands LFCS/RHCSA
Modulo: Essential Commands (Control de Acceso y Permisos Especiales)
Playground: EC-003-v1
Titulo: El Permiso Prohibido – Control de Acceso y Bits Especiales
Fecha de Inicio: 2026-06-15
Dificultad: 6.5/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Permisos básicos y avanzados (chmod, chown, chgrp)
  - Bits especiales: SUID, SGID y Sticky Bit
  - Listas de Control de Acceso básicas (ACLs: setfacl, getfacl)
  - Configuración y validación de UMASK por defecto
  - Refresco: Búsqueda y ejecución masiva con find -exec (EC-002)
Competencias: |-
  - Asegurar directorios temporales compartidos implementando el Sticky Bit para prevenir eliminaciones o modificaciones no autorizadas por parte de otros usuarios.
  - Configurar la herencia de grupo en directorios de proyecto mediante el bit SGID, garantizando la colaboración segura entre equipos.
  - Evaluar y aplicar el bit SUID de manera controlada y segura en binarios o scripts específicos que requieran elevación de privilegios sin depender de sudo.
  - Ajustar el UMASK del sistema para garantizar permisos por defecto seguros y corregir inconsistencias de permisos de forma recursiva y eficiente utilizando find -exec.
  - Documentar y enviar la evidencia de los cambios de permisos y ACLs a la bóveda de cumplimiento (node03) mediante pipelines SSH, sin materializar archivos en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_ec003.sh
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

  echo -e "\e[1;33m⏳ Inyectando vulnerabilidades de permisos en node02...\e[0m"
  $SSH2 bash << 'NODE02_INJECT' || echo -e "\e[1;33m  [!] Detalle en node02, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'
      groupadd -f dev-team 2>/dev/null || true
      groupadd -f backup-ops 2>/dev/null || true

      # 1. Directorio compartido inseguro (Falta Sticky Bit)
      mkdir -p /tmp/shared-project
      chmod 777 /tmp/shared-project
      touch /tmp/shared-project/file_userA.txt

      # 2. Directorio proyecto sin herencia de grupo (Falta SGID)
      mkdir -p /opt/projects/dev-team
      chown root:dev-team /opt/projects/dev-team
      chmod 755 /opt/projects/dev-team

      # 3. Script de backup (Creación robusta sin escapes)
      mkdir -p /opt/scripts
      cat > /opt/scripts/secure_backup << 'BACKUP_SCRIPT'
  #!/bin/bash
  echo "[BACKUP] Ejecutando con privilegios del grupo backup-ops"
  BACKUP_SCRIPT
      chmod 750 /opt/scripts/secure_backup
      chown root:backup-ops /opt/scripts/secure_backup

      # 4. Logs expuestos
      mkdir -p /var/log/app-logs
      chmod 777 /var/log/app-logs
      touch /var/log/app-logs/error.log
      chmod 666 /var/log/app-logs/error.log

      # 5. UMASK peligroso
      echo "umask 000" > /etc/profile.d/99-insecure-umask.sh

      echo "[EC-003] Escenario inyectado correctamente."
  SUDO_INNER
  NODE02_INJECT

  echo -e "\e[1;33m⏳ Preparando bóveda en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/ec-003/
      mkdir -p /opt/ops-compliance/ec-003/
      chown -R bob:bob /opt/ops-compliance/ec-003/
      chmod 750 /opt/ops-compliance/ec-003/
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en preparación de node03, continuando...\e[0m'"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m EC-003-v1 | El Permiso Prohibido | Dificultad: 6.5/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/ec-003/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El equipo de CISO (Chief Information Security Officer) ha finalizado una"
  echo -e " auditoría de hardening en node02 y ha levantado un ticket de remediación"
  echo -e " urgente. Se detectaron múltiples violaciones a la política de control de"
  echo -e " acceso que exponen al clúster a riesgos de elevación de privilegios y"
  echo -e " pérdida de integridad de datos."
  echo -e ""
  echo -e " Como ingeniero L2, se te asigna la remediación de estos hallazgos. Debes"
  echo -e " aplicar los principios de mínimo privilegio, asegurando la colaboración"
  echo -e " entre equipos sin comprometer la seguridad del sistema de archivos."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01 vía SSH."
  echo -e " \e[1m>\e[0m No se permite materializar archivos de reporte o scripts temporales en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente de node02 hacia node03 mediante pipeline."
  echo -e ""
  echo -e "\e[1;33m PARÁMETROS TÉCNICOS OBLIGATORIOS (TICKET DE REMEDIACIÓN - NIVEL L2)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Protección de Directorio Compartido (/tmp/shared-project)\e[0m"
  echo -e "    Estado actual: Permisos 777. Cualquier usuario puede borrar archivos ajenos."
  echo -e "    Objetivo: Asegurar que SOLO el propietario de un archivo (o root) pueda eliminarlo dentro de este directorio."
  echo -e "    \e[1;33mRestricción:\e[0m Investiga y aplica el bit especial correspondiente (Sticky Bit) manteniendo el acceso total actual."
  echo -e ""
  echo -e " \e[1m2. Herencia de Grupo en Proyectos (/opt/projects/dev-team)\e[0m"
  echo -e "    Estado actual: Los archivos nuevos creados por usuarios heredan su grupo primario, rompiendo la colaboración."
  echo -e "    Objetivo: Configurar el directorio para que CUALQUIER archivo o subdirectorio creado dentro herede automáticamente el grupo 'dev-team'."
  echo -e "    \e[1;33mRestricción:\e[0m Aplica el bit especial SGID en directorios. Los permisos base para Owner y Group deben ser de lectura/escritura/ejecución, y otros solo lectura/ejecución."
  echo -e ""
  echo -e " \e[1m3. Ejecución Privilegiada sin Sudo (/opt/scripts/secure_backup)\e[0m"
  echo -e "    Estado actual: El operador no tiene sudo, pero el binario requiere privilegios del grupo 'backup-ops' para correr."
  echo -e "    Objetivo: Permitir que cualquier miembro del sistema ejecute el script, pero que este corra CON LOS PRIVILEGIOS del GRUPO propietario ('backup-ops'), no del usuario que lo lanza."
  echo -e "    \e[1;33mRestricción:\e[0m Determina si requieres SUID o SGID. Configura el archivo para que el Owner tenga control total, el Grupo pueda leer/ejecutar con el bit especial activo, y Otros no tengan ningún acceso."
  echo -e ""
  echo -e " \e[1m4. Corrección Masiva y UMASK (/var/log/app-logs)\e[0m"
  echo -e "    Estado actual: Se detectó una vulnerabilidad global de UMASK (000) y logs expuestos con 777/666."
  echo -e "    Objetivo 4.1: Localizar y eliminar el archivo de inicialización en /etc/profile.d/ que altera el UMASK del sistema."
  echo -e "    Objetivo 4.2: Normalizar la estructura de /var/log/app-logs de forma eficiente (un solo comando por tipo de objeto)."
  echo -e "    \e[1;33mRestricción L2:\e[0m No uses chmod -R. Debes separar directorios (deben quedar en 750) de los archivos (deben quedar en 640) usando herramientas de búsqueda avanzada."
  echo -e ""
  echo -e "\e[1;33m PIPELINE DE EVIDENCIA A NODE03\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " Destino: \e[1m/opt/ops-compliance/ec-003/permisos_audit.txt\e[0m"
  echo -e " Debe contener la salida concatenada de:"
  echo -e "  - ls -ld /tmp/shared-project /opt/projects/dev-team"
  echo -e "  - ls -l /opt/scripts/secure_backup"
  echo -e "  - getfacl /var/log/app-logs (o ls -la detallado)"
  echo -e "  - grep umask /etc/profile.d/*.sh"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Sticky Bit aplicado correctamente en /tmp/shared-project        20%"
  echo -e "  [ ] SGID configurado para herencia de grupo en /opt/projects/       20%"
  echo -e "  [ ] Bit especial (SUID/SGID) aplicado a /opt/scripts/secure_backup  20%"
  echo -e "  [ ] UMASK inseguro eliminado y permisos de logs corregidos (find)   20%"
  echo -e "  [ ] Evidencia (permisos_audit.txt) presente en bóveda node03        20%"
  echo -e "  [ ] CERO archivos de resultados almacenados en node01 \e[1;31m(DESCALIFICA)\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_ec003.sh && rm -f /tmp/setup_ec003.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - File-Permissions
  - SUID-SGID-Sticky
  - ACLs
  - UMASK
Escenario: |-
  - Situación: Desde node01 te conectas a node02 (refrescando las técnicas de acceso remoto). Una auditoría de seguridad reciente ha revelado múltiples vulnerabilidades críticas en la gestión de archivos del sistema. 
  Tu misión:
  1. Un directorio temporal compartido (/tmp/shared-project) permite que cualquier usuario elimine o modifique archivos de otros usuarios. Debes aplicar el Sticky Bit para proteger la integridad de los datos.
  2. Los archivos nuevos creados en los directorios de proyecto (/opt/projects) no están heredando el grupo correcto, rompiendo la colaboración entre equipos. Debes configurar el bit SGID en estos directorios.
  3. Un script de backup crítico (/opt/scripts/secure_backup.sh) necesita ejecutarse con privilegios elevados, pero las políticas de seguridad prohíben el uso de sudo para esta tarea. Debes evaluar y configurar el bit SUID (o SGID) de manera segura para permitir su ejecución con los privilegios necesarios.
  4. Ajustar el UMASK global o del usuario para garantizar permisos por defecto seguros, y utilizar find -exec chmod para corregir inconsistencias de permisos de forma recursiva en los directorios afectados.
  Regla de Oro: Toda la evidencia de la auditoría de permisos (salida de ls -ld, getfacl, o find) debe enviarse a node03 via pipeline SSH, sin dejar rastros intermedios ni archivos de texto en node01.
---
[[Laboratorios del LFCS]]
---



Tell me about a recent challenge you've faced at work.

Sure. Recently, I was handed a remediation ticket — what we'd call an L2-level task — involving a multi-node Linux environment where several critical permission misconfigurations had been flagged as security vulnerabilities.

The scope covered four areas. First, a shared directory had world-writable permissions with no deletion protection, meaning any user could remove another user's files. I resolved that by applying the Sticky Bit, so only file owners or root can delete within that path. Second, a collaborative project directory wasn't enforcing group ownership on new files, which was breaking team workflows. I configured the SGID bit so any file or subdirectory created inside automatically inherits the correct group.

Third, there was a backup script that needed to run with elevated group privileges, but operators didn't have sudo access. I applied SGID directly to the binary so it executes under the owning group's context regardless of who launches it — no sudo required, no privilege escalation risk.

The fourth issue was the most systemic: someone had deployed a shell initialization file in /etc/profile.d/ that set the system-wide umask to 000, exposing every file created on the system. I tracked down that file, removed it, and then corrected the existing log directory structure using targeted find commands — separately for directories and files — without resorting to a blanket chmod -R, which is considered bad practice in production environments.

Once all four tasks were validated, I piped the audit evidence directly to a secure vault node without leaving any artifacts on the intermediate host — which was an explicit compliance requirement.

The whole exercise reinforced something I really believe in: in Linux systems administration, permissions aren't just a configuration detail. They're your first line of defense, and getting them wrong — even subtly — can have serious security implications.