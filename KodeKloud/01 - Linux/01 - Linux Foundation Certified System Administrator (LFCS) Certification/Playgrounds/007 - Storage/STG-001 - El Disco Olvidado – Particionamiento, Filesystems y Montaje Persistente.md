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
          
          # 3. Instalar herramientas
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass parted nfs-common
        SHELL

        # ── PROVISIONADO ESPECÍFICO: TICKET EN NODE01 ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket de Incidente para node01..."
            
            # Guardamos el texto plano intacto
            cat << 'TICKET' > /home/vagrant/TICKET_INC-5001.txt
  ================================================================================
    TICKET INC-5001  │  Severidad: MEDIA  │  Ambiente: CLÚSTER DISTRIBUIDO
  ================================================================================
    💾 STG-001-MN — El Disco Olvidado (Particiones, Fstab y Swap)
    Módulo: Storage  │  Dificultad: 6/10  │  Nivel: L2
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo a Intervenir:     node02  (Servidor con disco secundario mal configurado)
    Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/backup-vault/)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    Durante el proceso de expansión de capacidad del clúster, el equipo de
    infraestructura aprovisionó un disco secundario — /dev/vdb — en el nodo
    node02, destinado a servir como volumen de datos de aplicación bajo la
    ruta /mnt/app-data. El trabajo fue registrado como completado y el nodo
    fue reintegrado al clúster sin que se realizara una validación post-tarea.

    Al día siguiente, durante una ventana de mantenimiento programada que
    implicó el reinicio del servidor, la aplicación comenzó a reportar fallos
    de escritura. Al investigar, se encontró que /mnt/app-data aparecía vacío:
    el disco nunca fue configurado para montarse de forma persistente, y el
    reinicio dejó al sistema sin ese volumen disponible. La revisión posterior
    reveló además que el filesystem de /dev/vdb1 es ext3, en violación directa
    del estándar corporativo que exige ext4 en todos los volúmenes de datos.

    El problema se agravó cuando el equipo de monitoreo notificó que node02
    no cuenta con espacio de intercambio activo. La ausencia de Swap expone
    al nodo a un riesgo crítico de Out Of Memory (OOM) bajo carga sostenida,
    condición que el equipo de SRE considera inaceptable en producción.

    El ingeniero encargado deberá conectarse a node02 vía SSH desde node01
    y resolver la cadena completa. Reformateará /dev/vdb1 a ext4, corregirá
    la entrada en /etc/fstab para montar /mnt/app-data con las opciones
    defaults,noatime,nofail, y validará la sintaxis con sudo mount -a antes
    de continuar. Luego creará un archivo de swap de 128MB en la ruta
    /mnt/app-data/swapfile, le asignará permisos 600, lo inicializará con
    mkswap, lo activará y lo registrará en /etc/fstab para persistencia.
    Como cierre de gobernanza, copiará el fstab corregido y la salida de
    lsblk -f a la bóveda centralizada en node03:/opt/backup-vault/stg001_fstab.bak.

    ──────────────────────────────────────────────────────────────────────────
    CRITERIOS DE ACEPTACIÓN
    ──────────────────────────────────────────────────────────────────────────

     [ ] Partición /dev/vdb1 operativa con filesystem ext4                             → 25%
     [ ] /mnt/app-data montado con opciones noatime y nofail                   → 25%
     [ ] /etc/fstab corregido sintácticamente sin errores                                → 20%
     [ ] Swap activo de 128MB con permisos seguros (600)                           → 20%
     [ ] Evidencia copiada a node03:/opt/backup-vault/stg001_fstab.bak  → 10%

    REGLA DE ORO: Nunca apliques un cambio en fstab sin ejecutar sudo mount -a.
    Un error de sintaxis puede dejar el nodo inoperable en Emergency Mode.
    Diagnóstico previo recomendado: lsblk -f  y  cat /etc/fstab

  ================================================================================
  TICKET

            # Limpiamos basura de intentos previos en el bashrc
            sed -i '/TICKET/d' /home/vagrant/.bashrc
            sed -i '/# Mostrar/d' /home/vagrant/.bashrc
            sed -i '/cat \/home/d' /home/vagrant/.bashrc
            sed -i '/clear/d' /home/vagrant/.bashrc

            # Inyectamos de forma segura usando un heredoc limpio
            cat << 'EOF' >> /home/vagrant/.bashrc

  # Mostrar ticket de laboratorio al iniciar sesión de forma limpia
  clear
  cat /home/vagrant/TICKET_INC-5001.txt
  EOF
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
            sed -i "\#${DISK}#d" /etc/fstab
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
tags:
  - Laboratorios-del-LFCS
---
[[Laboratorios del LFCS]]

---

