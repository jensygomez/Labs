---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Playground: NET-002-v1
Titulo: La Paradoja Temporal – Deriva de Reloj y Fallo de Autenticación en Clúster
Fecha de Inicio: 2026-06-12
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para Devops Enginner y Kubernets
Temas: |-
  - System Time Synchronization (NTP, chronyd)
  - Firewall Management (iptables)
  - Service Persistence (systemctl)
Competencias: |-
  - Diagnosticar problemas de sincronización horaria en entornos distribuidos.
  - Administrar servicios de tiempo y asegurar su persistencia.
  - Configurar reglas de firewall sin interrumpir servicios críticos
Script: |-
  cat << 'EOF' > /tmp/setup-net002.sh


  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

  # ── Detectar usuario actual ─────────────────────────────────────────────────
  CURRENT_USER=$(whoami)
  if [ "$CURRENT_USER" = "root" ]; then
    USER_HOME="/home/$USER_NET"
  else
    USER_HOME="$HOME"
  fi

  # ─────────────────────────────────────────────────────────────────────────────
  # 1. INSTALAR SSHPASS LOCALMENTE (en node01, donde se ejecuta el script)
  # ─────────────────────────────────────────────────────────────────────────────
  echo -e "\e[1;33m⏳ Instalando sshpass en el nodo local (node01)...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      # Intentar con apt (Debian/Ubuntu)
      if command -v apt-get &>/dev/null; then
          sudo apt-get update -qq
          sudo apt-get install -y sshpass
      # Si no, intentar con yum (RHEL/CentOS)
      elif command -v yum &>/dev/null; then
          sudo yum install -y sshpass
      else
          echo -e "\e[1;31m✗ No se pudo instalar sshpass: no se encontró apt-get ni yum\e[0m"
          exit 1
      fi
      
      # Verificar que la instalación fue exitosa
      if ! command -v sshpass &>/dev/null; then
          echo -e "\e[1;31m✗ Falló la instalación de sshpass localmente\e[0m"
          exit 1
      fi
  fi
  echo -e "\e[1;32m✔ sshpass instalado localmente.\e[0m"

  # Ahora que sshpass existe localmente, podemos definir SSH
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  # ─────────────────────────────────────────────────────────────────────────────
  # 2. INSTALAR SSHPASS EN LOS NODOS REMOTOS (usando sshpass ya instalado)
  # ─────────────────────────────────────────────────────────────────────────────
  for NODE in node01 node02 node03; do
      echo -e "\e[1;33m⏳ Instalando sshpass en $NODE...\e[0m"
      $SSH ${USER_NET}@${NODE} "
          if ! command -v sshpass &>/dev/null; then
              # Intentar apt
              if command -v apt-get &>/dev/null; then
                  echo $PASS | sudo -S apt-get update -qq
                  echo $PASS | sudo -S apt-get install -y sshpass
              # Si no, intentar yum
              elif command -v yum &>/dev/null; then
                  echo $PASS | sudo -S yum install -y sshpass
              else
                  echo 'No se pudo instalar sshpass remotamente'
                  exit 1
              fi
          fi
      " < /dev/null
      echo -e "\e[1;32m✔ sshpass instalado en $NODE.\e[0m"
  done


  # ─────────────────────────────────────────────────────────────────────────────
  # 3. INSTALAR CHRONY e IPTABLES en los 3 nodos
  # ─────────────────────────────────────────────────────────────────────────────
  echo -e "\e[1;33m⏳ Instalando chrony e iptables en los nodos...\e[0m"
  for NODE in node01 node02 node03; do
      $SSH ${USER_NET}@${NODE} "
          echo $PASS | sudo -S apt-get update -qq && echo $PASS | sudo -S apt-get install -y chrony iptables -qq
          if [ \$? -ne 0 ]; then
              echo $PASS | sudo -S yum install -y chrony iptables -qq
          fi
      " < /dev/null
  done
  echo -e "\e[1;32m✔ Dependencias instaladas en todos los nodos.\e[0m"

  # ─────────────────────────────────────────────────────────────────────────────
  # 4. CONFIGURAR node02 como servidor NTP (referencia correcta)
  # ─────────────────────────────────────────────────────────────────────────────
  $SSH ${USER_NET}@${NODE_TARGET} "
    echo $PASS | sudo -S bash -c '
      CONF_FILE=\"/etc/chrony/chrony.conf\"
      [ -d /etc/chrony ] || CONF_FILE=\"/etc/chrony.conf\"
      cat > \$CONF_FILE << CHRONY
  pool pool.ntp.org iburst
  local stratum 10
  keyfile /etc/chrony/chrony.keys
  driftfile /var/lib/chrony/chrony.drift
  logdir /var/log/chrony
  CHRONY
      systemctl enable --now chrony 2>/dev/null || systemctl enable --now chronyd 2>/dev/null
    '
  " < /dev/null
  echo -e "\e[1;32m✔ node02 configurado como servidor NTP.\e[0m"

  # ─────────────────────────────────────────────────────────────────────────────
  # 5. OBTENER IP DE node03 (para romper su tiempo)
  # ─────────────────────────────────────────────────────────────────────────────
  IP_NODE03=$($SSH ${USER_NET}@${NODE_VAULT} 'hostname -i' 2>/dev/null | tr -d '\r')
  if [ -z "$IP_NODE03" ]; then
      IP_NODE03="10.244.29.59"
  fi

  # ─────────────────────────────────────────────────────────────────────────────
  # 6. ROMPER NTP Y FIREWALL EN node03
  # ─────────────────────────────────────────────────────────────────────────────
  $SSH ${USER_NET}@${IP_NODE03} "
    echo $PASS | sudo -S bash -c '
      systemctl stop chrony 2>/dev/null || systemctl stop chronyd 2>/dev/null || true
      systemctl disable chrony 2>/dev/null || systemctl disable chronyd 2>/dev/null || true

      CONF_FILE=\"/etc/chrony/chrony.conf\"
      [ -d /etc/chrony ] || CONF_FILE=\"/etc/chrony.conf\"
      cat > \$CONF_FILE << CHRONY
  server 192.0.2.1 iburst
  keyfile /etc/chrony/chrony.keys
  driftfile /var/lib/chrony/chrony.drift
  logdir /var/log/chrony
  CHRONY

      iptables -A OUTPUT -p udp --dport 123 -j DROP
      iptables -A INPUT -p udp --dport 123 -j DROP

      date -s \"+15 minutes\" 2>/dev/null || echo \"No se pudo modificar la hora (contenedor)\"
    '
  " < /dev/null
  echo -e "\e[1;33m⏳ node03: NTP roto, firewall bloqueando puerto 123.\e[0m"

  # ─────────────────────────────────────────────────────────────────────────────
  # 7. MOSTRAR EL TICKET
  # ─────────────────────────────────────────────────────────────────────────────
  clear
  cat << 'TICKET'

  RED='\e[1;31m'
  GREEN='\e[1;32m'
  YELLOW='\e[1;33m'
  CYAN='\e[1;36m'
  BLUE='\e[1;34m'
  BOLD='\e[1m'
  MAGENTA='\e[1;35m'
  WHITE='\e[1;37m'
  RESET='\e[0m'

  clear

  echo -e "${CYAN}================================================================================${RESET}"
  echo -e "${YELLOW}  TICKET INC-3002  │  Severidad: ALTA  │  Ambiente: CLÚSTER DISTRIBUIDO${RESET}"
  echo -e "${CYAN}================================================================================${RESET}"
  echo -e "${GREEN}  ⏱️  NET-002-MN — La Paradoja Temporal: NTP y Firewall${RESET}"
  echo -e "${CYAN}  Módulo: Networking  │  Dificultad: 6/10  │  Nivel: L2${RESET}"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Arquitectura del Escenario:${RESET}"
  echo -e "  ${BLUE}[node01]${RESET} → Estación del Administrador     (TU POSICIÓN ACTUAL)"
  echo -e "  ${GREEN}[node02]${RESET} → Servidor de Aplicaciones       (HORA CORRECTA — REFERENCIA)"
  echo -e "  ${RED}[node03]${RESET} → Servidor Backend / Base de Datos (AFECTADO — DERIVA DE TIEMPO)"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Contexto del Incidente:${RESET}"
  echo -e ""
  echo -e "  La señora Priya Nair llevaba dos semanas monitoreando de cerca el"
  echo -e "  comportamiento de la nueva versión del sistema de autenticación que"
  echo -e "  el equipo de desarrollo había desplegado el mes anterior. Todo había"
  echo -e "  funcionado correctamente durante las primeras semanas, así que el lunes"
  echo -e "  por la mañana decidió que ya no era necesario hacer seguimiento diario"
  echo -e "  y trasladó el monitoreo a revisión semanal. Esa misma tarde, a las"
  echo -e "  15:43, el equipo de soporte recibió las primeras llamadas."
  echo -e ""
  echo -e "  Los usuarios reportaban que el sistema los expulsaba de sus sesiones"
  echo -e "  sin previo aviso y les mostraba un mensaje que decía 'Token expirado'."
  echo -e "  Cuando intentaban volver a iniciar sesión, algunos recibían un segundo"
  echo -e "  error: 'Certificado no válido'. El equipo de soporte de primer nivel"
  echo -e "  intentó restablecer las sesiones manualmente, pero el problema persistía."
  echo -e "  En media hora, el volumen de llamadas había triplicado la capacidad"
  echo -e "  normal del turno de tarde."
  echo -e ""
  echo -e "  El ingeniero Vikram Desai, que ese día hacía guardia de segundo nivel,"
  echo -e "  tomó uno de los casos y comenzó a revisar los logs del sistema de"
  echo -e "  autenticación en node02. Los tokens se estaban generando correctamente"
  echo -e "  y los certificados estaban en orden. El problema no estaba en node02."
  echo -e "  Vikram Desai revisó entonces los logs de node03, el servidor de base de"
  echo -e "  datos que almacena las sesiones activas, y encontró algo que no esperaba:"
  echo -e "  los registros de tiempo en node03 estaban desfasados varios minutos"
  echo -e "  respecto a node02. El sistema de autenticación comparaba los timestamps"
  echo -e "  de ambos servidores para validar los tokens, y la diferencia era tan"
  echo -e "  grande que el sistema los interpretaba como expirados antes de tiempo."
  echo -e ""
  echo -e "  Vikram Desai intentó revisar el servicio NTP de node03 para entender"
  echo -e "  cuándo había comenzado la deriva. El servicio no estaba corriendo."
  echo -e "  Intentó iniciarlo manualmente. El servicio arrancaba pero no lograba"
  echo -e "  sincronizarse con ningún servidor de tiempo externo. Vikram Desai"
  echo -e "  revisó las reglas de firewall de node03 y encontró la causa: alguien"
  echo -e "  había agregado una regla que bloqueaba todo el tráfico saliente por"
  echo -e "  el puerto 123 UDP, que es precisamente el puerto que utiliza NTP."
  echo -e "  Nadie en el equipo recordaba haber agregado esa regla. No había"
  echo -e "  registro en el sistema de cambios. No había ticket asociado."
  echo -e ""
  echo -e "  Con ese diagnóstico en mano, Vikram Desai escaló el caso a tu nombre."
  echo -e "  Te dejó una nota en el sistema que decía: encontré el problema, pero"
  echo -e "  mi turno termina en diez minutos y tengo que salir. El firewall está"
  echo -e "  bloqueando NTP en node03, chrony no está sincronizando, y el reloj"
  echo -e "  lleva horas desfasado. Los usuarios siguen sin poder autenticarse."
  echo -e "  La señora Priya Nair ya fue notificada y está esperando el cierre."
  echo -e ""
  echo -e "  El caso lleva abierto noventa y cuatro minutos."
  echo -e ""
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Restricciones Operativas:${RESET}"
  echo -e ""
  echo -e "  ${RED}⚠${RESET}  No está permitido reiniciar node03 como solución al problema."
  echo -e "     La sincronización debe lograrse con el servicio en ejecución."
  echo -e ""
  echo -e "  ${RED}⚠${RESET}  Cualquier cambio en las reglas de firewall debe ser permanente."
  echo -e "     No es suficiente con eliminar la regla en memoria; debe persistir"
  echo -e "     después de un reinicio del sistema."
  echo -e ""
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Parámetros Técnicos Obligatorios:${RESET}"
  echo -e ""
  echo -e "  ${RED}1. Diagnóstico del Estado de Tiempo en node03${RESET}"
  echo -e "     Verifica el estado actual de la sincronización horaria con"
  echo -e "     timedatectl status. Compara la hora de node03 contra node02"
  echo -e "     para cuantificar la magnitud de la deriva antes de intervenir."
  echo -e ""
  echo -e "  ${RED}2. Identificar y Eliminar la Regla de Firewall que Bloquea NTP${RESET}"
  echo -e "     Revisa las reglas activas con sudo iptables -L -n -v e identifica"
  echo -e "     la regla que bloquea el puerto 123/UDP. Elimínala y asegúrate de"
  echo -e "     que el cambio persista después de un reinicio del sistema."
  echo -e ""
  echo -e "  ${RED}3. Configurar y Apuntar el Servicio NTP a un Servidor Válido${RESET}"
  echo -e "     Edita /etc/chrony/chrony.conf (o /etc/chrony.conf) para apuntar"
  echo -e "     a pool.ntp.org o a la IP de node02 como servidor de referencia."
  echo -e "     Asegúrate de que la configuración sea correcta antes de iniciar."
  echo -e ""
  echo -e "  ${RED}4. Iniciar, Habilitar y Forzar Sincronización Inmediata${RESET}"
  echo -e "     Inicia y habilita el servicio chrony para que arranque con el sistema."
  echo -e "     Fuerza una sincronización inmediata con sudo chronyc makestep."
  echo -e "     Verifica con chronyc sources que el servidor de tiempo responde."
  echo -e ""
  echo -e "  ${RED}5. Validación Final y Cierre del Incidente${RESET}"
  echo -e "     Confirma que timedatectl muestre 'System clock synchronized: yes'."
  echo -e "     Verifica que la diferencia de hora entre node02 y node03 sea"
  echo -e "     menor a 5 segundos antes de notificar el cierre a la señora Priya Nair."
  echo -e ""
  echo -e " ${BOLD}Criterios de Aceptación:${RESET}"
  echo -e ""
  echo -e "  [ ] Firewall de node03 permite tráfico NTP (puerto 123/UDP)       --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] Servicio chrony activo, habilitado y arranca con el sistema    --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] Configuración de chrony apunta a servidor NTP válido           --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] Reloj de node03 sincronizado (timedatectl: synchronized: yes)  --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] Diferencia de hora entre node02 y node03 menor a 5 segundos   --> ${MAGENTA}20%${RESET}"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${GREEN}🚨 REGLA DE ORO:${RESET}"
  echo -e "  - Trabaja SIEMPRE desde ${BOLD}node01${RESET}"
  echo -e "  - Conéctate a ${BOLD}node03${RESET} vía ${BOLD}sshpass${RESET} para todas las intervenciones"
  echo -e "  - Usa ${BOLD}node02${RESET} únicamente como referencia de hora"
  echo -e "  - ${RED}NUNCA${RESET} reinicies node03 como solución al problema"
  echo -e "${CYAN}================================================================================${RESET}"
  TICKET
  EOF

  bash /tmp/setup-net002.sh && rm -f /tmp/setup-net002.sh
tags: Laboratorios-del-LFCS
---

[[Laboratorios del LFCS]]




---

I recently worked through a distributed systems incident where node03 in a multi-node cluster was generating 'expired token' and 'invalid certificate' errors in production. The root cause turned out to be two compounding issues: iptables rules that were silently dropping all UDP port 123 traffic — completely blocking NTP communication — and a chrony configuration pointing to a reserved, non-routable IP address from the TEST-NET-1 block.

I approached it methodically. First, I confirmed the time synchronization status with timedatectl, which showed NTP inactive. Then I inspected the firewall rules and identified DROP entries in both INPUT and OUTPUT chains for port 123. I removed both rules using iptables -D, verified the chains were clean, and moved on to the configuration.

After correcting the chrony.conf to point to pool.ntp.org, I enabled and started the chrony service, confirmed it was actively tracking a stratum-2 source with sub-millisecond offset, and validated that both node02 and node03 were showing identical Unix timestamps — zero drift between them.

One thing worth mentioning: the makestep command returned a 500 Failure, which I recognized immediately as a container-level kernel restriction rather than a configuration error — chrony was synchronizing correctly through the normal slewing mechanism. Knowing the difference between environment constraints and actual misconfigurations is something I've developed working in this kind of containerized lab setup.