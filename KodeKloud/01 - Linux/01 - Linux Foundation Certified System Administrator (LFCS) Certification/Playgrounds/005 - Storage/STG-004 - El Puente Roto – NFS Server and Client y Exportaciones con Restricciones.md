---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Entorno: Vagrant (STG-004-MN)
Titulo: El Puente Roto – NFS Server/Client y Exportaciones con Restricciones - V1.0
Fecha de Inicio: 2026-06-23
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
  - Configurar y asegurar servicios de almacenamiento en red (NFS) con control de acceso granular.
Temas: |-
  - NFS Server Configuration (exports, access control, root_squash)
  - NFS Client Mounting (secure options, fstab)
  - Firewall Configuration (UFW for NFS/RPC ports)
  - LVM Management (vg_data/lv_shared)
Competencias: |-
  - Diagnosticar problemas de conectividad NFS identificando bloqueos de firewall y configuraciones incorrectas de exportación.
  - Configurar exportaciones NFS con control de acceso por subred y opciones de seguridad apropiadas (root_squash vs no_root_squash).
  - Implementar montajes NFS seguros con opciones de hardening (nosuid, nodev, hard, intr).
  - Gestionar volúmenes LVM para almacenamiento compartido y validar la persistencia de configuraciones.
Script Vagrant: |-
  # -*- mode: ruby -*-


  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"

    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['512M'] },
      { name: "node03", ip: "192.168.122.13", extra_disks: [] }
    ]

    nodes.each do |node|
      config.vm.define node[:name] do |node_config|
        node_config.vm.hostname = node[:name]
        
        node_config.vm.network "private_network", 
          ip: node[:ip], 
          libvirt__network_name: "mgmt-net",
          libvirt__dhcp_enabled: false

        node_config.vm.provider "libvirt" do |lv|
          lv.memory = 1024
          lv.cpus = 1
          lv.driver = "kvm"
          
          node[:extra_disks].each do |size|
            lv.storage :file, :size => size, :type => 'qcow2'
          end
        end

        # ── PROVISIONADO GENERAL ──
        node_config.vm.provision "shell", inline: <<-SHELL
          echo "🔧 Configurando #{node[:name]}..."
          
          cat << 'HOSTS' >> /etc/hosts
  192.168.122.11 node01
  192.168.122.12 node02
  192.168.122.13 node03
  HOSTS
          
          useradd -m -s /bin/bash bob
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass ufw lvm2
        SHELL

        # ── NODE02: SERVIDOR NFS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "💾 Configurando node02 como servidor NFS..."
            
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nfs-kernel-server xfsprogs
            
            # Limpiar residuos
            umount /srv/shared 2>/dev/null || true
            rm -rf /srv/shared /srv/nfs-share
            wipefs -a /dev/vdb 2>/dev/null || true
            vgremove -f vg_data 2>/dev/null || true
            pvremove -f /dev/vdb 2>/dev/null || true
            
            # Crear LVM directamente (ya somos root)
            echo "Creando LVM..."
            pvcreate /dev/vdb
            vgcreate vg_data /dev/vdb
            lvcreate -L 400M -n lv_shared vg_data
            
            # Formatear y montar
            echo "Formateando con XFS..."
            mkfs.xfs /dev/vg_data/lv_shared
            mkdir -p /srv/shared
            mount /dev/vg_data/lv_shared /srv/shared
            echo "/dev/vg_data/lv_shared /srv/shared xfs defaults 0 0" >> /etc/fstab
            
            # Crear datos de prueba
            echo "Shared NFS Data - STG-004" > /srv/shared/test.txt
            mkdir -p /srv/shared/devs
            chown -R nobody:nogroup /srv/shared
            chmod 755 /srv/shared
            
            # Configurar exports incorrecto
            echo "Configurando /etc/exports (con errores)..."
            echo "# Exportación NFS - STG-004 (CONFIGURACIÓN INCORRECTA)" > /etc/exports
            echo "/srv/shared 192.168.122.100(ro,root_squash,no_subtree_check)" >> /etc/exports
            exportfs -ra
            
            # Configurar firewall con bloqueos
            echo "Configurando firewall UFW..."
            ufw --force reset > /dev/null 2>&1
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow ssh
            ufw deny 111/tcp
            ufw deny 111/udp
            ufw deny 2049/tcp
            ufw deny 2049/udp
            ufw --force enable
            
            # Iniciar NFS
            systemctl enable nfs-kernel-server
            systemctl restart nfs-kernel-server
            
            echo "✅ node02 configurado con 3 problemas inyectados"
          SHELL
        end

        # ── NODE03: CLIENTE NFS ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "💾 Configurando node03 como cliente NFS..."
            
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nfs-common
            
            mkdir -p /mnt/shared
            
            echo "⏳ Intentando montar NFS desde node02..."
            mount -t nfs -o rw,bg,soft,timeo=30 192.168.122.12:/srv/shared /mnt/shared 2>/tmp/mount-error.log || \
              echo "⚠️  Montaje fallido (esperado)"
            
            echo "✅ node03 configurado como cliente NFS"
          SHELL
        end

        # ── NODE03: BÓVEDA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/stg-004
            chown -R bob:bob /opt/ops-compliance/stg-004
            chmod 750 /opt/ops-compliance/stg-004
            echo "✅ Bóveda lista"
          SHELL
        end

        # ── NODE01: TICKET + VERIFICACIÓN ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket en node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_STG-004.txt
  ================================================================================
    TICKET STG-004  │  Severidad: ALTA  │  Ambiente: PRODUCCIÓN
  ================================================================================
    🔐 STG-004-MN — El Puente Roto (NFS Server/Client y Exportaciones con Restricciones)
    Módulo: Storage  │  Dificultad: 6/10  │  Nivel: L2
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo Servidor NFS:     node02  (Almacenamiento compartido — /srv/shared)
    Nodo Cliente NFS:      node03  (Montaje fallido — /mnt/shared)
    Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/stg-004/)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    El equipo de aplicaciones ha desplegado un nuevo microservicio en node03 que
    requiere acceso de lectura/escritura a un volumen compartido exportado desde
    node02 vía NFS. El volumen fue recientemente migrado a LVM (vg_data/lv_shared)
    y se aplicaron nuevas políticas de seguridad.

    Sin embargo, desde el despliegue, el cliente node03 NO puede montar el share
    y reporta errores de "Permission denied" y timeouts de conexión. El equipo
    de desarrollo no puede continuar su trabajo hasta que el almacenamiento
    compartido sea accesible con los permisos correctos.

    Una revisión preliminar sugiere múltiples capas del problema:
      - Posibles bloqueos a nivel de firewall en el servidor
      - Configuración de exportaciones NFS con restricciones incorrectas
      - Opciones de montaje inseguras o mal configuradas en el cliente

    Se requiere que un ingeniero de sistemas diagnostique la causa raíz,
    corrija los bloqueos de red, ajuste las exportaciones NFS con control
    de acceso apropiado y configure el montaje seguro en el cliente.

    ARQUITECTURA DE ALMACENAMIENTO
    --------------------------------------------------------------------------------
    node02:
      - /dev/vdb → LVM: vg_data/lv_shared (512MB, XFS)
      - Punto de montaje local: /srv/shared
      - Servicio: nfs-kernel-server
      - Firewall: UFW activo
    
    node03:
      - Punto de montaje: /mnt/shared (actualmente no montado)
      - Servicio: nfs-common instalado

    PROCEDIMIENTO REQUERIDO
    --------------------------------------------------------------------------------
    1. Diagnóstico desde node03:
       - Intenta montar el share NFS y captura el error exacto.
       - Verifica la conectividad de red hacia node02 (ping, nc, rpcinfo).
       - Identifica si hay bloqueos a nivel de firewall.

    2. Corrección del Firewall en node02:
       - Conéctate a node02 y revisa las reglas de UFW.
       - Permite el tráfico NFS/RPC necesario (puertos 111 y 2049 TCP/UDP).
       - Valida que los puertos queden accesibles desde node03.

    3. Corrección de /etc/exports en node02:
       - Revisa la configuración actual de exportaciones.
       - Ajusta para permitir acceso desde la subred 192.168.122.0/24.
       - Configura permisos rw y las opciones de seguridad apropiadas:
         * no_root_squash (para permitir operaciones root desde node03)
         * sync, no_subtree_check
       - Recarga las exportaciones con exportfs -ra.

    4. Montaje Seguro en node03:
       - Monta el share NFS en /mnt/shared con opciones seguras:
         * rw, hard, intr, nosuid, nodev
       - Verifica que el montaje funcione correctamente.
       - Persiste la configuración en /etc/fstab.

    5. Pipeline de Evidencia a node03:
       - Destino: /opt/ops-compliance/stg-004/nfs_evidence.txt
       - Desde node01, envía mediante un pipeline SSH la salida consolidada de:
         a) Estado del firewall en node02 (sudo ufw status verbose)
         b) Exportaciones NFS activas en node02 (sudo exportfs -v)
         c) Estado del montaje en node03 (mount | grep nfs)
         d) Prueba de escritura: crear archivo en /mnt/shared desde node03
       - NO generar archivos temporales locales en node01.
    --------------------------------------------------------------------------------
    CRITERIOS DE ACEPTACIÓN
    --------------------------------------------------------------------------------
     [ ] Firewall en node02 permite puertos NFS (111, 2049)              --> 20%
     [ ] /etc/exports configurado correctamente (subred, rw, no_root_squash) --> 20%
     [ ] Montaje NFS funcional en node03 con opciones seguras            --> 20%
     [ ] Configuración persistente en /etc/fstab                         --> 20%
     [ ] Evidencia enviada a node03:/opt/ops-compliance/stg-004/         --> 20%
     [ ] CERO archivos de resultados almacenados en node01 (DESCALIFICA)

    REGLA DE ORO: El volumen LVM vg_data/lv_shared en node02 está correctamente
    formateado y montado en /srv/shared. NO modifiques la estructura LVM,
    NO reformatees el disco. Todo el trabajo debe enfocarse en:
      1. Abrir los puertos necesarios en el firewall
      2. Corregir las exportaciones NFS
      3. Configurar el montaje seguro en el cliente
  ================================================================================
  TICKET

            # ── SCRIPT DE VERIFICACIÓN ──
            cat << 'VERIFY' > /tmp/verify-stg004.sh
  #!/bin/bash

  RED='\e[1;31m'
  GREEN='\e[1;32m'
  YELLOW='\e[1;33m'
  CYAN='\e[1;36m'
  RESET='\e[0m'

  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  FAIL=0

  echo -e "\${CYAN}╔════════════════════════════════════════════════════════════════╗\${RESET}"
  echo -e "\${CYAN}║          VERIFICACIÓN DE ESCENARIO STG-004                    ║\${RESET}"
  echo -e "\${CYAN}╚════════════════════════════════════════════════════════════════╝\${RESET}"
  echo ""

  echo -e "\${YELLOW}[1/7] node02: LVM vg_data/lv_shared\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo lvs vg_data/lv_shared 2>/dev/null | grep -q lv_shared"; then
    echo -e "      \${GREEN}✓ LV lv_shared existe\${RESET}"
  else
    echo -e "      \${RED}✗ LV no encontrado\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[2/7] node02: Montaje en /srv/shared\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "df -h /srv/shared | grep -q shared"; then
    echo -e "      \${GREEN}✓ Montado correctamente\${RESET}"
  else
    echo -e "      \${RED}✗ No montado\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[3/7] node02: Servicio NFS activo\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "systemctl is-active --quiet nfs-kernel-server"; then
    echo -e "      \${GREEN}✓ Servicio activo\${RESET}"
  else
    echo -e "      \${RED}✗ Servicio inactivo\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[4/7] node02: Firewall UFW activo\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo ufw status | grep -q 'Status: active'"; then
    echo -e "      \${GREEN}✓ UFW activo\${RESET}"
  else
    echo -e "      \${RED}✗ UFW inactivo\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[5/7] node02: Puertos NFS bloqueados\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo ufw status | grep -E '2049|111' | grep -q 'DENY'"; then
    echo -e "      \${GREEN}✓ Puertos NFS bloqueados (esperado)\${RESET}"
  else
    echo -e "      \${RED}✗ Puertos no bloqueados\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[6/7] node02: /etc/exports con IP incorrecta\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "grep -q '192.168.122.100' /etc/exports"; then
    echo -e "      \${GREEN}✓ IP incorrecta detectada\${RESET}"
  else
    echo -e "      \${RED}✗ Configuración no coincide\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[7/7] node03: Bóveda de evidencia\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/stg-004 ]"; then
    echo -e "      \${GREEN}✓ Bóveda creada\${RESET}"
  else
    echo -e "      \${RED}✗ Bóveda no existe\${RESET}"
    FAIL=1
  fi

  echo ""
  if [ \$FAIL -eq 0 ]; then
    echo -e "\${GREEN}╔════════════════════════════════════════════════════════════════╗\${RESET}"
    echo -e "\${GREEN}║  ✅ TODAS LAS VERIFICACIONES PASARON - ESCENARIO LISTO         ║\${RESET}"
    echo -e "\${GREEN}╚════════════════════════════════════════════════════════════════╝\${RESET}"
  else
    echo -e "\${RED}╔════════════════════════════════════════════════════════════════╗\${RESET}"
    echo -e "\${RED}║  ⚠️  ALGUNAS VERIFICACIONES FALLARON                           ║\${RESET}"
    echo -e "\${RED}╚════════════════════════════════════════════════════════════════╝\${RESET}"
  fi

  echo ""
  echo -e "\${YELLOW}Presiona ENTER para ver el ticket del incidente...\${RESET}"
  read -r
  cat /home/vagrant/TICKET_STG-004.txt
  VERIFY

            chmod +x /tmp/verify-stg004.sh
            
            sed -i '/verify-stg004/d' /home/vagrant/.bashrc
            cat << 'EOF' >> /home/vagrant/.bashrc
  bash /tmp/verify-stg004.sh
  EOF
          SHELL
        end
      end
    end
  end
