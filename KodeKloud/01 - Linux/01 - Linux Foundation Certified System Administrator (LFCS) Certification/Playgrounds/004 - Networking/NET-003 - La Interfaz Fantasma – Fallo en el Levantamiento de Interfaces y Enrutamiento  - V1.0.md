---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Playground: NET-003-v1
Titulo: La Interfaz Fantasma – Fallo en el Levantamiento de Interfaces y Enrutamiento - V1.0
Fecha de Inicio: 2026-06-13
Dificultad: 7/10
Level Escalation: L2/L3
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Sysadmin Kubernetes (La red subyacente del nodo es crítica para el CNI)
Temas: |-
  - Network Interface Configuration (Netplan / systemd-networkd)
  - IPv4/IPv6 Networking and Subnetting
  - Routing Tables and Static Routes (ip route)
  - Network Service Management (apply/reload without reboot)
Competencias: |-
  - Diagnosticar fallos de conectividad a nivel de capa 2/3 (interfaces caídas, IPs mal configuradas o sin levantar).
  - Corregir archivos de configuración de red declarativos (YAML en Netplan o .network en systemd-networkd) y aplicarlos en caliente.
  - Manipular la tabla de enrutamiento del kernel añadiendo rutas estáticas para alcanzar subredes remotas (ej. redes de pods o almacenamiento).
  - Verificar el estado de la red utilizando herramientas modernas (ip addr, ip route, networkctl) en lugar de las obsoletas (ifconfig, route).
