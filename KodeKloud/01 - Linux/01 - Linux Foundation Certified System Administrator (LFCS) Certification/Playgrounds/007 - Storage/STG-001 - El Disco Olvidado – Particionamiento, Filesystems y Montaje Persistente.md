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
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e "  \e[1mUbicación de Control:\e[0m  node01  (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e "  \e[1mNodo a Intervenir:\e[0m     node02  (Servidor con disco secundario mal configurado)"
  echo -e "  \e[1mNodo Bóveda Destino:\e[0m   node03  (Bóveda de Gobernanza — \e[1;35m/opt/backup-vault/\e[0m)"
  echo -e "  \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  Durante el proceso de expansión de capacidad, el equipo de infraestructura"
  echo -e "  aprovisionó un disco secundario — identificado como \e[1m/dev/nvme1n1\e[0m — en el"
  echo -e "  nodo \e[1mnode02\e[0m, con la intención de que sirviera como volumen dedicado para"
  echo -e "  los datos de aplicación bajo la ruta \e[1m/mnt/app-data\e[0m. El trabajo se dio"
  echo -e "  por concluido y el nodo fue incorporado al clúster sin mayor validación."
  echo ""
  echo -e "  Al día siguiente, tras una ventana de mantenimiento que requirió un reinicio"
  echo -e "  del servidor, la aplicación comenzó a reportar fallos de escritura y lectura."
  echo -e "  Al investigar, se descubrió que el directorio \e[1m/mnt/app-data\e[0m aparecía vacío"
  echo -e "  e inaccesible: el disco nunca había sido configurado para montarse de forma"
  echo -e "  persistente, y el reinicio dejó al sistema sin ese volumen disponible."
  echo ""
  echo -e "  El problema se agravó cuando el equipo de monitoreo notificó que \e[1mnode02\e[0m"
  echo -e "  no cuenta con espacio de intercambio activo. La ausencia de \e[1mSwap\e[0m expone"
  echo -e "  al nodo a un riesgo crítico de \e[1mOut Of Memory (OOM)\e[0m bajo carga sostenida,"
  echo -e "  situación que el equipo de SRE considera inaceptable en un nodo productivo."
  echo ""
  echo -e "  El ingeniero encargado deberá conectarse a \e[1mnode02\e[0m vía SSH desde \e[1mnode01\e[0m"
  echo -e "  y resolver la cadena completa de problemas. Primero verificará el estado"
  echo -e "  del filesystem en \e[1m/dev/nvme1n1\e[0m: si el formato es incorrecto — por ejemplo"
  echo -e "  \e[1mext3\e[0m — deberá reformatear la partición a \e[1mext4\e[0m. Luego corregirá la"
  echo -e "  entrada correspondiente en \e[1m/etc/fstab\e[0m para que \e[1m/mnt/app-data\e[0m se monte"
  echo -e "  de forma persistente con las opciones \e[1mdefaults,noatime,nofail\e[0m, validando"
  echo -e "  la sintaxis mediante \e[1msudo mount -a\e[0m antes de continuar."
  echo ""
  echo -e "  Una vez resuelto el montaje, creará un archivo de swap de \e[1m1G\e[0m en la ruta"
  echo -e "  \e[1m/mnt/app-data/swapfile\e[0m, le asignará permisos \e[1m600\e[0m, lo inicializará con"
  echo -e "  \e[1mmkswap\e[0m, lo activará con \e[1mswapon\e[0m y registrará su entrada en \e[1m/etc/fstab\e[0m"
  echo -e "  para garantizar que persista tras futuros reinicios."
  echo ""
  echo -e "  Como paso final de gobernanza, el ingeniero copiará el \e[1m/etc/fstab\e[0m"
  echo -e "  corregido junto con la salida del comando \e[1mlsblk -f\e[0m hacia la bóveda"
  echo -e "  centralizada en \e[1mnode03:/opt/backup-vault/stg001_fstab.bak\e[0m, dejando"
  echo -e "  evidencia auditada de la intervención realizada."
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m Partición válida en \e[1m/dev/nvme1n1\e[0m con filesystem \e[1mext4\e[0m          \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m \e[1m/mnt/app-data\e[0m montado con opciones \e[1mnoatime\e[0m y \e[1mnofail\e[0m          \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m \e[1m/etc/fstab\e[0m con entradas correctas y sin errores de sintaxis    \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Swap activo (\e[1mswapon --show\e[0m) con tamaño >= \e[1m1G\e[0m                  \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Backup de \e[1mfstab\e[0m y \e[1mlsblk\e[0m custodiado en \e[1mnode03\e[0m               \e[0;35m→ 10%\e[0m"
  echo ""
  echo -e "\e[1;31m  REGLA DE ORO:\e[0m Nunca reinicie sin validar \e[1msudo mount -a\e[0m. Un error en"
  echo -e "  \e[1m/etc/fstab\e[0m puede dejar el nodo inoperable en \e[1mEmergency Mode\e[0m."
  echo -e "  Diagnóstico previo recomendado: \e[1mlsblk -f\e[0m y \e[1mcat /etc/fstab\e[0m"
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""

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

