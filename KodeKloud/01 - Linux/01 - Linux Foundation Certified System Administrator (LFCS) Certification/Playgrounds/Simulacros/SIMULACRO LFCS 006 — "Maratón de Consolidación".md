---
Titulo: SIMULACRO LFCS 005 — "Incidentes Variados"
Severidad: MEDIA
Ambiente: Produccion
Modulo: LFCS Complete
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-16
Script Vagrant: |-
  # -- mode: ruby --
  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    
    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['1G', '512M'] },
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
          for host in node01 node02 node03; do sed -i "/$host/d" /etc/hosts; done
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
          apt-get install -y -qq sshpass curl acl lvm2 git
        SHELL
        
        # ── NODE02: SERVIDOR DE PRUEBAS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configurando node02..."
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nginx cron
            
            # Preparar datos para find y tar
            mkdir -p /opt/project
            cd /opt/project
            git init
            echo "Initial commit" > README.md
            git add README.md
            git config user.email "test@test.com"
            git config user.name "Test"
            git commit -m "init"
            
            mkdir -p /var/log/custom-app
            touch /var/log/custom-app/app1.log /var/log/custom-app/app2.log /var/log/custom-app/error.log
            
            # Preparar usuarios y grupos
            groupadd -f devteam
            useradd -m -s /bin/bash -G devteam developer1 2>/dev/null || true
            echo 'developer1:caleston123' | chpasswd
            useradd -m -s /bin/bash auditor 2>/dev/null || true
            echo 'auditor:caleston123' | chpasswd
            
            # Preparar directorio para ACL
            mkdir -p /opt/shared
            chmod 770 /opt/shared
            chown root:devteam /opt/shared
            
            # Preparar disco para LVM (/dev/vdb)
            # Se deja sin formatear para que el alumno lo haga
            
            # Preparar disco para fstab (/dev/vdc)
            mkfs.ext4 -F /dev/vdc 2>/dev/null || true
            
            systemctl enable nginx
            systemctl start nginx
            
            echo "✅ node02 listo"
          SHELL
        end
        
        # ── NODE03: BÓVEDA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            mkdir -p /opt/ops-compliance/simulacro-006
            chown -R bob:bob /opt/ops-compliance
            chmod -R 755 /opt/ops-compliance
          SHELL
        end
        
        # ── NODE01: TICKET + SCRIPT ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            cat << 'TICKET' > /home/vagrant/TICKET_SIMULACRO-006.txt
  ================================================================================
  TICKET SIMULACRO-006  │  Severidad: MEDIA  │  Ambiente: PRODUCCIÓN
  🔐 SIMULACRO-006 — Maratón de Consolidación (12 Tareas)
  Módulo: LFCS Complete  │  Dificultad: 3/10  │  Nivel: L2
  Ubicación de Control:  node01  (Estación del Administrador — bob)
  Nodo Servidor:         node02  (Ubuntu 22.04)
  Nodo Bóveda Destino:   node03  (/opt/ops-compliance/simulacro-006/)
  Contraseña del Clúster: caleston123

  Completa las 12 tareas en node02. Son tareas directas de consolidación.
  Gestiona tu tiempo: máximo 8-10 minutos por tarea.

  --- TAREAS ---
  1. [Essential/Git] En node02, ve a /opt/project, agrega un archivo llamado "config.txt" con el texto "debug=false", haz git add y un git commit con el mensaje "add config".
  2. [Users/Groups] Crea un grupo "sysadmins". Crea un usuario "admin01" con shell /bin/bash, que pertenezca al grupo "sysadmins" como grupo primario.
  3. [Storage/LVM] Usa /dev/vdb. Crea un Physical Volume (PV), un Volume Group (VG) llamado "data_vg", y un Logical Volume (LV) llamado "app_lv" de 500M. Formatealo en ext4. (No hace falta montarlo aún).
  4. [Storage/Swap] Crea un archivo de swap de 256MB en /swapfile, actívalo y asegúrate de que persista en /etc/fstab.
  5. [Storage/fstab] Monta /dev/vdc en el directorio /mnt/backup. Asegura que persista en /etc/fstab con opciones 'defaults'.
  6. [Operations/sysctl] Establece el parámetro del kernel 'net.ipv4.ip_forward' a 1 de forma persistente (archivo en /etc/sysctl.d/) y aplícalo en la sesión actual.
  7. [Operations/Process] Encuentra el PID del proceso principal de 'nginx' y guárdalo en /opt/nginx-pid.txt (solo el número).
  8. [Networking/Ports] Usa 'ss' para listar los puertos TCP en estado LISTEN. Filtra solo la línea del puerto 80 y guárdala en /opt/port-80.txt.
  9. [Networking/SSH] Edita /etc/ssh/sshd_config para deshabilitar la autenticación por contraseña (PasswordAuthentication no). NO reinicies el servicio.
  10. [Operations/Cron] Programa una tarea para el usuario 'developer1' que ejecute 'echo "daily check" >> /tmp/check.log' todos los días a las 05:00 AM.
  11. [Users/ACLs] Otorga permisos de solo lectura y ejecución (r-x) al usuario 'auditor' sobre el directorio /opt/shared usando setfacl.
  12. [Essential/Tar] Crea un archivo comprimido /opt/logs-backup.tar.gz que contenga todo el contenido del directorio /var/log/custom-app/.

  --- EVIDENCIA ---
  Envía TODO a node03:/opt/ops-compliance/simulacro-006/evidence.txt vía pipeline SSH desde node01:
  a) git log --oneline -1 (de /opt/project)
  b) id admin01
  c) sudo lvs
  d) sudo swapon --show
  e) mount | grep vdc
  f) sysctl net.ipv4.ip_forward
  g) cat /opt/nginx-pid.txt
  h) cat /opt/port-80.txt
  i) grep "^PasswordAuthentication" /etc/ssh/sshd_config
  j) sudo crontab -u developer1 -l
  k) getfacl /opt/shared
  l) ls -lh /opt/logs-backup.tar.gz

  REGLA DE ORO: CERO archivos temporales en node01.
  ================================================================================
  TICKET

            cat << 'VERIFY' > /tmp/verify-006.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; RESET='\e[0m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"; PASS="caleston123"; FAIL=0
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          VERIFICACIÓN DE ESCENARIO SIMULACRO-006              ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"

  checks=(
    "node02: Directorio /opt/project existe|[ -d /opt/project ]"
    "node02: Grupo sysadmins existe|getent group sysadmins >/dev/null"
    "node02: Disco vdb disponible|sudo blkid /dev/vdb | grep -q . || true"
    "node02: Disco vdc formateado|sudo blkid /dev/vdc | grep -q ext4"
    "node02: nginx activo|sudo systemctl is-active --quiet nginx"
    "node03: Bóveda existe|[ -d /opt/ops-compliance/simulacro-006 ]"
  )

  for check in "${checks[@]}"; do
    IFS='|' read -r desc cmd <<< "$check"
    echo -e "${YELLOW}[ ] $desc${RESET}"
    if sshpass -p $PASS ssh -t $SSH_OPTS bob@node02 "sudo $cmd" 2>/dev/null || sshpass -p $PASS ssh -t $SSH_OPTS bob@node03 "$cmd" 2>/dev/null; then
      echo -e "      ${GREEN}✓ OK${RESET}"
    else
      echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
    fi
  done

  echo ""
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ ESCENARIO LISTO. Presiona ENTER para ver el ticket.${RESET}"
  else
    echo -e "${RED}⚠️  ALGUNAS VERIFICACIONES FALLARON. Presiona ENTER de todas formas.${RESET}"
  fi
  read -r
  cat /home/vagrant/TICKET_SIMULACRO-006.txt
  VERIFY
            chmod +x /tmp/verify-006.sh
            echo 'bash /tmp/verify-006.sh' >> /home/vagrant/.bashrc
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---

