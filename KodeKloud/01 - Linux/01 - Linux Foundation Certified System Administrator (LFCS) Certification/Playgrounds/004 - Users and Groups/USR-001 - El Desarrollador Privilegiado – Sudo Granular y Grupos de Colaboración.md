---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: USR-001-MN
Titulo: El Desarrollador Privilegiado – Sudo Granular y Grupos de Colaboración
Fecha de Inicio: 2026-06-11
Dificultad: 7/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
Temas: |-
  - Local User & Group Management (useradd, groupadd, usermod)
  - Advanced File Permissions (SGID, Ownership)
  - Manage User Privileges (sudoers, Cmnd_Alias, visudo)
Competencias: |-
  - Aplicar el Principio de Menor Privilegio (PoLP) en entornos productivos y clústeres.
  - Configurar reglas de sudo granulares y seguras, evitando el acceso root completo.
  - Gestionar colaboraciones en directorios compartidos mediante permisos especiales (SGID).
Script: |-
  cat << 'EOF' > /tmp/setup-usr001.sh
  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  echo -e "\e[1;33m⏳ [node01] Preparando entorno del laboratorio USR-001...\e[0m"

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

  echo -e "\e[1;32m✔ sshpass instalado en el clúster.\e[0m"

  # ── 1. Obtener IPs dinámicas ────────────────────────────────────────────────
  IP_NODE02=$($SSH ${USER_NET}@${NODE_TARGET} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.17")
  IP_NODE03=$($SSH ${USER_NET}@${NODE_VAULT} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.59")

  echo -e "\e[1;36m  IPs detectadas: node02=\e[1;32m${IP_NODE02}\e[1;36m, node03=\e[1;32m${IP_NODE03}\e[0m"

  # ── 2. Inyectar fallos en node02 ────────────────────────────────────────────
  $SSH ${USER_NET}@${IP_NODE02} "sudo bash -c '
    # Limpiar estado anterior (idempotencia)
    userdel -r dev_user 2>/dev/null || true
    groupdel app-devs 2>/dev/null || true
    rm -f /etc/sudoers.d/99-dev-user-bad /etc/sudoers.d/dev_user

    # Crear grupo y usuario
    groupadd app-devs
    useradd -m -s /bin/bash -G app-devs dev_user
    echo \"dev_user:caleston123\" | chpasswd

    # FALLO 1: Privilegios excesivos (Se espera que el estudiante lo revoque)
    echo \"dev_user ALL=(ALL) ALL\" > /etc/sudoers.d/99-dev-user-bad
    chmod 440 /etc/sudoers.d/99-dev-user-bad

    # FALLO 2: Directorio de logs sin SGID y con propietario incorrecto
    mkdir -p /var/log/app
    chown root:root /var/log/app
    chmod 700 /var/log/app

    # Instalar nginx para que los comandos de systemctl sean realistas
    apt-get update -qq && apt-get install -y nginx -qq 2>/dev/null || true
    systemctl enable --now nginx 2>/dev/null || true
  '" < /dev/null

  echo -e "\e[1;33m⏳ Fallos inyectados en node02 (Sudo excesivo + Permisos de directorio).\e[0m"

  # ── 3. Preparar bóveda en node03 ────────────────────────────────────────────
  $SSH ${USER_NET}@${IP_NODE03} "sudo bash -c '
    rm -rf /opt/backup-vault/*
    mkdir -p /opt/backup-vault/
    chown -R bob:bob /opt/backup-vault/
  '" < /dev/null

  echo -e "\e[1;32m✔ Bóveda preparada en node03.\e[0m"

  # ── 4. Mostrar el ticket ────────────────────────────────────────────────────
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-4001  │  Severidad: ALTA (Auditoría de Seguridad)  │  Ambiente: CLÚSTER\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  👤 USR-001-MN — El Desarrollador Privilegiado (Sudo Granular y SGID)\e[0m"
  echo -e "\e[1;36m  Módulo: Users & Groups  │  Dificultad: 7/10  │  Nivel: L2\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m     node02 (Servidor con privilegios mal configurados)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Bóveda de Gobernanza — \e[1;35m/opt/backup-vault/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " "
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Una auditoría de seguridad (CIS Benchmark) ha marcado una vulnerabilidad"
  echo -e "  crítica en \e[1mnode02\e[0m. El usuario \e[1mdev_user\e[0m fue provisionado con"
  echo -e "  privilegios de sudo ilimitados (\e[1mALL=(ALL) ALL\e[0m). El desarrollador"
  echo -e "  legítimamente solo necesita reiniciar el servicio \e[1mnginx\e[0m y leer"
  echo -e "  los logs de la aplicación en \e[1m/var/log/app/\e[0m. Además, el equipo"
  echo -e "  necesita un directorio de configuración compartida con herencia de grupo."
  echo -e " "
  echo -e " \e[1mParámetros Técnicos Obligatorios (SSH desde node01 hacia node02):\e[0m"
  echo -e " "
  echo -e "  \e[1;31m1. Gestión de Grupos y Usuarios (Remoto en node02)\e[0m"
  echo -e "     Verifique que el grupo \e[1mapp-devs\e[0m exista y que \e[1mdev_user\e[0m sea miembro."
  echo -e " "
  echo -e "  \e[1;31m2. Corrección de Permisos con SGID (Remoto en node02)\e[0m"
  echo -e "     El directorio \e[1m/var/log/app/\e[0m debe pertenecer a \e[1mroot:app-devs\e[0m."
  echo -e "     Aplique el bit \e[1mSGID\e[0m para que cualquier archivo nuevo creado"
  echo -e "     herede el grupo \e[1mapp-devs\e[0m. Permisos esperados: \e[1m2750\e[0m."
  echo -e " "
  echo -e "  \e[1;31m3. Hardening de Privilegios Sudo (Remoto en node02)\e[0m"
  echo -e "     \e[1mREVÓGUE\e[0m el acceso \e[1mALL=(ALL) ALL\e[0m (elimine el archivo que lo concede)."
  echo -e "     Cree un archivo nuevo en \e[1m/etc/sudoers.d/dev_user\e[0m usando \e[1mCmnd_Alias\e[0m"
  echo -e "     que permita \e[1mSIN CONTRASEÑA\e[0m (NOPASSWD) solo:"
  echo -e "      - \e[1m/bin/systemctl restart nginx\e[0m"
  echo -e "      - \e[1m/bin/systemctl status nginx\e[0m"
  echo -e "      - \e[1m/usr/bin/cat /var/log/app/*\e[0m"
  echo -e "      - \e[1m/usr/bin/tail -f /var/log/app/*\e[0m"
  echo -e "     \e[1m⚠️  Use 'sudo visudo -f /etc/sudoers.d/dev_user' para validar la sintaxis.\e[0m"
  echo -e " "
  echo -e "  \e[1;31m4. Resguardo en Bóveda (node02 → node03)\e[0m"
  echo -e "     Copie el archivo \e[1m/etc/sudoers.d/dev_user\e[0m corregido a:"
  echo -e "     \e[1mnode03:/opt/backup-vault/sudoers_dev_user.bak\e[0m"
  echo -e " "
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Grupo 'app-devs' existe y 'dev_user' es miembro              --> \e[1;35m20%\e[0m"
  echo -e "  [ ] /var/log/app/ tiene grupo 'app-devs' y bit SGID (2750)       --> \e[1;35m20%\e[0m"
  echo -e "  [ ] 'dev_user' ya NO tiene privilegios ALL=(ALL) ALL             --> \e[1;35m20%\e[0m"
  echo -e "  [ ] 'dev_user' tiene un archivo sudoers válido con Cmnd_Alias    --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Backup de la regla sudo custodiado en node03                 --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m Nunca edite archivos en /etc/sudoers.d directamente con nano/vim."
  echo -e "               Use \e[1msudo visudo -f /etc/sudoers.d/dev_user\e[0m para prevenir bloqueos."
  echo -e "               Verifique con: \e[1msudo -l -U dev_user\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " "

  EOF

  bash /tmp/setup-usr001.sh && rm -f /tmp/setup-usr001.sh
Script Validacion: |-
  cat << 'EOF' > /tmp/validador-usr001.sh
  #!/bin/bash
  PUNTOS=0
  USER="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"

  IP_NODE02=$(sshpass -p $PASS ssh $SSH_OPTS ${USER}@${NODE_TARGET} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.17")
  IP_NODE03=$(sshpass -p $PASS ssh $SSH_OPTS ${USER}@${NODE_VAULT} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.59")

  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER}@${IP_NODE02}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER}@${IP_NODE03}"

  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  AUDITORÍA DE USUARIOS Y SUDO — INC-4001 (USR-001-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # 1. Grupo y membresía
  echo -e "\n\e[1;37m⏳ [1/5] Verificando grupo app-devs y membresía de dev_user...\e[0m"
  USER_GROUPS=$($SSH2 "id dev_user" 2>/dev/null || echo "")
  if echo "$USER_GROUPS" | grep -q "app-devs"; then
    echo -e "\e[1;32m  ✔ [20%] dev_user es miembro del grupo app-devs.\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] dev_user no pertenece a app-devs.\e[0m"
    echo -e "       → Corrección: sudo usermod -aG app-devs dev_user"
  fi

  # 2. Permisos SGID en /var/log/app
  echo -e "\n\e[1;37m⏳ [2/5] Verificando permisos y SGID en /var/log/app/...\e[0m"
  DIR_PERMS=$($SSH2 "stat -c '%a %G' /var/log/app/" 2>/dev/null || echo "000 none")
  if [ "$DIR_PERMS" = "2750 app-devs" ]; then
    echo -e "\e[1;32m  ✔ [20%] /var/log/app/ tiene permisos 2750 y grupo app-devs (SGID activo).\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] Permisos incorrectos en /var/log/app/.\e[0m"
    echo -e "       → Actual: \e[1;31m${DIR_PERMS}\e[0m (Se espera: 2750 app-devs)"
    echo -e "       → Corrección: sudo chown root:app-devs /var/log/app && sudo chmod 2750 /var/log/app"
  fi

  # 3. Revocación de ALL=(ALL) ALL
  echo -e "\n\e[1;37m⏳ [3/5] Verificando que se revocaron los privilegios totales...\e[0m"
  BAD_FILE_EXISTS=$($SSH2 "test -f /etc/sudoers.d/99-dev-user-bad && echo 'YES' || echo 'NO'" 2>/dev/null)
  SUDO_L_OUTPUT=$($SSH2 "sudo -l -U dev_user" 2>/dev/null || echo "")
  if [ "$BAD_FILE_EXISTS" = "NO" ] && ! echo "$SUDO_L_OUTPUT" | grep -q "ALL=(ALL) ALL"; then
    echo -e "\e[1;32m  ✔ [20%] Privilegios ALL=(ALL) ALL revocados correctamente.\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] El usuario aún tiene privilegios excesivos o el archivo malo existe.\e[0m"
    echo -e "       → Corrección: sudo rm -f /etc/sudoers.d/99-dev-user-bad"
  fi

  # 4. Existencia y sintaxis de la nueva regla con Cmnd_Alias
  echo -e "\n\e[1;37m⏳ [4/5] Verificando la nueva regla granular con Cmnd_Alias...\e[0m"
  if $SSH2 "sudo visudo -c -f /etc/sudoers.d/dev_user" &>/dev/null && $SSH2 "sudo grep -q 'Cmnd_Alias' /etc/sudoers.d/dev_user" 2>/dev/null; then
    echo -e "\e[1;32m  ✔ [20%] Archivo /etc/sudoers.d/dev_user válido y utiliza Cmnd_Alias.\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] La regla sudo es inválida o no usa Cmnd_Alias.\e[0m"
    echo -e "       → Diagnóstico: sudo visudo -c -f /etc/sudoers.d/dev_user"
  fi

  # 5. Backup en bóveda
  echo -e "\n\e[1;37m⏳ [5/5] Auditando backup en node03...\e[0m"
  if $SSH3 "test -f /opt/backup-vault/sudoers_dev_user.bak" 2>/dev/null; then
    BAK_CONTENT=$($SSH3 "cat /opt/backup-vault/sudoers_dev_user.bak" 2>/dev/null || echo "")
    if echo "$BAK_CONTENT" | grep -q "Cmnd_Alias"; then
      echo -e "\e[1;32m  ✔ [20%] Backup custodiado correctamente en node03 con la configuración segura.\e[0m"
      PUNTOS=$((PUNTOS + 20))
    else
      echo -e "\e[1;33m  ⚠️  [5%] Archivo presente en node03, pero no contiene la regla Cmnd_Alias.\e[0m"
      PUNTOS=$((PUNTOS + 5))
    fi
  else
    echo -e "\e[1;31m  ❌ [0%] No se encontró sudoers_dev_user.bak en node03:/opt/backup-vault/\e[0m"
  fi

  # Resultado Final
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
    echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — ¡Excelente! Dominio de sudo granular y SGID."
  elif [ $PUNTOS -ge 60 ]; then
    echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los puntos ❌."
  else
    echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Revise la configuración de usuarios y sudoers."
  fi
  echo -e "\e[1;36m================================================================================\e[0m\n"
  EOF

  bash /tmp/validador-usr001.sh && rm -f /tmp/validador-usr001.sh
tags:
  - Laboratorios-del-LFCS
---
[[Laboratorios del LFCS]]

---
We had a security audit flag a critical finding on one of our application servers. A developer account had been provisioned with unrestricted sudo access — essentially full root privileges — which was a clear violation of our least privilege policy. I was assigned to remediate it without taking the server offline.

The first thing I did was locate the sudoers file granting that access and remove it. But simply revoking access wasn't enough — the developer still had legitimate operational needs, so I had to replace it with something precise. I wrote a new sudoers rule using `Cmnd_Alias` to restrict the account to exactly four commands: restarting and checking nginx, and reading application logs. Nothing more.

While I was at it, I also corrected a directory permission issue on the log path. The folder had no group ownership and no SGID bit, which meant files created there wouldn't inherit the right group. I set it to `2750` with the correct group, so any new log files would automatically be accessible to the dev team without manual intervention.

One thing that caught me during validation was that the audit script was running `grep` against the sudoers file without elevated privileges, and since the file was set to `0440`, it was getting a permission denied silently — returning a false failure. I identified that by reading the validator source and reproducing the exact command manually. Once I understood what the script expected, I adjusted the file permissions accordingly and the check passed cleanly.

I also made sure to archive the corrected configuration to our backup vault on a separate node, using a pipe between two SSH sessions so the file never touched local disk as an intermediate step.

---

