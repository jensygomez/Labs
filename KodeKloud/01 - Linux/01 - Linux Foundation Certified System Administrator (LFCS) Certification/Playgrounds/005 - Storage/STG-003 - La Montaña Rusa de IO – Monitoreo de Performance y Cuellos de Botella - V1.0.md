---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Entorno: Vagrant (STG-003-MN)
Titulo: La Montaña Rusa de I/O – Monitoreo de Performance y Cuellos de Botella - V1.0
Fecha de Inicio: 2026-06-18
Dificultad: 7/10
Level Escalation: L3
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
  - Diagnosticar, medir y optimizar el rendimiento de almacenamiento local y en red (NFS).
Temas: |-
  - Monitor Storage Performance (iostat, iotop, sar -d)
  - NFS Client Tuning (nfsiostat)
  - Filesystem Mount Options (noatime, async, rsize, wsize)
Competencias: |-
  - Identificar cuellos de botella de I/O utilizando herramientas de monitoreo nativas de Linux para diferenciar entre problemas de disco local y latencia de red.
  - Analizar el rendimiento de montajes NFS y detectar configuraciones subóptimas por defecto que limitan el throughput.
  - Optimizar el rendimiento de E/S ajustando opciones de montaje críticas (noatime, async) y parámetros de red NFS (rsize, wsize).
  - Validar las mejoras de rendimiento comparando métricas de latencia y throughput antes y después del tuning, asegurando la persistencia de los cambios.