Script Vagrant: |-
  # -*- mode: ruby -*-


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
        
        # Interfaz principal de gestión (acceso SSH)
        # FIX-1: "mgmt" en lugar de "default" para evitar colisión con la NAT
        # de libvirt (192.168.121.x). Se deshabilita DHCP para respetar IPs estáticas.
        node_config.vm.network "private_network", ip: node[:ip], libvirt__network_name: "mgmt", libvirt__dhcp_enabled: false
        
        # INTERFAZ SECUNDARIA PARA NET-003 (Red aislada del clúster)
        # Solo node02 y node03 tendrán esta segunda interfaz
        if node[:name] == "node02" || node[:name] == "node03"
          node_config.vm.network "private_network", 
            ip: (node[:name] == "node02" ? "10.99.99.2" : "10.99.99.3"),
            libvirt__network_name: "cluster-internal",
            libvirt__dhcp_enabled: false
        end

        node_config.vm.provider "libvirt" do |lv|
          lv.memory = 1024
          lv.cpus = 1
          lv.driver = "kvm"
          
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
  10.99.99.2 node02-internal
  10.99.99.3 node03-internal
  HOSTS
          
          # 2. Crear usuario bob y dar permisos
          useradd -m -s /bin/bash bob
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          # 3. Instalar herramientas esenciales
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass net-tools iproute2
        SHELL

        # ── PROVISIONADO ESPECÍFICO: TICKET EN NODE01 ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket de Incidente para node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_NET-003.txt
  ================================================================================
    TICKET NET-003  │  Severidad: ALTA  │  Ambiente: CLÚSTER DISTRIBUIDO
  ================================================================================
    🧠 NET-003-MN — La Interfaz Fantasma: Fallo en Levantamiento y Enrutamiento
    Módulo: Networking  │  Dificultad: 7/10  │  Nivel: L2/L3
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo a Intervenir:     node02  (Servidor con interfaz secundaria caída)
    Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/net-003/)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    Tras una actualización de kernel y un reinicio del servicio de red en node02,
    la interfaz secundaria (ens6, usada para comunicación interna del clúster)
    no ha levantado. Esto ha dejado al nodo aislado de la red interna y los pods
    de Kubernetes no pueden comunicarse con los servicios en node03.

    Al revisar los archivos de configuración de red en node02, se sospecha que
    la migración reciente dejó un error de sintaxis en el archivo de Netplan
    y que la directiva de enrutamiento estático fue omitida por completo.

    Como Ingeniero de Sistemas L2/L3, su misión es diagnosticar el fallo de
    configuración, corregir el archivo declarativo, agregar la ruta estática
    faltante hacia la subred de pods (10.244.0.0/16) y aplicar los cambios
    en caliente sin reiniciar el servidor.

    ARQUITECTURA DE RED
    --------------------------------------------------------------------------------
    Red de Gestión (SSH):     192.168.122.0/24  (eth0/ens5)
    Red Interna del Clúster:  10.99.99.0/24     (eth1/ens6)
      - node02-internal: 10.99.99.2
      - node03-internal: 10.99.99.3
    Subred de Pods (K8s):     10.244.0.0/16     (Ruta estática requerida)

   PROCEDIMIENTO REQUERIDO
    --------------------------------------------------------------------------------
    1. Diagnóstico de Capa 2/3:
       - Conéctate a node02 y audita el estado de todas las interfaces de red.
       - Determina cuál interfaz de clúster no está operativa y por qué
         el subsistema de red no pudo configurarla al último arranque.
       - Localiza y examina los archivos de configuración de Netplan activos.

    2. Ingeniería de Configuración Declarativa:
       - Corrige el archivo de Netplan responsable de la interfaz secundaria.
       - Asegura que la interfaz levante con IP estática 10.99.99.2/24.

    3. Enrutamiento Estático Persistente:
       - Agrega la ruta estática hacia la subred de pods 10.244.0.0/16
         directamente en el archivo de Netplan (directiva 'routes').
       - El gateway para esta ruta debe ser 10.99.99.3 (node03-internal).

    4. Aplicación en Caliente y Validación:
       - Aplica los cambios sin reiniciar el sistema.
       - Verifica conectividad de capa 3 hacia node03-internal antes de
         proceder al pipeline de evidencia.

    5. Pipeline de Evidencia a node03:
       - Destino: /opt/ops-compliance/net-003/network_evidence.txt
       - Desde node01, construye un pipeline SSH que entregue evidencia
         suficiente para demostrar:
           a) Que la interfaz secundaria está UP con la IP correcta
           b) Que la ruta hacia 10.244.0.0/16 está activa en la tabla
       - CERO archivos temporales en node01.
    CRITERIOS DE ACEPTACIÓN
    --------------------------------------------------------------------------------
     [ ] Interfaz secundaria UP con IP 10.99.99.2/24 asignada              --> 25%
     [ ] Archivo de Netplan sin errores de sintaxis y aplicado             --> 25%
     [ ] Ruta estática a 10.244.0.0/16 vía 10.99.99.3 presente             --> 25%
     [ ] Evidencia enviada a node03:/opt/ops-compliance/net-003/           --> 25%
     [ ] CERO archivos de resultados almacenados en node01  (DESCALIFICA)

    REGLA DE ORO: Bajo ninguna circunstancia reinicies node02. Los cambios
    deben aplicarse en caliente con 'netplan apply'. La evidencia debe fluir
    por pipeline SSH sin dejar rastros en node01.
  ================================================================================
  TICKET

            # Limpiar y mostrar ticket al iniciar sesión
            sed -i '/TICKET/d' /home/vagrant/.bashrc 2>/dev/null || true
            sed -i '/# Mostrar/d' /home/vagrant/.bashrc 2>/dev/null || true
            cat << 'EOF' >> /home/vagrant/.bashrc
  clear
  cat /home/vagrant/TICKET_NET-003.txt
  EOF
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: INYECCIÓN DE FALLOS EN NODE02 ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "💥 Inyectando escenario de interfaz caída en #{node[:name]}..."
            
            # FIX-2: Detectar interfaz secundaria por su IP (10.99.99.2) en lugar
            # de asumir nombre fijo. La IP ya está asignada en este punto del provisionado.
            SECONDARY_IF=$(ip --oneline address show | awk '/10\.99\.99\.2/ {print $2}')
            if [ -z "$SECONDARY_IF" ]; then
              echo "❌ ERROR: No se pudo detectar la interfaz secundaria con 10.99.99.2"
              exit 1
            fi
            echo "Interfaz secundaria detectada: $SECONDARY_IF"
            
            # Bajar la interfaz para simular el fallo
            ip link set $SECONDARY_IF down 2>/dev/null || true
            ip addr flush dev $SECONDARY_IF 2>/dev/null || true
            
            # FIX-3: Heredoc SIN comillas para que ${SECONDARY_IF} se expanda.
            # Error intencional: Falta los dos puntos (:) después de 'addresses'
            # y no se incluye la directiva de rutas (routes)
            cat > /etc/netplan/60-secondary.yaml << NETPLAN
  network:
    version: 2
    ethernets:
      ${SECONDARY_IF}:
        dhcp4: no
        addresses
          - 10.99.99.2/24
  NETPLAN
            
            # Intentar aplicar (fallará por el error de sintaxis)
            netplan apply 2>/dev/null || echo "Netplan apply falló (esperado por error de sintaxis)"
            
            echo "✅ Escenario de interfaz caída y Netplan roto inyectado en node02."
          SHELL
        end
        
        # ── PROVISIONADO ESPECÍFICO: CONFIGURAR NODE03 COMO GATEWAY DE PODS ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Configurando node03 como gateway de la subred de pods..."
            
            # Habilitar IP forwarding para que node03 pueda rutear hacia los pods
            sysctl -w net.ipv4.ip_forward=1
            echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-pod-routing.conf
            
            # Agregar una ruta negra (blackhole) para simular la subred de pods
            # En un entorno real, aquí estaría el CNI de Kubernetes
            ip route add blackhole 10.244.0.0/16 2>/dev/null || true
            
            echo "✅ node03 configurado como gateway de pods (10.244.0.0/16)."
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: PREPARAR BÓVEDA EN NODE03 ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparando bóveda de auditoría en #{node[:name]}..."
            mkdir -p /opt/ops-compliance/net-003/
            chown -R bob:bob /opt/ops-compliance/net-003/
            chmod 750 /opt/ops-compliance/net-003/
            echo "✅ Bóveda /opt/ops-compliance/net-003/ lista."
          SHELL
        end
      end
    end
  end
