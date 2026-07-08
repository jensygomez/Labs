---
Titulo: TICKET SIMULACRO-001 - El Servidor Olvidado
Severidad: MEDIA
Ambiente: Produccion
Modulo: LFCS Complete
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-07
Escenario: |-
  Un servidor de aplicaciones en node02 fue encontrado sin documentación y con 
  múltiples problemas de configuración. El equipo anterior dejó el servidor en 
  un estado inconsistente y necesitas realizar tareas de diagnóstico y 
  configuración básica antes de ponerlo en producción.

  Tu misión es completar las 4 tareas siguientes en el orden que prefieras, 
  respetando los tiempos máximos y enviando la evidencia a node03.
Script Vagrant: |-
  # -- mode: ruby --

  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    
    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: [] },
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
          apt-get install -y -qq sshpass curl
        SHELL
        
        # ── NODE02: SERVIDOR CON PROBLEMAS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configurando node02 como servidor de aplicaciones..."
            
            # Instalar servicios básicos
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq htop nmap net-tools
            
            # Crear directorio de logs de aplicación
            mkdir -p /var/log/myapp
            chown root:root /var/log/myapp
            chmod 755 /var/log/myapp
            
            # Crear archivos de log con diferentes permisos
            touch /var/log/myapp/app.log
            touch /var/log/myapp/error.log
            touch /var/log/myapp/debug.log
            chmod 644 /var/log/myapp/app.log
            chmod 600 /var/log/myapp/error.log
            chmod 644 /var/log/myapp/debug.log
            
            # Crear algunos archivos con permisos especiales
            touch /var/log/myapp/secure.conf
            chmod 600 /var/log/myapp/secure.conf
            
            # Crear archivos dispersos
            mkdir -p /opt/configs
            echo "db_host=localhost" > /opt/configs/db.conf
            echo "api_key=secret123" > /opt/configs/api.conf
            echo "log_level=INFO" > /opt/configs/app.conf
            
            # Crear usuario para cron
            useradd -m -s /bin/bash appuser 2>/dev/null || true
            echo 'appuser:caleston123' | chpasswd
            
            echo "✅ node02 configurado con problemas"
          SHELL
        end
        
        # ── NODE03: BÓVEDA DE EVIDENCIA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/simulacro-002
            chown -R bob:bob /opt/ops-compliance
            chmod -R 755 /opt/ops-compliance
            echo "✅ Bóveda lista en /opt/ops-compliance/simulacro-002/"
          SHELL
        end
        
        # ── NODE01: TICKET + SCRIPT DE VERIFICACIÓN ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket y script de verificación en node01..."
            
            # --- CREAR EL TICKET ---
            cat << 'TICKET' > /home/vagrant/TICKET_SIMULACRO-002.txt
  ================================================================================
  TICKET SIMULACRO-002  │  Severidad: MEDIA  │  Ambiente: PRODUCCIÓN
  🔐 SIMULACRO-002 — La Red Silenciosa
  Módulo: LFCS Complete  │  Dificultad: 3/10  │  Nivel: L2
  Ubicación de Control:  node01  (Estación del Administrador — bob)
  Nodo Servidor:         node02  (Servidor de aplicaciones — Ubuntu 22.04)
  Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/simulacro-002/)
  Contraseña del Clúster: caleston123

  Un servidor de aplicaciones en node02 necesita configuración de red, tareas 
  programadas, instalación de paquetes adicionales y auditoría de archivos. 
  El equipo anterior dejó el servidor sin documentar y necesitas realizar 
  tareas básicas de administración antes de ponerlo en producción.

  Tu misión es completar las 4 tareas siguientes en el orden que prefieras, 
  respetando los tiempos máximos y enviando la evidencia a node03.

  ================================================================================
  TAREA 1 — Networking (peso 3 puntos)
  ================================================================================
  El equipo de operaciones necesita verificar la configuración de red de node02.

  Conéctate a node02 y:
  1. Identifica la dirección IP de la interfaz de red principal (no localhost)
  2. Verifica que node02 puede hacer ping a node03
  3. Guarda la dirección IP en /opt/network-info.txt en node02

  CRITERIOS:
    [ ] El archivo /opt/network-info.txt existe y contiene una IP válida      --> 50%
    [ ] La IP corresponde a node02 (192.168.122.12)                          --> 50%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 2 — Service Configuration (peso 4 puntos)
  ================================================================================
  Se requiere configurar una tarea programada para el usuario appuser.

  En node02:
  1. Crea un cron job para el usuario appuser que ejecute el comando 
     'echo "Backup completed" >> /tmp/backup.log' todos los días a las 2:30 AM
  2. Verifica que el cron job fue creado correctamente

  CRITERIOS:
    [ ] El cron job existe para el usuario appuser                           --> 60%
    [ ] El cron job está configurado para ejecutarse a las 2:30 AM diarios   --> 40%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 3 — Package Management (peso 4 puntos)
  ================================================================================
  El equipo de desarrollo necesita instalar herramientas de diagnóstico.

  En node02:
  1. Instala el paquete 'iftop' (herramienta de monitoreo de red)
  2. Verifica que el paquete fue instalado correctamente
  3. Guarda la versión instalada en /opt/package-info.txt en node02

  CRITERIOS:
    [ ] El paquete iftop está instalado                                      --> 50%
    [ ] El archivo /opt/package-info.txt contiene información de versión     --> 50%

  TIEMPO MÁXIMO: 10 minutos

  ================================================================================
  TAREA 4 — Essential Commands (peso 5 puntos)
  ================================================================================
  El equipo de seguridad necesita auditar archivos con permisos sensibles.

  En node02:
  1. Busca todos los archivos en /var/log/myapp/ que tengan permisos 600 
     (solo el propietario puede leer y escribir)
  2. Cuenta cuántos archivos coinciden
  3. Guarda la lista completa de estos archivos (ruta completa) en 
     /opt/secure-files.txt en node02

  CRITERIOS:
    [ ] El archivo /opt/secure-files.txt existe                              --> 30%
    [ ] Contiene la lista de archivos con permisos 600                       --> 40%
    [ ] La lista es correcta (debe incluir error.log y secure.conf)          --> 30%

  TIEMPO MÁXIMO: 15 minutos

  ================================================================================
  PIPELINE DE EVIDENCIA A NODE03
  ================================================================================
  Una vez completadas las 4 tareas, debes enviar TODA la evidencia a node03 
  mediante pipeline SSH (sin crear archivos temporales en node01).

  Destino: /opt/ops-compliance/simulacro-002/evidence.txt

  La evidencia debe incluir:
  a) Contenido de /opt/network-info.txt en node02
  b) Salida de 'sudo crontab -u appuser -l' en node02
  c) Contenido de /opt/package-info.txt en node02
  d) Contenido de /opt/secure-files.txt en node02

  NO crear archivos temporales en node01. Todo debe ir vía pipeline SSH.

  CRITERIOS:
    [ ] Evidencia enviada a node03:/opt/ops-compliance/simulacro-002/        --> 100%
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
            cat << 'VERIFY' > /tmp/verify-simulacro002.sh
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
  echo -e "${CYAN}║          VERIFICACIÓN DE ESCENARIO SIMULACRO-002              ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${YELLOW}[1/6] node02: Herramientas básicas instaladas${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "which htop nmap >/dev/null 2>&1" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Herramientas instaladas${RESET}"
  else
    echo -e "      ${RED}✗ Herramientas no encontradas${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[2/6] node02: Directorio de logs existe${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "[ -d /var/log/myapp ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Directorio de logs existe${RESET}"
  else
    echo -e "      ${RED}✗ Directorio de logs no encontrado${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[3/6] node02: Archivos de log con permisos específicos${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "[ -f /var/log/myapp/error.log ] && [ -f /var/log/myapp/secure.conf ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Archivos de log existen${RESET}"
  else
    echo -e "      ${RED}✗ Archivos de log no encontrados${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[4/6] node02: Usuario appuser existe${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "id appuser >/dev/null 2>&1" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Usuario appuser existe${RESET}"
  else
    echo -e "      ${RED}✗ Usuario appuser no encontrado${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[5/6] node02: Conectividad con node03${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "ping -c 1 node03 >/dev/null 2>&1" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Conectividad con node03${RESET}"
  else
    echo -e "      ${RED}✗ Sin conectividad con node03${RESET}"
    FAIL=1
  fi

  echo -e "${YELLOW}[6/6] node03: Bóveda de evidencia${RESET}"
  if sshpass -p $PASS ssh -t $SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/simulacro-002 ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ Bóveda creada${RESET}"
  else
    echo -e "      ${RED}✗ Bóveda no existe${RESET}"
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
  cat /home/vagrant/TICKET_SIMULACRO-002.txt
  VERIFY

            chmod +x /tmp/verify-simulacro002.sh
            
            # --- AÑADIR AL .bashrc PARA EJECUCIÓN AUTOMÁTICA ---
            sed -i '/verify-simulacro002/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-simulacro002.sh' >> /home/vagrant/.bashrc
            
            echo "✅ Ticket y script de verificación creados."
            echo "🚀 Al hacer 'vagrant ssh node01' se ejecutará automáticamente."
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---

