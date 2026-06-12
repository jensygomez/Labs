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
  - Prepararme para Devops Enginner. 
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
  ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"
  ── Detectar usuario actual ─────────────────────────────────────────────────
  CURRENT_USER=$(whoami)
  if [ "$CURRENT_USER" = "root" ]; then
  USER_HOME="/home/$USER_NET"
  else
  USER_HOME="$HOME"
  fi
  echo -e "\e[1;33m⏳ [node01] Instalando dependencias (chrony, iptables) en el clúster...\e[0m"
  ── 0. Instalar chrony en los 3 nodos ──────────────────────────────────────
  for NODE in node01 node02 node03; do
  $SSH ${USER_NET}@${NODE} "
  echo $PASS | sudo -S apt-get update -qq && echo $PASS | sudo -S apt-get install -y chrony iptables -qq 2>/dev/null ||
  echo $PASS | sudo -S yum install -y chrony iptables -qq 2>/dev/null
  " < /dev/null 2>/dev/null || true
  done
  echo -e "\e[1;32m✔ Chrony instalado en los 3 nodos.\e[0m"
  ── 1. Configurar node02 como referencia NTP correcta ───────────────────────
  $SSH ${USER_NET}@${NODE_TARGET} "
  echo $PASS | sudo -S bash -c '
  CONF_FILE="/etc/chrony/chrony.conf"
  if [ ! -d /etc/chrony ]; then CONF_FILE="/etc/chrony.conf"; fi
  cat > $CONF_FILE << CHRONY
  pool pool.ntp.org iburst
  local stratum 10
  keyfile /etc/chrony/chrony.keys
  driftfile /var/lib/chrony/chrony.drift
  logdir /var/log/chrony
  CHRONY
  systemctl enable --now chronyd
  '
  " < /dev/null
  echo -e "\e[1;32m✔ node02 configurado con NTP correcto y chronyd activo.\e[0m"
  ── 2. Obtener IP de node03 ─────────────────────────────────────────────────
  IP_NODE03=$($SSH ${USER_NET}@${NODE_VAULT} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.59")
  ── 3. Romper NTP y Firewall en node03 ──────────────────────────────────────
  $SSH ${USER_NET}@${IP_NODE03} "
  echo $PASS | sudo -S bash -c '
  # Detener y deshabilitar chronyd
  systemctl stop chronyd 2>/dev/null || true
  systemctl disable chronyd 2>/dev/null || true

  # Configurar chrony con servidor inexistente (falso)
  CONF_FILE="/etc/chrony/chrony.conf"
  if [ ! -d /etc/chrony ]; then CONF_FILE="/etc/chrony.conf"; fi
  cat > $CONF_FILE << CHRONY
  server 192.0.2.1 iburst
  keyfile /etc/chrony/chrony.keys
  driftfile /var/lib/chrony/chrony.drift
  logdir /var/log/chrony
  CHRONY

  # Bloquear puerto 123 UDP (NTP) en INPUT y OUTPUT
  iptables -A OUTPUT -p udp --dport 123 -j DROP
  iptables -A INPUT -p udp --dport 123 -j DROP

  # Intentar derivar el reloj 15 minutos (si el entorno lo permite)
  date -s \"+15 minutes\" 2>/dev/null || echo \"No se pudo modificar la hora (restricción de contenedor).\"
  '
  " < /dev/null
  echo -e "\e[1;33m⏳ node03 configurado con deriva, chronyd caído y firewall bloqueando NTP.\e[0m"
  ── 4. Mostrar el ticket ────────────────────────────────────────────────────
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-3002  │  Severidad: ALTA  │  Ambiente: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  ⏱️  NET-002-MN — La Paradoja Temporal (NTP + Firewall)\e[0m"
  echo -e "\e[1;36m  Módulo: Networking  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo Afectado:\e[0m        node03 (Backend/DB con deriva de tiempo)"
  echo -e " \e[1mNodo Referencia:\e[0m      node02 (Servidor de Aplicaciones — Hora correcta)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " "
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  La aplicación distribuida entre \e[1mnode02\e[0m y \e[1mnode03\e[0m está fallando con"
  echo -e "  errores de 'Token expirado' y 'Certificado no válido'. El diagnóstico"
  echo -e "  inicial indica que \e[1mnode03\e[0m tiene una deriva de tiempo significativa."
  echo -e "  El servicio NTP está inoperativo y hay sospechas de bloqueo a nivel de red."
  echo -e " "
  echo -e " \e[1mParámetros Técnicos Obligatorios:\e[0m"
  echo -e " "
  echo -e "  \e[1;31m1. Diagnóstico de Tiempo (en node03)\e[0m"
  echo -e "     Verifique el estado de la sincronización horaria con \e[1mtimedatectl status\e[0m."
  echo -e " "
  echo -e "  \e[1;31m2. Corrección de Firewall (en node03)\e[0m"
  echo -e "     Identifique y elimine las reglas de \e[1miptables\e[0m que estén bloqueando"
  echo -e "     el tráfico NTP (puerto \e[1m123/UDP\e[0m)."
  echo -e " "
  echo -e "  \e[1;31m3. Configuración del Servicio NTP (en node03)\e[0m"
  echo -e "     Edite \e[1m/etc/chrony/chrony.conf\e[0m (o \e[1m/etc/chrony.conf\e[0m) para apuntar"
  echo -e "     a un servidor NTP válido (puede usar \e[1mpool.ntp.org\e[0m o la IP de \e[1mnode02\e[0m)."
  echo -e " "
  echo -e "  \e[1;31m4. Persistencia y Sincronización (en node03)\e[0m"
  echo -e "     Inicie y habilite el servicio \e[1mchronyd\e[0m para que arranque con el sistema."
  echo -e "     Fuerce una sincronización inmediata para corregir la deriva."
  echo -e " "
  echo -e "  \e[1;31m5. Validación Final\e[0m"
  echo -e "     Verifique que \e[1mtimedatectl\e[0m muestre 'System clock synchronized: yes'."
  echo -e "     Confirme que la diferencia de hora entre node02 y node03 es mínima."
  echo -e " "
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Firewall de node03 permite tráfico NTP (123/UDP)             --> \e[1;35m20%\e[0m"
  echo -e "  [ ] chronyd está activo y habilitado en node03                   --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Configuración de chrony apunta a servidor NTP válido         --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Reloj de node03 está sincronizado (timedatectl)              --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Diferencia de hora entre node02 y node03 < 5 segundos        --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m Use 'timedatectl status' para ver el estado general."
  echo -e "               Diagnóstico de red: 'sudo iptables -L -n -v' y 'chronyc sources'."
  echo -e "               Fuerce la hora con 'sudo chronyc makestep' si la deriva es muy grande."
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " "
  EOF
  bash /tmp/setup-net002.sh && rm -f /tmp/setup-net002.sh
tags: Laboratorios-del-LFCS
Script Validacion: |-
  cat << 'EOF' > /tmp/validador-net002.sh
  #!/bin/bash
  PUNTOS=0
  USER="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"
  ── Leer IPs del inventario ─────────────────────────────────────────────────
  if [ -f /tmp/inventory.txt ]; then
  IP_NODE02=$(grep node02 /tmp/inventory.txt | awk '{print $1}')
  IP_NODE03=$(grep node03 /tmp/inventory.txt | awk '{print $1}')
  else
  IP_NODE02="10.244.29.17"
  IP_NODE03="10.244.29.59"
  fi
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER}@${IP_NODE02}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER}@${IP_NODE03}"
  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  AUDITORÍA DE TIEMPO Y NTP — INC-3002 (NET-002-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  ── 1. Firewall (20%) ───────────────────────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [1/5] Verificando reglas de firewall en node03...\e[0m"
  IPTABLES_CHECK=$($SSH3 'echo $PASS | sudo -S iptables -L -n -v 2>/dev/null | grep "dpt:123"' || echo "")
  if echo "$IPTABLES_CHECK" | grep -q "DROP"; then
  echo -e "\e[1;31m  ❌ [0%] El puerto 123/UDP sigue bloqueado en node03.\e[0m"
  echo -e "       → Corrección: 'sudo iptables -D OUTPUT -p udp --dport 123 -j DROP'"
  echo -e "                     'sudo iptables -D INPUT -p udp --dport 123 -j DROP'"
  else
  echo -e "\e[1;32m  ✔ [20%] No hay reglas bloqueando NTP (123/UDP) en node03.\e[0m"
  PUNTOS=$((PUNTOS + 20))
  fi
  ── 2. Servicio Chronyd (20%) ───────────────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [2/5] Verificando estado del servicio chronyd en node03...\e[0m"
  CHRONY_ACTIVE=$($SSH3 'systemctl is-active chronyd 2>/dev/null' || echo "inactive")
  CHRONY_ENABLED=$($SSH3 'systemctl is-enabled chronyd 2>/dev/null' || echo "disabled")
  if [ "$CHRONY_ACTIVE" = "active" ] && [ "$CHRONY_ENABLED" = "enabled" ]; then
  echo -e "\e[1;32m  ✔ [20%] chronyd está activo y habilitado en node03.\e[0m"
  PUNTOS=$((PUNTOS + 20))
  else
  echo -e "\e[1;31m  ❌ [0%] chronyd no está correctamente configurado en node03.\e[0m"
  echo -e "       → Estado actual: Activo=\e[1;31m${CHRONY_ACTIVE}\e[0m, Habilitado=\e[1;31m${CHRONY_ENABLED}\e[0m"
  fi
  ── 3. Configuración de Chrony (20%) ────────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [3/5] Verificando configuración de chrony en node03...\e[0m"
  CHRONY_CONF=$($SSH3 'cat /etc/chrony/chrony.conf 2>/dev/null || cat /etc/chrony.conf 2>/dev/null' || echo "")
  if echo "$CHRONY_CONF" | grep -qE "^(server|pool).*(ntp.org|node02|pool.ntp)"; then
  echo -e "\e[1;32m  ✔ [20%] chrony apunta a un servidor NTP válido.\e[0m"
  PUNTOS=$((PUNTOS + 20))
  else
  echo -e "\e[1;31m  ❌ [0%] La configuración de chrony no tiene servidores NTP válidos.\e[0m"
  echo -e "       → Verifique /etc/chrony/chrony.conf o /etc/chrony.conf"
  fi
  ── 4. Sincronización del reloj (20%) ───────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [4/5] Verificando sincronización del reloj en node03...\e[0m"
  TIMEDATECTL_OUT=$($SSH3 'timedatectl status 2>/dev/null' || echo "")
  if echo "$TIMEDATECTL_OUT" | grep -q "System clock synchronized: yes"; then
  echo -e "\e[1;32m  ✔ [20%] El reloj de node03 está sincronizado.\e[0m"
  PUNTOS=$((PUNTOS + 20))
  else
  echo -e "\e[1;31m  ❌ [0%] El reloj de node03 NO está sincronizado.\e[0m"
  echo -e "       → Ejecute 'sudo chronyc makestep' o espere a que chronyd sincronice."
  fi
  ── 5. Diferencia de hora entre nodos (20%) ─────────────────────────────────
  echo -e "\n\e[1;37m⏳ [5/5] Verificando deriva de tiempo entre node02 y node03...\e[0m"
  TIME_NODE02=$($SSH2 'date +%s' 2>/dev/null || echo "0")
  TIME_NODE03=$($SSH3 'date +%s' 2>/dev/null || echo "0")
  DIFF=$((TIME_NODE03 - TIME_NODE02))
  if [ "$DIFF" -lt 0 ]; then DIFF=$(( -DIFF )); fi
  if [ "$DIFF" -le 5 ]; then
  echo -e "\e[1;32m  ✔ [20%] La diferencia de hora es mínima (${DIFF}s). Clúster sincronizado.\e[0m"
  PUNTOS=$((PUNTOS + 20))
  else
  echo -e "\e[1;31m  ❌ [0%] La diferencia de hora es de ${DIFF}s (debe ser <= 5s).\e[0m"
  echo -e "       → Fuerce la sincronización con 'sudo chronyc makestep'"
  fi
  ── Resultado Final ─────────────────────────────────────────────────────────
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
  echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — ¡Dominio completo de NTP y sincronización!"
  elif [ $PUNTOS -ge 55 ]; then
  echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los puntos ❌."
  else
  echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Revise la configuración de NTP y firewall."
  fi
  echo -e "\e[1;36m================================================================================\e[0m\n"
  EOF
  bash /tmp/validador-net002.sh && rm -f /tmp/validador-net002.sh
---

[[Laboratorios del LFCS]]
