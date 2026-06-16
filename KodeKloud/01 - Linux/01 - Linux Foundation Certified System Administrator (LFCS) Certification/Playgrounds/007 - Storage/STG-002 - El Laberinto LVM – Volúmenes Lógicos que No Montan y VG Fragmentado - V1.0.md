---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Playground: STG-002-MN
Titulo: El Laberinto LVM – Volúmenes Lógicos que No Montan y VG Fragmentado
Fecha de Inicio: 2026-06-11
Dificultad: 7/10
Level Escalation: L2/L3
Objetivo: |-
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
  - Dominar el ciclo de vida completo de LVM: creación, diagnóstico, extensión y reparación.
Temas: |-
  - LVM Management (pvcreate, vgcreate, lvcreate, pvs, vgs, lvs)
  - Filesystem Resizing (resize2fs / xfs_growfs)
  - Persistent Mounting Troubleshooting (/etc/fstab, blkid, UUID)
  - Logical Volume Consistency Checks
Competencias: |-
  - Diagnosticar estados inconsistentes en volúmenes lógicos y grupos de volúmenes fragmentados.
  - Extender volúmenes lógicos y sus sistemas de archivos en caliente (online) sin pérdida de datos.
  - Corregir errores de montaje persistente causados por UUIDs obsoletos o cambios en la topología de almacenamiento.
Script Vagrant: |-
  # -*- mode: ruby -*-

  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"

    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['200M', '100M'] }, # STG-002: 2 discos específicos
      { name: "node03", ip: "192.168.122.13", extra_disks: [] }
    ]

    nodes.each do |node|
      config.vm.define node[:name] do |node_config|
        node_config.vm.hostname = node[:name]
        node_config.vm.network "private_network", ip: node[:ip], libvirt__network_name: "default"

        node_config.vm.provider "libvirt" do |lv|
          lv.memory = 1024
          lv.cpus = 1
          lv.driver = "kvm"
          
          # Crear discos adicionales según la configuración del nodo
          node[:extra_disks].each do |size|
            lv.storage :file, :size => size, :type => 'qcow2'
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
          apt-get install -y -qq sshpass parted lvm2
        SHELL

        # ── PROVISIONADO ESPECÍFICO: TICKET EN NODE01 ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket de Incidente para node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_STG-002.txt
  ================================================================================
    TICKET STG-002  │  Severidad: ALTA  │  Ambiente: CLÚSTER DISTRIBUIDO
  ================================================================================
    💾 STG-002-MN — El Laberinto LVM (Volúmenes que No Montan y VG Fragmentado)
    Módulo: Storage  │  Dificultad: 7/10  │  Nivel: L2/L3
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo a Intervenir:     node02  (Servidor con LVM inconsistente)
    Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/backup-vault/)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    Tras una ventana de mantenimiento fallida, el equipo de infraestructura 
    reportó que el volumen de datos de la aplicación en node02 (/mnt/app-data) 
    no está disponible. Una revisión preliminar indica que un intento de 
    expansión de almacenamiento quedó a medias: el Grupo de Volúmenes (VG) 
    presenta Physical Extents (PE) libres sin asignar, y el archivo /etc/fstab 
    contiene una referencia a un UUID que ya no corresponde a la topología 
    actual del sistema, impidiendo el montaje automático y arriesgando un 
    fallo de arranque (Emergency Mode).

    Se requiere que un ingeniero senior tome el control, diagnostique la 
    topología LVM real, recupere la persistencia del montaje y complete la 
    expansión del volumen lógico para consumir todo el espacio disponible, 
    asegurando la integridad del sistema de archivos existente.

    PROCEDIMIENTO REQUERIDO
    --------------------------------------------------------------------------------
    1. Diagnóstico y Saneamiento:
    - Conectarse a node02 e identificar la topología LVM real y el UUID actual 
      del filesystem utilizando las herramientas estándar de diagnóstico de bloques.
    - Saneer el archivo /etc/fstab, eliminando o comentando la entrada obsoleta 
      que está impidiendo el montaje y generando riesgo de fallo en el arranque.

    2. Ingeniería del Almacenamiento (LVM):
    - Identificar el Volumen Lógico (LV) de la aplicación y extenderlo para consumir 
      el 100% del espacio libre (PE) disponible en su Grupo de Volúmenes (VG).
    - Redimensionar el sistema de archivos subyacente en caliente (online) para que 
      el sistema operativo reconozca la nueva capacidad sin interrumpir el servicio 
      (sin desmontar).

    3. Despliegue y Validación de Persistencia:
    - Registrar el montaje en /etc/fstab utilizando el UUID correcto y aplicando 
      las opciones de resiliencia corporativas (noatime, nofail).
    - Validar la sintaxis del fstab obligatoriamente con `sudo mount -a` y verificar 
      que el punto de montaje esté activo y refleje el tamaño total expandido.

    4. Pipeline de Evidencia a node03:
    - Destino: /opt/backup-vault/stg002_evidence.txt
    - Desde node01, enviar mediante un pipeline SSH la salida consolidada de: 
      'lsblk -f', 'vgs' y 'df -h /mnt/app-data', sin generar archivos temporales 
      locales en el nodo de control.
    --------------------------------------------------------------------------------
    CRITERIOS DE ACEPTACIÓN
    --------------------------------------------------------------------------------
     [ ] Diagnóstico correcto de la topología LVM y UUIDs reales.
     [ ] /etc/fstab corregido con el UUID válido y opciones de resiliencia.
     [ ] LV 'lv_apps' extendido al 100% del espacio libre del VG.
     [ ] Filesystem redimensionado en caliente (sin pérdida de datos).
     [ ] Evidencia enviada a node03:/opt/backup-vault/stg002_evidence.txt

    REGLA DE ORO: Bajo ninguna circunstancia ejecutes 'mkfs' sobre el LV 
    existente. Se asume que contiene datos de producción. La expansión debe 
    ser 'online' y la corrección del fstab debe validarse con 'mount -a'.
  ================================================================================
  TICKET

            # Limpiar y mostrar ticket al iniciar sesión
            sed -i '/TICKET/d' /home/vagrant/.bashrc
            sed -i '/# Mostrar/d' /home/vagrant/.bashrc
            cat << 'EOF' >> /home/vagrant/.bashrc
  clear
  cat /home/vagrant/TICKET_STG-002.txt
  EOF
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: INYECCIÓN DE FALLOS EN NODE02 ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "💥 Inyectando fallos STG-002 en #{node[:name]}..."
            
            # 0. Limpieza de residuos del STG-001 para evitar conflictos
            umount /mnt/app-data 2>/dev/null || true
            sed -i '/app-data/d' /etc/fstab
            swapoff -a 2>/dev/null || true
            wipefs -a /dev/vdb /dev/vdc 2>/dev/null || true

            # 1. Crear la topología LVM base
            pvcreate /dev/vdb /dev/vdc
            vgcreate vg_apps /dev/vdb /dev/vdc
            
            # 2. Crear LV con solo 150M (dejando ~150M libres para que el alumno extienda)
            lvcreate -n lv_apps -L 150M vg_apps
            
            # 3. Formatear y preparar punto de montaje
            mkfs.ext4 /dev/vg_apps/lv_apps
            mkdir -p /mnt/app-data
            
            # 4. LA TRAMPA: Insertar un UUID falso/obsoleto en fstab
            echo "UUID=00000000-0000-0000-0000-000000000000 /mnt/app-data ext4 defaults 0 0" >> /etc/fstab
            
            echo "✅ Fallos STG-002 inyectados correctamente."
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
  - LFCS
  - RHCSA
  - Laboratorios-del-LFCS
  - Storage-Management
  - LVM-Troubleshooting