tags:
  - LFCS
  - RHCSA
  - Laboratorios-del-LFCS
  - NFS-Security
  - Firewall-Configuration
  - LVM-Management
Escenario: |-
  - Situación: node02 exporta /srv/shared hacia node03, pero el cliente recibe "Permission denied" al intentar montar. Una revisión inicial revela múltiples problemas: el firewall UFW está bloqueando los puertos RPC necesarios (111, 2049), la configuración de /etc/exports tiene una IP incorrecta (192.168.122.100), solo permisos de lectura (ro) y root_squash activo. Además, las opciones de montaje en el cliente son inseguras.
  - Tu misión:
    1. Conectarte a node03 e intentar montar el share NFS desde node02 para reproducir el error.
    2. Diagnosticar el problema verificando la conectividad de red y los puertos NFS/RPC.
    3. Configurar el firewall en node02 para permitir el tráfico NFS (puertos 111 y 2049 TCP/UDP).
    4. Corregir la configuración de /etc/exports en node02 para permitir acceso de lectura/escritura desde la subred 192.168.122.0/24 con no_root_squash.
    5. Configurar el montaje en node03 con opciones seguras (rw, hard, intr, nosuid, nodev).
    6. Validar que el montaje funcione correctamente y persistir la configuración en /etc/fstab.
    7. Enviar evidencia a la bóveda de compliance en node03:/opt/ops-compliance/stg-004/
