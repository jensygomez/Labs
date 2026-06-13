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

  echo -e "\e[1;33m⏳ [node01] Preparando entorno del laboratorio STG-001 (Multi-Nodo)...\e[0m"

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

  echo -e "\e[1;32m✔ sshpass verificado/instalado en todo el clúster.\e[0m"

  # ── 1. Obtener IPs dinámicas ────────────────────────────────────────────────
  IP_NODE02=$($SSH ${USER_NET}@${NODE_TARGET} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.17")
  IP_NODE03=$($SSH ${USER_NET}@${NODE_VAULT} 'hostname -i' 2>/dev/null | tr -d '\r' || echo "10.244.29.59")

  echo -e "\e[1;36m  IPs detectadas: node02=\e[1;32m${IP_NODE02}\e[1;36m, node03=\e[1;32m${IP_NODE03}\e[0m"

  # ── 2. Inyectar fallos de Storage en node02 usando Loop Devices ──────────────
  $SSH ${USER_NET}@${IP_NODE02} "sudo bash -c '
    # Desactivar swap actual para simular el fallo
    swapoff -a 2>/dev/null || true
    
    # Desmontar si quedó algo colgado
    umount -f /mnt/app-data 2>/dev/null || true
    
    # Limpieza profunda de loops previos (cualquiera que use el archivo o el dispositivo)
    losetup -a | grep \"/storage_loop10\" | cut -d: -f1 | xargs -r losetup -d 2>/dev/null || true
    losetup -d /dev/loop10 2>/dev/null || true
    rm -f /storage_loop10

    # Crear un archivo de 256MB que simulará el disco físico (CORREGIDO: of= en lugar de out=)
    dd if=/dev/zero of=/storage_loop10 bs=1M count=256 status=none
    
    # Forzar la creación y asociación de /dev/loop10
    mknod /dev/loop10 b 7 10 2>/dev/null || true
    losetup /dev/loop10 /storage_loop10

    # Limpiar firmas previas dentro del loop
    wipefs -a /dev/loop10 2>/dev/null || true

    # FALLO 1: Crear partición pero con filesystem obsoleto (ext3 en lugar de ext4)
    parted -s /dev/loop10 mklabel gpt
    parted -s /dev/loop10 mkpart primary ext3 1MiB 100%
    
    # Informar al kernel de la nueva partición (/dev/loop10p1)
    partprobe /dev/loop10 2>/dev/null || true
    udevadm settle
    
    # Formatear la partición resultante en ext3 (el error a solucionar)
    mkfs.ext3 /dev/loop10p1 >/dev/null 2>&1

    # Crear punto de montaje objetivo
    mkdir -p /mnt/app-data

    # FALLO 2: Entrada errónea en fstab con filesystem incorrecto y sin resiliencia
    sed -i \"/loop10/d\" /etc/fstab
    sed -i \"/app-data/d\" /etc/fstab
    echo \"/dev/loop10p1 /mnt/app-data ext3 defaults 0 2\" >> /etc/fstab

    # FALLO 3: Eliminar cualquier swapfile previo para forzar su recreación desde cero
    rm -f /swapfile /mnt/app-data/swapfile 2>/dev/null || true
  '" < /dev/null

  # ── 3. Preparar bóveda en node03 ────────────────────────────────────────────
  $SSH ${USER_NET}@${IP_NODE03} "sudo bash -c '
    rm -rf /opt/backup-vault/*
    mkdir -p /opt/backup-vault/
    chown -R bob:bob /opt/backup-vault/
  '" < /dev/null

  echo -e "\e[1;32m✔ Bóveda de auditoría preparada en node03.\e[0m"

  # ── 4. Mostrar el ticket de Soporte Técnico ─────────────────────────────────
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-5001  │  Severidad: MEDIA  │  Ambiente: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  💾 STG-001-MN — El Disco Olvidado (Particiones, Fstab y Swap con Loop Devices)\e[0m"
  echo -e "\e[1;36m  Módulo: Storage  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e "  \e[1mUbicación de Control:\e[0m  node01  (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e "  \e[1mNodo a Intervenir:\e[0m     node02  (Servidor con disco virtual mal configurado)"
  echo -e "  \e[1mNodo Bóveda Destino:\e[0m   node03  (Bóveda de Gobernanza — \e[1;35m/opt/backup-vault/\e[0m)"
  echo -e "  \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  Durante el proceso de aprovisionamiento ágil, el equipo de infraestructura"
  echo -e "  asignó un bloque de almacenamiento virtualizado — identificado como \e[1m/dev/loop10\e[0m —"
  echo -e "  en el nodo \e[1mnode02\e[0m, con la intención de que sirviera como volumen dedicado"
  echo -e "  para almacenar datos críticos de la aplicación en la ruta \e[1m/mnt/app-data\e[0m."
  echo ""
  echo -e "  Al día siguiente, tras una ventana de mantenimiento que requirió un reinicio"
  echo -e "  del servidor, la aplicación comenzó a reportar fallos de persistencia. Al"
  echo -e "  investigar, se descubrió que \e[1m/mnt/app-data\e[0m no monta automáticamente,"
  echo -e "  el sistema de archivos utilizado fue \e[1mext3\e[0m (en lugar del estándar corporativo \e[1mext4\e[0m)"
  echo -e "  y los parámetros de montaje carecen de tolerancia a fallos."
  echo ""
  echo -e "  Adicionalmente, el equipo de SRE notificó que \e[1mnode02\e[0m se encuentra sin memoria"
  echo -e "  de intercambio activa, rompiendo las políticas de resiliencia frente a eventos"
  echo -e "  Out-Of-Memory (OOM)."
  echo ""
  echo -e "  \e[1;34mTU MISIÓN:\e[0m"
  echo -e "  1. Conéctate a \e[1mnode02\e[0m desde \e[1mnode01\e[0m."
  echo -e "  2. Reformatea la partición \e[1m/dev/loop10p1\e[0m al tipo \e[1mext4\e[0m (¡Cuidado con perder el loop!)."
  echo -e "  3. Corrige el archivo \e[1m/etc/fstab\e[0m para que monte de forma persistente en \e[1m/mnt/app-data\e[0m"
  echo -e "     utilizando obligatoriamente las opciones: \e[1mdefaults,noatime,nofail\e[0m"
  echo -e "  4. Crea un archivo swap de \e[1m128MB\e[0m (debido a la cuota del disco) en la ruta"
  echo -e "     \e[1m/mnt/app-data/swapfile\e[0m, configúrale permisos seguros (\e[1m600\e[0m), inicialízalo"
  echo -e "     y asegúralo de forma permanente en el \e[1m/etc/fstab\e[0m."
  echo ""
  echo -e "  Como paso final de gobernanza, copia el \e[1m/etc/fstab\e[0m modificado junto con la salida"
  echo -e "  del comando \e[1mlsblk -f\e[0m a la bóveda centralizada en:"
  echo -e "  \e[1mnode03:/opt/backup-vault/stg001_fstab.bak\e[0m"
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m Partición \e[1m/dev/loop10p1\e[0m operativa con filesystem \e[1mext4\e[0m       \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Punto \e[1m/mnt/app-data\e[0m montado con opciones \e[1mnoatime\e[0m y \e[1mnofail\e[0m      \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m \e[1m/etc/fstab\e[0m corregido sintácticamente sin errores de montaje     \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Swap activo basado en archivo dentro del montaje asignado          \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Evidencia y respaldos custodiados con éxito en \e[1mnode03\e[0m          \e[0;35m→ 10%\e[0m"
  echo ""
  echo -e "\e[1;31m  REGLA DE ORO:\e[0m Nunca apliques un cambio en fstab sin ejecutar \e[1msudo mount -a\e[0m."
  echo -e "  Si cometes un error de sintaxis, podrías romper el arranque del nodo."
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

