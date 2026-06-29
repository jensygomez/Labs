---
Curso: Transición Sysadmin a DevOps - Users, Groups & Resource Management LFCS/RHCSA
Modulo: Users, Groups & Resource Management (Autenticación SSH y Hardening)
Playground: USR-005-v1
Titulo: Cerrando la Puerta Grande – SSH Hardening Básico en node02
Fecha de Inicio: 2026-06-29
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Configuración del servidor SSH (/etc/ssh/sshd_config)
  - Gestión de acceso a la cuenta root (PermitRootLogin)
  - Autenticación por llaves vs contraseñas (PasswordAuthentication)
  - Reinicio seguro del servicio sshd
  - Validación de configuración antes de aplicar cambios (sshd -t)
  - Estrategias de recuperación ante bloqueo accidental de acceso SSH
Competencias: |-
  - Auditar la configuración actual del servidor SSH identificando directivas inseguras (PermitRootLogin, PasswordAuthentication) mediante inspección directa de sshd_config y configuración activa (sshd -T).
  - Modificar /etc/ssh/sshd_config aplicando hardening básico: deshabilitar login directo de root y forzar autenticación exclusiva por llaves públicas.
  - Validar sintácticamente la configuración modificada con sshd -t antes de reiniciar el servicio, evitando bloqueos por errores de sintaxis.
  - Ejecutar un reinicio controlado del servicio sshd manteniendo una sesión activa como red de seguridad (patrón "no cierres la puerta hasta probar la nueva llave").
  - Verificar que la configuración efectiva (sshd -T) refleje los cambios aplicados sin requerir reconexión.
  - Documentar el antes/después de la configuración y enviar la evidencia a node03 mediante pipeline SSH, sin materializar archivos en node01.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_usr005.sh

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

      # 2. Asegurar que la autenticación por contraseña está HABILITADA inicialmente
      # (para que el estudiante pueda conectarse y hacer el hardening)
      
      # Restaurar configuración por defecto si existe
      if [ -f /etc/ssh/sshd_config.dpkg-dist ]; then
          cp /etc/ssh/sshd_config.dpkg-dist /etc/ssh/sshd_config
      fi
      
      # Forzar estado inseguro para el escenario
      # PermitRootLogin habilitado
      if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
          sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
      else
          echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
      fi
      
      # PasswordAuthentication habilitado (CRÍTICO: el estudiante necesita esto para conectarse)
      if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
          sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
      else
          echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
      fi
      
      # ChallengeResponseAuthentication habilitado
      if grep -q "^ChallengeResponseAuthentication" /etc/ssh/sshd_config; then
          sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
      else
          echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config
      fi
      
      # Remover AllowUsers si existe (para que cualquier usuario pueda entrar)
      sed -i '/^AllowUsers/d' /etc/ssh/sshd_config

      # 3. Reiniciar sshd para aplicar la configuración "insegura"
      systemctl restart sshd
      
      # 4. Verificar que la contraseña funciona (para confirmar que el escenario está listo)
      echo "[USR-005] Escenario preparado: SSH en estado inseguro (acceso por contraseña habilitado)"
      echo "[USR-005] El estudiante puede conectarse con: ssh bob@node02 (contraseña: caleston123)"

  SUDO_INNER
  NODE02_INJECT

  echo -e "\e[1;33m⏳ Preparando bóveda de evidencia en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/usr-005/
      mkdir -p /opt/ops-compliance/usr-005/
      chown -R bob:bob /opt/ops-compliance/usr-005/
      chmod 750 /opt/ops-compliance/usr-005/
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en preparación de node03, continuando...\e[0m'"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m USR-005-v1 | Cerrando la Puerta Grande | Dificultad: 6/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Objetivo: node02  |  Bóveda: node03:/opt/ops-compliance/usr-005/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El equipo de auditoría de seguridad interna acaba de entregar su reporte"
  echo -e " trimestral. Entre los hallazgos críticos, se identificó que node02 —un servidor"
  echo -e " de aplicación en producción— permite el login directo del usuario root vía SSH"
  echo -e " y además acepta autenticación por contraseña."
  echo -e ""
  echo -e " Esto viola la política de seguridad corporativa y expone al nodo a ataques de"
  echo -e " fuerza bruta y escalada de privilegios directa. El CISO ha emitido un ticket"
  echo -e " urgente (SEC-2026-0412) exigiendo remediación inmediata."
  echo -e ""
  echo -e " Como ingeniero L2 del equipo de seguridad de infraestructura, se te asigna"
  echo -e " la tarea de aplicar hardening básico al servidor SSH de node02."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Toda la intervención debe realizarse desde node01."
  echo -e " \e[1m>\e[0m No se permite materializar archivos de reporte o scripts temporales en node01."
  echo -e " \e[1m>\e[0m La evidencia debe fluir directamente hacia node03 mediante pipeline."
  echo -e " \e[1m>\e[0m Debes mantener tu sesión SSH activa como red de seguridad durante el reinicio."
  echo -e ""
  echo -e "\e[1;33m PARÁMETROS TÉCNICOS OBLIGATORIOS (TICKET SEC-2026-0412 - NIVEL L2)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1m1. Conexión Inicial a node02\e[0m"
  echo -e "    Estado actual: node02 acepta autenticación por contraseña."
  echo -e "    Objetivo: Conectarte a node02 desde node01 usando SSH con contraseña."
  echo -e "    \e[1;33mComando:\e[0m ssh bob@node02 (contraseña: caleston123)"
  echo -e ""
  echo -e " \e[1m2. Auditoría de Configuración Actual\e[0m"
  echo -e "    Estado actual: Ya estás conectado a node02."
  echo -e "    Objetivo: Auditar la configuración actual del servidor SSH."
  echo -e "    Debes identificar el estado de las directivas PermitRootLogin, PasswordAuthentication,"
  echo -e "    y ChallengeResponseAuthentication, tanto en el archivo de configuración como en la"
  echo -e "    configuración efectiva cargada por el daemon."
  echo -e "    \e[1;33mComandos clave:\e[0m grep en /etc/ssh/sshd_config, sudo sshd -T"
  echo -e ""
  echo -e " \e[1m3. Aplicar Hardening Básico\e[0m"
  echo -e "    Estado actual: sshd_config permite login de root y autenticación por contraseña."
  echo -e "    Objetivo: Modificar /etc/ssh/sshd_config para:"
  echo -e "    - Establecer PermitRootLogin en no (prohibir login directo de root)"
  echo -e "    - Establecer PasswordAuthentication en no (forzar autenticación por llaves)"
  echo -e "    - Establecer ChallengeResponseAuthentication en no (evitar bypasses por PAM)"
  echo -e "    \e[1;33mRestricción:\e[0m Haz backup de sshd_config antes de modificarlo."
  echo -e ""
  echo -e " \e[1m4. Validación de Sintaxis\e[0m"
  echo -e "    Estado actual: Archivo modificado pero no validado."
  echo -e "    Objetivo: Validar la sintaxis del archivo modificado con sudo sshd -t antes de cualquier reinicio."
  echo -e "    Si hay errores, corregirlos antes de continuar."
  echo -e "    \e[1;33mComando:\e[0m sudo sshd -t"
  echo -e ""
  echo -e " \e[1m5. Reinicio Seguro del Servicio\e[0m"
  echo -e "    Estado actual: Configuración validada pero no aplicada."
  echo -e "    Objetivo: Reiniciar el servicio sshd aplicando el patrón de seguridad 'sesión abierta"
  echo -e "    como red de seguridad': mantén tu sesión SSH activa mientras reinicias el servicio."
  echo -e "    \e[1;33mPatrón:\e[0m NO cierres tu sesión actual. Abre otra terminal o usa sshd -T para"
  echo -e "    verificar que la nueva configuración está cargada. Si algo falla, tu sesión activa"
  echo -e "    te permite revertir los cambios sin quedar bloqueado fuera del servidor."
  echo -e ""
  echo -e " \e[1m6. Verificación de Configuración Efectiva\e[0m"
  echo -e "    Estado actual: Servicio reiniciado."
  echo -e "    Objetivo: Verificar que la configuración efectiva refleje los cambios aplicados."
  echo -e "    \e[1;33mComando:\e[0m sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|challengeresponseauthentication'"
  echo -e "    \e[1;33mRestricción:\e[0m No necesitas reconectarte para verificar; sshd -T muestra la configuración cargada."
  echo -e ""
  echo -e "\e[1;33m PIPELINE DE EVIDENCIA A NODE03\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " Destino: \e[1m/opt/ops-compliance/usr-005/ssh_hardening_audit.txt\e[0m"
  echo -e " Debe contener la salida concatenada de:"
  echo -e "  - Estado ANTES: grep -E 'PermitRootLogin|PasswordAuthentication|ChallengeResponseAuthentication' /etc/ssh/sshd_config (antes de modificar)"
  echo -e "  - Estado ANTES: sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|challengeresponseauthentication' (antes de modificar)"
  echo -e "  - Backup creado: ls -la /etc/ssh/sshd_config.pre-usr005.*"
  echo -e "  - Estado DESPUÉS: grep -E 'PermitRootLogin|PasswordAuthentication|ChallengeResponseAuthentication' /etc/ssh/sshd_config"
  echo -e "  - Validación de sintaxis: sudo sshd -t"
  echo -e "  - Estado efectivo DESPUÉS: sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|challengeresponseauthentication'"
  echo -e "  - Estado del servicio: systemctl status sshd"
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Auditoría inicial documentada (estado antes del hardening)          15%"
  echo -e "  [ ] Backup de sshd_config creado antes de modificaciones                10%"
  echo -e "  [ ] PermitRootLogin establecido en no                                   20%"
  echo -e "  [ ] PasswordAuthentication establecido en no                            20%"
  echo -e "  [ ] ChallengeResponseAuthentication establecido en no                   10%"
  echo -e "  [ ] Sintaxis validada con sshd -t (sin errores)                         10%"
  echo -e "  [ ] Servicio sshd reiniciado y corriendo                                10%"
  echo -e "  [ ] Configuración efectiva verificada con sshd -T                        5%"
  echo -e ""
  echo -e "\e[1;31m  ⚠️  ADVERTENCIA CRÍTICA DE SEGURIDAD:\e[0m"
  echo -e "     Nunca cierres tu sesión SSH actual hasta haber verificado que puedes"
  echo -e "     abrir una nueva conexión con la configuración aplicada. El reinicio de"
  echo -e "     sshd NO corta sesiones establecidas, pero un error de configuración"
  echo -e "     mal validado SÍ puede bloquearte permanentemente."
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_usr005.sh && rm -f /tmp/setup_usr005.sh
tags:
  - Laboratorios-del-LFCS
  - Users-Groups
  - SSH
  - Hardening
  - Security
  - Root-Account
  - Zero-Trust
Escenario: |-
  - Situación: El equipo de auditoría de seguridad interna acaba de entregar su reporte trimestral. Entre los hallazgos críticos, se identificó que node02 —un servidor de aplicación en producción— permite el login directo del usuario root vía SSH y además acepta autenticación por contraseña. Esto viola la política de seguridad corporativa y expone al nodo a ataques de fuerza bruta y escalada de privilegios directa.

  El CISO ha emitido un ticket urgente (SEC-2026-0412) exigiendo remediación inmediata. Tienes 30 minutos antes de la ventana de cambio programada.

  Tu misión:
  1. Conectarte a node02 desde node01 (ya tienes acceso configurado con llaves SSH desde el laboratorio USR-004) y auditar la configuración actual del servidor SSH. Debes identificar el estado de las directivas PermitRootLogin y PasswordAuthentication, tanto en el archivo de configuración como en la configuración efectiva cargada por el daemon.

  2. Aplicar el hardening básico modificando /etc/ssh/sshd_config:
     - Establecer PermitRootLogin en no (prohibir login directo de root).
     - Establecer PasswordAuthentication en no (forzar autenticación exclusiva por llaves).
     - Asegurarte de que ChallengeResponseAuthentication también esté en no para evitar bypasses por PAM.

  3. Validar la sintaxis del archivo modificado con sshd -t antes de cualquier reinicio. Si hay errores, corregirlos antes de continuar.

  4. Reiniciar el servicio sshd aplicando el patrón de seguridad "sesión abierta como red de seguridad": mantén tu sesión SSH activa mientras reinicias el servicio y verifica desde otra conexión (o con sshd -T) que la nueva configuración está cargada. Si algo falla, tu sesión activa te permite revertir los cambios sin quedar bloqueado fuera del servidor.

  5. Verificar que la configuración efectiva refleje los cambios (sshd -T | grep -E 'permitrootlogin|passwordauthentication|challengeresponseauthentication') y documentar el estado final.

  Regla de Oro: Nunca cierres tu sesión SSH actual hasta haber verificado que puedes abrir una nueva conexión con la configuración aplicada. El reinicio de sshd no corta sesiones establecidas, pero un error de configuración mal validado sí puede bloquearte permanentemente. Además, no puedes crear archivos de texto intermedios en node01; toda la evidencia debe fluir directamente a node03 mediante pipelines.
---
[[Laboratorios del LFCS]]
---

Recently, I worked on a security remediation ticket where our internal audit team found that one of our production servers was allowing direct root login via SSH and also accepted password authentication — which violated our security policy and created a real risk of brute-force attacks.

I was responsible for hardening the SSH daemon: I audited the current configuration, both in the config file and the effective settings loaded by the daemon, created a backup before touching anything, then disabled root login, password authentication, and challenge-response authentication. I validated the syntax before restarting the service, and the restart went fine — sshd came back up clean.

But here's the real lesson from that day: I lost SSH access to the server right after the restart. The reason was simple — I never kept a persistent, already-authenticated session open as a safety net before disabling password auth. Each of my commands opened and closed its own connection, so once password authentication was off, there was no existing key-based session still alive to fall back on if something went wrong.

It was a great hands-on reminder that as an administrator, access is never automatic — it depends entirely on having a recovery path active _before_ you change anything that controls that same access. Now I always make sure to keep a live session open, or have an out-of-band recovery method ready, before applying any change to authentication settings.