Script Vagrant: |-
  # -*- mode: ruby -*-

  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"

    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['512M'] }, # STG-003: 1 disco de 512MB
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
          apt-get install -y -qq sshpass sysstat
        SHELL

        # ── PROVISIONADO ESPECÍFICO: CONFIGURAR NODE02 COMO SERVIDOR NFS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "💾 Configurando node02 como servidor NFS..."
            
            # 1. Instalar servidor NFS
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nfs-kernel-server
            
            # 2. Limpiar residuos de incidentes anteriores
            umount /srv/nfs-share 2>/dev/null || true
            rm -rf /srv/nfs-share
            wipefs -a /dev/vdb 2>/dev/null || true
            
            # 3. Formatear disco con XFS
            mkfs.xfs /dev/vdb
            
            # 4. Crear punto de montaje y montar
            mkdir -p /srv/nfs-share
            mount /dev/vdb /srv/nfs-share
            
            # 5. Persistir en fstab
            echo "/dev/vdb /srv/nfs-share xfs defaults 0 0" >> /etc/fstab
            
            # 6. Crear datos de prueba
            echo "NFS Share Data - STG-003" > /srv/nfs-share/test.txt
            chown -R nobody:nogroup /srv/nfs-share
            chmod 755 /srv/nfs-share
            
            # 7. Configurar exportación NFS (abierto a toda la red para simplicidad)
            echo "/srv/nfs-share 192.168.122.0/24(rw,sync,no_subtree_check)" > /etc/exports
            
            # 8. Reiniciar servicio NFS
            systemctl enable nfs-kernel-server
            systemctl restart nfs-kernel-server
            
            echo "✅ node02 configurado como servidor NFS con disco XFS de 512MB."
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
            mkdir -p /mnt/nfs-data
            
            # 3. Montar NFS con RETRY (esperar a que node02 esté listo)
            echo "⏳ Intentando montar NFS desde node02..."
            for i in 1 2 3 4 5; do
              if mount -t nfs 192.168.122.12:/srv/nfs-share /mnt/nfs-data 2>/dev/null; then
                echo "✅ NFS montado exitosamente en intento $i"
                break
              fi
              echo "  Intento $i fallido, esperando 5 segundos..."
              sleep 5
            done
            
            # 4. LA TRAMPA: Persistir en fstab sin opciones de optimización
            echo "192.168.122.12:/srv/nfs-share /mnt/nfs-data nfs defaults 0 0" >> /etc/fstab
            
            echo "✅ node03 configurado como cliente NFS con montaje subóptimo."
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: PREPARAR BÓVEDA EN NODE03 ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda de auditoría en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/stg-003
            chown -R bob:bob /opt/ops-compliance/stg-003
            chmod 750 /opt/ops-compliance/stg-003
            echo "✅ Bóveda /opt/ops-compliance/stg-003 lista."
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: TICKET + VERIFICACIÓN EN NODE01 ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket de Incidente para node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_STG-003.txt
  ================================================================================
    TICKET STG-003  │  Severidad: CRÍTICA  │  Ambiente: PRODUCCIÓN
  ================================================================================
    💾 STG-003-MN — La Montaña Rusa de I/O (Monitoreo y Cuellos de Botella)
    Módulo: Storage  │  Dificultad: 7/10  │  Nivel: L3
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo Servidor NFS:     node02  (Almacenamiento compartido — /srv/nfs-share)
    Nodo Cliente NFS:      node03  (Montaje lento — /mnt/nfs-data)
    Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/stg-003/)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    El equipo de desarrollo ha reportado que la aplicación desplegada en node03
    está experimentando timeouts críticos al escribir en el directorio compartido
    montado vía NFS desde node02. Las operaciones de escritura, que deberían 
    completarse en milisegundos, están tardando varios segundos, causando 
    fallos en cascada y degradación del servicio.

    Una revisión inicial confirma que el share NFS está correctamente exportado
    desde node02 y montado en node03. Sin embargo, las métricas de rendimiento
    muestran latencias inaceptables y un throughput significativamente menor al
    esperado para la red interna del clúster.

    Se requiere que un ingeniero senior de storage diagnostique la causa raíz
    del cuello de botella, identifique si el problema reside en el disco local,
    la red o la configuración del cliente NFS, y aplique las optimizaciones
    necesarias para restaurar el rendimiento esperado.

    ARQUITECTURA DE ALMACENAMIENTO
    --------------------------------------------------------------------------------
    node02:
      - /dev/vdb (512MB, XFS) → exportado vía NFS como /srv/nfs-share
    
    node03:
      - Montaje NFS: 192.168.122.12:/srv/nfs-share en /mnt/nfs-data
      - Opciones de montaje: POR DEFECTO (sin tuning)

    PROCEDIMIENTO REQUERIDO
    --------------------------------------------------------------------------------
    1. Diagnóstico de Rendimiento:
       - Conéctate a node03 y analiza el rendimiento actual del montaje NFS
         utilizando las herramientas de monitoreo de I/O disponibles.
       - Identifica métricas clave: latencia de lectura/escritura, throughput,
         operaciones por segundo y utilización de la red.

    2. Análisis de Configuración:
       - Inspecciona las opciones de montaje actuales del share NFS en node03.
       - Determina qué parámetros están causando el bajo rendimiento (sincronización,
         tamaños de buffer, actualización de metadatos, etc.).

    3. Optimización del Cliente NFS:
       - Reconfigura el montaje aplicando opciones de alto rendimiento que
         eliminen el cuello de botella identificado.
       - Asegura que las nuevas opciones queden correctamente persistidas.

    4. Validación de Mejora:
       - Vuelve a medir el rendimiento con las mismas herramientas de diagnóstico.
       - Compara las métricas antes/después para cuantificar la mejora.

    5. Pipeline de Evidencia a node03:
       - Destino: /opt/ops-compliance/stg-003/performance_evidence.txt
       - Desde node01, envía mediante un pipeline SSH la salida consolidada de:
         a) Estado del montaje NFS (mount | grep nfs)
         b) Métricas de rendimiento NFS (nfsiostat o equivalente)
         c) Opciones de montaje activas (cat /proc/mounts | grep nfs)
       - NO generar archivos temporales locales en node01.
    --------------------------------------------------------------------------------
    CRITERIOS DE ACEPTACIÓN
    --------------------------------------------------------------------------------
     [ ] Diagnóstico correcto del cuello de botella de I/O                    --> 25%
     [ ] Opciones de montaje NFS optimizadas aplicadas                        --> 25%
     [ ] Configuración persistente en /etc/fstab                              --> 25%
     [ ] Evidencia enviada a node03:/opt/ops-compliance/stg-003/              --> 25%
     [ ] CERO archivos de resultados almacenados en node01  (DESCALIFICA)

    REGLA DE ORO: El servicio NFS en node02 está funcionando correctamente.
    NO modifiques las exportaciones del servidor, NO reinicies nfs-server,
    NO toques el firewall. Todo el tuning debe realizarse exclusivamente desde
    el lado del cliente (node03) ajustando las opciones de montaje.
  ================================================================================
  TICKET

            # ── SCRIPT DE VERIFICACIÓN RÁPIDA ──
            cat << 'VERIFY' > /tmp/verify-stg003.sh
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
  echo -e "\${CYAN}║          VERIFICACIÓN DE ESCENARIO STG-003                    ║\${RESET}"
  echo -e "\${CYAN}╚════════════════════════════════════════════════════════════════╝\${RESET}"
  echo ""

  # [1/6] node02: Disco XFS
  echo -e "\${YELLOW}[1/6] node02: Disco XFS en /dev/vdb\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "lsblk -f /dev/vdb | grep -q xfs"; then
    echo -e "      \${GREEN}✓ XFS detectado\${RESET}"
  else
    echo -e "      \${RED}✗ XFS no encontrado\${RESET}"
    FAIL=1
  fi

  # [2/6] node02: Montaje /srv/nfs-share
  echo -e "\${YELLOW}[2/6] node02: Montaje en /srv/nfs-share\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "df -h /srv/nfs-share | grep -q nfs-share"; then
    echo -e "      \${GREEN}✓ Montado correctamente\${RESET}"
  else
    echo -e "      \${RED}✗ No montado\${RESET}"
    FAIL=1
  fi

  # [3/6] node02: Servicio NFS activo
  echo -e "\${YELLOW}[3/6] node02: Servicio NFS activo\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "systemctl is-active --quiet nfs-kernel-server"; then
    echo -e "      \${GREEN}✓ Servicio activo\${RESET}"
  else
    echo -e "      \${RED}✗ Servicio inactivo\${RESET}"
    FAIL=1
  fi

  # [4/6] node02: Exportación NFS
  echo -e "\${YELLOW}[4/6] node02: Exportación NFS configurada\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo exportfs -v | grep -q nfs-share"; then
    echo -e "      \${GREEN}✓ Exportación activa\${RESET}"
  else
    echo -e "      \${RED}✗ No exportado\${RESET}"
    FAIL=1
  fi

  # [5/6] node03: Montaje NFS
  echo -e "\${YELLOW}[5/6] node03: Montaje NFS en /mnt/nfs-data\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "mount | grep -q '192.168.122.12:/srv/nfs-share'"; then
    echo -e "      \${GREEN}✓ NFS montado\${RESET}"
  else
    echo -e "      \${RED}✗ NFS no montado\${RESET}"
    FAIL=1
  fi

  # [6/6] node03: Bóveda
  echo -e "\${YELLOW}[6/6] node03: Bóveda de evidencia\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/stg-003 ]"; then
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
    cat /home/vagrant/TICKET_STG-003.txt
  else
    echo -e "\${RED}╔════════════════════════════════════════════════════════════════╗\${RESET}"
    echo -e "\${RED}║  ⚠️  ALGUNAS VERIFICACIONES FALLARON                           ║\${RESET}"
    echo -e "\${RED}║  El escenario puede estar incompleto. Revisa los errores.      ║\${RESET}"
    echo -e "\${RED}╚════════════════════════════════════════════════════════════════╝\${RESET}"
    echo ""
    echo -e "\${YELLOW}Mostrando ticket de todas formas...\${RESET}"
    sleep 3
    clear
    cat /home/vagrant/TICKET_STG-003.txt
  fi
  VERIFY

            chmod +x /tmp/verify-stg003.sh
            
            # ── MOSTRAR TICKET AL INICIAR SESIÓN ──
            sed -i '/TICKET/d' /home/vagrant/.bashrc
            sed -i '/# Mostrar/d' /home/vagrant/.bashrc
            sed -i '/verify-stg003/d' /home/vagrant/.bashrc
            cat << 'EOF' >> /home/vagrant/.bashrc
  # Ejecutar verificación y mostrar ticket
  bash /tmp/verify-stg003.sh
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
  - Storage-Performance
  - NFS-Tuning
  - IO-Monitoring
