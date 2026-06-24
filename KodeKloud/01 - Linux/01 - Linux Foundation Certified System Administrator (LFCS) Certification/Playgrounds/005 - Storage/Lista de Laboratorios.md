---
PROMT STG-005: |-
  Perfecto, aquí tienes un **prompt maestro** autocontenido que captura todas las lecciones aprendidas de STG-004 y las especificaciones de STG-005. Puedes copiarlo y pegarlo en una nueva sesión:

  ---

  ```
  # ═══════════════════════════════════════════════════════════════════
  # PROMPT PARA GENERACIÓN DE VAGRANTFILE - STG-005
  # ═══════════════════════════════════════════════════════════════════

  ## CONTEXTO DEL PROYECTO
  Estoy construyendo escenarios de entrenamiento tipo "incidentes de operaciones" 
  usando Vagrant con libvirt. Cada escenario (STG-XXX) despliega un clúster de 3 
  nodos Ubuntu 22.04 donde un nodo actúa como "estación de administración" y los 
  otros como servidores/clientes con problemas inyectados que el alumno debe resolver.

  ## ARQUITECTURA BASE (NO MODIFICAR)
  - Box: generic/ubuntu2204
  - Provider: libvirt con KVM
  - Red: private_network con libvirt__network_name: "mgmt-net"
  - Recursos por nodo: 1024MB RAM, 1 CPU
  - Usuario alumno: bob (password: caleston123, sudo sin password)
  - IPs estáticas: node01=192.168.122.11, node02=192.168.122.12, node03=192.168.122.13

  ## LECCIONES APRENDIDAS DE STG-004 (CRÍTICO - APLICAR SIEMPRE)

  ### 1. PROBLEMA DE HEREDOCS ANIDADOS ❌
  NO usar `sudo bash << 'INNEREOF'` dentro de un provisioner que ya tiene 
  `privileged: true`. Esto causa que los comandos fallen silenciosamente.

  ✅ SOLUCIÓN: Ejecutar comandos directamente ya que el provisioner corre como root.

  ### 2. PROBLEMA DE PANTALLA BORRADA ❌
  NO usar `clear` ni `sleep` antes de mostrar resultados al usuario.

  ✅ SOLUCIÓN: Mostrar resultados, luego pausar con `read -r` para que el alumno 
  pueda capturar la salida.

  ### 3. PROBLEMA DE TAMAÑO DE DISCO ❌
  NO crear LVs del mismo tamaño exacto que el disco (512M disco → 512M LV falla).

  ✅ SOLUCIÓN: Dejar margen. Disco 512M → LV 400M.

  ### 4. PROBLEMA DE PAQUETES FALTANTES ❌
  NO asumir que herramientas como xfsprogs están instaladas.

  ✅ SOLUCIÓN: Instalar explícitamente todos los paquetes necesarios.

  ## ESTRUCTURA OBLIGATORIA DEL VAGRANTFILE

  ```ruby
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

        # ── PROVISIONADO GENERAL (todos los nodos) ──
        node_config.vm.provision "shell", inline: <<-SHELL
          # Configurar /etc/hosts, usuario bob, herramientas base
        SHELL

        # ── PROVISIONADO ESPECÍFICO POR NODO ──
        if node[:name] == "node02"
          # Configurar servidor con problemas inyectados
        end

        if node[:name] == "node03"
          # Configurar cliente con estado fallido
        end

        if node[:name] == "node01"
          # Generar TICKET + SCRIPT DE VERIFICACIÓN
        end
      end
    end
  end
  ```

  ## PLANTILLA OBLIGATORIA DEL SCRIPT DE VERIFICACIÓN

  ```bash
  #!/bin/bash
  # Colores
  RED='\e[1;31m'
  GREEN='\e[1;32m'
  YELLOW='\e[1;33m'
  CYAN='\e[1;36m'
  RESET='\e[0m'

  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  FAIL=0

  # Header
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          VERIFICACIÓN DE ESCENARIO STG-XXX                    ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"

  # Checks numerados [1/N], [2/N], etc.
  # Cada check usa sshpass para validar estado remoto

  # Footer CON PAUSA (NO usar clear)
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ TODAS LAS VERIFICACIONES PASARON - ESCENARIO LISTO${RESET}"
  else
    echo -e "${RED}⚠️  ALGUNAS VERIFICACIONES FALLARON${RESET}"
  fi

  echo -e "${YELLOW}Presiona ENTER para ver el ticket del incidente...${RESET}"
  read -r
  cat /home/vagrant/TICKET_STG-XXX.txt
  ```

  ## INYECCIÓN DE PROBLEMAS
  - Ejecutar comandos DIRECTAMENTE (sin heredocs anidados)
  - El provisioner ya corre como root (privileged: true)
  - Limpiar residuos antes de crear estado nuevo
  - Usar `|| true` para comandos que pueden fallar en limpieza

  ---

  ## ESCENARIO STG-005: LOS PERMISOS REBELDES

  ### METADATOS
  - **Dificultad:** 6/10 | **Nivel:** L2
  - **Temas LFCS/RHCSA:** Advanced Filesystem Permissions, ACLs
  - **Módulo:** Storage / Permissions

  ### ARQUITECTURA
  - **node01:** Estación de administración (bob)
  - **node02:** Servidor de archivos compartidos
    - Disco adicional: /dev/vdb (512MB) → montado en /srv/proyectos
    - Grupos: devs, ops, auditor
    - Usuarios: alice (devs), carlos (ops), diana (auditor)
  - **node03:** Bóveda de evidencia (/opt/ops-compliance/stg-005/)

  ### PROBLEMAS A INYECTAR EN NODE02

  **Problema #1: Permisos de directorio incorrectos**
  - /srv/proyectos debe tener SGID para herencia de grupo
  - Sticky bit para que solo el dueño borre archivos
  - Estado actual: permisos 755 normales (sin SGID, sin sticky)

  **Problema #2: ACLs faltantes o incorrectas**
  - Subdirectorio /srv/proyectos/auditoria requiere:
    * Grupo auditor con acceso r-x (solo lectura + ejecución para listar)
    * Default ACLs para herencia en archivos nuevos
  - Estado actual: sin ACLs configuradas

  **Problema #3: Propietarios/grupos incorrectos**
  - /srv/proyectos debe pertenecer a root:devs (grupo devs como grupo principal)
  - Estado actual: root:root

  ### ESTADO ESPERADO DESPUÉS DE RESOLVER
  ```bash
  # Permisos del directorio principal
  ls -ld /srv/proyectos
  # drwxrws--T root devs /srv/proyectos  (2775 + sticky = 3775)

  # ACLs del subdirectorio auditoria
  getfacl /srv/proyectos/auditoria
  # group:auditor:r-x
  # default:group:auditor:r-x

  # Usuarios en grupos correctos
  id alice  # uid=... gid=... groups=...,devs
  id carlos # uid=... gid=... groups=...,ops
  id diana  # uid=... gid=... groups=...,auditor
  ```

  ### TICKET DE INCIDENTE (resumen)
  El equipo de desarrollo y operaciones necesitan colaborar en /srv/proyectos.
  Requisitos de seguridad:
  1. Todos los archivos creados deben heredar el grupo devs (SGID)
  2. Solo el dueño del archivo puede borrarlo (Sticky bit)
  3. El equipo de auditoría (grupo auditor) debe tener acceso de solo lectura
     a /srv/proyectos/auditoria con herencia automática (default ACLs)

  Actualmente los permisos están mal configurados y los equipos no pueden trabajar.

  ### CRITERIOS DE ACEPTACIÓN (20% cada uno)
  - [ ] /srv/proyectos con SGID y Sticky bit (permisos 3775 o 2775+T)
  - [ ] Grupo propietario: devs (no root)
  - [ ] ACLs en /srv/proyectos/auditoria: group:auditor:r-x
  - [ ] Default ACLs configuradas para herencia
  - [ ] Usuarios en grupos correctos (alice→devs, carlos→ops, diana→auditor)
  - [ ] Evidencia enviada a node03:/opt/ops-compliance/stg-005/
  - [ ] CERO archivos de resultados en node01 (descalifica)

  ### PROCEDIMIENTO REQUERIDO (para el ticket)
  1. Crear grupos: devs, ops, auditor
  2. Crear usuarios: alice (devs), carlos (ops), diana (auditor)
  3. Formatear y montar /dev/vdb en /srv/proyectos (XFS con soporte ACL)
  4. Configurar permisos: chown root:devs, chmod 3775 /srv/proyectos
  5. Crear subdirectorio auditoria y configurar ACLs:
     - setfacl -m g:auditor:r-x /srv/proyectos/auditoria
     - setfacl -d -m g:auditor:r-x /srv/proyectos/auditoria
  6. Persistir en /etc/fstab con opciones acl
  7. Pipeline de evidencia a node03

  ---

  ## INSTRUCCIONES PARA LA IA

  1. Genera el Vagrantfile completo siguiendo la estructura obligatoria
  2. Aplica TODAS las lecciones aprendidas de STG-004
  3. Incluye los 3 problemas inyectados en node02
  4. Genera el ticket completo en node01
  5. Genera el script de verificación con 7-8 checks
  6. NO uses heredocs anidados (sudo bash << 'INNEREOF')
  7. NO uses clear en el script de verificación
  8. USA read -r para pausar antes de mostrar el ticket
  9. Asegúrate de instalar todos los paquetes necesarios (acl, xfsprogs, etc.)
  10. Deja margen en el tamaño del LV (disco 512M → LV 400M)
  ```

  ---

  Este prompt está diseñado para que la IA:
  - No repita los errores de STG-004
  - Siga una estructura probada
  - Tenga todas las especificaciones técnicas claras
  - Genere un script funcional a la primera
