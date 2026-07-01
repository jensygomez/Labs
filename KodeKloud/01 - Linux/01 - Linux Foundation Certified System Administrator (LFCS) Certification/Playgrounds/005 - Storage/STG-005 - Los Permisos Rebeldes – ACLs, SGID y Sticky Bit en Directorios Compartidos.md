---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Entorno: Vagrant (STG-005-MN)
Titulo: Los Permisos Rebeldes – ACLs, SGID y Sticky Bit en Directorios Compartidos - V1.0
Fecha de Inicio: 2026-06-30
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
  - Dominar control de acceso granular en Linux mediante permisos avanzados, ACLs y bits especiales.
Temas: |-
  - Advanced Filesystem Permissions (SGID, Sticky Bit)
  - Access Control Lists (ACLs) con setfacl/getfacl
  - Default ACLs y Herencia de Permisos
  - Group Collaboration en Directorios Compartidos
  - Validación de Permisos y Auditoría de Acceso
Competencias: |-
  - Configurar directorios de colaboración grupal con SGID para mantener la pertenencia de grupo en archivos creados.
  - Implementar Sticky Bit para proteger archivos compartidos contra eliminación no autorizada.
  - Diseñar y aplicar ACLs complejas con permisos diferenciados para múltiples usuarios y grupos.
  - Configurar Default ACLs para garantizar herencia consistente de permisos en subdirectorios y archivos nuevos.
  - Diagnosticar y resolver conflictos de permisos en entornos de colaboración multi-grupo.
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
          apt-get install -y -qq sshpass acl
        SHELL

        # ── NODE02: SERVIDOR CON DIRECTORIO COMPARTIDO ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "💾 Configurando node02 con directorio compartido..."
            
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq xfsprogs
            
            # Crear usuarios y grupos
            echo "Creando usuarios y grupos..."
            groupadd -f devs
            groupadd -f ops
            useradd -m -s /bin/bash -G devs alice 2>/dev/null || true
            useradd -m -s /bin/bash -G devs charlie 2>/dev/null || true
            useradd -m -s /bin/bash -G ops dave 2>/dev/null || true
            useradd -m -s /bin/bash auditor 2>/dev/null || true
            
            echo 'alice:caleston123' | chpasswd
            echo 'charlie:caleston123' | chpasswd
            echo 'dave:caleston123' | chpasswd
            echo 'auditor:caleston123' | chpasswd
            
            # Limpiar residuos
            umount /srv/proyectos 2>/dev/null || true
            rm -rf /srv/proyectos
            wipefs -a /dev/vdb 2>/dev/null || true
            
            # Formatear y montar directamente (sin LVM para simplificar)
            echo "Formateando con XFS..."
            mkfs.xfs -f /dev/vdb
            mkdir -p /srv/proyectos
            mount /dev/vdb /srv/proyectos
            echo "/dev/vdb /srv/proyectos xfs defaults 0 0" >> /etc/fstab
            
            # INYECCIÓN DE PROBLEMAS
            echo "Inyectando problemas de configuración..."
            
            cat << 'INNEREOF' | bash
  #!/bin/bash
  set -e

  # Problema 1: Directorio sin SGID (debería tenerlo para herencia de grupo)
  echo "Problema 1: Directorio sin SGID..."
  chown root:devs /srv/proyectos
  chmod 0770 /srv/proyectos  # Sin SGID (debería ser 2770)

  # Problema 2: Sin Sticky Bit (debería tenerlo para proteger archivos)
  # Ya está sin sticky bit con 0770 (debería ser 3770 con SGID+Sticky)

  # Problema 3: Crear subdirectorio de auditoría sin ACLs correctas
  mkdir -p /srv/proyectos/auditoria
  chown root:devs /srv/proyectos/auditoria
  chmod 0770 /srv/proyectos/auditoria

  # Problema 4: Sin Default ACLs (archivos nuevos no heredan permisos)
  # No configuramos default ACLs intencionalmente

  # Problema 5: ACLs mal configuradas para grupo ops
  # Damos permisos incorrectos (solo lectura cuando debería ser rwx)
  setfacl -m g:ops:r /srv/proyectos  # Incorrecto: solo lectura

  # Crear archivos de prueba con permisos incorrectos
  su - alice -c "touch /srv/proyectos/proyecto1.txt"
  su - charlie -c "touch /srv/proyectos/proyecto2.txt"

  echo "✅ Problemas inyectados correctamente"
  INNEREOF
            
            echo "✅ node02 configurado con 5 problemas inyectados"
          SHELL
        end

        # ── NODE03: BÓVEDA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/stg-005
            chown -R bob:bob /opt/ops-compliance/stg-005
            chmod 750 /opt/ops-compliance/stg-005
            echo "✅ Bóveda lista"
          SHELL
        end

        # ── NODE01: TICKET + VERIFICACIÓN ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket en node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_STG-005.txt
  ================================================================================
    TICKET STG-005  │  Severidad: MEDIA  │  Ambiente: PRODUCCIÓN
  ================================================================================
    🔐 STG-005-MN — Los Permisos Rebeldes (ACLs, SGID y Sticky Bit)
    Módulo: Storage  │  Dificultad: 6/10  │  Nivel: L2
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo Servidor:         node02  (Directorio compartido — /srv/proyectos)
    Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/stg-005/)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    El equipo de desarrollo trabaja en un directorio compartido /srv/proyectos
    en node02 donde los grupos devs y ops necesitan colaborar. Sin embargo,
    han surgido múltiples problemas de permisos que están afectando la
    productividad y seguridad:

    PROBLEMAS REPORTADOS:
    
    1. Los archivos creados por miembros del grupo devs NO heredan el grupo
       devs automáticamente. Cada usuario tiene que cambiar manualmente el
       grupo después de crear archivos, lo que rompe el flujo de trabajo.

    2. Usuarios del grupo ops pueden ELIMINAR archivos creados por otros
       usuarios, causando pérdida accidental de trabajo. Se requiere que
       solo el dueño de un archivo pueda eliminarlo.

    3. El grupo ops tiene permisos INSUFICIENTES en el directorio principal.
       Actualmente solo pueden leer, pero necesitan poder crear y modificar
       archivos para colaborar efectivamente.

    4. Los archivos nuevos creados en /srv/proyectos NO heredan los permisos
       correctos automáticamente. Cada archivo nuevo requiere configuración
       manual de ACLs, lo cual es propenso a errores.

    5. El departamento de auditoría (usuario auditor) necesita acceso de
       SOLO LECTURA al subdirectorio /srv/proyectos/auditoria para cumplir
       con requisitos de compliance, pero actualmente no tiene ningún acceso.

    ARQUITECTURA DE ALMACENAMIENTO
    --------------------------------------------------------------------------------
    node02:
      - /dev/vdb → Montado en /srv/proyectos (512MB, XFS)
      - Grupos: devs (alice, charlie), ops (dave)
      - Usuario especial: auditor
      - Subdirectorio crítico: /srv/proyectos/auditoria

    USUARIOS DE PRUEBA
    --------------------------------------------------------------------------------
    alice (grupo devs)    - Contraseña: caleston123
    charlie (grupo devs)  - Contraseña: caleston123
    dave (grupo ops)      - Contraseña: caleston123
    auditor               - Contraseña: caleston123

    PROCEDIMIENTO REQUERIDO
    --------------------------------------------------------------------------------
    1. Diagnóstico en node02:
       - Conéctate a node02 y verifica el estado actual de /srv/proyectos.
       - Revisa permisos con: ls -ld /srv/proyectos
       - Verifica ACLs con: getfacl /srv/proyectos
       - Identifica los problemas de SGID, Sticky Bit y ACLs.

    2. Configurar SGID en /srv/proyectos:
       - Aplica el bit SGID para que todos los archivos nuevos hereden
         automáticamente el grupo devs.
       - Comando: chmod g+s /srv/proyectos
       - Valida que el bit SGID esté activo (debe mostrar 's' en permisos de grupo).

    3. Implementar Sticky Bit en /srv/proyectos:
       - Aplica el Sticky Bit para que solo el dueño de un archivo pueda
         eliminarlo, protegiendo contra eliminación accidental.
       - Comando: chmod +t /srv/proyectos
       - Valida que el Sticky Bit esté activo (debe mostrar 't' en permisos de otros).

    4. Corregir ACLs para grupo ops:
       - El grupo ops necesita permisos completos (rwx) para colaborar.
       - Comando: setfacl -m g:ops:rwx /srv/proyectos
       - Valida con: getfacl /srv/proyectos

    5. Configurar Default ACLs para herencia automática:
       - Configura Default ACLs para que archivos y subdirectorios nuevos
         hereden automáticamente los permisos correctos.
       - Comandos:
         * setfacl -d -m g:devs:rwx /srv/proyectos
         * setfacl -d -m g:ops:rwx /srv/proyectos
         * setfacl -d -m o::--- /srv/proyectos
       - Valida que las Default ACLs estén configuradas.

    6. Configurar acceso para usuario auditor:
       - Crea el subdirectorio /srv/proyectos/auditoria si no existe.
       - Configura ACLs para otorgar acceso de solo lectura (r-x) al
         usuario auditor en este subdirectorio.
       - Comandos:
         * mkdir -p /srv/proyectos/auditoria
         * setfacl -m u:auditor:r-x /srv/proyectos/auditoria
         * setfacl -d -m u:auditor:r-x /srv/proyectos/auditoria
       - Valida con: getfacl /srv/proyectos/auditoria

    7. Validación y Pruebas:
       - Como alice: crea un archivo en /srv/proyectos y verifica que
         herede el grupo devs automáticamente.
       - Como dave: crea un archivo y verifica que puedas escribir.
       - Como charlie: intenta eliminar el archivo de dave (debe fallar).
       - Como auditor: verifica que puedas leer en /srv/proyectos/auditoria
         pero no escribir.

    8. Pipeline de Evidencia a node03:
       - Destino: /opt/ops-compliance/stg-005/permissions_evidence.txt
       - Desde node01, envía mediante un pipeline SSH la salida consolidada de:
         a) Permisos del directorio principal (ls -ld /srv/proyectos)
         b) ACLs completas del directorio principal (getfacl /srv/proyectos)
         c) ACLs del subdirectorio auditoria (getfacl /srv/proyectos/auditoria)
         d) Prueba de herencia: crear archivo como alice y verificar grupo
       - NO generar archivos temporales locales en node01.
    --------------------------------------------------------------------------------
    CRITERIOS DE ACEPTACIÓN
    --------------------------------------------------------------------------------
     [ ] SGID activo en /srv/proyectos (archivos heredan grupo devs)     --> 15%
     [ ] Sticky Bit activo (solo dueño puede eliminar archivos)          --> 15%
     [ ] ACLs correctas para grupo ops (rwx)                             --> 15%
     [ ] Default ACLs configuradas para herencia automática              --> 15%
     [ ] Acceso de auditor configurado (r-x en auditoria)                --> 15%
     [ ] Validación exitosa con usuarios de prueba                       --> 10%
     [ ] Evidencia enviada a node03:/opt/ops-compliance/stg-005/         --> 15%
     [ ] CERO archivos de resultados almacenados en node01 (DESCALIFICA)

    REGLA DE ORO: El disco /dev/vdb en node02 está correctamente formateado
    y montado en /srv/proyectos. NO reformatees el disco. Todo el trabajo
    debe enfocarse en configurar correctamente los permisos avanzados,
    ACLs y bits especiales.
  ================================================================================
  TICKET

            # ── SCRIPT DE VERIFICACIÓN ──
            cat << 'VERIFY' > /tmp/verify-stg005.sh
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
  echo -e "\${CYAN}║          VERIFICACIÓN DE ESCENARIO STG-005                    ║\${RESET}"
  echo -e "\${CYAN}╚════════════════════════════════════════════════════════════════╝\${RESET}"
  echo ""

  echo -e "\${YELLOW}[1/7] node02: Disco montado en /srv/proyectos\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "df -h /srv/proyectos | grep -q vdb"; then
    echo -e "      \${GREEN}✓ Disco montado correctamente\${RESET}"
  else
    echo -e "      \${RED}✗ Disco no montado\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[2/7] node02: Grupos devs y ops creados\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "getent group devs | grep -q devs && getent group ops | grep -q ops"; then
    echo -e "      \${GREEN}✓ Grupos existen\${RESET}"
  else
    echo -e "      \${RED}✗ Grupos no encontrados\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[3/7] node02: Usuarios alice, charlie, dave, auditor\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "id alice &>/dev/null && id charlie &>/dev/null && id dave &>/dev/null && id auditor &>/dev/null"; then
    echo -e "      \${GREEN}✓ Usuarios creados\${RESET}"
  else
    echo -e "      \${RED}✗ Usuarios no encontrados\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[4/7] node02: Directorio /srv/proyectos existe\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "[ -d /srv/proyectos ]"; then
    echo -e "      \${GREEN}✓ Directorio existe\${RESET}"
  else
    echo -e "      \${RED}✗ Directorio no existe\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[5/7] node02: Sin SGID (problema inyectado)\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "stat -c %a /srv/proyectos | grep -q '770'"; then
    echo -e "      \${GREEN}✓ SGID no configurado (esperado)\${RESET}"
  else
    echo -e "      \${RED}✗ Permisos inesperados\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[6/7] node02: ACLs incorrectas para grupo ops\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "getfacl /srv/proyectos 2>/dev/null | grep 'group:ops:r--' | grep -v default | grep -q r"; then
    echo -e "      \${GREEN}✓ ACLs incorrectas detectadas (esperado)\${RESET}"
  else
    echo -e "      \${RED}✗ ACLs no coinciden\${RESET}"
    FAIL=1
  fi

  echo -e "\${YELLOW}[7/7] node03: Bóveda de evidencia\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/stg-005 ]"; then
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
  cat /home/vagrant/TICKET_STG-005.txt
  VERIFY

            chmod +x /tmp/verify-stg005.sh
            
            sed -i '/verify-stg005/d' /home/vagrant/.bashrc
            cat << 'EOF' >> /home/vagrant/.bashrc
  bash /tmp/verify-stg005.sh
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
  - Advanced-Permissions
  - ACLs
  - SGID-StickyBit
  - Filesystem-Security