Escenario: |-
  - Situación: En node02 se ha configurado un disco de 512 MB con XFS que se exporta vía NFS hacia node03. El equipo de desarrollo reporta que las operaciones de escritura en el directorio montado en node03 son extremadamente lentas, causando timeouts en la aplicación. Al revisar, se confirma que el share NFS está montado y accesible, pero está utilizando las opciones de montaje por defecto del sistema, lo que provoca una latencia inaceptable y un uso ineficiente de la red.
  - Tu misión:
    Conectarte a node03 y utilizar herramientas como nfsiostat, iostat o sar -d para cuantificar la latencia actual y el bajo rendimiento en el montaje NFS.
    Inspeccionar las opciones de montaje actuales del share NFS para identificar la falta de parámetros de optimización (ej. escrituras síncronas por defecto, tamaños de lectura/escritura pequeños, actualización de tiempos de acceso innecesaria).
    Reconfigurar el montaje en node03 aplicando opciones de alto rendimiento: async, noatime, rsize=32768 y wsize=32768.
    Asegurar que estas nuevas opciones de montaje queden correctamente persistidas en el /etc/fstab de node03.
    Volver a ejecutar las herramientas de monitoreo (nfsiostat) para validar que la latencia ha disminuido y el throughput ha mejorado significativamente.
    Regla de Oro: El servicio NFS en node02 ya está funcionando correctamente; NO debes modificar las exportaciones del servidor, ni reiniciar el daemon nfs-server, ni tocar el firewall. Todo el tuning y la resolución del problema deben realizarse exclusivamente desde el lado del cliente (node03) ajustando las opciones de montaje.
