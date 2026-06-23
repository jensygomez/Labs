---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Playground: NET-004-v1
Titulo: El Muro Ciego – Reglas de Firewall Bloquean Tráfico Legítimo - V1.0
Fecha de Inicio: 2026-06-13
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA (Gestión de Firewalls y Seguridad de Red).
  - Pensar como Sysadmin Linux Pleno (Auditoría de reglas y análisis de flujos).
  - Prepararme para DevOps Engineer y Sysadmin Kubernetes (Entender por qué los health-checks fallan o el tráfico de pods se pierde por firewall). Temas: |-
  - Configure Packet Filtering (Firewall)
  - Stateful Inspection (Connection Tracking: NEW, ESTABLISHED, RELATED)
  - iptables vs nftables (Persistencia y sintaxis)
  - Network Troubleshooting (tcpdump, ss, journalctl) Competencias: |-
  - Auditar reglas de firewall activas para identificar políticas de "Denegar todo" mal aplicadas.
  - Comprender y configurar el seguimiento de estados (Connection Tracking) para permitir el retorno de tráfico legítimo.
  - Diferenciar entre reglas temporales y persistentes, asegurando que la corrección sobreviva a un reinicio.
  - Utilizar herramientas de diagnóstico para confirmar que el bloqueo es a nivel de firewall y no de red física o enrutamiento. 
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
        node_config.vm.network "private_network", ip: node[:ip], libvirt__network_name: "mgmt", libvirt__dhcp_enabled: false
        
        # INTERFAZ SECUNDARIA PARA COMUNICACIÓN INTERNA (Usada en NET-003 y necesaria aquí)
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
          apt-get install -y -qq sshpass net-tools iproute2 iptables-persistent
          # Pre-seed iptables-persistent para que no pida confirmación interactiva
          echo "iptables-persistent iptables-persistent/autosave_v4 boolean false" | debconf-set-selections
          echo "iptables-persistent iptables-persistent/autosave_v6 boolean false" | debconf-set-selections
          
        SHELL

        # ── PROVISIONADO ESPECÍFICO: TICKET EN NODE01 ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generando Ticket de Incidente para node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_NET-004.txt
  ================================================================================
    TICKET NET-004  │  Severidad: CRÍTICA  │  Ambiente: CLÚSTER DISTRIBUIDO
  ================================================================================
    🧠 NET-004-MN — El Muro Ciego: Reglas de Firewall Bloquean Tráfico Legítimo
    Módulo: Networking  │  Dificultad: 6/10  │  Nivel: L2
  --------------------------------------------------------------------------------
    Ubicación de Control:  node01  (Estación del Administrador — bob)
    Nodo Afectado:         node02  (Servidor con políticas de firewall restrictivas)
    Nodo Cliente Prueba:   node03  (Generador de tráfico de validación)
    Contraseña del Clúster: caleston123
  --------------------------------------------------------------------------------

    REPORTES DE INCIDENTE:
    El equipo de operaciones reporta que, tras una auditoría de seguridad aplicada
    ayer por la tarde en node02, los servicios internos han dejado de responder.
    
    Específicamente, node03 intenta conectar a servicios en node02 (puertos 80, 22, 
    o custom apps) y las conexiones se quedan en estado "SYN_SENT" hasta agotar 
    el tiempo de espera (Connection timed out). No hay rechazo activo (RST), solo 
    silencio de red.

    El equipo de seguridad confirmó haber aplicado un endurecimiento (hardening) 
    mediante iptables en node02, estableciendo políticas de caída (DROP) por defecto.
    Sin embargo, al parecer, la configuración actual impide el retorno del tráfico
    de conexiones iniciadas externamente o relacionadas con sesiones activas.

    Como Ingeniero de Sistemas L2, su misión es auditar las reglas de filtrado de
    paquetes en node02, identificar la omisión crítica en la inspección de estados
    (Connection Tracking), corregir la cadena INPUT/FORWARD para permitir tráfico
    ESTABLISHED y RELATED, y asegurar la persistencia de la corrección.

    ARQUITECTURA DE RED Y SEGURIDAD
    --------------------------------------------------------------------------------
    Red de Gestión (SSH):     192.168.122.0/24
    Red Interna del Clúster:  10.99.99.0/24
    Herramientas Requeridas:  iptables, nftables (según distro), tcpdump, ss

    PROCEDIMIENTO REQUERIDO
    --------------------------------------------------------------------------------
    1. Auditoría de Estado Actual:
       - Acceda a node02 y liste las reglas activas de iptables con detalle
         (contadores de paquetes y bytes).
       - Identifique la política por defecto y el orden de las reglas en las
         cadenas INPUT y FORWARD.

    2. Diagnóstico de Flujo:
       - Determine por qué el tráfico de retorno (ACKs) está siendo descartado.
       - Confirme la ausencia de la regla de estado "ESTABLISHED,RELATED".

    3. Ingeniería de Corrección:
       - Inserte la regla adecuada (-m state --state ESTABLISHED,RELATED -j ACCEPT)
         en la posición correcta (antes de las reglas de DROP o REJECT).
       - Valide inmediatamente la conectividad desde node03 hacia node02.

    4. Persistencia y Gobernanza:
       - Asegure que las reglas corregidas sobrevivan a un reinicio del servicio
         de firewall o del sistema operativo.
       - Documente la evidencia de la corrección.

    5. Pipeline de Evidencia a node03:
       - Destino: /opt/ops-compliance/net-004/firewall_evidence.txt
       - Desde node01, construya un pipeline SSH que entregue evidencia de:
         a) Las reglas de iptables activas en node02 mostrando contadores en la
            regla de ESTABLISHED,RELATED (tras generar tráfico).
         b) Un prueba de conexión exitosa (ej. curl o nc) desde node03 a node02.
       - CERO archivos temporales en node01.

    CRITERIOS DE ACEPTACIÓN
    --------------------------------------------------------------------------------
     [ ] Regla ESTABLISHED,RELATED presente y funcional en node02              --> 30%
     [ ] Conectividad restaurada entre node03 y node02                         --> 30%
     [ ] Reglas persistentes configuradas correctamente                        --> 20%
     [ ] Evidencia enviada a node03:/opt/ops-compliance/net-004/               --> 20%
     [ ] CERO archivos de resultados almacenados en node01  (DESCALIFICA)

    REGLA DE ORO: No deshabilite el firewall completamente (iptables -F). La solución
    debe ser quirúrgica: permitir lo legítimo manteniendo la postura de seguridad.
    La evidencia debe fluir por pipeline SSH sin dejar rastros en node01.
  ================================================================================
  TICKET

            # Limpiar y mostrar ticket al iniciar sesión
            sed -i '/TICKET/d' /home/vagrant/.bashrc 2>/dev/null || true
            sed -i '/# Mostrar/d' /home/vagrant/.bashrc 2>/dev/null || true
            cat << 'EOF' >> /home/vagrant/.bashrc
  clear
  cat /home/vagrant/TICKET_NET-004.txt
  EOF
          SHELL
        end

        # ── PROVISIONADO ESPECÍFICO: INYECCIÓN DE FALLOS EN NODE02 (FIREWALL) ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔥 Inyectando escenario de firewall restrictivo en #{node[:name]}..."
            
            # 1. Limpiar reglas existentes para empezar de cero
            iptables -F
            iptables -X
            iptables -t nat -F
            iptables -t nat -X
            iptables -t mangle -F
            iptables -t mangle -X

            # 2. Mientras la política sigue en ACCEPT (default de Ubuntu/iptables),
            #    construimos primero las rendijas de salvación. Si invirtiéramos
            #    este orden, el propio script se cortaría la sesión SSH a sí mismo
            #    (self-lockout) apenas se ejecute "iptables -P INPUT DROP".
            iptables -A INPUT -i lo -j ACCEPT
            iptables -A OUTPUT -o lo -j ACCEPT

            # Canal de management SIEMPRE abierto (red mgmt 192.168.122.0/24).
            # Esto es lo que te permite seguir entrando por SSH desde node01
            # como un sysadmin remoto real, sin necesitar consola/virsh.
            iptables -A INPUT -p tcp -s 192.168.122.0/24 --dport 22 -j ACCEPT

            # 3. ERROR INTENCIONAL (bug pedagógico real del lab):
            #    Regla de ICMP inútil que no resuelve el problema de fondo.
            #    Se permite ping solo desde un origen falso que nunca se usará.
            iptables -A INPUT -p icmp --icmp-type echo-request -s 192.168.99.99 -j ACCEPT
            
            # Logging de los descartes (útil para debug con journalctl/dmesg)
            iptables -A INPUT -j LOG --log-prefix "IPTABLES-DROP: " --log-level 4
            
            # 4. RECIÉN AHORA, con la rendija de management ya garantizada,
            #    cerramos la puerta. Esto es lo que rompe el tráfico de node03
            #    (red cluster-internal 10.99.99.0/24): sigue faltando la regla
            #    de estado ESTABLISHED,RELATED para ese tráfico específico.
            iptables -P FORWARD DROP
            iptables -P OUTPUT ACCEPT
            iptables -P INPUT DROP

            # Guardar reglas actuales (incorrectas a propósito) para que sean
            # persistentes al reiniciar. En Ubuntu suele estar con iptables-persistent
            if command -v netfilter-persistent &> /dev/null; then
               netfilter-persistent save
            elif command -v iptables-save &> /dev/null; then
               iptables-save > /etc/iptables/rules.v4
            fi

            # Iniciar un servicio simple para probar conectividad (Python HTTP server)
            # Esto correrá en background. Si el firewall está bien, node03 podrá acceder.
            cd /var/www/html 2>/dev/null || mkdir -p /var/www/html && cd /var/www/html
            echo "<h1>Node02 Secure Service</h1>" > index.html
            nohup python3 -m http.server 8080 --bind 0.0.0.0 > /dev/null 2>&1 &
            
            echo "✅ Escenario de firewall 'Muro Ciego' inyectado en node02."
            echo "   - Política INPUT: DROP"
            echo "   - SSH management (192.168.122.0/24): PERMITIDO"
            echo "   - Regla ESTABLISHED,RELATED: AUSENTE"
            echo "   - Servicio de prueba: Puerto 8080"
          SHELL
        end
        
        # ── PROVISIONADO ESPECÍFICO: PREPARAR NODE03 COMO CLIENTE DE PRUEBA ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔍 Configurando node03 como cliente de prueba y bóveda..."
            
            # Instalar herramientas de prueba de red
            apt-get install -y -qq curl telnet netcat-openbsd

            # Preparar bóveda de auditoría
            mkdir -p /opt/ops-compliance/net-004/
            chown -R bob:bob /opt/ops-compliance/net-004/
            chmod 750 /opt/ops-compliance/net-004/
            
            echo "✅ node03 listo para generar tráfico y almacenar evidencia."
          SHELL
        end

      end
    end
  end
