---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Entorno: Vagrant (STG-004-MN)
Titulo: El Puente Roto – NFS Server/Client y Exportaciones con Restricciones - V1.0
Fecha de Inicio: 2026-06-18
Dificultad: 7/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
  - Configurar y depurar servicios NFS con control de acceso granular y reglas de firewall.
Temas: |-
  - Use Remote Filesystems: NFS
  - Firewalld Service Management
Competencias: |-
  - Configurar exportaciones NFS por subred con opciones de seguridad (root_squash, no_root_squash).
  - Diagnosticar y resolver problemas de "Permission denied" causados por mismatch de configuración entre exports, firewall y cliente.
  - Gestionar puertos RPC dinámicos de NFS mediante firewalld para permitir acceso controlado.
  - Implementar mount seguro desde el cliente con opciones que respeten las restricciones del servidor.
Script Vagrant: |2-
    # -*- mode: ruby -*-

    # vi: set ft=ruby :

    Vagrant.configure("2") do |config|
      config.vm.box = "generic/ubuntu2204"

      nodes = [
        { name: "node01", ip: "192.168.122.11", extra_disks: [] },
        { name: "node02", ip: "192.168.122.12", extra_disks: ['512M'] }, # STG-004: 1 disco LVM de 512MB
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
            apt-get install -y -qq sshpass lvm2 firewalld
          SHELL

          # ── PROVISIONADO ESPECÍFICO: CONFIGURAR NODE02 COMO SERVIDOR NFS ──
          if node[:name] == "node02"
            node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
              echo "💾 Configurando node02 como servidor NFS con LVM..."

              # 1. Instalar servidor NFS
              export DEBIAN_FRONTEND=noninteractive
              apt-get install -y -qq nfs-kernel-server

              # 2. Limpiar residuos de incidentes anteriores
              umount /srv/shared 2>/dev/null || true
              rm -rf /srv/shared
              vgremove -f vg_data 2>/dev/null || true
              wipefs -a /dev/vdb 2>/dev/null || true

              # 3. Configurar LVM
              pvcreate /dev/vdb
              vgcreate vg_data /dev/vdb
              lvcreate -L 512M -n lv_shared vg_data
              mkfs.ext4 /dev/vg_data/lv_shared

              # 4. Crear punto de montaje y montar
              mkdir -p /srv/shared
              mount /dev/vg_data/lv_shared /srv/shared

              # 5. Persistir en fstab
              echo "/dev/vg_data/lv_shared /srv/shared ext4 defaults 0 0" >> /etc/fstab

              # 6. Crear datos de prueba
              echo "NFS Shared Data - STG-004" > /srv/shared/welcome.txt
              echo "restricted_file" > /srv/shared/secret.txt
              chown -R nobody:nogroup /srv/shared
              chmod 755 /srv/shared

              # 7. Configurar exportación NFS con root_squash (LA TRAMPA)
              echo "/srv/shared 192.168.122.13(rw,sync,root_squash,no_subtree_check)" > /etc/exports

              # 8. Habilitar firewalld pero NO abrir puertos NFS (LA TRAMPA)
              systemctl enable firewalld
              systemctl start firewalld
              firewall-cmd --permanent --add-service=ssh
              firewall-cmd --reload

              # 9. Reiniciar servicio NFS
              systemctl enable nfs-kernel-server
              systemctl restart nfs-kernel-server

              echo "✅ node02 configurado como servidor NFS. Exporta solo a node03 con root_squash. Firewalld bloquea RPC."
            SHELL
          end

          # ── PROVISIONADO ESPECÍFICO: CONFIGURAR NODE03 COMO CLIENTE NFS ──
          if node[:name] == "node03"
            node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
              echo "💾 Configurando node03 como cliente NFS..."

              # 1. Instalar cliente NFS
              export DEBIAN_FRONTEND=noninteractive
              apt-get install -y -qq nfs-common

              # 2. Crear punto de montaje
              mkdir -p /mnt/shared

              # 3. LA TRAMPA: Intentar montar con opciones inseguras (no_root_squash)
              echo "⏳ Intentando montar NFS desde node02..."
              # Este mount fallará por firewall o por root_squash
              mount -t nfs -o rw,noatime 192.168.122.12:/srv/shared /mnt/shared 2>/dev/null || echo "⚠️ Mount falló - configuración requerida"

              # 4. LA TRAMPA: Persistir en fstab con opciones incorrectas
              echo "192.168.122.12:/srv/shared /mnt/shared nfs rw,noatime 0 0" >> /etc/fstab

              echo "✅ node03 preparado. Mount NFS requerirá configuración correcta."
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
      🔗 STG-004-MN — El Puente Roto (NFS Server/Client y Exportaciones con Restricciones)
      Módulo: Storage  │  Dificultad: 7/10  │  Nivel: L2
    --------------------------------------------------------------------------------
      Ubicación de Control:  node01  (Estación del Administrador — bob)
      Nodo Servidor NFS:     node02  (Almacenamiento LVM exportado — /srv/shared)
      Nodo Cliente NFS:      node03  (Acceso denegado — /mnt/shared)
      Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/stg-004/)
      Contraseña del Clúster: caleston123
    --------------------------------------------------------------------------------

      El equipo de operaciones reporta que node03 no puede acceder al directorio
      compartido exportado desde node02 vía NFS. El mensaje de error es consistente:
      "Permission denied" al intentar montar o acceder al share.

      La arquitectura indica que node02 exporta /srv/shared utilizando un volumen
      LVM de 512MB. Las exportaciones están configuradas pero el cliente no logra
      montar el recurso. Se sospecha de una combinación de problemas:
      - Posible mismatch entre la subred permitida en exports y la IP del cliente
      - root_squash activado en el servidor, impactando acceso root del cliente
      - firewalld en node02 posiblemente bloqueando puertos RPC dinámicos de NFS

      El cliente también reporta que intentó montar con opciones no_root_squash
      desde el lado cliente, lo cual es incorrecto (debe configurarse en el servidor).

      Se requiere que un ingeniero de storage diagnostique y corrija la configuración
      de exportación NFS, las reglas de firewall, y asegure un montaje exitoso desde
      el cliente respetando las políticas de seguridad del servidor.

      ARQUITECTURA DE ALMACENAMIENTO
      --------------------------------------------------------------------------------
      node02:
        - /dev/vg_data/lv_shared (512MB, ext4) → montado en /srv/shared
        - Exportación NFS: configurada con root_squash
        - Firewalld: activo, solo SSH permitido

      node03:
        - Punto de montaje objetivo: /mnt/shared
        - Intento previo con opciones incorrectas en fstab

      PROCEDIMIENTO REQUERIDO
      --------------------------------------------------------------------------------
      1. Diagnóstico del Servidor:
         - Conéctate a node02 e inspecciona la configuración actual de /etc/exports.
         - Verifica qué subred/IP está permitida y si root_squash está activo.
         - Revisa el estado de firewalld y los puertos permitidos.

      2. Diagnóstico del Cliente:
         - Conéctate a node03 e intenta montar manualmente el share NFS.
         - Captura el mensaje de error exacto para identificar la causa raíz.
         - Revisa /var/log/syslog o dmesg para detalles del fallo de montaje.

      3. Corrección en el Servidor:
         - Ajusta /etc/exports para permitir el acceso desde node03 (192.168.122.13).
         - Asegúrate de que las opciones (rw, sync, root_squash) sean correctas.
         - Exporta la nueva configuración con `exportfs -rav`.

      4. Apertura de Puertos RPC en Firewalld:
         - Identifica los puertos dinámicos requeridos por NFS/RPC.
         - Configura firewalld para permitir el tráfico NFS de forma segura.
         - Recuerda: NFS usa puerto 2049 (fijo) pero el portmapper y mountd usan puertos dinámicos.

      5. Montaje Seguro desde el Cliente:
         - Configura el montaje en node03 con opciones seguras (rw, noatime).
         - NO uses no_root_squash desde el cliente; respeta la configuración del servidor.
         - Persiste la configuración correcta en /etc/fstab.

      6. Validación de Acceso:
         - Verifica que el montaje sea exitoso.
         - Confirma que un usuario no-root puede leer/escribir en el share.
         - Confirma que root del cliente es "squashed" a nobody (por seguridad).

      7. Pipeline de Evidencia a node03:
         - Destino: /opt/ops-compliance/stg-004/nfs_access_evidence.txt
         - Desde node01, envía mediante un pipeline SSH la salida consolidada de:
           a) Exportaciones activas (exportfs -v desde node02)
           b) Reglas de firewall (firewall-cmd --list-all desde node02)
           c) Estado del montaje NFS (mount | grep shared en node03)
           d) Verificación de squash (id nobody desde node03 al acceder como root)
         - NO generar archivos temporales locales en node01.
      --------------------------------------------------------------------------------
      CRITERIOS DE ACEPTACIÓN
      --------------------------------------------------------------------------------
       [ ] Exportación NFS configurada correctamente para node03          --> 15%
       [ ] Firewalld permite tráfico NFS/RPC desde node03                 --> 15%
       [ ] Montaje exitoso en node03 con opciones seguras                 --> 15%
       [ ] Verificación de root_squash funcionando (nobody squash)        --> 15%
       [ ] Evidencia enviada a node03:/opt/ops-compliance/stg-004/        --> 20%
       [ ] CERO archivos de resultados almacenados en node01  (DESCALIFICA)

      REGLA DE ORO: El problema está en node02 (servidor) y su configuración de exportación/firewall.
      NO intentes "forzar" el acceso desde el cliente usando no_root_squash. Configura el servidor
      correctamente, abre los puertos necesarios, y monta respetando las políticas de seguridad.
    ================================================================================
    TICKET

              # ── SCRIPT DE PROVISIONAMIENTO (para --fix) ──
              cat << 'PROVISION' > /tmp/provision-stg004.sh
    #!/bin/bash
    # Este script reaplica el provisioning del incidente STG-004
    echo "Este script requiere acceso a Vagrant para re-provisionar."
    echo "Ejecuta: vagrant provision --provision-with shell"
    PROVISION
              chmod +x /tmp/provision-stg004.sh

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

    # Soporte para flag --fix
    if [[ "$1" == "--fix" ]]; then
        echo -e "\${YELLOW}🔧 Re-aplicando provisioning...\${RESET}"
        echo -e "\${CYAN}Este flag requiere re-ejecutar vagrant provision.\${RESET}"
        echo -e "\${CYAN}Por favor ejecuta: vagrant provision\${RESET}"
        exit 0
    fi

    echo -e "\${CYAN}╔════════════════════════════════════════════════════════════════╗\${RESET}"
    echo -e "\${CYAN}║          VERIFICACIÓN DE ESCENARIO STG-004                    ║\${RESET}"
    echo -e "\${CYAN}╚════════════════════════════════════════════════════════════════╝\${RESET}"
    echo ""

    # [1/8] node02: LVM Volume
    echo -e "\${YELLOW}[1/8] node02: Volumen LVM lv_shared\${RESET}"
    if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo lvs | grep -q lv_shared"; then
      echo -e "      \${GREEN}✓ LVM lv_shared existe\${RESET}"
    else
      echo -e "      \${RED}✗ LVM lv_shared no encontrado\${RESET}"
      FAIL=1
    fi

    # [2/8] node02: Mount /srv/shared
    echo -e "\${YELLOW}[2/8] node02: Montaje en /srv/shared\${RESET}"
    if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "df -h /srv/shared | grep -q shared"; then
      echo -e "      \${GREEN}✓ Montado correctamente\${RESET}"
    else
      echo -e "      \${RED}✗ No montado\${RESET}"
      FAIL=1
    fi

    # [3/8] node02: Exportación NFS configurada
    echo -e "\${YELLOW}[3/8] node02: Exportación NFS a node03\${RESET}"
    if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo exportfs -v | grep -q '192.168.122.13'"; then
      echo -e "      \${GREEN}✓ Exportación a node03 configurada\${RESET}"
    else
      echo -e "      \${RED}✗ Exportación no configurada correctamente\${RESET}"
      FAIL=1
    fi

    # [4/8] node02: root_squash activo
    echo -e "\${YELLOW}[4/8] node02: root_squash en exports\${RESET}"
    if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo exportfs -v | grep -q root_squash"; then
      echo -e "      \${GREEN}✓ root_squash activo\${RESET}"
    else
      echo -e "      \${RED}✗ root_squash no encontrado\${RESET}"
      FAIL=1
    fi

    # [5/8] node02: Firewalld activo con puertos NFS
    echo -e "\${YELLOW}[5/8] node02: Firewalld con puertos NFS\${RESET}"
    if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo firewall-cmd --list-services 2>/dev/null | grep -qE 'nfs|rpc'"; then
      echo -e "      \${GREEN}✓ Puertos NFS/RPC permitidos\${RESET}"
    else
      echo -e "      \${YELLOW}⚠ Firewalld no tiene reglas NFS explícitas (puede requerir configuración manual)\${RESET}"
      # No marcamos como FAIL porque el usuario puede necesitar agregar las reglas
    fi

    # [6/8] node03: Montaje NFS exitoso
    echo -e "\${YELLOW}[6/8] node03: Montaje NFS en /mnt/shared\${RESET}"
    if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "mount | grep -q '192.168.122.12:/srv/shared'"; then
      echo -e "      \${GREEN}✓ NFS montado correctamente\${RESET}"
    else
      echo -e "      \${RED}✗ NFS no montado\${RESET}"
      FAIL=1
    fi

    # [7/8] node03: Verificación de squash (root → nobody)
    echo -e "\${YELLOW}[7/8] node03: Verificación root_squash (acceso como root)\${RESET}"
    if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "sudo touch /mnt/shared/test_root.txt 2>&1 | grep -qE 'denied|Permission' || sudo stat 
  /mnt/shared/welcome.txt 2>/dev/null | grep -q 'Uid:.*99'"; then
      echo -e "      \${GREEN}✓ root_squash verificado (acceso restringido)\${RESET}"
    else
      echo -e "      \${YELLOW}⚠ Verificación de squash pendiente (acceso root puede estar permitido)\${RESET}"
      # No es FAIL crítico, pero indica posible misconfiguración
    fi

    # [8/8] node03: Bóveda
    echo -e "\${YELLOW}[8/8] node03: Bóveda de evidencia\${RESET}"
    if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/stg-004 ]"; then
      echo -e "      \${GREEN}✓ Bóveda creada\${RESET}"
    else
      echo -e "      \${RED}✗ Bóveda no existe\${RESET}"
      FAIL=1
    fi

    echo ""
    if [ \$FAIL -eq 0 ]; then
      clear
      cat /home/vagrant/TICKET_STG-004.txt
      echo -e "\n\e[32m✅ Lab listo para practicar\e[0m"
    else
      echo " "
      echo -e "\e[41m\e[97m ⚠  INCIDENTE MAL GENERADO \e[0m"
      echo -e "\e[33m\$FAIL check(s) fallaron.\e[0m"
      echo " "
      cat /home/vagrant/TICKET_STG-004.txt
      echo " "
      echo -e "\e[36m──────────────────────────────────────\e[0m"
      echo -e "\e[36m⏸  PAUSA — El laboratorio NO está listo.\e[0m"
      echo -e "\e[36m   Copia este output y pídeme que lo arregle.\e[0m"
      echo -e "\e[36m   Cuando estés listo, pulsa ENTER para entrar al shell.\e[0m"
      echo -e "\e[36m──────────────────────────────────────\e[0m"
      read -r -p ">>> Presiona ENTER para continuar... " _
      clear
    fi
    VERIFY

     chmod +x /tmp/verify-stg004.sh
     chmod +x /tmp/provision-stg004.sh

     # ── MOSTRAR TICKET AL INICIAR SESIÓN ──
     sed -i '/TICKET/d' /home/vagrant/.bashrc
     sed -i '/# Mostrar/d' /home/vagrant/.bashrc
     sed -i '/verify-stg004/d' /home/vagrant/.bashrc
     cat << 'EOF' >> /home/vagrant/.bashrc
    # Ejecutar verificación y mostrar ticket
    if [ -x /tmp/verify-stg004.sh ]; then
        bash /tmp/verify-stg004.sh
    fi
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
  - NFS-Server
  - NFS-Client
  - Firewalld
  - root_squash
  - RPC-Ports
