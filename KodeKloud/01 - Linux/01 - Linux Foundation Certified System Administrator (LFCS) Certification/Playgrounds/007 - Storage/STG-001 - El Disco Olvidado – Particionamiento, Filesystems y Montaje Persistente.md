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
Script Vagrant: |-
  # -*- mode: ruby -*-
  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"

    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disk: false },
      { name: "node02", ip: "192.168.122.12", extra_disk: true },
      { name: "node03", ip: "192.168.122.13", extra_disk: false }
    ]

    nodes.each do |node|
      config.vm.define node[:name] do |node_config|
        node_config.vm.hostname = node[:name]
        node_config.vm.network "private_network", ip: node[:ip], libvirt__network_name: "default"

        node_config.vm.provider "libvirt" do |lv|
          lv.memory = 1024
          lv.cpus = 1
          lv.driver = "kvm"
          
          if node[:extra_disk]
            lv.storage :file, :size => '1G', :type => 'qcow2'
          end
        end

        # ── PROVISIONADO GENERAL (Todos los nodos) ──
        node_config.vm.provision "shell", inline: <<-SHELL
          echo "🔧 Configurando #{node[:name]}..."
          
          # 1. Resolver nombres de host localmente
          cat << 'HOSTS' >> /etc/hosts
  192.168.122.11 node01
  192.168.122.12 node02
  192.168.122.13 node03
  HOSTS
          
          # 2. Crear usuario bob y dar permisos
          useradd -m -s /bin/bash bob
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          # 3. Instalar herramientas (wipefs ya viene en util-linux)
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass parted nfs-common
        SHELL

        # ── PROVISIONADO ESPECÍFICO: TICKET EN NODE01 ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket de Incidente para node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_INC-5001.txt
  clear
  echo -e "\\e[1;36m================================================================================\\e[0m"
  echo -e "\\e[1;33m  TICKET INC-5001  │  Severidad: MEDIA  │  Ambiente: CLÚSTER DISTRIBUIDO\\e[0m"
  echo -e "\\e[1;36m================================================================================\\e[0m"
  echo ""
  echo -e "  Durante el proceso de aprovisionamiento, se asignó un disco secundario"
  echo -e "  (\\e[1m/dev/vdb\\e[0m) al nodo \\e[1mnode02\\e[0m para almacenar datos críticos en \\e[1m/mnt/app-data\\e[0m."
  echo ""
  echo -e "  Tras un reinicio de mantenimiento, la aplicación reportó fallos de escritura."
  echo -e "  La investigación inicial revela que:"
  echo -e "  1. El punto de montaje \\e[1m/mnt/app-data\\e[0m no se monta automáticamente."
  echo -e "  2. El sistema de archivos es \\e[1mext3\\e[0m (violando el estándar corporativo \\e[1mext4\\e[0m)."
  echo -e "  3. El servidor carece de memoria de intercambio (Swap) activa."
  echo ""
  echo -e "  \\e[1;34mTU MISIÓN:\\e[0m"
  echo -e "  1. Conéctate a \\e[1mnode02\\e[0m desde aquí (usuario: \\e[1mbob\\e[0m, pass: \\e[1mcaleston123\\e[0m)."
  echo -e "  2. Reformatea la partición \\e[1m/dev/vdb1\\e[0m al tipo \\e[1mext4\\e[0m."
  echo -e "  3. Corrige \\e[1m/etc/fstab\\e[0m para montar en \\e[1m/mnt/app-data\\e[0m con opciones:"
  echo -e "     \\e[1mdefaults,noatime,nofail\\e[0m"
  echo -e "  4. Crea un swapfile de \\e[1m128MB\\e[0m en \\e[1m/mnt/app-data/swapfile\\e[0m,"
  echo -e "     con permisos \\e[1m600\\e[0m, inicialízalo y asegúralo en \\e[1m/etc/fstab\\e[0m."
  echo ""
  echo -e "\\e[1;36m  ──────────────────────────────────────────────────────────────────────────\\e[0m"
  echo -e "\\e[1;33m  CRITERIOS DE ACEPTACIÓN\\e[0m"
  echo -e "\\e[1;36m  ──────────────────────────────────────────────────────────────────────────\\e[0m"
  echo ""
  echo -e "   \\e[1;37m[ ]\\e[0m Partición \\e[1m/dev/vdb1\\e[0m operativa con filesystem \\e[1mext4\\e[0m       \\e[0;35m→ 25%\\e[0m"
  echo -e "   \\e[1;37m[ ]\\e[0m Punto \\e[1m/mnt/app-data\\e[0m montado con opciones \\e[1mnoatime\\e[0m y \\e[1mnofail\\e[0m \\e[0;35m→ 25%\\e[0m"
  echo -e "   \\e[1;37m[ ]\\e[0m \\e[1m/etc/fstab\\e[0m corregido sintácticamente sin errores          \\e[0;35m→ 20%\\e[0m"
  echo -e "   \\e[1;37m[ ]\\e[0m Swap activo de 128MB con permisos seguros (\\e[1m600\\e[0m)          \\e[0;35m→ 20%\\e[0m"
  echo -e "   \\e[1;37m[ ]\\e[0m Evidencia copiada a \\e[1mnode03:/opt/backup-vault/\\e[0m            \\e[0;35m→ 10%\\e[0m"
  echo ""
  echo -e "\\e[1;31m  ⚠️ REGLA DE ORO:\\e[0m Nunca apliques un cambio en fstab sin ejecutar \\e[1msudo mount -a\\e[0m."
  echo -e "  Si cometes un error de sintaxis, podrías romper el arranque del nodo."
  echo ""
  echo -e "\\e[1;36m================================================================================\\e[0m"
  echo ""
  TICKET

            # Hacer que el ticket aparezca al iniciar sesión
            echo "" >> /home/vagrant/.bashrc
            echo "# Mostrar ticket de laboratorio al iniciar sesión" >> /home/vagrant/.bashrc
            echo "cat /home/vagrant/TICKET_INC-5001.txt" >> /home/vagrant/.bashrc
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: INYECCIÓN DE FALLOS EN NODE02 ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "💥 Inyectando fallos STG-001 en #{node[:name]}..."
            DISK="/dev/vdb"
            [ ! -b "$DISK" ] && DISK="/dev/sdb"
            
            swapoff -a 2>/dev/null || true
            wipefs -a $DISK 2>/dev/null || true
            parted -s $DISK mklabel gpt
            parted -s $DISK mkpart primary ext3 1MiB 100%
            partprobe $DISK 2>/dev/null || true
            udevadm settle
            mkfs.ext3 ${DISK}1 >/dev/null 2>&1
            
            mkdir -p /mnt/app-data
            sed -i "/${DISK}/d" /etc/fstab
            sed -i "/app-data/d" /etc/fstab
            echo "${DISK}1 /mnt/app-data ext3 defaults 0 2" >> /etc/fstab
            rm -f /swapfile /mnt/app-data/swapfile 2>/dev/null || true
            echo "✅ Fallos inyectados correctamente."
          SHELL
        end
        
        # ── PROVISIONADO ESPECÍFICO: PREPARAR BÓVEDA EN NODE03 ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda de auditoría en #{node[:name]}..."
            mkdir -p /opt/backup-vault
            chown -R bob:bob /opt/backup-vault
            chmod 755 /opt/backup-vault
          SHELL
        end
      end
    end
  end