tags:
  - Laboratorios-del-LFCS
  - Networking
  - Firewall
  - iptables
  - nftables
  - Security
Escenario: |-
  - Situación: El equipo de seguridad aplicó un endurecimiento (hardening) agresivo en `node02` utilizando `iptables`. Se añadió una política por defecto de `DROP` en la cadena `INPUT` y `FORWARD`. Sin embargo, olvidaron incluir la regla crítica para aceptar paquetes pertenecientes a conexiones ya establecidas o relacionadas (`-m state --state ESTABLISHED,RELATED -j ACCEPT`).
  - Como resultado, `node02` puede iniciar conexiones hacia fuera, pero descarta todas las respuestas entrantes. Desde `node03`, los intentos de conexión (SSH, HTTP, o pings de respuesta) hacia `node02` se quedan colgados hasta dar "Connection timed out". Los logs pueden mostrar paquetes descartados si se habilitó el logging, pero el síntoma principal es la asimetría del tráfico.
  - Tu misión:
    1. Conectarte a `node02` (vía consola directa o SSH si aún permite algo, usualmente requerirá acceso local en el laboratorio) y auditar las reglas actuales con `iptables -L -n -v`.
    2. Identificar la ausencia de la regla de estado `ESTABLISHED,RELATED` antes de las reglas de bloqueo.
    3. Insertar la regla correcta en la posición adecuada de la cadena para permitir el tráfico de retorno sin abrir puertos innecesarios.
    4. Verificar la conectividad desde `node03` hacia `node02`.
    5. Hacer la configuración persistente (usando `iptables-persistent`, `nftables` o el mecanismo adecuado de la distro) para asegurar que el fix no se pierda al reiniciar.