Escenario: |-
  - Situación= El equipo de desarrollo necesita un directorio compartido en `/srv/proyectos` donde los grupos `devs` y `ops` puedan colaborar creando archivos de proyecto. Sin embargo, hay múltiples problemas de configuración:
    1. El directorio `/srv/proyectos` no tiene SGID activo, causando que los archivos creados pertenezcan al grupo primario del usuario en lugar del grupo `devs`, rompiendo la colaboración.
    2. No hay Sticky Bit configurado, permitiendo que cualquier usuario con permisos de escritura pueda eliminar archivos de otros usuarios.
    3. El departamento de auditoría necesita acceso de solo lectura al subdirectorio `/srv/proyectos/auditoria`, pero actualmente no tiene ningún acceso configurado.
    4. Los archivos nuevos creados en `/srv/proyectos` no heredan los permisos correctos porque no hay Default ACLs configuradas.
    5. El usuario `auditor` necesita acceso explícito de solo lectura a todo el árbol de directorios, pero las ACLs actuales están mal configuradas.

  - Tu misión:
    1. Conectarte a node02 y verificar el estado actual de permisos en `/srv/proyectos`.
    2. Configurar SGID en `/srv/proyectos` para que todos los archivos nuevos pertenezcan al grupo `devs`.
    3. Implementar Sticky Bit en `/srv/proyectos` para proteger los archivos contra eliminación no autorizada.
    4. Configurar ACLs para otorgar permisos de lectura y ejecución al grupo `ops` en `/srv/proyectos`.
    5. Crear el subdirectorio `/srv/proyectos/auditoria` y configurar Default ACLs para que el usuario `auditor` tenga acceso de solo lectura (r-x) con herencia.
    6. Validar la configuración creando archivos de prueba y verificando que los permisos se hereden correctamente.
    7. Documentar la configuración final con getfacl para auditoría.
---
[[Laboratorios del LFCS]]

---
I finalized