---
[[Laboratorios del LFCS]]

---
**What's a recent challenge you faced in your current role?*

In my current role as a NOC analyst, I don't have direct access to typical NOC tools, so most of my hands-on technical growth comes from my own lab practice. Recently, I worked through a realistic incident where a microservice deployment was blocked because a client server couldn't mount a shared NFS volume from a storage server — the team was getting "permission denied" errors and connection timeouts.

I approached it methodically, layer by layer. First, I confirmed basic network connectivity was fine, but a port-level test using netcat revealed that ports 111 and 2049, which NFS depends on, were timing out instead of being refused — that pointed directly to a firewall issue rather than a connectivity problem. I checked the firewall rules on the server and found explicit DENY rules blocking exactly those ports. I removed them and added scoped ALLOW rules restricted to the internal subnet, which is more secure than opening the ports to everyone.

Once the network path was clear, I moved to the NFS export configuration itself. The original setup only allowed one specific IP, was read-only, and used root squash, which would have blocked the application's write operations. I corrected it to allow the whole subnet with read-write access and the proper permission settings, then reloaded the exports.

After that, I mounted the share on the client with secure mount options — read-write, hard mount, no setuid binaries, no device files — and verified everything with an actual write test before persisting the configuration in fstab so it would survive a reboot.

What I found most valuable was the diagnostic process itself: distinguishing between a network-layer block and an application-layer permission issue using packet-level and port-level tools, rather than just guessing. It's the kind of structured troubleshooting I don't get to practice in my current ticket-routing role, so I built this scenario myself to develop that muscle.