---

[[Laboratorios del LFCS]]

---

_Sure — one challenge I tackled recently involved a network connectivity issue between two servers in a distributed environment. After a security hardening update, internal services stopped responding, and connections were just timing out, with no rejection at all, which made it trickier to diagnose._

_I started by auditing the firewall rules on the affected server using iptables, and I noticed the default policy was set to DROP, but there was no rule allowing established or related traffic. That meant any return traffic from legitimate connections was being silently dropped, which matched the symptoms perfectly._

_Before jumping to a fix, I wanted solid evidence, so I ran a packet capture with tcpdump while generating test traffic from the client side. That confirmed the SYN packets were arriving at the server, but it never replied — no SYN-ACK, no RST, nothing. The packets were being dropped before the TCP stack could even respond._

_I also discovered the actual service was running on a different port than what was documented, which added another layer to the investigation. Once I had that clarity, I inserted the missing ESTABLISHED,RELATED rule and a specific rule to allow new connections from the internal subnet to the correct port, making sure to place them in the right order — before any DROP or LOG rules._

_After validating connectivity was restored, I made the fix persistent so it would survive a service or system restart, and I documented everything with clear evidence — firewall rule counters and a successful connection test — without leaving any temporary files on the control node, since that was a strict requirement._

_What I really took away from that case is the importance of methodical troubleshooting — inspecting the configuration, reproducing the issue, running the right diagnostic command, fixing it surgically, and then verifying and documenting the fix — rather than just applying a quick patch._