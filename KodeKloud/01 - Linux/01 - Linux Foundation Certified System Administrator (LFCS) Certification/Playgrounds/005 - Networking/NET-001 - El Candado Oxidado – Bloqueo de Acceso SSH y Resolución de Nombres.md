---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Playground: NET-001-v1
Titulo: El Candado Oxidado – Bloqueo de Acceso SSH y Resolución de Nombres
Fecha de Inicio: 2026-06-11
Dificultad: 6/10
Level Escalation: L2
Objetivo: Aprobar LFCS,Pensar como Sysadmin Linux Pleno
Temas: SSH Server & Client Configuration,Hostname Resolution (DNS, /etc/hosts, nsswitch.conf),File Permissions & Ownership (.ssh/),Remote Administration
Competencias: Diagnosticar y corregir fallos de resolución de nombres en entornos distribuidos,Asegurar el acceso SSH mediante autenticación por clave y permisos estrictos,Administrar servicios críticos (sshd) sin interrumpir la disponibilidad
Script: |-
  cat << 'EOF' > /tmp/setup-net001.sh

  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  # ── Detectar usuario actual y su HOME ───────────────────────────────────────
  CURRENT_USER=$(whoami)
  if [ "$CURRENT_USER" = "root" ]; then
    USER_HOME="/home/$USER_NET"
    SSH_DIR="$USER_HOME/.ssh"
  else
    USER_HOME="$HOME"
    SSH_DIR="$HOME/.ssh"
  fi

  echo -e "\e[1;33m⏳ [node01] Instalando dependencias en el clúster...\e[0m"

  # ── 0. Instalar sshpass en los 3 nodos ──────────────────────────────────────
  if ! command -v sshpass &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y sshpass -qq 2>/dev/null || sudo yum install -y sshpass -qq 2>/dev/null
  fi

  for NODE in node01 node02 node03; do
    $SSH ${USER_NET}@${NODE} "
      if ! command -v sshpass &>/dev/null; then
        echo $PASS | sudo -S apt-get update -qq && echo $PASS | sudo -S apt-get install -y sshpass -qq 2>/dev/null || 
        echo $PASS | sudo -S yum install -y sshpass -qq 2>/dev/null
      fi
    " < /dev/null 2>/dev/null || true
  done

  echo -e "\e[1;32m✔ sshpass instalado en los 3 nodos.\e[0m"

  # ── 1. Obtener IPs dinámicas de node02 y node03 ─────────────────────────────
  IP_NODE02=$($SSH ${USER_NET}@${NODE_TARGET} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.17")
  IP_NODE03=$($SSH ${USER_NET}@${NODE_VAULT} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.59")
  IP_NODE01=$(hostname -i 2>/dev/null | tr -d '\r' || echo "10.244.29.16")

  echo -e "\e[1;36m  IPs detectadas:\e[0m"
  echo -e "    node01: \e[1;32m${IP_NODE01}\e[0m"
  echo -e "    node02: \e[1;32m${IP_NODE02}\e[0m"
  echo -e "    node03: \e[1;32m${IP_NODE03}\e[0m"

  # ── 2. Crear archivo de inventario en node01 ────────────────────────────────
  cat > /tmp/inventory.txt << INV
  ${IP_NODE01} node01
  ${IP_NODE02} node02
  ${IP_NODE03} node03
  INV

  echo -e "\e[1;32m✔ Archivo de inventario creado en /tmp/inventory.txt\e[0m"

  # ── 3. Generar clave SSH en node01 (si no existe) ───────────────────────────
  if [ ! -f "$SSH_DIR/id_rsa" ]; then
    mkdir -p "$SSH_DIR"
    ssh-keygen -t rsa -b 2048 -f "$SSH_DIR/id_rsa" -N "" -q
    if [ "$CURRENT_USER" = "root" ]; then
      chown -R bob:bob "$SSH_DIR"
      chmod 700 "$SSH_DIR"
      chmod 600 "$SSH_DIR/id_rsa"
      chmod 644 "$SSH_DIR/id_rsa.pub"
    fi
    echo -e "\e[1;32m✔ Clave SSH generada en node01.\e[0m"
  else
    echo -e "\e[1;33m⚠️  Clave SSH ya existe en node01.\e[0m"
  fi

  # ── 4. Copiar clave pública a node02 (con permisos incorrectos) ─────────────
  PUB_KEY=$(cat "$SSH_DIR/id_rsa.pub")
  $SSH ${USER_NET}@${IP_NODE02} "
    mkdir -p ~/.ssh
    echo '$PUB_KEY' >> ~/.ssh/authorized_keys
    chmod 777 ~/.ssh
    chmod 777 ~/.ssh/authorized_keys
  " < /dev/null

  echo -e "\e[1;32m✔ Clave pública copiada a node02 (con permisos incorrectos: 777).\e[0m"

  # ── 5. Romper SSH en node02 ─────────────────────────────────────────────────
  $SSH ${USER_NET}@${IP_NODE02} "sudo bash -c '
    sed -i \"s/^#*PubkeyAuthentication.*/PubkeyAuthentication no/\" /etc/ssh/sshd_config
    systemctl restart ssh
  '" < /dev/null

  echo -e "\e[1;33m⏳ SSH roto en node02 (PubkeyAuthentication=no, permisos 777).\e[0m"

  # ── 6. Romper resolución de nombres en node01 ───────────────────────────────
  sudo cp /etc/nsswitch.conf /etc/nsswitch.conf.bak 2>/dev/null || true
  sudo sed -i 's/^hosts:.*/hosts:          files/' /etc/nsswitch.conf

  echo -e "\e[1;33m⏳ Resolución de nombres rota en node01 (nsswitch.conf: solo files).\e[0m"

  # ── 7. Preparar bóveda en node03 (¡USANDO IP porque DNS ya está roto!) ──────
  $SSH ${USER_NET}@${IP_NODE03} "sudo bash -c '
    rm -rf /opt/backup-vault/*
    mkdir -p /opt/backup-vault/
    chown -R bob:bob /opt/backup-vault/
  '" < /dev/null

  echo -e "\e[1;32m✔ Bóveda preparada en node03.\e[0m"

  # ── 8. Mostrar el ticket ────────────────────────────────────────────────────
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-3001  │  Severidad: ALTA  │  Ambiente: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  🔐 NET-001-MN — El Candado Oxidado (SSH + Resolución de Nombres)\e[0m"
  echo -e "\e[1;36m  Módulo: Networking  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m     node02 (Servidor con SSH y permisos degradados)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Bóveda de Configuraciones — \e[1;35m/opt/backup-vault/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " "
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Tras una auditoría de seguridad, el acceso SSH por clave a \e[1mnode02\e[0m"
  echo -e "  fue deshabilitado y los permisos de \e[1m~/.ssh/\e[0m fueron alterados."
  echo -e "  Además, la resolución de nombres en \e[1mnode01\e[0m fue modificada,"
  echo -e "  impidiendo conectar usando hostnames. Debe restaurar el acceso seguro"
  echo -e "  y la resolución de nombres operando remotamente."
  echo -e " "
  echo -e " \e[1mParámetros Técnicos Obligatorios:\e[0m"
  echo -e " "
  echo -e "  \e[1;31m1. Corrección de Resolución de Nombres (en node01)\e[0m"
  echo -e "     Restaure la línea \e[1mhosts:\e[0m en \e[1m/etc/nsswitch.conf\e[0m para incluir \e[1mdns\e[0m."
  echo -e "     Verifique que \e[1mping node02\e[0m funcione correctamente."
  echo -e " "
  echo -e "  \e[1;31m2. Corrección de Permisos SSH (en node02)\e[0m"
  echo -e "     Asegure que \e[1m/home/bob/.ssh/\e[0m tenga permisos \e[1m700\e[0m."
  echo -e "     Asegure que \e[1m/home/bob/.ssh/authorized_keys\e[0m tenga permisos \e[1m600\e[0m."
  echo -e " "
  echo -e "  \e[1;31m3. Habilitar Autenticación por Clave (en node02)\e[0m"
  echo -e "     Modifique \e[1m/etc/ssh/sshd_config\e[0m para habilitar \e[1mPubkeyAuthentication yes\e[0m."
  echo -e "     Reinicie el servicio \e[1mssh\e[0m con \e[1msudo systemctl restart ssh\e[0m."
  echo -e " "
  echo -e "  \e[1;31m4. Validación de Acceso (desde node01)\e[0m"
  echo -e "     Verifique que puede conectar a \e[1mnode02\e[0m por SSH sin contraseña:"
  echo -e "     \e[1mssh bob@node02 'hostname'\e[0m"
  echo -e " "
  echo -e "  \e[1;31m5. Resguardo en Bóveda (node02 → node03)\e[0m"
  echo -e "     Copie \e[1m/etc/ssh/sshd_config\e[0m corregido a:"
  echo -e "     \e[1mnode03:/opt/backup-vault/sshd_config.bak\e[0m"
  echo -e " "
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] node01 resuelve node02 por hostname (ping node02 OK)        --> \e[1;35m20%\e[0m"
  echo -e "  [ ] SSH sin password desde node01 a node02 funciona             --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Permisos de .ssh/ (700) y authorized_keys (600) correctos   --> \e[1;35m20%\e[0m"
  echo -e "  [ ] PubkeyAuthentication yes en sshd_config de node02           --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Backup de sshd_config en node03:/opt/backup-vault/          --> \e[1;35m10%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m Use 'ssh -v bob@node02' para ver el proceso de autenticación."
  echo -e "               Diagnóstico: 'cat /etc/nsswitch.conf | grep hosts' y 'ls -la ~/.ssh/'"
  echo -e "               Inventario de IPs: 'cat /tmp/inventory.txt'"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " "

  EOF

  bash /tmp/setup-net001.sh && rm -f /tmp/setup-net001.sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  cat << 'EOF' > /tmp/validador-net001.sh

  #!/bin/bash
  PUNTOS=0
  USER="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"

  # Leer IPs del inventario por si acaso
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
  echo -e "\e[1;33m  🕵️  AUDITORÍA DE RED Y SSH — INC-3001 (NET-001-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # 1. Resolución de nombres
  echo -e "\n\e[1;37m⏳ [1/5] Verificando resolución de nombres en node01...\e[0m"
  if ping -c1 -W2 node02 &>/dev/null; then
    echo -e "\e[1;32m  ✔ [20%] node01 resuelve node02 por hostname correctamente.\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] node01 no puede resolver node02 por hostname.\e[0m"
    echo -e "       → Corrección: Asegure que 'cat /etc/nsswitch.conf | grep hosts' incluya 'dns'"
  fi

  # 2. SSH sin password
  echo -e "\n\e[1;37m⏳ [2/5] Verificando autenticación SSH por clave...\e[0m"
  SSH_RESULT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${USER}@node02 'echo OK' 2>/dev/null || echo "FAIL")
  if [ "$SSH_RESULT" = "OK" ]; then
    echo -e "\e[1;32m  ✔ [30%] SSH sin password desde node01 a node02 funciona.\e[0m"
    PUNTOS=$((PUNTOS + 30))
  else
    echo -e "\e[1;31m  ❌ [0%] SSH sin password falla.\e[0m"
    echo -e "       → Diagnóstico: ssh -v bob@node02 (revisa permisos de ~/.ssh y sshd_config)"
  fi

  # 3. Permisos de .ssh en node02
  echo -e "\n\e[1;37m⏳ [3/5] Verificando permisos de SSH en node02...\e[0m"
  SSH_DIR_PERM=$($SSH2 'stat -c %a ~/.ssh' 2>/dev/null || echo "000")
  AUTH_KEY_PERM=$($SSH2 'stat -c %a ~/.ssh/authorized_keys' 2>/dev/null || echo "000")

  if [ "$SSH_DIR_PERM" = "700" ] && [ "$AUTH_KEY_PERM" = "600" ]; then
    echo -e "\e[1;32m  ✔ [20%] Permisos de .ssh/ (700) y authorized_keys (600) correctos.\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] Permisos incorrectos en node02.\e[0m"
    echo -e "       → .ssh/ actual: \e[1;31m${SSH_DIR_PERM}\e[0m (se espera: 700)"
    echo -e "       → authorized_keys actual: \e[1;31m${AUTH_KEY_PERM}\e[0m (se espera: 600)"
  fi

  # 4. PubkeyAuthentication en node02
  echo -e "\n\e[1;37m⏳ [4/5] Verificando PubkeyAuthentication en node02...\e[0m"
  PUBKEY_AUTH=$($SSH2 'grep "^PubkeyAuthentication" /etc/ssh/sshd_config' 2>/dev/null || echo "")
  if echo "$PUBKEY_AUTH" | grep -q "yes"; then
    echo -e "\e[1;32m  ✔ [20%] PubkeyAuthentication yes configurado en node02.\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] PubkeyAuthentication no está habilitado en node02.\e[0m"
    echo -e "       → Valor actual: \e[1;31m${PUBKEY_AUTH:-no configurado}\e[0m"
  fi

  # 5. Backup en node03
  echo -e "\n\e[1;37m⏳ [5/5] Auditando backup en node03...\e[0m"
  if $SSH3 'test -f /opt/backup-vault/sshd_config.bak' 2>/dev/null; then
    BAK_CONTENT=$($SSH3 'grep "^PubkeyAuthentication" /opt/backup-vault/sshd_config.bak' 2>/dev/null || echo "")
    if echo "$BAK_CONTENT" | grep -q "yes"; then
      echo -e "\e[1;32m  ✔ [10%] Backup de sshd_config custodiado en node03 con configuración correcta.\e[0m"
      PUNTOS=$((PUNTOS + 10))
    else
      echo -e "\e[1;33m  ⚠️  [5%] Backup presente, pero PubkeyAuthentication no está habilitado en él.\e[0m"
      PUNTOS=$((PUNTOS + 5))
    fi
  else
    echo -e "\e[1;31m  ❌ [0%] No se encontró sshd_config.bak en node03:/opt/backup-vault/\e[0m"
  fi

  # Resultado Final
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
    echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — ¡Dominio completo de SSH y resolución de nombres!"
  elif [ $PUNTOS -ge 55 ]; then
    echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los puntos ❌."
  else
    echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Revise la configuración de SSH y resolución."
  fi
  echo -e "\e[1;36m================================================================================\e[0m\n"
  EOF

  bash /tmp/validador-net001.sh && rm -f /tmp/validador-net001.sh
---
[[Laboratorios del LFCS]]



---

I had an incident where SSH key-based authentication was completely broken on one of our servers, and on top of that, the control node couldn't even resolve hostnames — so I was essentially locked out on two fronts simultaneously.

The first thing I did was check `/etc/nsswitch.conf`, and I found that the `dns` source had been removed from the `hosts` line — probably during a misconfigured change window. That alone was preventing any hostname resolution. I patched it in place with `sed` and confirmed connectivity immediately.

Then I moved on to the SSH issue. I connected using password authentication as a fallback and inspected the `.ssh` directory. The permissions were completely open — `777` on the directory and the `authorized_keys` file — which SSH rejects silently for security reasons. I tightened those to `700` and `600`. But the authentication was still failing, so I went deeper into `sshd_config` and found `PubkeyAuthentication` had been explicitly disabled. I enabled it, restarted the daemon, and re-propagated the public key using `ssh-copy-id`.

After that, passwordless authentication was restored. Before closing the ticket I made sure to back up the corrected `sshd_config` to our configuration vault on a separate node, which is standard procedure for audit trail purposes.

The whole intervention was done remotely, without direct console access to the affected server, which I think is important — in production you rarely have the luxury of sitting in front of the machine.

---

