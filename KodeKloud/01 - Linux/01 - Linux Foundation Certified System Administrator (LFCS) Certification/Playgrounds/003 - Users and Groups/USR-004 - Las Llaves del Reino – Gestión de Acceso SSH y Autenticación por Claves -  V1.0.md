---
Curso: Transición Sysadmin a DevOps - Users, Groups & Resource Management LFCS/RHCSA
Modulo: Users, Groups & Resource Management (Autenticación SSH y Hardening)
Playground: USR-004-v1
Titulo: Las Llaves del Reino – Gestión de Acceso SSH y Autenticación por Claves
Fecha de Inicio: 2026-06-22
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Configuración del servidor SSH (sshd_config)
  - Métodos de autenticación SSH (contraseñas vs llaves)
  - Generación y gestión de pares de llaves SSH (ssh-keygen)
  - Distribución de llaves públicas (authorized_keys)
  - Restricciones avanzadas en authorized_keys (from=, command=, no-pty)
  - Hardening de SSH (PasswordAuthentication, PermitRootLogin, AllowUsers)
Competencias: |-
  - Generar pares de llaves SSH seguros (ed25519 o rsa 4096-bit) para diferentes propósitos: acceso humano y automatización.
  - Distribuir llaves públicas a servidores remotos configurando correctamente ~/.ssh/authorized_keys con permisos apropiados (700 para .ssh, 600 para authorized_keys).
  - Aplicar restricciones avanzadas en authorized_keys para limitar el origen de conexiones (from=), comandos permitidos (command=), y otras opciones de seguridad.
  - Realizar hardening del servidor SSH modificando /etc/ssh/sshd_config para deshabilitar autenticación por contraseña, login directo de root, y aplicar el principio de menor privilegio.
  - Configurar acceso SSH sin contraseña para procesos de automatización (scripts de despliegue, CI/CD pipelines) manteniendo la trazabilidad y seguridad.
  - Documentar la configuración SSH y enviar la evidencia de acceso exitoso a node03 vía pipeline SSH, sin materializar archivos en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_usr004.sh

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

  echo -e "\e[1;33m⏳ Preparando escenario de hardening SSH en node02...\e[0m"
  $SSH2 bash << 'NODE02_INJECT' || echo -e "\e[1;33m  [!] Detalle en node02, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'

      # 1. Asegurar que SSH está instalado y funcionando
      systemctl is-active --quiet sshd || systemctl start sshd
      systemctl enable sshd

      # 2. Crear script de health-check que será el único comando permitido para automatización
      cat > /usr/local/bin/health-check.sh << 'HEALTHCHECK'
  #!/bin/bash
  echo "=== Health Check Report ==="
  echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Hostname: $(hostname)"
  echo "Uptime: $(uptime -p)"
  echo "Load Average: $(cat /proc/loadavg | cut -d' ' -f1-3)"
  echo "Memory Usage: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
  echo "Disk Usage: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
  echo "=== End Report ==="
  HEALTHCHECK
      chmod 755 /usr/local/bin/health-check.sh

      # 3. Crear directorio .ssh para bob (será limpiado por el ingeniero)
      mkdir -p /home/bob/.ssh
      chown bob:bob /home/bob/.ssh
      chmod 700 /home/bob/.ssh
      
      # Crear authorized_keys vacío (el ingeniero lo poblará)
      touch /home/bob/.ssh/authorized_keys
      chown bob:bob /home/bob/.ssh/authorized_keys
      chmod 600 /home/bob/.ssh/authorized_keys

      # 4. Hacer backup de la configuración actual de SSH
      cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%s)

      # 5. Obtener la IP de node01 para usarla en las restricciones
      NODE01_IP=$(hostname -I | awk '{print $1}')
      
      # 6. Crear archivo de documentación sobre la política de SSH
      cat > /etc/ssh/SSH_POLICY.txt << 'SSHPOLICY'
  POLÍTICA DE SEGURIDAD SSH - RESTRICCIONES APLICABLES
  =====================================================

  1. La autenticación por contraseña ESTÁ PROHIBIDA para acceso de producción
  2. Solo se permite autenticación basada en llaves SSH (RSA 4096-bit o Ed25519)
  3. El login directo de root está DESHABILITADO
  4. Las llaves de automatización deben estar restringidas por IP de origen
  5. Las llaves de automatización solo pueden ejecutar comandos específicos

  Para agregar una nueva llave:
  - Acceso humano: agregar directamente a authorized_keys
  - Acceso automatizado: usar formato restrictivo:
    from="IP_NODE01",command="/usr/local/bin/health-check.sh",no-pty,no-port-forwarding ssh-ed25519 AAAA...
  SSHPOLICY
      chmod 644 /etc/ssh/SSH_POLICY.txt

      echo "[USR-004] Escenario de hardening SSH preparado correctamente."
  SUDO_INNER
  NODE02_INJECT

  echo -e "\e[1;33m⏳ Preparando bóveda de evidencia en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/usr-004/
      mkdir -p /opt/ops-compliance/usr-004/
      chown -R bob:bob /opt/ops-compliance/usr-004/
      chmod 750 /opt/ops-compliance/usr-004/
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en preparación de node03, continuando...\e[0m'"

  # Limpiar cualquier llave SSH previa en node01 para empezar desde cero
  rm -rf /home/bob/.ssh 2>/dev/null || true
  mkdir -p /home/bob/.ssh
  chmod 700 /home/bob/.ssh

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m USR-004-v1 | Las Llaves del Reino | Dificultad: 6/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Objetivo: node02  |  Bóveda: node03:/opt/ops-compliance/usr-004/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El Centro de Operaciones de Seguridad (SOC) ha detectado múltiples intentos"
  echo -e " de fuerza bruta contra el servidor node02 durante las últimas 24 horas. El"
  echo -e " análisis forense de los logs de autenticación revela que los atacantes están"
  echo -e " utilizando diccionarios de contraseñas comunes para intentar acceder mediante"
  echo -e " SSH."
  echo -e ""
  echo -e " El CISO ha emitido una directiva urgente para implementar autenticación"
  echo -e " basada exclusivamente en llaves SSH en todos los servidores de producción,"
  echo -e " eliminando por completo la autenticación por contraseña. Esta medida es parte"
  echo -e " de la adopción del marco de seguridad Zero Trust."
  echo -e ""
  echo -e " Como ingeniero L2 del equipo de seguridad de infraestructura, se te asigna"
  echo -e " la tarea de configurar la autenticación SSH basada en llaves, aplicar"
  echo -e " restricciones avanzadas para llaves de automatización, y realizar el"
  echo -e " hardening completo del servidor SSH."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01."
  echo -e " \e[1m>\e[0m No se permite materializar archivos de reporte o scripts temporales en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente hacia node03 mediante pipeline."
  echo -e " \e[1m>\e[0m Las llaves SSH deben generarse en node01 y distribuirse a node02."
  echo -e ""
  echo -e "\e[1;33m PARÁMETROS TÉCNICOS OBLIGATORIOS (TICKET DE HARDENING - NIVEL L2)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Generación de Llaves SSH en node01\e[0m"
  echo -e "    Estado actual: No existen llaves SSH configuradas para acceso a node02."
  echo -e "    Objetivo: Generar dos pares de llaves SSH en node01:"
  echo -e "    - \e[1mLlave de acceso humano\e[0m: Para el administrador (sin restricciones)"
  echo -e "    - \e[1mLlave de automatización\e[0m: Para scripts de despliegue (con restricciones)"
  echo -e "    \e[1;33mRestricción:\e[0m Usa ssh-keygen con algoritmo ed25519 o rsa 4096-bit."
  echo -e "    Almacena las llaves en ~/.ssh/ con nombres descriptivos (ej. id_ed25519_admin,"
  echo -e "    id_ed25519_automation)."
  echo -e ""
  echo -e " \e[1m2. Distribución de Llaves Públicas a node02\e[0m"
  echo -e "    Estado actual: El archivo authorized_keys en node02 está vacío."
  echo -e "    Objetivo: Copiar las llaves públicas generadas a /home/bob/.ssh/authorized_keys"
  echo -e "    en node02, asegurando los permisos correctos."
  echo -e "    \e[1;33mRestricción:\e[0m El directorio .ssh debe tener permisos 700 y authorized_keys"
  echo -e "    debe tener permisos 600. La propiedad debe ser bob:bob."
  echo -e ""
  echo -e " \e[1m3. Restricciones Avanzadas en authorized_keys\e[0m"
  echo -e "    Estado actual: Las llaves están instaladas sin restricciones."
  echo -e "    Objetivo: Aplicar restricciones a la llave de automatización:"
  echo -e "    - Solo permitir conexiones desde la IP de node01 (from=\"IP\")"
  echo -e "    - Solo permitir ejecutar /usr/local/bin/health-check.sh (command=\"...\")"
  echo -e "    - Deshabilitar PTY y port-forwarding (no-pty, no-port-forwarding)"
  echo -e "    \e[1;33mRestricción:\e[0m Modifica la línea de la llave de automatización en"
  echo -e "    authorized_keys agregando las opciones al inicio de la línea."
  echo -e ""
  echo -e " \e[1m4. Hardening del Servidor SSH en node02\e[0m"
  echo -e "    Estado actual: sshd_config permite autenticación por contraseña y root login."
  echo -e "    Objetivo: Modificar /etc/ssh/sshd_config para:"
  echo -e "    - Deshabilitar PasswordAuthentication (PasswordAuthentication no)"
  echo -e "    - Deshabilitar PermitRootLogin (PermitRootLogin no)"
  echo -e "    - Permitir solo usuarios específicos (AllowUsers bob)"
  echo -e "    - Reiniciar el servicio sshd para aplicar los cambios"
  echo -e "    \e[1;33mRestricción:\e[0m Haz backup de sshd_config antes de modificarlo. Valida"
  echo -e "    la sintaxis con sshd -t antes de reiniciar el servicio."
  echo -e ""
  echo -e " \e[1m5. Verificación de Acceso SSH\e[0m"
  echo -e "    Estado actual: Se requiere validar que el acceso con llave funciona."
  echo -e "    Objetivo: Verificar que:"
  echo -e "    - La llave de acceso humano permite login interactivo a node02"
  echo -e "    - La llave de automatización solo permite ejecutar health-check.sh"
  echo -e "    - El acceso por contraseña está deshabilitado"
  echo -e "    \e[1;33mRestricción:\e[0m Usa ssh -i para especificar la llave. Verifica que"
  echo -e "    sshpass ya no funciona (debe fallar)."
  echo -e ""
  echo -e "\e[1;33m PIPELINE DE EVIDENCIA A NODE03\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " Destino: \e[1m/opt/ops-compliance/usr-004/ssh_audit.txt\e[0m"
  echo -e " Debe contener la salida concatenada de:"
  echo -e "  - ls -la ~/.ssh/ en node01 (llaves generadas)"
  echo -e "  - cat ~/.ssh/authorized_keys en node02 (contenido con restricciones)"
  echo -e "  - grep -E 'PasswordAuthentication|PermitRootLogin|AllowUsers' /etc/ssh/sshd_config"
  echo -e "  - systemctl status sshd en node02"
  echo -e "  - Prueba de acceso con llave de automatización (ssh -i ... /usr/local/bin/health-check.sh)"
  echo -e "  - Verificación de que sshpass falla (autenticación por contraseña deshabilitada)"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Llaves SSH generadas en node01 (humana y automatización)          15%"
  echo -e "  [ ] Llaves distribuidas a node02 con permisos correctos               15%"
  echo -e "  [ ] Restricciones aplicadas a llave de automatización                 20%"
  echo -e "  [ ] Hardening de sshd_config aplicado correctamente                   20%"
  echo -e "  [ ] Acceso con llave funcional (humana y automatización)              15%"
  echo -e "  [ ] Acceso por contraseña deshabilitado (sshpass falla)               10%"
  echo -e "  [ ] Evidencia (ssh_audit.txt) presente en bóveda node03               5%"
  echo -e ""
  echo -e "\e[1;31m  ⚠️  NOTA DE SEGURIDAD:\e[0m Después de aplicar el hardening, la contraseña"
  echo -e "     'caleston123' ya NO funcionará para SSH. Solo las llaves configuradas"
  echo -e "     permitirán el acceso."
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_usr004.sh && rm -f /tmp/setup_usr004.sh
tags:
  - Laboratorios-del-LFCS
  - Users-Groups
  - SSH
  - SSH-Keys
  - Hardening
  - Security
  - Zero-Trust
Escenario: |-
  - Situación: El departamento de Seguridad de la Información ha emitido una directiva urgente para eliminar la autenticación SSH basada en contraseñas en todos los servidores de producción. Esta medida responde a incidentes recientes de fuerza bruta detectados en los logs de autenticación y al cumplimiento del marco de seguridad Zero Trust adoptado por la organización.

  Tu misión:
  1. Generar pares de llaves SSH en node01 para dos propósitos específicos: acceso humano interactivo (para el administrador) y acceso automatizado (para scripts de despliegue que correrán desde node01 hacia node02).

  2. Distribuir las llaves públicas a node02 configurando correctamente el directorio ~/.ssh/ y el archivo authorized_keys del usuario bob, asegurando los permisos correctos (700 para .ssh, 600 para authorized_keys).

  3. Aplicar restricciones avanzadas en authorized_keys: la llave de automatización solo debe permitir conexiones desde la IP de node01, y debe estar restringida a ejecutar únicamente un script específico de health check (/usr/local/bin/health-check.sh).

  4. Realizar hardening del servidor SSH en node02 modificando /etc/ssh/sshd_config para deshabilitar autenticación por contraseña (PasswordAuthentication no), login directo de root (PermitRootLogin no), y permitir solo usuarios específicos (AllowUsers).

  5. Verificar que el acceso SSH con llave funciona correctamente desde node01 hacia node02, tanto para el usuario administrador como para el script de automatización.

  6. Generar un reporte completo de la configuración SSH implementada, incluyendo las llaves instaladas, las restricciones aplicadas, y la verificación de acceso exitoso, enviándolo directamente a node03 vía pipeline SSH.

  Regla de Oro: No puedes crear archivos de texto intermedios en node01. Todo el proceso de configuración debe realizarse en node01 y node02, y la evidencia debe fluir directamente a node03 mediante pipelines.
---
[[Laboratorios del LFCS]]
---