---

# 📘 Ruta de Práctica: Storage Avanzado LFCS/RHCSA (Multi-Nodo en KVM/Vagrant)

## 🏗️ Guía Maestra: Estructura Estándar y Flujo de Trabajo


---

## 🗺️ Ruta de Práctica: Escenarios Storage

#### **1. STG-001: El Disco Olvidado – Particionamiento, Filesystems y Montaje Persistente**
- **Dificultad:** 6/10 | **Nivel:** L2
- **Temas LFCS/RHCSA:** Partitions, File Systems, Mount at Boot, Swap.
- **Recursos:** 1 Disco virtual en `node02`: `/dev/vdb` (1 GB).
- **Objetivo:** Dominar el flujo básico de aprovisionamiento y corrección de `fstab`.
- **Escenario:** Tras un reinicio, `/dev/vdb1` no monta en `/mnt/app-data`. El `fstab` apunta a `ext3`, el estándar corporativo es `ext4`, y no hay swap. Debes particionar, formatear, montar con `noatime,nofail` y crear un `swapfile` de 128MB persistente.
- **Validación:** `lsblk -f`, `mount | grep app-data`, `swapon --show`, `sudo mount -a` (sin errores).

#### **2. STG-002: El Laberinto LVM – Volúmenes Lógicos que No Montan y VG Fragmentado**
- **Dificultad:** 7/10 | **Nivel:** L2/L3
- **Temas LFCS/RHCSA:** Manage and Configure LVM Storage, Resize Filesystems.
- **Recursos:** 2 Discos virtuales en `node02`: `/dev/vdb` (2 GB) y `/dev/vdc` (2 GB).
- **Objetivo:** Creación, extensión y reparación de volúmenes LVM.
- **Escenario:** `lv-apps` no monta tras una expansión fallida. El VG tiene PE libres, el LV está inconsistente y `fstab` usa un UUID obsoleto. Diagnóstico con `pvs/vgs/lvs`, extensión de LV, `resize2fs`/`xfs_growfs` y corrección de montaje.