Script Validacion: |-
  cat << 'EOF' > /tmp/validador-stg001.sh

  #!/bin/bash

  PUNTOS=0
  USER="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"

  # Fallbacks adaptados a la topología estática de tu Vagrantfile
  IP_NODE02=$(sshpass -p "$PASS" ssh $SSH_OPTS ${USER}@${NODE_TARGET} 'hostname -i' 2>/dev/null | awk '{print $1}' | tr -d '\r' || echo "192.168.122.12")
  IP_NODE03=$(sshpass -p "$PASS" ssh $SSH_OPTS ${USER}@${NODE_VAULT} 'hostname -i' 2>/dev/null | awk '{print $1}' | tr -d '\r' || echo "192.168.122.13")

  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER}@${IP_NODE02}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER}@${IP_NODE03}"

  # Detectar dinámicamente si el disco mapeado es vdb o sdb en el destino
  DISK_TARGET=$($SSH2 "lsblk -no NAME | grep -E '^(vdb1|sdb1)' | head -n1" 2>/dev/null | tr -d '\r')
  [ -z "$DISK_TARGET" ] && DISK_TARGET="vdb1"

  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  AUDITORÍA DE STORAGE Y PERSISTENCIA — INC-5001 (STG-001-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # 1. Filesystem ext4 en el segundo disco
  echo -e "\n\e[1;37m⏳ [1/5] Verificando filesystem de la partición en /dev/${DISK_TARGET}...\e[0m"
  FS_TYPE=$($SSH2 "lsblk -no FSTYPE /dev/${DISK_TARGET}" 2>/dev/null | tr -d '\r' || echo "none")
  if [ "$FS_TYPE" = "ext4" ]; then
    echo -e "\e[1;32m  ✔ [25%] La partición /dev/${DISK_TARGET} está formateada correctamente como ext4.\e[0m"
    PUNTOS=$((PUNTOS + 25))
  else
    echo -e "\e[1;31m  ❌ [0%] Filesystem incorrecto o partición no encontrada.\e[0m"
    echo -e "       → Actual: \e[1;31m${FS_TYPE}\e[0m (Se espera: ext4)"
    echo -e "       → Corrección: sudo mkfs.ext4 /dev/${DISK_TARGET}"
  fi

  # 2. Montaje con noatime y nofail
  echo -e "\n\e[1;37m⏳ [2/5] Verificando montaje y opciones de /mnt/app-data...\e[0m"
  MOUNT_OPTS=$($SSH2 "findmnt -no OPTIONS /mnt/app-data" 2>/dev/null | tr -d '\r' || echo "none")
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
  if [ -z "$FSTAB_CHECK" ] && echo "$FSTAB_CONTENT" | grep -q "nofail" && echo "$FSTAB_CONTENT" | grep -q "noatime"; then
    echo -e "\e[1;32m  ✔ [20%] /etc/fstab es válido y contiene las directivas de resiliencia requeridas.\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] Errores en /etc/fstab o faltan directivas críticas.\e[0m"
    echo -e "       → Diagnóstico de salida: \e[1;31m${FSTAB_CHECK}\e[0m"
    echo -e "       → Asegure que las entradas de la partición y el swapfile tengan 'noatime,nofail' y aplique 'sudo mount -a'"
  fi

  # 4. Swap activo >= 128MB (Mapeado al requerimiento del ticket)
  echo -e "\n\e[1;37m⏳ [4/5] Verificando espacio de intercambio (Swap) activo...\e[0m"
  SWAP_INFO=$($SSH2 "swapon --show" 2>/dev/null || echo "")
  SWAP_SIZE=$($SSH2 "free -m | awk '/^Swap:/ {print \$2}'" 2>/dev/null | tr -d '\r' || echo "0")
  if [ -n "$SWAP_INFO" ] && [ "$SWAP_SIZE" -ge 120 ]; then
    echo -e "\e[1;32m  ✔ [20%] Swap activo correctamente con tamaño adecuado (${SWAP_SIZE}MB).\e[0m"
    PUNTOS=$((PUNTOS + 20))
  else
    echo -e "\e[1;31m  ❌ [0%] Swap inactivo o tamaño insuficiente (< 128MB).\e[0m"
    echo -e "       → Tamaño actual detectado: \e[1;31m${SWAP_SIZE}MB\e[0m"
    echo -e "       → Corrección: sudo dd if=/dev/zero of=/mnt/app-data/swapfile bs=1M count=128"
    echo -e "                     sudo chmod 600 /mnt/app-data/swapfile && sudo mkswap /mnt/app-data/swapfile && sudo swapon /mnt/app-data/swapfile"
  fi

  # 5. Backup en bóveda (node03)
  echo -e "\n\e[1;37m⏳ [5/5] Auditando backup en node03...\e[0m"
  if $SSH3 "test -f /opt/backup-vault/stg001_fstab.bak" 2>/dev/null; then
    BAK_CONTENT=$($SSH3 "cat /opt/backup-vault/stg001_fstab.bak" 2>/dev/null || echo "")
    # Comprobamos que el backup enviado sea el corregido (contenga noatime o ext4)
    if echo "$BAK_CONTENT" | grep -q "noatime" || echo "$BAK_CONTENT" | grep -q "ext4"; then
      echo -e "\e[1;32m  ✔ [10%] Backup custodiado correctamente en node03 con la configuración válida.\e[0m"
      PUNTOS=$((PUNTOS + 10))
    else
      echo -e "\e[1;33m  ⚠️  [5%] Archivo presente en node03, pero parece ser la versión vieja sin modificar.\e[0m"
      PUNTOS=$((PUNTOS + 5))
    fi
  else
    echo -e "\e[1;31m  ❌ [0%] No se encontró stg001_fstab.bak en node03:/opt/backup-vault/\e[0m"
    echo -e "       → Corrección: Desde node02 ejecute: scp /etc/fstab bob@node03:/opt/backup-vault/stg001_fstab.bak"
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

