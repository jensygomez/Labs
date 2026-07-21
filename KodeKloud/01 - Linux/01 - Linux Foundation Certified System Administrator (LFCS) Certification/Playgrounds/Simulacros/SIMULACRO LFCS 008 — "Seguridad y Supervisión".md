---
Titulo: SIMULACRO LFCS 005 — "Incidentes Variados"
Severidad: MEDIA
Ambiente: Produccion
Modulo: LFCS Complete
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-20
Script Vagrant: |-
  # -- mode: ruby --
  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    
    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['1G'] }, # solo un disco extra
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
          echo "🔧 Configurando #{node[:name]}..."
          
          for host in node01 node02 node03; do
            sed -i "/$host/d" /etc/hosts
          done
          
          cat << 'HOSTS' >> /etc/hosts
  192.168.122.11 node01
  192.168.122.12 node02
  192.168.122.13 node03
  HOSTS

          useradd -m -s /bin/bash bob 2>/dev/null || true
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass curl acl lvm2 ufw zip tree ntp
        SHELL
        
        # ── NODE02: SERVIDOR CON 12 INCIDENTES ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configurando node02 con 12 incidentes..."
            
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nginx vim tree
            
            # ── TAREA 1: Archivos grandes para find ──
            mkdir -p /var/tmp/bigfiles
            dd if=/dev/zero of=/var/tmp/bigfiles/file1.dat bs=1M count=15 2>/dev/null
            dd if=/dev/zero of=/var/tmp/bigfiles/file2.dat bs=1M count=8 2>/dev/null
            dd if=/dev/zero of=/var/tmp/bigfiles/file3.dat bs=1M count=20 2>/dev/null
            dd if=/dev/zero of=/var/tmp/bigfiles/file4.dat bs=1M count=5 2>/dev/null
            
            # ── TAREA 2: Grupo admins para usuario ──
            groupadd -f admins
            
            # ── TAREA 3: Disco /dev/vdb sin formatear ──
            
            # ── TAREA 4: Log para logrotate ──
            mkdir -p /var/log/webapp
            cat << 'LOG' > /var/log/webapp/access.log
  192.168.1.10 GET /index.html 200 1024
  192.168.1.11 POST /api/login 401 512
  192.168.1.12 GET /dashboard 200 2048
  LOG
            
            # ── TAREA 5: SUID en ping (ya tiene, pero se puede cambiar) ──
            # Dejamos el binario sin cambios para que el alumno lo modifique
            
            # ── TAREA 6: Script para systemd ──
            mkdir -p /opt/scripts
            cat << 'SCRIPT' > /opt/scripts/health-check.sh
  #!/bin/bash
  echo "Health check OK - $(date)" >> /var/log/health-status.log
  SCRIPT
            chmod +x /opt/scripts/health-check.sh
            
            # ── TAREA 7: Procesos de bob para ps (bob ya existe) ──
            # (No se crean adicionales, bob ya tiene procesos bash)
            
            # ── TAREA 8: ufw deshabilitado por defecto ──
            ufw disable 2>/dev/null || true
            
            # ── TAREA 9: ss mostrará conexiones existentes ──
            
            # ── TAREA 10: Archivos para zip ──
            mkdir -p /opt/app-configs
            echo "db_host=10.0.0.5" > /opt/app-configs/database.conf
            echo "cache_ttl=3600" > /opt/app-configs/cache.conf
            echo "log_level=info" > /opt/app-configs/logging.conf
            
            # ── TAREA 11: NTP ya instalado (configuración por defecto) ──
            
            # ── TAREA 12: Directorio para SGID ──
            mkdir -p /opt/shared
            chown root:admins /opt/shared
            chmod 775 /opt/shared
            
            # nginx activo (para tener algo corriendo)
            systemctl enable nginx
            systemctl start nginx
            
            echo "✅ node02 configurado con 12 incidentes"
          SHELL
        end
        
        # ── NODE03: BÓVEDA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda..."
            mkdir -p /opt/ops-compliance/simulacro-008
            chown -R bob:bob /opt/ops-compliance
            chmod -R 755 /opt/ops-compliance
            echo "✅ Bóveda lista en /opt/ops-compliance/simulacro-008/"
          SHELL
        end
        
        # ── NODE01: TICKET + VERIFICACIÓN + VALIDADOR + EVIDENCIA ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket, verificación, validador y script de evidencia en node01..."
            
            # ═══════════════════════════════════════════════════════
            # TICKET
            # ═══════════════════════════════════════════════════════
            cat << 'TICKET' > /home/vagrant/TICKET_SIMULACRO-008.txt
  ================================================================================
  TICKET SIMULACRO-008  │  Severidad: MEDIA  │  Ambiente: PRODUCCIÓN
  🔐 SIMULACRO-008 — Seguridad y Supervisión (12 Tareas)
  Módulo: LFCS Complete  │  Dificultad: 3/10  │  Nivel: L2
  Ubicación de Control:  node01  (Estación del Administrador — bob)
  Nodo Servidor:         node02  (Ubuntu 22.04)
  Nodo Bóveda Destino:   node03  (/opt/ops-compliance/simulacro-008/)
  Contraseña del Clúster: caleston123

  Un servidor en node02 requiere 12 tareas de administración, enfocadas en seguridad,
  monitorización y operaciones del sistema. Cada tarea aborda un dominio diferente.
  Gestiona tu tiempo: máximo 8-10 minutos por tarea. Si te trabas, pasa a la siguiente.

  ================================================================================
  TAREA 1 — Essential Commands: Buscar y Comprimir (peso 3 puntos)
  ================================================================================
  El equipo de desarrollo quiere liberar espacio comprimiendo archivos grandes.

  En node02:
  1. Busca en /var/tmp/bigfiles todos los archivos de más de 10M
  2. Comprime cada uno con gzip (deben quedar archivos .gz)
  3. No borres los originales (gzip los reemplaza por defecto)

  CRITERIOS:
    [ ] Los archivos >10M fueron comprimidos (existen .gz)                    --> 40%
    [ ] Los archivos <=10M permanecen sin comprimir                          --> 30%
    [ ] El total de archivos es 4, los grandes son 3 (file1, file3, file4?)  --> 30%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 2 — Users/Groups: Usuario con UID Específico (peso 3 puntos)
  ================================================================================
  Se necesita un usuario con UID fijo para integración con un sistema externo.

  En node02:
  1. Crea un usuario llamado "appuser" con UID=1500
  2. Shell: /bin/bash
  3. Grupo primario: appuser (creado automáticamente)
  4. Grupo secundario: admins
  5. Contraseña: caleston123

  CRITERIOS:
    [ ] Usuario appuser existe con UID=1500                                   --> 40%
    [ ] Grupo primario es appuser (mismo nombre)                             --> 30%
    [ ] Pertenece al grupo secundario admins                                  --> 30%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 3 — Storage: Formatear y Montar XFS (peso 3 puntos)
  ================================================================================
  Se requiere un sistema de archivos XFS para datos de aplicación.

  En node02:
  1. El disco /dev/vdb está disponible (sin formatear)
  2. Formatea /dev/vdb como XFS (mkfs.xfs)
  3. Crea el directorio /mnt/data
  4. Monta /dev/vdb en /mnt/data (montaje temporal, no necesita fstab)

  CRITERIOS:
    [ ] /dev/vdb está formateado como XFS (blkid)                            --> 40%
    [ ] /mnt/data existe                                                      --> 20%
    [ ] /dev/vdb está montado en /mnt/data                                    --> 40%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 4 — Operations/logrotate: Rotación de Logs (peso 3 puntos)
  ================================================================================
  El archivo /var/log/webapp/access.log crece mucho y necesita rotación diaria.

  En node02:
  1. Crea un archivo de configuración en /etc/logrotate.d/webapp
  2. Debe rotar el log diariamente (daily)
  3. Mantén 7 rotaciones (rotate 7)
  4. Comprime los logs rotados (compress)
  5. No uses create (opcional, pero no necesario)

  CRITERIOS:
    [ ] Archivo /etc/logrotate.d/webapp existe                                --> 30%
    [ ] Contiene "daily", "rotate 7" y "compress"                            --> 50%
    [ ] La ruta /var/log/webapp/access.log está especificada                  --> 20%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 5 — Security/SUID: Establecer SUID en Binario (peso 3 puntos)
  ================================================================================
  Por seguridad, se requiere que el comando ping pueda ejecutarse con privilegios.

  En node02:
  1. Verifica que /usr/bin/ping tenga permisos SUID (chmod u+s)
  2. Si no lo tiene, actívalo
  3. Comprueba que el bit SUID está establecido (ls -l)

  CRITERIOS:
    [ ] /usr/bin/ping tiene el bit SUID (s en permisos del propietario)      --> 100%

  TIEMPO MÁXIMO: 5 minutos

  ================================================================================
  TAREA 6 — Systemd: Crear un Servicio (peso 3 puntos)
  ================================================================================
  Se necesita un servicio que ejecute un script de salud cada 5 minutos.

  En node02:
  1. El script /opt/scripts/health-check.sh ya existe y es ejecutable
  2. Crea un archivo de unidad systemd en /etc/systemd/system/health-check.service
  3. Debe ejecutar el script como servicio simple (Type=simple)
  4. Activa el servicio (systemctl enable --now)
  5. Verifica que esté activo (systemctl status)

  CRITERIOS:
    [ ] Archivo de unidad existe en la ruta correcta                         --> 30%
    [ ] Contiene las directivas básicas (ExecStart, Type, etc.)              --> 30%
    [ ] El servicio está habilitado y activo                                  --> 40%

  TIEMPO MÁXIMO: 12 minutos

  ================================================================================
  TAREA 7 — Monitoring/ps: Contar Procesos de Usuario (peso 3 puntos)
  ================================================================================
  Se requiere saber cuántos procesos del usuario "bob" están corriendo.

  En node02:
  1. Usa ps y grep para contar los procesos de bob (sin contar el propio grep)
  2. Guarda el número en /opt/bob-process-count.txt

  CRITERIOS:
    [ ] /opt/bob-process-count.txt existe                                     --> 30%
    [ ] Contiene solo un número entero                                        --> 30%
    [ ] El número es correcto (al menos 1)                                    --> 40%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 8 — Networking/ufw: Firewall para SSH (peso 3 puntos)
  ================================================================================
  Se debe restringir el acceso SSH solo desde la máquina anfitriona (IP 192.168.122.1).

  En node02:
  1. Habilita ufw si está deshabilitado
  2. Configura una regla para permitir SSH solo desde 192.168.122.1
  3. Deniega SSH desde cualquier otra IP
  4. Aplica la regla (ufw enable)

  CRITERIOS:
    [ ] ufw está activo (ufw status)                                          --> 20%
    [ ] Existe regla permitiendo SSH desde 192.168.122.1                      --> 40%
    [ ] No hay regla permitiendo SSH desde cualquier IP (o está denegada)    --> 40%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 9 — Networking/ss: Mostrar Conexiones TCP Establecidas (peso 3 puntos)
  ================================================================================
  El equipo de redes necesita ver las conexiones TCP activas.

  En node02:
  1. Usa ss para listar todas las conexiones TCP en estado ESTABLISHED
  2. Guarda la salida en /opt/tcp-established.txt

  CRITERIOS:
    [ ] /opt/tcp-established.txt existe                                       --> 30%
    [ ] Contiene líneas con conexiones ESTAB                                  --> 40%
    [ ] Se usó el comando ss (no netstat)                                     --> 30%

  TIEMPO MÁXIMO: 8 minutos

  ================================================================================
  TAREA 10 — Packaging/zip: Comprimir Configuraciones (peso 3 puntos)
  ================================================================================
  Se necesita un backup en formato zip de las configuraciones de aplicación.

  En node02:
  1. El directorio /opt/app-configs/ contiene archivos .conf
  2. Crea /opt/configs.zip con todo el contenido de /opt/app-configs/
  3. Verifica que el archivo es válido (unzip -t)

  CRITERIOS:
    [ ] /opt/configs.zip existe                                                --> 40%
    [ ] Es un zip válido (unzip -t)                                            --> 30%
    [ ] Contiene los archivos .conf (database.conf, cache.conf, logging.conf)  --> 30%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 11 — Time/NTP: Sincronizar Hora (peso 3 puntos)
  ================================================================================
  El servidor debe tener la hora sincronizada con servidores NTP.

  En node02:
  1. Asegura que el servicio NTP está instalado (ya lo está)
  2. Verifica que esté activo (systemctl status ntp o systemd-timesyncd)
  3. Si no está activo, actívalo y verifica sincronización
  4. Guarda la salida de `timedatectl show` en /opt/time-status.txt

  CRITERIOS:
    [ ] Servicio NTP activo (o systemd-timesyncd)                             --> 40%
    [ ] timedatectl muestra "synchronized: yes"                               --> 30%
    [ ] /opt/time-status.txt contiene la salida de timedatectl               --> 30%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 12 — Permissions/SGID: Herencia de Grupo (peso 3 puntos)
  ================================================================================
  Se requiere que todos los archivos creados en /opt/shared hereden el grupo "admins".

  En node02:
  1. El directorio /opt/shared ya existe (propiedad root:admins, permisos 775)
  2. Establece el bit SGID en el directorio (chmod g+s)
  3. Crea un archivo de prueba dentro para verificar que hereda el grupo

  CRITERIOS:
    [ ] /opt/shared tiene el bit SGID (s en grupo)                            --> 40%
    [ ] Los nuevos archivos creados dentro pertenecen al grupo admins         --> 40%
    [ ] getfacl o ls -ld muestra el bit SGID                                  --> 20%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  PIPELINE DE EVIDENCIA A NODE03 (OPCIONAL — NO PUNTÚA)
  ================================================================================
  Si deseas automatizar la entrega de evidencias, ejecuta en node01:
    bash /home/vagrant/generate-evidence.sh

  Esto recolectará las salidas de las 12 tareas y las copiará a:
    node03:/opt/ops-compliance/simulacro-008/evidence.txt

  No es obligatorio, pero ayuda a completar el flujo de trabajo.

  ================================================================================
  RESUMEN DE PUNTUACIÓN
  ================================================================================
  Tarea 1:  3 pts (Essential - find/gzip)
  Tarea 2:  3 pts (Users/Groups - UID específico)
  Tarea 3:  3 pts (Storage - XFS)
  Tarea 4:  3 pts (Operations - logrotate)
  Tarea 5:  3 pts (Security - SUID)
  Tarea 6:  3 pts (Systemd - Servicio)
  Tarea 7:  3 pts (Monitoring - ps)
  Tarea 8:  3 pts (Networking - ufw)
  Tarea 9:  3 pts (Networking - ss)
  Tarea 10: 3 pts (Packaging - zip)
  Tarea 11: 3 pts (Time - NTP)
  Tarea 12: 3 pts (Permissions - SGID)
  TOTAL: 36 puntos
  MÍNIMO PARA APROBAR (67%): 25 puntos

  TIEMPO TOTAL MÁXIMO: 120 minutos

  Cuando termines, ejecuta: bash /home/vagrant/validate.sh
  ================================================================================
  TICKET

            # ═══════════════════════════════════════════════════════
            # SCRIPT DE VERIFICACIÓN INICIAL
            # ═══════════════════════════════════════════════════════
            cat << 'VERIFY' > /tmp/verify-008.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; RESET='\e[0m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"; PASS="caleston123"; FAIL=0

  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          VERIFICACIÓN DE ESCENARIO SIMULACRO-008              ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${YELLOW}[1/8] node02: Archivos grandes en /var/tmp/bigfiles${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls /var/tmp/bigfiles/file*.dat 2>/dev/null | wc -l | grep -q 4" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[2/8] node02: Grupo admins existe${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "getent group admins >/dev/null" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[3/8] node02: Disco /dev/vdb sin formatear${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo blkid /dev/vdb 2>/dev/null | grep -q ." 2>/dev/null; then
    echo -e "      ${RED}✗ Disco ya formateado${RESET}"; FAIL=1
  else
    echo -e "      ${GREEN}✓ OK (crudo)${RESET}"
  fi

  echo -e "${YELLOW}[4/8] node02: Log /var/log/webapp/access.log existe${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -f /var/log/webapp/access.log ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[5/8] node02: Script health-check.sh existe${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -x /opt/scripts/health-check.sh ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[6/8] node02: Directorio /opt/app-configs con archivos.conf${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls /opt/app-configs/*.conf 2>/dev/null | wc -l | grep -q 3" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[7/8] node02: Directorio /opt/shared existe${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -d /opt/shared ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[8/8] node03: Bóveda existe${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/simulacro-008 ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo ""
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ ESCENARIO LISTO — Presiona ENTER para ver el ticket${RESET}"
  else
    echo -e "${RED}⚠️  ALGUNAS VERIFICACIONES FALLARON${RESET}"
  fi
  echo ""
  read -r
  cat /home/vagrant/TICKET_SIMULACRO-008.txt
  VERIFY
            chmod +x /tmp/verify-008.sh
            sed -i '/verify-008/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-008.sh' >> /home/vagrant/.bashrc

            # ═══════════════════════════════════════════════════════
            # VALIDADOR FINAL (validate.sh)
            # ═══════════════════════════════════════════════════════
            cat << 'VALIDATOR' > /home/vagrant/validate.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; MAGENTA='\e[1;35m'; RESET='\e[0m'; BOLD='\e[1m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  TOTAL=0; MAX=36; PASS_COUNT=0; FAIL_COUNT=0

  run02() { sshpass -p $PASS ssh $SSH_OPTS bob@node02 "$1" 2>/dev/null; }

  check() {
    local n=$1; local name=$2; local pts=$3; local cmd=$4; local desc=$5
    echo -e "\n${CYAN}┌─ TAREA $n: $name ($pts pts) ─${RESET}"
    echo -e "${YELLOW}   $desc${RESET}"
    if run02 "$cmd" >/dev/null 2>&1; then
      echo -e "   ${GREEN}✅ +$pts pts${RESET}"
      TOTAL=$((TOTAL + pts)); PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo -e "   ${RED}❌ +0 pts${RESET}"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  }

  echo -e "${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║     🎯 VALIDADOR LFCS — SIMULACRO #008                      ║"
  echo "║        Seguridad y Supervisión (12 tareas)                  ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${BOLD}Validando en node02...${RESET}\n"

  # T1: find + gzip
  check 1 "find/gzip grandes" 3 \
    "[ -f /var/tmp/bigfiles/file1.dat.gz ] && [ -f /var/tmp/bigfiles/file3.dat.gz ] && [ -f /var/tmp/bigfiles/file2.dat ] && [ -f /var/tmp/bigfiles/file4.dat ] && [ ! -f /var/tmp/bigfiles/file1.dat ] && [ ! -f /var/tmp/bigfiles/file3.dat ]" \
    "Archivos >10M comprimidos (.gz), <=10M no comprimidos (file2 y file4)"

  # T2: User appuser UID 1500 + grupo admins
  check 2 "User appuser" 3 \
    "id -u appuser 2>/dev/null | grep -q 1500 && id -g appuser 2>/dev/null | grep -q appuser && id -Gn appuser 2>/dev/null | grep -q admins" \
    "Usuario appuser UID=1500, grupo primario appuser, secundario admins"

  # T3: XFS y montaje
  echo -e "\n${CYAN}┌─ TAREA 3: XFS y montaje (3 pts) ─${RESET}"
  xfs=$(run02 "sudo blkid /dev/vdb 2>/dev/null | grep -q 'TYPE=\"xfs\"' && echo ok")
  mnt=$(run02 "mount | grep -q '/dev/vdb on /mnt/data' && echo ok")
  if [ "$xfs" = "ok" ] && [ "$mnt" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$xfs" != "ok" ] && echo -e "   ${RED}  ✗ No es XFS${RESET}"
    [ "$mnt" != "ok" ] && echo -e "   ${RED}  ✗ No montado en /mnt/data${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T4: logrotate
  check 4 "logrotate" 3 \
    "[ -f /etc/logrotate.d/webapp ] && grep -q 'daily' /etc/logrotate.d/webapp && grep -q 'rotate 7' /etc/logrotate.d/webapp && grep -q 'compress' /etc/logrotate.d/webapp" \
    "Archivo /etc/logrotate.d/webapp con daily, rotate 7, compress"

  # T5: SUID en ping
  check 5 "SUID ping" 3 \
    "[ -u /usr/bin/ping ]" \
    "Bit SUID activo en /usr/bin/ping"

  # T6: Systemd service
  echo -e "\n${CYAN}┌─ TAREA 6: Systemd service (3 pts) ─${RESET}"
  srv=$(run02 "[ -f /etc/systemd/system/health-check.service ] && echo ok")
  act=$(run02 "systemctl is-active --quiet health-check.service && echo ok")
  if [ "$srv" = "ok" ] && [ "$act" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$srv" != "ok" ] && echo -e "   ${RED}  ✗ Archivo de unidad no existe${RESET}"
    [ "$act" != "ok" ] && echo -e "   ${RED}  ✗ Servicio no activo${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T7: ps count bob
  check 7 "ps count bob" 3 \
    "[ -f /opt/bob-process-count.txt ] && [ \$(cat /opt/bob-process-count.txt | tr -d '[:space:]' | grep -E '^[0-9]+$') ] && [ \$(cat /opt/bob-process-count.txt | tr -d '[:space:]') -ge 1 ]" \
    "/opt/bob-process-count.txt con número >= 1 (solo dígitos)"

  # T8: ufw SSH rule
  echo -e "\n${CYAN}┌─ TAREA 8: ufw SSH desde IP específica (3 pts) ─${RESET}"
  ufw_active=$(run02 "sudo ufw status 2>/dev/null | grep -q 'Status: active' && echo ok")
  rule_allow=$(run02 "sudo ufw status 2>/dev/null | grep -q '22.*ALLOW.*192.168.122.1' && echo ok")
  rule_deny=$(run02 "sudo ufw status 2>/dev/null | grep -q '22.*DENY' || echo ok") # si no hay deny explícito, pero se permite solo desde esa IP
  # Combinamos: si está activo y tiene la regla allow desde esa IP, y no hay allow from any (o está denegado)
  if [ "$ufw_active" = "ok" ] && [ "$rule_allow" = "ok" ]; then
    # verificamos que no haya allow from any
    allow_any=$(run02 "sudo ufw status 2>/dev/null | grep -E '22.*ALLOW.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v '192.168.122.1' | wc -l")
    if [ "$allow_any" -eq 0 ]; then
      echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
    else
      echo -e "   ${RED}❌ +0 pts (hay otras reglas permitiendo SSH)${RESET}"; FAIL_COUNT=$((FAIL_COUNT+1))
    fi
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$ufw_active" != "ok" ] && echo -e "   ${RED}  ✗ ufw no activo${RESET}"
    [ "$rule_allow" != "ok" ] && echo -e "   ${RED}  ✗ No existe regla allow desde 192.168.122.1${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T9: ss established
  check 9 "ss established" 3 \
    "[ -f /opt/tcp-established.txt ] && grep -q 'ESTAB' /opt/tcp-established.txt" \
    "Archivo /opt/tcp-established.txt con conexiones ESTAB"

  # T10: zip
  echo -e "\n${CYAN}┌─ TAREA 10: zip (3 pts) ─${RESET}"
  z1=$(run02 "[ -f /opt/configs.zip ] && echo ok")
  z2=$(run02 "unzip -t /opt/configs.zip 2>/dev/null | grep -q 'No errors' && echo ok")
  z3=$(run02 "unzip -l /opt/configs.zip 2>/dev/null | grep -q database.conf && unzip -l /opt/configs.zip 2>/dev/null | grep -q cache.conf && unzip -l /opt/configs.zip 2>/dev/null | grep -q logging.conf && echo ok")
  if [ "$z1" = "ok" ] && [ "$z2" = "ok" ] && [ "$z3" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$z1" != "ok" ] && echo -e "   ${RED}  ✗ Archivo no existe${RESET}"
    [ "$z2" != "ok" ] && echo -e "   ${RED}  ✗ No es zip válido${RESET}"
    [ "$z3" != "ok" ] && echo -e "   ${RED}  ✗ Faltan archivos .conf${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T11: NTP / timedatectl
  echo -e "\n${CYAN}┌─ TAREA 11: NTP (3 pts) ─${RESET}"
  ntp_active=$(run02 "systemctl is-active --quiet ntp 2>/dev/null && echo ok || systemctl is-active --quiet systemd-timesyncd 2>/dev/null && echo ok")
  sync=$(run02 "timedatectl 2>/dev/null | grep -q 'synchronized: yes' && echo ok")
  file=$(run02 "[ -f /opt/time-status.txt ] && echo ok")
  if { [ "$ntp_active" = "ok" ] || [ "$sync" = "ok" ]; } && [ "$file" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$ntp_active" != "ok" ] && echo -e "   ${RED}  ✗ Servicio NTP no activo${RESET}"
    [ "$sync" != "ok" ] && echo -e "   ${RED}  ✗ No sincronizado${RESET}"
    [ "$file" != "ok" ] && echo -e "   ${RED}  ✗ /opt/time-status.txt no existe${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T12: SGID en /opt/shared
  echo -e "\n${CYAN}┌─ TAREA 12: SGID (3 pts) ─${RESET}"
  sgid=$(run02 "ls -ld /opt/shared 2>/dev/null | grep -q '^d...s' && echo ok")
  # creamos archivo de prueba y vemos grupo
  run02 "touch /opt/shared/testfile 2>/dev/null" >/dev/null
  group=$(run02 "ls -l /opt/shared/testfile 2>/dev/null | awk '{print \$4}' | grep -q 'admins' && echo ok")
  if [ "$sgid" = "ok" ] && [ "$group" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$sgid" != "ok" ] && echo -e "   ${RED}  ✗ No tiene SGID${RESET}"
    [ "$group" != "ok" ] && echo -e "   ${RED}  ✗ El archivo de prueba no hereda grupo admins${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # ═══════════════════════════════════════════════════════════════
  # RESULTADO FINAL
  # ═══════════════════════════════════════════════════════════════
  PERCENT=$((TOTAL * 100 / MAX))

  echo -e "\n${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                    📊 RESULTADO FINAL                        ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${BOLD}Tareas aprobadas:${RESET}  ${GREEN}$PASS_COUNT / 12${RESET}"
  echo -e "${BOLD}Tareas fallidas:${RESET}   ${RED}$FAIL_COUNT / 12${RESET}"
  echo -e "${BOLD}Puntuación:${RESET}       ${CYAN}$TOTAL / $MAX puntos${RESET}"
  echo -e "${BOLD}Porcentaje:${RESET}       ${CYAN}$PERCENT%${RESET}"
  echo -e "${BOLD}Mínimo (67%):${RESET}     ${CYAN}25 puntos${RESET}"
  echo ""

  if [ $PERCENT -ge 67 ]; then
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           🎉 ¡APROBADO! ¡FELICIDADES, BOB! 🎉               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
  else
    echo -e "${RED}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               ❌ NO APROBADO — ¡Sigue así! 💪               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
  fi
  echo ""
  VALIDATOR
            chmod +x /home/vagrant/validate.sh
            
            # ═══════════════════════════════════════════════════════
            # SCRIPT DE EVIDENCIA OPCIONAL
            # ═══════════════════════════════════════════════════════
            cat << 'EVIDENCE' > /home/vagrant/generate-evidence.sh
  #!/bin/bash
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  DEST="node03:/opt/ops-compliance/simulacro-008/evidence.txt"

  echo "🔍 Recopilando evidencias de node02..."
  {
    echo "=== EVIDENCIAS SIMULACRO-008 ==="
    echo "Fecha: $(date)"
    echo ""
    echo "--- Tarea 1: ls -l /var/tmp/bigfiles ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -l /var/tmp/bigfiles 2>/dev/null || echo 'No existe'"
    echo ""
    echo "--- Tarea 2: id appuser ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "id appuser 2>/dev/null || echo 'No existe'"
    echo ""
    echo "--- Tarea 3: sudo blkid /dev/vdb; mount | grep vdb ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo blkid /dev/vdb 2>/dev/null; mount | grep vdb 2>/dev/null || echo 'No montado'"
    echo ""
    echo "--- Tarea 4: cat /etc/logrotate.d/webapp ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /etc/logrotate.d/webapp 2>/dev/null || echo 'No existe'"
    echo ""
    echo "--- Tarea 5: ls -l /usr/bin/ping ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -l /usr/bin/ping 2>/dev/null || echo 'No existe'"
    echo ""
    echo "--- Tarea 6: systemctl status health-check.service ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "systemctl status health-check.service 2>/dev/null || echo 'No existe'"
    echo ""
    echo "--- Tarea 7: cat /opt/bob-process-count.txt ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /opt/bob-process-count.txt 2>/dev/null || echo 'No existe'"
    echo ""
    echo "--- Tarea 8: sudo ufw status ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo ufw status 2>/dev/null || echo 'ufw no disponible'"
    echo ""
    echo "--- Tarea 9: head /opt/tcp-established.txt ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "head /opt/tcp-established.txt 2>/dev/null || echo 'No existe'"
    echo ""
    echo "--- Tarea 10: unzip -l /opt/configs.zip ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "unzip -l /opt/configs.zip 2>/dev/null || echo 'No existe o inválido'"
    echo ""
    echo "--- Tarea 11: cat /opt/time-status.txt; timedatectl ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /opt/time-status.txt 2>/dev/null; timedatectl 2>/dev/null"
    echo ""
    echo "--- Tarea 12: ls -ld /opt/shared; ls -l /opt/shared/testfile ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -ld /opt/shared 2>/dev/null; ls -l /opt/shared/testfile 2>/dev/null || echo 'No testfile'"
    echo ""
    echo "=== FIN DE EVIDENCIAS ==="
  } | sshpass -p $PASS ssh $SSH_OPTS bob@node03 "cat > /opt/ops-compliance/simulacro-008/evidence.txt"

  if [ $? -eq 0 ]; then
    echo "✅ Evidencia guardada en $DEST"
  else
    echo "❌ Fallo al guardar la evidencia"
  fi
  EVIDENCE
            chmod +x /home/vagrant/generate-evidence.sh
            
            echo "✅ Ticket + Verificación + Validador + Script de evidencia creados."
            echo "🚀 vagrant ssh node01 → verificación automática"
            echo "📝 Al terminar: bash /home/vagrant/validate.sh"
            echo "📦 (Opcional) Envía evidencias: bash /home/vagrant/generate-evidence.sh"
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---