#### **3. STG-003: La Montaña Rusa de I/O – Monitoreo de Performance y Cuellos de Botella**
- **Dificultad:** 7/10 | **Nivel:** L3
- **Temas LFCS/RHCSA:** Monitor Storage Performance, Filesystem Mount Options, NFS tuning.
- **Recursos:** 1 Disco en `node02`: `/dev/vdb` (512 MB, XFS, exportado vía NFS).
- **Objetivo:** Diagnosticar y mitigar problemas de rendimiento de almacenamiento.
- **Escenario:** Latencia extrema en `node03` al escribir en mount NFS. Uso de `iostat`, `iotop`, `sar -d`, `nfsiostat`. Ajuste de opciones `async,noatime,rsize=32768,wsize=32768` y validación de mejora.

#### **4. STG-004: El Puente Roto – NFS Server/Client y Exportaciones con Restricciones**
- **Dificultad:** 6/10 | **Nivel:** L2
- **Temas LFCS/RHCSA:** Use Remote Filesystems: NFS, Firewalld.
- **Recursos:** 1 Volumen LVM en `node02`: `/dev/vg_data/lv_shared` (512 MB).
- **Objetivo:** Configurar servicios de red de almacenamiento con control de acceso.
- **Escenario:** `node02` exporta `/srv/shared` a `node03`, pero el cliente recibe `Permission denied`. `root_squash` activo, firewall bloqueando puertos RPC, opciones de mount inseguras. Configuración de `exports` por subred, apertura de puertos y montaje seguro.