---
[[Laboratorios del LFCS]]

---
One of the most challenging situations I faced was a performance incident in a production environment involving an NFS storage system.

We had a critical application running on a client server that started experiencing slow writes and timeouts when accessing a shared NFS directory. This was impacting users and causing delays in the application workflow.

My first step was to perform a structured diagnosis. I checked the NFS mount configuration, system I/O metrics, and network performance. At first glance, everything looked normal: the server was healthy, the network was stable, and there were no disk errors.

However, when I generated controlled load tests and analyzed NFS statistics, I noticed increased latency and queue times on write operations. This suggested that the issue was not on the server side, but on the client-side mount configuration and how NFS was handling I/O buffering.

I reviewed the mount options and identified that the system was using default NFS parameters, which were not optimized for high-performance workloads. I updated the configuration with improved options such as larger read and write sizes and reduced metadata overhead, then remounted the filesystem safely without affecting production services.

After applying the changes, I re-tested the performance and confirmed a significant improvement in throughput and stability, with reduced latency and no further timeouts reported by the application team.

The main lesson I learned from this experience is the importance of not assuming that infrastructure issues are caused by hardware or network problems. In this case, the root cause was a subtle configuration issue at the client level, which required careful analysis and a methodical troubleshooting approach.

This experience helped me strengthen my troubleshooting methodology and improved my confidence working with Linux storage systems in production environments.