Escenario: |-
  - Situación: node02 exporta /srv/shared (sobre LVM de 512MB) a node03 vía NFS, pero el cliente recibe "Permission denied". La configuración de exports
  usa root_squash y está limitada a la IP de node03. Firewalld en node02 está activo pero solo permite SSH, bloqueando los puertos RPC dinámicos necesarios
  para NFS. El cliente intentó montar con no_root_squash (opción incorrecta desde el cliente).
  - Tu misión:
      Diagnosticar en node02: revisar /etc/exports para confirmar la exportación a 192.168.122.13 con root_squash.
      Diagnosticar en node03: intentar montar y capturar el error exacto de "Permission denied".
      Corregir en node02: asegurar que exports permite node03, re-exportar con exportfs -rav.
      Configurar firewalld en node02: agregar servicios nfs, rpc-bind, mountd para abrir puertos RPC.
      Montar desde node03 con opciones seguras (rw, noatime), respetando root_squash del servidor (NO usar no_root_squash en cliente).
      Validar que el montaje funciona, que usuarios normales pueden leer/escribir, y que root del cliente es squashed a nobody.
      Enviar evidencia consolidada a node03:/opt/ops-compliance/stg-004/nfs_access_evidence.txt sin almacenar archivos temporales en node01.
      Regla de Oro: NO fuerces el acceso desde el cliente. Configura el servidor correctamente (exports + firewall) y monta respetando las políticas de seguridad.
---
[[Laboratorios del LFCS]]

---