#### **5. STG-005: Los Permisos Rebeldes – ACLs, SGID y Sticky Bit en Directorios Compartidos**
- **Dificultad:** 6/10 | **Nivel:** L2
- **Temas LFCS/RHCSA:** Advanced Filesystem Permissions, ACLs.
- **Recursos:** 1 Disco en `node02`: `/dev/vdb` (512 MB, montado en `/srv/proyectos`).
- **Objetivo:** Dominar control de acceso granular en Linux.
- **Escenario:** Directorio `/srv/proyectos` debe permitir colaboración entre `devs` y `ops`, pero solo el dueño puede borrar archivos. Subdirectorio requiere acceso de solo lectura para `auditor`. Implementación de `SGID`, `Sticky Bit`, `setfacl` con `default ACLs` y validación de herencia.
---

---

#### **6. STG-006: El Volumen Fantasma – Recuperación de Filesystem Corrupto y LVM con PV Faltante**
- **Dificultad:** 8/10 | **Nivel:** L3 (Recuperación de Desastres)
- **Temas LFCS/RHCSA:** LVM Metadata Recovery, Filesystem Recovery (`fsck`/`xfs_repair`).
- **Recursos:** 3 Discos en `node02`: `/dev/vdb`, `/dev/vdc`, `/dev/vdd` (1 GB cada uno, en un VG).
- **Objetivo:** Recuperar datos tras caída abrupta o fallo de disco.
- **Escenario:** Caída simulada (desconexión de `/dev/vdc` desde Virt-Manager). LV `xfs` no monta, `pvs` muestra PV `missing`. Uso de `pvscan --cache`, `vgcfgrestore`, `xfs_repair`/`e2fsck` y montaje en modo recuperación.

#### **7. STG-007: El Almacén Elástico – Thin Provisioning con LVM y Snapshots para Backups**
- **Dificultad:** 8/10 | **Nivel:** L3 (Enfoque DevOps/SRE)
- **Temas LFCS/RHCSA:** LVM Thin Provisioning, Snapshots.
- **Recursos:** 1 Disco grande en `node02`: `/dev/vdb` (5 GB).
- **Objetivo:** Implementar almacenamiento eficiente y puntos de restauración rápidos.
- **Escenario:** Entorno de pruebas que debe clonarse rápidamente. Configuración de `Thin Pool`, volúmenes thin-provisioned, snapshots consistentes. Validación de montabilidad del snapshot y monitoreo de sobrecompromiso (<80%).

#### **8. STG-008: El Colapso del Storage – Incidente Compuesto (Examen Final)**
- **Dificultad:** 9.5/10 | **Nivel:** L3 (Simulacro de Examen)
- **Temas LFCS/RHCSA:** Integración de todos los temas anteriores.
- **Recursos:** Configuración acumulada de `node02` (LVM + Thin Pool + NFS + ACLs).
- **Objetivo:** Diagnóstico bajo presión y resolución integral.
- **Escenario:** CTF operativo. App en `node03` falla: alta latencia I/O, errores `Read-only file system` intermitentes, filesystem al 95%. Diagnóstico con `df/du/iostat/nfsiostat`, expansión en caliente de LV, corrección de ACLs, optimización de mount NFS y documentación en bóveda.

---