tags:
  - Laboratorios-del-LFCS
  - Networking
  - Interfaces
  - Routing
  - Netplan
Escenario: |-
  -  Situación: Tras una actualización de kernel y un reinicio simulado en node02, la interfaz de red secundaria (ej. enp0s8, usada para el tráfico interno del clúster hacia node03) no levanta. Al revisar, se detecta que el archivo de configuración de red (Netplan o systemd-networkd) tiene un error de sintaxis YAML o una directiva incorrecta (por ejemplo, indentación rota o configuración DHCP cuando debería ser estática). Además, falta una ruta estática crítica para alcanzar la subred de los pods (10.244.0.0/16) o de almacenamiento en node03.
  - Tu misión:
    1. Identificar la interfaz caída y diagnosticar el error en el archivo de configuración de red mediante los logs del servicio de red.
    2. Corregir la sintaxis del archivo de configuración (asegurando IP estática, máscara de red correcta y gateway si aplica).
    3. Configurar la ruta estática faltante (ya sea de forma persistente en el archivo de configuración o temporalmente con ip route) para alcanzar la subred remota.
    4. Aplicar los cambios en caliente (sin reiniciar el servidor completo) y validar que la interfaz esté UP, tenga la IP correcta y la tabla de enrutamiento muestre la ruta estática.
---

[[Laboratorios del LFCS]]

---
Recently, I was assigned a high-severity incident in our distributed cluster environment. The secondary network interface on one of our nodes had failed to come up after a kernel update and a network service restart, which completely isolated that node from the internal cluster network and broke pod-to-pod communication.

My first step was to connect remotely to the affected node and audit all network interfaces. I identified that the secondary interface was in a DOWN state with no IP address assigned. I then located the Netplan configuration file responsible for that interface and found two issues: a missing colon in the `addresses` directive that caused a syntax error, and the complete absence of a static route toward the pod subnet.

I corrected both issues directly in the Netplan file — fixing the syntax and adding the static route to `10.244.0.0/16` via the internal gateway — and applied the changes live using `netplan apply`, without restarting the server at any point. I then verified layer 3 connectivity by pinging the gateway node before closing the incident.

Finally, I built an SSH pipeline from the control node to collect interface and routing evidence and deliver it directly to the compliance vault on a third node, without leaving any temporary files behind on the intermediate host. The incident was fully resolved with zero downtime and clean audit evidence.