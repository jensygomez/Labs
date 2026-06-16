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
  $SSH2 "echo caleston123 | sudo -S bash -c '
      # 1. Preparar grupos necesarios
      groupadd -f dev-team
      groupadd -f backup-ops

      # 2. Vulnerabilidad A: Directorio compartido sin Sticky Bit
      mkdir -p /tmp/shared-project
      chmod 777 /tmp/shared-project
      touch /tmp/shared-project/file_userA.txt /tmp/shared-project/file_userB.txt
      chown root:root /tmp/shared-project/file_userA.txt /tmp/shared-project/file_userB.txt

      # 3. Vulnerabilidad B: Directorio de proyecto sin herencia de grupo (SGID)
      mkdir -p /opt/projects/dev-team
      chown root:dev-team /opt/projects/dev-team
      chmod 755 /opt/projects/dev-team

      # 4. Vulnerabilidad C: Script de backup sin privilegios delegados (necesita SGID/SUID)
      mkdir -p /opt/scripts
      printf \"#!/bin/bash\\necho 'Ejecutando backup seguro con privilegios...'\\n\" > /opt/scripts/secure_backup
      chmod 750 /opt/scripts/secure_backup
      chown root:backup-ops /opt/scripts/secure_backup

      # 5. Vulnerabilidad D: Permisos recursivos incorrectos en logs
      mkdir -p /var/log/app-logs
      chmod 777 /var/log/app-logs
      touch /var/log/app-logs/error.log /var/log/app-logs/access.log
      chmod 666 /var/log/app-logs/*.log

      # 6. Vulnerabilidad E: UMASK global inseguro
      echo \"umask 000\" > /etc/profile.d/99-insecure-umask.sh
      
      echo \"[EC-003] Escenario de permisos inyectado correctamente.\"
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en inyección de node02, continuando...\e[0m'"

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
  echo -e "\e[1;33m PARÁMETROS TÉCNICOS OBLIGATORIOS (TICKET DE REMEDIACIÓN)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Protección de Directorio Compartido (/tmp/shared-project)\e[0m"
  echo -e "    Estado actual: Cualquier usuario puede eliminar o modificar archivos"
  echo -e "    de otros usuarios dentro de este directorio."
  echo -e "    Objetivo: Asegurar que los usuarios puedan crear archivos, pero que"
  echo -e "    solo el propietario del archivo o root puedan eliminarlo o renombrarlo."
  echo -e ""
  echo -e " \e[1m2. Herencia de Grupo en Proyectos (/opt/projects/dev-team)\e[0m"
  echo -e "    Estado actual: Los archivos nuevos creados en este directorio no"
  echo -e "    pertenecen al grupo del proyecto, rompiendo la colaboración."
  echo -e "    Objetivo: Configurar el directorio para que cualquier archivo o"
  echo -e "    subdirectorio nuevo herede automáticamente el grupo propietario."
  echo -e ""
  echo -e " \e[1m3. Ejecución Privilegiada sin Sudo (/opt/scripts/secure_backup)\e[0m"
  echo -e "    Estado actual: El operador necesita ejecutar este script, pero las"
  echo -e "    políticas de seguridad prohíben otorgarle acceso sudo."
  echo -e "    Objetivo: Configurar el bit especial de ejecución adecuado en el"
  echo -e "    archivo para que se ejecute con los privilegios de su propietario/grupo."
  echo -e ""
  echo -e " \e[1m4. Corrección Masiva y UMASK (/var/log/app-logs y perfil global)\e[0m"
  echo -e "    Estado actual: Los logs tienen permisos 777/666. El UMASK global"
  echo -e "    está configurado en 000, exponiendo archivos nuevos."
  echo -e "    Objetivo: Identificar y neutralizar el UMASK inseguro. Utilizar"
  echo -e "    herramientas de búsqueda masiva (find -exec) para corregir los"
  echo -e "    permisos de /var/log/app-logs a estándares seguros (ej. 750/640)."
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
