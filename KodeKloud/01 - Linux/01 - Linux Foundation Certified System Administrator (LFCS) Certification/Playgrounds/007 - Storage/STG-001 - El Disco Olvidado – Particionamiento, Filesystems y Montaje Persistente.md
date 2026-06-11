---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Playground: STG-001-MN
Titulo: El Disco Olvidado – Particionamiento, Filesystems y Montaje Persistente
Fecha de Inicio: 2026-06-11
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
Temas: |-
  - Block Device Management (lsblk, fdisk/parted)
  - File System Creation (mkfs.ext4)
  - Persistent Mounting (/etc/fstab, mount options)
  - Swap Space Configuration
Competencias: |-
  - Identificar y preparar discos raw sin afectar el sistema operativo.
  - Configurar montajes persistentes con opciones de resiliencia (nofail, noatime).
  - Gestionar espacio de intercambio (Swap) de forma segura.
Script: |-
  cat << 'EOF' > /tmp/setup-stg001.sh

  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  echo -e "\e[1;33m⏳ [node01] Preparando entorno del laboratorio STG-001...\e[0m"

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

  # ── 2. Inyectar fallos de Storage en node02 ─────────────────────────────────
  $SSH ${USER_NET}@${IP_NODE02} "sudo bash -c '
    # Desactivar swap actual para simular el fallo
    swapoff -a 2>/dev/null || true
    
    # Limpiar el disco secundario (idempotencia)
    wipefs -a /dev/nvme1n1 2>/dev/null || true
    partprobe /dev/nvme1n1 2>/dev/null || true

    # FALLO 1: Crear partición pero con filesystem subóptimo (ext3 en lugar de ext4)
    parted -s /dev/nvme1n1 mklabel gpt
    parted -s /dev/nvme1n1 mkpart primary ext3 1MiB 100%
    mkfs.ext3 /dev/nvme1n1p1

    # Crear punto de montaje
    mkdir -p /mnt/app-data

    # FALLO 2: Entrada en fstab con filesystem incorrecto y sin opciones de resiliencia
    # (Eliminamos entradas previas de nvme1n1 para limpiar)
    sed -i \"/nvme1n1/d\" /etc/fstab
    echo \"/dev/nvme1n1p1 /mnt/app-data ext3 defaults 0 2\" >> /etc/fstab

    # FALLO 3: Dejar un archivo de swap huérfano o inactivo (simulamos que no hay swap activo)
    rm -f /swapfile
  '" < /dev/null

  echo -e "\e[1;33m⏳ Fallos inyectados en node02 (FS incorrecto, fstab sin noatime/nofail, sin swap).\e[0m"

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
  echo -e "\e[1;33m  TICKET INC-5001  │  Severidad: MEDIA  │  Ambiente: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  💾 STG-001-MN — El Disco Olvidado (Particiones, Fstab y Swap)\e[0m"
  echo -e "\e[1;36m  Módulo: Storage  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m     node02 (Servidor con disco secundario mal configurado)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Bóveda de Gobernanza — \e[1;35m/opt/backup-vault/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " "
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Se aprovisionó un disco secundario (\e[1m/dev/nvme1n1\e[0m) en \e[1mnode02\e[0m para"
  echo -e "  almacenar datos de aplicación en \e[1m/mnt/app-data\e[0m. Tras un reinicio,"
  echo -e "  la aplicación falla porque el directorio está vacío o inaccesible."
  echo -e "  Además, el monitoreo reporta que el nodo no tiene espacio de intercambio"
  echo -e "  (Swap) activo, representando un riesgo crítico de OOM (Out Of Memory)."
  echo -e " "
  echo -e " \e[1mParámetros Técnicos Obligatorios (SSH desde node01 hacia node02):\e[0m"
  echo -e " "
  echo -e "  \e[1;31m1. Particionamiento y Filesystem Correcto (Remoto en node02)\e[0m"
  echo -e "     Verifique la partición en \e[1m/dev/nvme1n1\e[0m. Si el filesystem es"
  echo -e "     incorrecto (ej. ext3), reformatee a \e[1mext4\e[0m."
  echo -e " "
  echo -e "  \e[1;31m2. Montaje Persistente y Resiliente (Remoto en node02)\e[0m"
  echo -e "     Corrija la entrada en \e[1m/etc/fstab\e[0m para \e[1m/mnt/app-data\e[0m."
  echo -e "     \e[1mOBLIGATORIO:\e[0m Incluya las opciones \e[1mdefaults,noatime,nofail\e[0m."
  echo -e "     Valide la sintaxis con \e[1msudo mount -a\e[0m antes de continuar."
  echo -e " "
  echo -e "  \e[1;31m3. Configuración de Swap Persistente (Remoto en node02)\e[0m"
  echo -e "     Cree un archivo de swap de \e[1m1G\e[0m dentro de \e[1m/mnt/app-data/swapfile\e[0m."
  echo -e "     Asegure permisos \e[1m600\e[0m, inicialícelo con \e[1mmkswap\e[0m y actívelo."
  echo -e "     Agregue la entrada correspondiente en \e[1m/etc/fstab\e[0m para persistencia."
  echo -e " "
  echo -e "  \e[1;31m4. Resguardo en Bóveda (node02 → node03)\e[0m"
  echo -e "     Copie el \e[1m/etc/fstab\e[0m corregido y la salida de \e[1mlsblk -f\e[0m a:"
  echo -e "     \e[1mnode03:/opt/backup-vault/stg001_fstab.bak\e[0m"
  echo -e " "
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Existe partición válida en /dev/nvme1n1 con filesystem ext4   --> \e[1;35m25%\e[0m"
  echo -e "  [ ] /mnt/app-data está montado con opciones noatime y nofail       --> \e[1;35m25%\e[0m"
  echo -e "  [ ] /etc/fstab contiene las entradas correctas y sin errores       --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Swap está activo (swapon --show) con tamaño >= 1G              --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Backup de fstab y lsblk custodiado en node03                   --> \e[1;35m10%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m NUNCA reinicie sin validar \e[1msudo mount -a\e[0m."
  echo -e "               Un error en fstab puede dejar el nodo inoperable (Emergency Mode)."
  echo -e "               Diagnóstico: \e[1mlsblk -f\e[0m y \e[1mcat /etc/fstab\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " "

  EOF

  bash /tmp/setup-stg001.sh && rm -f /tmp/setup-stg001.sh
Script Validacion: |-
  cat << 'EOF' > /tmp/validador-stg001.sh

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
  echo -e "\e[1;33m  🕵️  AUDITORÍA DE STORAGE Y PERSISTENCIA — INC-5001 (STG-001-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # 1. Filesystem ext4 en nvme1n1
  echo -e "\n\e[1;37m⏳ [1/5] Verificando filesystem de la partición en /dev/nvme1n1...\e[0m"
  FS_TYPE=$($SSH2 "lsblk -no FSTYPE /dev/nvme1n1p1" 2>/dev/null || echo "none")
  if [ "$FS_TYPE" = "ext4" ]; then
    echo -e "\e[1;32m  ✔ [25%] La partición /dev/nvme1n1p1 está formateada correctamente como ext4.\e[0m"
    PUNTOS=$((PUNTOS + 25))
  else
    echo -e "\e[1;31m  ❌ [0%] Filesystem incorrecto o partición no encontrada.\e[0m"
    echo -e "       → Actual: \e[1;31m${FS_TYPE}\e[0m (Se espera: ext4)"
    echo -e "       → Corrección: sudo mkfs.ext4 /dev/nvme1n1p1"
  fi

  # 2. Montaje con noatime y nofail
  echo -e "\n\e[1;37m⏳ [2/5] Verificando montaje y opciones de /mnt/app-data...\e[0m"
  MOUNT_OPTS=$($SSH2 "findmnt -no OPTIONS /mnt/app-data" 2>/dev/null || echo "none")
  if echo "$MOUNT_OPTS" | grep -q "noatime" && echo "$MOUNT_OPTS" | grep -q "nofail"; then
    echo -e "\e[1;32m  ✔ [25%] /mnt/app-data está montado con las opciones noatime y nofail.\e[0m"
    PUNTOS=$((PUNTOS + 25))
  else
    echo -e "\e[1;31m  ❌ [0%] Opciones de montaje incorrectas o directorio no montado.\e[0m"
    echo -e "       → Opciones actuales: \e[1;31m${MOUNT_OPTS}\e[0m"
    echo -e "       → Se esperan: rw,noatime,nofail (o similares que incluyan noatime y nofail)"
  fi

  # 3. Sintaxis de /etc/fstab
  echo -e "\n\e[1;37m⏳ [3/5] Validando sintaxis y contenido de /etc/fstab...\e[0m"
  FSTAB_CHECK=$($SSH2 "sudo mount -a 2>&1" 2>/dev/null || echo "ERROR")
  FSTAB_CONTENT=$($SSH2 "cat /etc/fstab" 2>/dev/null || echo "")
  if [ "$FSTAB_CHECK" = "" ] && echo "$FSTAB_CONTENT" | grep -q "nofail" && echo "$FSTAB_CONTENT" | grep -q "noatime"; then
    echo -e "\e[1;32m  ✔ [20%] /etc/fstab es válido y contiene las directivas de resiliencia requeridas.\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] Errores en /etc/fstab o faltan directivas críticas.\e[0m"
    echo -e "       → Diagnóstico: ssh bob@node02 'sudo mount -a'"
    echo -e "       → Asegure que las entradas de nvme1n1p1 y el swapfile tengan 'noatime,nofail'"
  fi

  # 4. Swap activo >= 1G
  echo -e "\n\e[1;37m⏳ [4/5] Verificando espacio de intercambio (Swap) activo...\e[0m"
  SWAP_INFO=$($SSH2 "swapon --show" 2>/dev/null || echo "")
  SWAP_SIZE=$($SSH2 "free -m | awk '/^Swap:/ {print \$2}'" 2>/dev/null || echo "0")
  if [ -n "$SWAP_INFO" ] && [ "$SWAP_SIZE" -ge 1000 ]; then
    echo -e "\e[1;32m  ✔ [20%] Swap activo correctamente con tamaño >= 1G (${SWAP_SIZE}MB).\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] Swap inactivo o tamaño insuficiente (< 1G).\e[0m"
    echo -e "       → Tamaño actual: \e[1;31m${SWAP_SIZE}MB\e[0m"
    echo -e "       → Corrección: sudo fallocate -l 1G /mnt/app-data/swapfile && sudo chmod 600 /mnt/app-data/swapfile"
    echo -e "                     sudo mkswap /mnt/app-data/swapfile && sudo swapon /mnt/app-data/swapfile"
  fi

  # 5. Backup en bóveda
  echo -e "\n\e[1;37m⏳ [5/5] Auditando backup en node03...\e[0m"
  if $SSH3 "test -f /opt/backup-vault/stg001_fstab.bak" 2>/dev/null; then
    BAK_CONTENT=$($SSH3 "cat /opt/backup-vault/stg001_fstab.bak" 2>/dev/null || echo "")
    if echo "$BAK_CONTENT" | grep -q "noatime" && echo "$BAK_CONTENT" | grep -q "nofail" && echo "$BAK_CONTENT" | grep -q "nvme1n1"; then
      echo -e "\e[1;32m  ✔ [10%] Backup custodiado correctamente en node03 con la configuración válida.\e[0m"
      PUNTOS=$((PUNTOS + 10))
    else
      echo -e "\e[1;33m  ⚠️  [5%] Archivo presente en node03, pero no contiene la configuración completa corregida.\e[0m"
      PUNTOS=$((PUNTOS + 5))
    fi
  else
    echo -e "\e[1;31m  ❌ [0%] No se encontró stg001_fstab.bak en node03:/opt/backup-vault/\e[0m"
  fi

  # Resultado Final
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
    echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — ¡Excelente! Dominio de storage persistente y resiliente."
  elif [ $PUNTOS -ge 60 ]; then
    echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los puntos ❌."
  else
    echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Revise la configuración de fstab, montaje y swap."
  fi
  echo -e "\e[1;36m================================================================================\e[0m\n"
  EOF

  bash /tmp/validador-stg001.sh && rm -f /tmp/validador-stg001.sh
tags:
  - Laboratorios-del-LFCS
---
[[Laboratorios del LFCS]]

---