Escenario: |-
  - Situación: Tras un intento fallido de expandir el almacenamiento de la aplicación crítica en `node02`, el volumen lógico `lv-apps` dejó de montar tras el último reinicio. El grupo de volúmenes (`vg_apps`) presenta Physical Extents (PE) libres sin asignar (fragmentación lógica), el LV reporta un estado inconsistente y el archivo `/etc/fstab` contiene un UUID obsoleto que impide el montaje automático y podría generar un fallo de arranque (boot failure) en un entorno real.
  - Tu misión:
    1. Conectarte a `node02` y diagnosticar el estado actual del almacenamiento utilizando `pvs`, `vgs`, `lvs` y `lsblk -f` para identificar el espacio libre en el VG y el UUID real del LV.
    2. Corregir el archivo `/etc/fstab` reemplazando la entrada obsoleta por el UUID correcto (o la ruta `/dev/mapper/...`) y añadir las opciones de resiliencia adecuadas (`nofail`).
    3. Extender el volumen lógico `lv-apps` para consumir el 100% del espacio libre disponible en el VG (`lvextend -l +100%FREE`).
    4. Redimensionar el sistema de archivos subyacente (usando `resize2fs` o `xfs_growfs` según el formato detectado) para que el SO reconozca el nuevo espacio sin desmontar el volumen (expansión en caliente).
    5. Validar el montaje persistente ejecutando `sudo mount -a` (sin errores) y verificando el espacio final con `df -h /mnt/app-data`.
  - Regla de Oro: Bajo ninguna circunstancia debes formatear (`mkfs`) el volumen lógico existente, ya que se asume que contiene datos críticos. La expansión debe ser *online* y la corrección del `fstab` debe ser validada antes de cualquier reinicio de prueba.
---
[[Laboratorios del LFCS]]

---
Tell me about a recent challenge you faced at work."

Recently I had to respond to a high-severity storage incident on a distributed cluster. The application data volume on one of our servers was completely unavailable after a failed maintenance window. The team had attempted a storage expansion that was left incomplete — the Volume Group had unallocated Physical Extents sitting idle, and the fstab contained a placeholder UUID of all zeros, which was causing the system to fail at boot and drop into Emergency Mode.

I started with a full diagnostic before touching anything — I mapped the real LVM topology using lsblk and pvs/vgs/lvs to understand exactly what was there versus what the configuration assumed. Once I had a clear picture, I commented out the broken fstab entry to stop the boot failure risk, then brought the logical volume online and extended it to consume 100% of the available free extents across both physical volumes. The critical constraint was that this had to be an online resize — no unmounting, no data loss — so I used lvextend with the -r flag to call resize2fs automatically while the filesystem was live.
After that I updated fstab with the real UUID extracted dynamically via blkid, applied the corporate resilience options noatime and nofail, and validated the syntax with mount -a before considering the task done. Finally I piped the consolidated evidence — lsblk, vgs, and df output — directly from the affected node to the governance vault on a third node via an SSH pipeline, without writing any temporary files on the control station.
What I valued most from this incident was the discipline of diagnosing before acting. The temptation in a P1 is to start fixing immediately, but reading the system state first is what prevented me from making the situation worse.