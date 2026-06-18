---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Entorno: Vagrant (STG-004-MN)
Titulo: El Puente Roto – NFS Server or Client y Exportaciones con Restricciones - V1.0
Fecha de Inicio: 2026-06-18
Dificultad: 7/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
  - Configurar servicios de red de almacenamiento NFS con control de acceso mediante Firewalld.
Temas: |-
  - Use Remote Filesystems: NFS
  - Firewalld configuration (RPC, NFS ports)
  - NFS exports by subnet with restrictions
  - Mount options security
Competencias: |-
  - Configurar exportaciones NFS con control de acceso por subred y opciones de seguridad apropiadas.
  - Diagnosticar y resolver problemas de "Permission denied" causados por root_squash y configuraciones de firewall.
  - Abrir puertos RPC necesarios (111, 2049, 20048) para que el cliente NFS pueda montar correctamente.
  - Configurar montajes NFS seguros con opciones restrictivas y validación end-to-end.
Script Vagrant: |-
  # -*- mode: ruby -*-

  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"

    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: [] }, # STG-004: LVM en node02 para /dev/vg_data/lv_shared
      { name: "node03", ip: "192.168.122.13", extra_disks: [] }
    ]

    nodes.each do |node|
      config.vm.define node[:name] do |node_config|
        node_config.vm.hostname = node[:name]

        # Red de gestión dedicada (no "default")
        node_config.vm.network "private_network",
          ip: node[:ip],
          libvirt__network_name: "mgmt-net",
          libvirt__dhcp_enabled: false

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

          # 3. Instalar herramientas base
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass nfs-common
        SHELL

        # ── PROVISIONADO ESPECÍFICO: CONFIGURAR NODE02 COMO SERVIDOR NFS CON FIREWALL ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "💾 Configurando node02 como servidor NFS con restricciones..."

            # 1. Instalar servidor NFS y firewalld
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nfs-kernel-server firewalld

            # 2. Crear volume group y logical volume simulado
            # (simulamos LVM ya que no hay discos extra - usamos directorio local)
            mkdir -p /srv/shared
            echo "NFS Shared Volume - STG-004" > /srv/shared/welcome.txt
            chown -R nobody:nogroup /srv/shared
            chmod 755 /srv/shared

            # 3. LA TRAMPA: Configurar exportación con root_squash y subnet específica
            # Exporta a subnet incorrecta (192.168.100.0/24 en lugar de 192.168.122.0/24)
            echo "/srv/shared 192.168.100.0/24(rw,sync,root_squash,no_subtree_check)" > /etc/exports

            # 4. Habilitar firewalld pero NO abrir puertos RPC
            systemctl enable firewalld
            systemctl start firewalld

            # 5. Reiniciar servicio NFS
            systemctl enable nfs-kernel-server
            systemctl restart nfs-kernel-server

            echo "✅ node02 configurado como servidor NFS con firewall activo y exportación restringida."
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: PREPARAR BÓVEDA EN NODE03 ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda de auditoría en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/stg-004
            chown -R bob:bob /opt/ops-compliance/stg-004
            chmod 750 /opt/ops-compliance/stg-004
            echo "✅ Bóveda /opt/ops-compliance/stg-004 lista."
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: TICKET + VERIFICACIÓN EN NODE01 ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket de Incidente para node01..."

            cat << 'TICKET' > /home/vagrant/TICKET_STG-004.txt
  ================================================================================
    TICKET STG-004  │  Severidad: ALTA  │  Ambiente: PRODUCCIÓN
  ================================================================================
    🌉 STG-004-MN — El Puente Roto (NFS Server/Client y Exportaciones)
    Módulo: Storage  │  Dificultad: 7/10  │  Nivel: L2
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo Servidor NFS:     node02  (Exportación NFS — /srv/shared)
    Nodo Cliente NFS:      node03  (Cliente con Permission denied)
    Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/stg-004/)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    El equipo de desarrollo reporta que node03 no puede montar el share NFS
    exportado desde node02. El mensaje de error es: "mount.nfs: access denied by
    server while mounting 192.168.122.12:/srv/shared".

    Una revisión de logs en node03 muestra "Permission denied" tanto al intentar
    montar como al acceder luego de montaje manual. El servidor NFS en node02
    aparece en ejecución, pero la configuración de exportación y seguridad de
    red parece estar causando el rechazo.

    Se requiere que un administrador de almacenamiento diagnostique por qué el
    cliente no puede montar, identifique si el problema es de exportación NFS,
    configuración de firewall, o mismatch de subnets, y restaure el acceso
    controlado desde node03.

    ARQUITECTURA DE ALMACENAMIENTO
    --------------------------------------------------------------------------------
    node02:
      - /srv/shared (directorio exportado vía NFS)
      - Exportación: SOLO a 192.168.100.0/24 (subnet incorrecta)
      - Firewalld: ACTIVO pero sin reglas para puertos RPC/NFS
      - root_squash: ACTIVO

    node03:
      - Intento de montaje: 192.168.122.12:/srv/shared

    PROCEDIMIENTO REQUERIDO
    --------------------------------------------------------------------------------
    1. Diagnóstico del Servidor NFS (node02):
       - Inspecciona las exportaciones NFS actuales con `exportfs -v`.
       - Verifica que la subnet del cliente (192.168.122.0/24) esté permitida.
       - Identifica si root_squash está causando problemas de permisos.

    2. Diagnóstico del Firewall (node02):
       - Revisa el estado de firewalld y las reglas activas.
       - Identifica qué puertos RPC/NFS están bloqueados.
       - Puertos requeridos: 111 (rpcbind), 2049 (nfs), 20048 (mountd).

    3. Corrección de Exportaciones NFS:
       - Actualiza /etc/exports para permitir la subnet correcta (192.168.122.0/24).
       - Aplica opciones de seguridad apropiadas (sync, no_subtree_check).
       - Reinicia el servicio NFS y verifica exportfs -v.

    4. Apertura de Puertos en Firewall:
       - Agrega reglas permanentes en firewalld para puertos RPC/NFS.
       - Recarga el firewall y verifica conectividad.

    5. Montaje Seguro en Cliente (node03):
       - Monta NFS con opciones seguras (ro, nosuid, nodev si aplica).
       - Valida que el montaje funcione correctamente.
       - Persiste en /etc/fstab si es requerido.

    6. Pipeline de Evidencia a node03:
       - Destino: /opt/ops-compliance/stg-004/nfs_access_evidence.txt
       - Desde node01, envía mediante un pipeline SSH la salida consolidada de:
         a) Exportaciones NFS (exportfs -v desde node02)
         b) Estado del firewall (firewall-cmd --list-all desde node02)
         c) Montaje exitoso (mount | grep nfs desde node03)
       - NO generar archivos temporales locales en node01.
    --------------------------------------------------------------------------------
    CRITERIOS DE ACEPTACIÓN
    --------------------------------------------------------------------------------
     [ ] Exportación NFS configurada para subnet correcta (192.168.122.0/24) --> 20%
     [ ] Puertos RPC/NFS abiertos en firewalld (111, 2049, 20048)           --> 20%
     [ ] Montaje NFS exitoso desde node03                                   --> 20%
     [ ] Configuración persistente y servicios reiniciados                  --> 20%
     [ ] Evidencia enviada a node03:/opt/ops-compliance/stg-004/            --> 20%
     [ ] CERO archivos de resultados almacenados en node01  (DESCALIFICA)

    REGLA DE ORO: NO uses ACLs, SGID ni Sticky Bits. Este incidente es
    exclusivamente sobre NFS + Firewalld. NO modifiques permisos de archivos
    más allá de los requeridos para el servicio NFS.
  ================================================================================
  TICKET

            # ── SCRIPT DE VERIFICACIÓN RÁPIDA ──
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

  # [1/7] node02: Servicio NFS activo
  echo -e "\${YELLOW}[1/7] node02: Servicio NFS activo\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "systemctl is-active --quiet nfs-kernel-server"; then
    echo -e "      \${GREEN}✓ Servicio activo\${RESET}"
  else
    echo -e "      \${RED}✗ Servicio inactivo\${RESET}"
    FAIL=1
  fi

  # [2/7] node02: Exportación NFS a subnet correcta
  echo -e "\${YELLOW}[2/7] node02: Exportación a 192.168.122.0/24\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "exportfs -v | grep -q '192.168.122.0/24'"; then
    echo -e "      \${GREEN}✓ Exportación a subnet correcta\${RESET}"
  else
    echo -e "      \${RED}✗ Exportación incorrecta\${RESET}"
    FAIL=1
  fi

  # [3/7] node02: Firewalld activo
  echo -e "\${YELLOW}[3/7] node02: Firewalld activo\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "systemctl is-active --quiet firewalld"; then
    echo -e "      \${GREEN}✓ Firewalld activo\${RESET}"
  else
    echo -e "      \${RED}✗ Firewalld inactivo\${RESET}"
    FAIL=1
  fi

  # [4/7] node02: Puertos NFS abiertos
  echo -e "\${YELLOW}[4/7] node02: Puertos NFS/RPC abiertos\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "firewall-cmd --list-ports 2>/dev/null | grep -qE '111|2049|20048'"; then
    echo -e "      \${GREEN}✓ Puertos RPC/NFS configurados\${RESET}"
  else
    echo -e "      \${RED}✗ Puertos no abiertos\${RESET}"
    FAIL=1
  fi

  # [5/7] node02: Servicio firewalld habilitado
  echo -e "\${YELLOW}[5/7] node02: Firewalld habilitado al boot\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "systemctl is-enabled --quiet firewalld"; then
    echo -e "      \${GREEN}✓ Firewalld habilitado\${RESET}"
  else
    echo -e "      \${RED}✗ Firewalld no habilitado\${RESET}"
    FAIL=1
  fi

  # [6/7] node03: Montaje NFS exitoso
  echo -e "\${YELLOW}[6/7] node03: Montaje NFS desde node02\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "mount | grep -q '192.168.122.12:/srv/shared'"; then
    echo -e "      \${GREEN}✓ NFS montado correctamente\${RESET}"
  else
    echo -e "      \${RED}✗ NFS no montado\${RESET}"
    FAIL=1
  fi

  # [7/7] node03: Bóveda
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
    echo ""
    sleep 2
    clear
    cat /home/vagrant/TICKET_STG-004.txt
  else
    echo -e "\${RED}╔════════════════════════════════════════════════════════════════╗\${RESET}"
    echo -e "\${RED}║  ⚠️  ALGUNAS VERIFICACIONES FALLARON                           ║\${RESET}"
    echo -e "\${RED}║  El escenario puede estar incompleto. Revisa los errores.      ║\${RESET}"
    echo -e "\${RED}╚════════════════════════════════════════════════════════════════╝\${RESET}"
    echo ""
    echo -e "\${YELLOW}Mostrando ticket de todas formas...\${RESET}"
    sleep 3
    clear
    cat /home/vagrant/TICKET_STG-004.txt
  fi
  VERIFY

            chmod +x /tmp/verify-stg004.sh

            # ── MOSTRAR TICKET AL INICIAR SESIÓN ──
            sed -i '/TICKET/d' /home/vagrant/.bashrc
            echo '/tmp/verify-stg004.sh' >> /home/vagrant/.bashrc

            echo "✅ Ticket y script de verificación creados."
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

