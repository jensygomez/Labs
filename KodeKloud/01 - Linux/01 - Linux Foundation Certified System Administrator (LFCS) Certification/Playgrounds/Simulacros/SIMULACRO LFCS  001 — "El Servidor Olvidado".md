---
Script Vagrant: |-
  # -- mode: ruby --
  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    
    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['1G'] },
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
          
          # Limpiar /etc/hosts
          for host in node01 node02 node03; do
            sed -i "/$host/d" /etc/hosts
          done
          
          cat << 'HOSTS' >> /etc/hosts
  192.168.122.11 node01
  192.168.122.12 node02
  192.168.122.13 node03
  HOSTS

          # Crear usuario bob
          useradd -m -s /bin/bash bob 2>/dev/null || true
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          # Instalar herramientas básicas
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass
        SHELL
        
        # ── NODE02: SERVIDOR CON PROBLEMAS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configurando node02 como servidor de aplicaciones..."
            
            # Instalar servicios básicos
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nginx cron
            
            # Crear grupo developers
            groupadd -f developers
            
            # Crear usuarios
            useradd -m -s /bin/bash -G developers alice 2>/dev/null || true
            useradd -m -s /bin/bash -G developers charlie 2>/dev/null || true
            echo 'alice:caleston123' | chpasswd
            echo 'charlie:caleston123' | chpasswd
            
            # Crear directorio de logs de aplicación
            mkdir -p /var/log/myapp
            chown root:root /var/log/myapp
            chmod 755 /var/log/myapp
            
            # Crear archivos de log con errores
            cat << 'LOG1' > /var/log/myapp/app.log
  2026-07-01 10:15:23 INFO Application started
  2026-07-01 10:16:45 ERROR Database connection failed
  2026-07-01 10:17:02 WARNING High memory usage
  2026-07-01 10:18:30 ERROR Timeout on API call
  2026-07-01 10:19:15 INFO Request processed
  2026-07-01 10:20:00 ERROR File not found: /data/config.yml
  2026-07-01 10:21:45 INFO User login successful
  2026-07-01 10:22:10 ERROR Permission denied: /var/www/html
  LOG1
            
            # Crear archivos de configuración dispersos
            mkdir -p /opt/configs
            echo "db_host=localhost" > /opt/configs/db.conf
            echo "api_key=secret123" > /opt/configs/api.conf
            echo "log_level=INFO" > /opt/configs/app.conf
            
            # Asegurar que nginx esté corriendo
            systemctl enable nginx
            systemctl start nginx
            
            # Preparar disco para montar (formateado pero no montado)
            mkfs.ext4 -F /dev/vdb 2>/dev/null || true
            
            echo "✅ node02 configurado con problemas"
          SHELL
        end
        
        # ── NODE03: BÓVEDA DE EVIDENCIA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/simulacro-001
            chown -R bob:bob /opt/ops-compliance
            chmod -R 755 /opt/ops-compliance
            echo "✅ Bóveda lista en /opt/ops-compliance/simulacro-001/"
          SHELL
        end
        
        # ── NODE01: TICKET + SCRIPT DE VERIFICACIÓN ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket y script de verificación en node01..."
            
            # --- CREAR EL TICKET ---
            cat << 'TICKET' > /home/vagrant/TICKET_SIMULACRO-001.txt
  ================================================================================
  TICKET SIMULACRO-001  │  Severidad: MEDIA  │  Ambiente: PRODUCCIÓN
  🔐 SIMULACRO-001 — El Servidor Olvidado
  Módulo: LFCS Complete  │  Dificultad: 3/10  │  Nivel: L2
  Ubicación de Control:  node01  (Estación del Administrador — bob)
  Nodo Servidor:         node02  (Servidor de aplicaciones — Ubuntu 22.04)
  Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/simulacro-001/)
  Contraseña del Clúster: caleston123

  Un servidor de aplicaciones en node02 fue encontrado sin documentación y con 
  múltiples problemas de configuración. El equipo anterior dejó el servidor en 
  un estado inconsistente y necesitas realizar tareas de diagnóstico y 
  configuración básica antes de ponerlo en producción.

  Tu misión es completar las 4 tareas siguientes en el orden que prefieras, 
  respetando los tiempos máximos y enviando la evidencia a node03.

  ================================================================================
  TAREA 1 — Essential Commands (peso 3 puntos)
  ================================================================================
  El equipo de desarrollo necesita un reporte de todos los errores encontrados 
  en los logs de la aplicación.

  Conéctate a node02 y:
  1. Busca todas las líneas que contengan la palabra "ERROR" (case-sensitive) 
     en el archivo /var/log/myapp/app.log
  2. Cuenta cuántas líneas coinciden
  3. Guarda SOLO el número en /opt/error-count.txt en node02

  CRITERIOS:
    [ ] El archivo /opt/error-count.txt existe y contiene solo un número     --> 50%
    [ ] El número es correcto (debe ser 4)                                   --> 50%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 2 — User and Group Management (peso 4 puntos)
  ================================================================================
  Se requiere crear un nuevo usuario para el departamento de QA.

  En node02:
  1. Crea un grupo llamado "qa"
  2. Crea un usuario llamado "tester" con:
     - Shell: /bin/bash
     - Grupo primario: qa
     - Grupos secundarios: developers
     - Contraseña: caleston123
  3. Verifica que el usuario exista y pertenezca a los grupos correctos

  CRITERIOS:
    [ ] El grupo "qa" existe                                                 --> 25%
    [ ] El usuario "tester" existe                                           --> 25%
    [ ] tester tiene shell /bin/bash                                         --> 25%
    [ ] tester pertenece a qa (primario) y developers (secundario)           --> 25%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 3 — Operation of Running Systems (peso 4 puntos)
  ================================================================================
  El servicio nginx no está configurado para iniciar automáticamente después 
  de un reinicio.

  En node02:
  1. Verifica el estado actual del servicio nginx
  2. Configura nginx para que inicie automáticamente en el arranque
  3. Asegúrate de que nginx esté corriendo en este momento
  4. Verifica que el servicio responda correctamente con curl

  CRITERIOS:
    [ ] nginx está habilitado para iniciar en el arranque                    --> 40%
    [ ] nginx está activo (running)                                          --> 30%
    [ ] curl http://localhost devuelve código 200                            --> 30%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 4 — Storage Management (peso 5 puntos)
  ================================================================================
  Hay un disco adicional /dev/vdb en node02 que necesita ser utilizado para 
  almacenamiento de datos.

  En node02:
  1. El disco /dev/vdb ya está formateado como ext4
  2. Crea el directorio /data
  3. Monta /dev/vdb en /data
  4. Configura /etc/fstab para que el montaje sea persistente
  5. Verifica que el montaje funcione correctamente

  CRITERIOS:
    [ ] El directorio /data existe                                           --> 20%
    [ ] /dev/vdb está montado en /data                                       --> 30%
    [ ] La entrada en /etc/fstab es correcta                                 --> 30%
    [ ] El montaje es persistente (sobrevive a mount -a)                     --> 20%

  TIEMPO MÁXIMO: 15 minutos

  ================================================================================
  PIPELINE DE EVIDENCIA A NODE03
  ================================================================================
  Una vez completadas las 4 tareas, debes enviar TODA la evidencia a node03 
  mediante pipeline SSH (sin crear archivos temporales en node01).

  Destino: /opt/ops-compliance/simulacro-001/evidence.txt

  La evidencia debe incluir:
  a) Contenido de /opt/error-count.txt en node02
  b) Salida de 'id tester' en node02
  c) Salida de 'systemctl is-enabled nginx' en node02
  d) Salida de 'mount | grep vdb' en node02
  e) Contenido de la línea de /etc/fstab relacionada con vdb

  NO crear archivos temporales en node01. Todo debe ir vía pipeline SSH.

  CRITERIOS:
    [ ] Evidencia enviada a node03:/opt/ops-compliance/simulacro-001/        --> 100%
    [ ] CERO archivos de resultados almacenados en node01 (DESCALIFICA)

  ================================================================================
  RESUMEN DE PUNTUACIÓN
  ================================================================================
  Tarea 1: 3 puntos
  Tarea 2: 4 puntos
  Tarea 3: 4 puntos
  Tarea 4: 5 puntos
  Evidencia: incluido en las tareas
  TOTAL: 16 puntos
  MÍNIMO PARA APROBAR (67%): 11 puntos

  REGLA DE ORO: Está PROHIBIDO crear archivos de resultados en node01.
  Todo debe enviarse a node03 mediante pipelines SSH.

  TIEMPO TOTAL MÁXIMO: 45 minutos
  ================================================================================
  TICKET

            # --- CREAR EL SCRIPT DE VERIFICACIÓN ---
            cat << 'VERIFY' > /tmp/verify-simulacro001.sh
  #!/bin/bash
  RED='\e[1;31m'
  GREEN='\e[1;32m'
  YELLOW='\e[1;33m'
  CYAN='\e[1;36m'
  RESET='\e[0m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  FAIL=0

  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          VERIFICACIÓN DE ESCENARIO SIMULACRO-001              ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${YELLOW}[1/8] node02: nginx instalado y activo${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "sudo systemctl is-active --quiet nginx" 2>/dev/null; then
    echo -e "      ${GREEN}✓ nginx activo${RESET}"
  else
    echo -e "      ${RED}✗ nginx inactivo${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[2/8] node02: Grupo developers existe${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "getent group developers | grep -q developers" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Grupo developers existe${RESET}"
  else
    echo -e "      ${RED}✗ Grupo developers no encontrado${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[3/8] node02: Usuarios alice y charlie existen${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "id alice >/dev/null 2>&1 && id charlie >/dev/null 2>&1" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Usuarios existen${RESET}"
  else
    echo -e "      ${RED}✗ Usuarios no encontrados${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[4/8] node02: Archivo de log existe${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "[ -f /var/log/myapp/app.log ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Archivo de log existe${RESET}"
  else
    echo -e "      ${RED}✗ Archivo de log no encontrado${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[5/8] node02: Disco /dev/vdb formateado${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "sudo blkid /dev/vdb | grep -q ext4" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Disco formateado como ext4${RESET}"
  else
    echo -e "      ${RED}✗ Disco no formateado${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[6/8] node02: Disco NO montado aún (bug inyectado)${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "mount | grep -q vdb" 2>/dev/null; then
    echo -e "      ${RED}✗ Disco ya está montado (bug no inyectado)${RESET}"
    FAIL=1
  else
    echo -e "      ${GREEN}✓ Disco no montado (esperado)${RESET}"
  fi

  echo -e "${YELLOW}[7/8] node03: Bóveda de evidencia${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/simulacro-001 ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Bóveda creada${RESET}"
  else
    echo -e "      ${RED}✗ Bóveda no existe${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[8/8] node01: Sin archivos de resultados (regla de oro)${RESET}"
  if [ ! -f /home/vagrant/error-count.txt ] && [ ! -f /tmp/evidence.txt ]; then
    echo -e "      ${GREEN}✓ No hay archivos temporales en node01${RESET}"
  else
    echo -e "      ${RED}✗ Archivos temporales detectados en node01${RESET}"
    FAIL=1
  fi

  echo ""
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║  ✅ TODAS LAS VERIFICACIONES PASARON - ESCENARIO LISTO         ║${RESET}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║  ⚠️  ALGUNAS VERIFICACIONES FALLARON                           ║${RESET}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${RESET}"
  fi

  echo ""
  echo -e "${YELLOW}Presiona ENTER para ver el ticket del incidente...${RESET}"
  read -r
  cat /home/vagrant/TICKET_SIMULACRO-001.txt
  VERIFY

            chmod +x /tmp/verify-simulacro001.sh
            
            # --- AÑADIR AL .bashrc PARA EJECUCIÓN AUTOMÁTICA ---
            sed -i '/verify-simulacro001/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-simulacro001.sh' >> /home/vagrant/.bashrc
            
            echo "✅ Ticket y script de verificación creados."
            echo "🚀 Al hacer 'vagrant ssh node01' se ejecutará automáticamente."
          SHELL
        end
      end
    end
  end
---
[[LFCS Mock Exam 1]]

---

