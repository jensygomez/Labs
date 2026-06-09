---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Playground: PG-NET-001
Titulo: Recuperación de Infraestructura tras Migración de Red - V1
Fecha de Inicio: 2026-06-08
Dificultad: 5/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Historia: Recuperación de infraestructura tras migración de red
Infraestructura: |-
  Host CentOS Stream 9
  │
  ├── Namespace admin-client -->  192.168.100.10
  │
  ├── Namespace web01 -->  192.168.100.20
  │
  └── Namespace dns01 -->  192.168.100.53
Temas: |-
  - Configure IPv4 and IPv6 Networking and Hostname Resolution
  - Start, Stop and Check Status of Network Services
  - Configure Packet Filtering (Firewall)
  - Set and Synchronize System Time Using Time Servers
  - Configure SSH Servers and Clients
Competencias: |-
  - Diagnosticar problemas de conectividad tras cambios de red
  - Restaurar acceso administrativo remoto
  - Resolver incidencias de resolución de nombres
  - Implementar controles básicos de acceso mediante firewall
  - Verificar servicios críticos de infraestructura
Validacion: |-
  - Objetivo: El servidor web responde utilizando la dirección IPv4 corporativa requerida.
    Peso: 10 %
  - Objetivo: El servidor web posee conectividad IPv6 funcional.
    Peso: 10 %
  - Objetivo: El servidor se identifica correctamente como web01.corp.internal.
    Peso: 5 %
  - Objetivo: La resolución DNS interna funciona correctamente.
    Peso: 15 %
  - Objetivo: Los servicios de red críticos se encuentran activos y habilitados.
    Peso: 10 %
  - Objetivo: El acceso administrativo remoto funciona mediante el puerto corporativo.
    Peso: 15 %
  - Objetivo: El sistema mantiene sincronización horaria con la infraestructura corporativa.
    Peso: 10 %
  Objetivo: El firewall cumple la política corporativa definida.
  Peso: 15 %
  Objetivo: El portal web corporativo responde correctamente.
  Peso: 10 %
tags:
  - Laboratorios-del-LFCS
Infra Base: |-
  cat << 'EOF' > /tmp/infra_base.sh
  #!/bin/bash
  # =============================================================================
  # LFCS NETWORKING LABS - INFRAESTRUCTURA BASE
  # Compatible: CentOS Stream 9 / Rocky Linux 9 (KodeKloud playground)
  # Arquitectura: dummy interfaces + systemctl + servicios reales
  # Reutilizable para todos los laboratorios - NO modificar este script
  # =============================================================================

  set -e

  if [ "$EUID" -ne 0 ]; then
      echo "Ejecutar como root"
      exit 1
  fi

  echo ""
  echo "=============================================="
  echo " LFCS NETWORKING LABS - Desplegando infra base"
  echo "=============================================="

  # ==============================================================
  # 1. INSTALAR PAQUETES
  # ==============================================================
  echo "[1/7] Instalando paquetes..."
  dnf install -y --skip-broken \
      nginx \
      bind \
      bind-utils \
      chrony \
      openssh-server \
      curl \
      iproute \
      iptables \
      iputils \
      net-tools \
      tcpdump \
      wget \
      vim \
      2>/dev/null
  echo "[OK] Paquetes instalados"

  # ==============================================================
  # 2. INTERFACES DUMMY (IPs fijas por nodo)
  # ==============================================================
  echo "[2/7] Configurando interfaces dummy..."

  # Limpiar interfaces dummy anteriores
  for i in 0 1 2 3; do
      ip link del dummy$i 2>/dev/null || true
  done

  # web01
  ip link add dummy0 type dummy
  ip addr add 192.168.100.20/24 dev dummy0
  ip link set dummy0 up

  # web02
  ip link add dummy1 type dummy
  ip addr add 192.168.100.21/24 dev dummy1
  ip link set dummy1 up

  # proxy01
  ip link add dummy2 type dummy
  ip addr add 192.168.100.100/24 dev dummy2
  ip link set dummy2 up

  # dns01
  ip link add dummy3 type dummy
  ip addr add 192.168.100.53/24 dev dummy3
  ip link set dummy3 up

  # IPv6 en web01
  ip -6 addr add fd00:dead:beef::20/64 dev dummy0
  ip -6 addr add fd00:dead:beef::21/64 dev dummy1
  ip -6 addr add fd00:dead:beef::100/64 dev dummy2
  ip -6 addr add fd00:dead:beef::53/64  dev dummy3

  echo "[OK] Interfaces dummy configuradas"
  echo "      dummy0  → 192.168.100.20  (web01)"
  echo "      dummy1  → 192.168.100.21  (web02)"
  echo "      dummy2  → 192.168.100.100 (proxy01)"
  echo "      dummy3  → 192.168.100.53  (dns01)"

  # ==============================================================
  # 3. HOSTNAME
  # ==============================================================
  echo "[3/7] Configurando hostname..."
  echo "web01.corp.internal" > /etc/hostname
  hostname web01.corp.internal
  echo "[OK] hostname: web01.corp.internal"

  # /etc/hosts
  cat > /etc/hosts << 'HOSTS'
  127.0.0.1       localhost
  ::1             localhost

  192.168.100.20  web01.corp.internal  web01
  192.168.100.21  web02.corp.internal  web02
  192.168.100.100 proxy01.corp.internal proxy01
  192.168.100.53  dns01.corp.internal  dns01
  HOSTS
  echo "[OK] /etc/hosts configurado"

  # ==============================================================
  # 4. NGINX
  # ==============================================================
  echo "[4/7] Configurando nginx..."

  cat > /usr/share/nginx/html/index.html << 'HTML'
  <!DOCTYPE html>
  <html lang="es">
  <head>
      <meta charset="UTF-8">
      <title>Portal Corporativo</title>
      <style>
          body { font-family: sans-serif; background: #f0f4f8;
                 display: flex; justify-content: center;
                 align-items: center; height: 100vh; margin: 0; }
          .card { background: white; border-radius: 8px; padding: 40px;
                  box-shadow: 0 2px 8px rgba(0,0,0,0.1); text-align: center; }
          h1  { color: #2c5282; }
          p   { color: #4a5568; }
          .badge { background: #48bb78; color: white; padding: 4px 12px;
                   border-radius: 20px; font-size: 0.85em; }
      </style>
  </head>
  <body>
      <div class="card">
          <h1>Portal Corporativo</h1>
          <p>Servidor <strong>web01.corp.internal</strong></p>
          <p><span class="badge">OPERATIVO</span></p>
          <p style="font-size:0.8em;color:#a0aec0;">192.168.100.20</p>
      </div>
  </body>
  </html>
  HTML

  cat > /etc/nginx/nginx.conf << 'NGINXCONF'
  user nginx;
  worker_processes auto;
  error_log /var/log/nginx/error.log;
  pid /run/nginx.pid;
  include /usr/share/nginx/modules/*.conf;

  events {
      worker_connections 1024;
  }

  http {
      include       /etc/nginx/mime.types;
      default_type  application/octet-stream;
      access_log    /var/log/nginx/access.log;
      sendfile      on;
      keepalive_timeout 65;

      server {
          listen      192.168.100.20:80;
          listen      [fd00:dead:beef::20]:80;
          server_name web01.corp.internal web01;
          root        /usr/share/nginx/html;
          index       index.html;

          location / {
              try_files $uri $uri/ =404;
          }
      }
  }
  NGINXCONF

  systemctl enable nginx
  systemctl restart nginx
  echo "[OK] nginx activo → 192.168.100.20:80"

  # ==============================================================
  # 5. BIND (named) - DNS interno
  # ==============================================================
  echo "[5/7] Configurando BIND..."

  # Zona directa
  cat > /var/named/corp.internal.db << 'ZONE'
  $TTL 86400
  @   IN  SOA dns01.corp.internal. admin.corp.internal. (
              2026060801  ; Serial
              3600        ; Refresh
              1800        ; Retry
              604800      ; Expire
              86400 )     ; Minimum TTL

          IN  NS   dns01.corp.internal.

  dns01   IN  A    192.168.100.53
  dns01   IN  AAAA fd00:dead:beef::53
  web01   IN  A    192.168.100.20
  web01   IN  AAAA fd00:dead:beef::20
  web02   IN  A    192.168.100.21
  web02   IN  AAAA fd00:dead:beef::21
  proxy01 IN  A    192.168.100.100
  proxy01 IN  AAAA fd00:dead:beef::100
  ZONE

  # Zona reversa
  cat > /var/named/100.168.192.in-addr.arpa.db << 'RZONE'
  $TTL 86400
  @   IN  SOA dns01.corp.internal. admin.corp.internal. (
              2026060801 3600 1800 604800 86400 )
          IN  NS  dns01.corp.internal.

  20  IN  PTR web01.corp.internal.
  21  IN  PTR web02.corp.internal.
  53  IN  PTR dns01.corp.internal.
  100 IN  PTR proxy01.corp.internal.
  RZONE

  chown named:named /var/named/corp.internal.db
  chown named:named /var/named/100.168.192.in-addr.arpa.db
  chmod 640 /var/named/corp.internal.db
  chmod 640 /var/named/100.168.192.in-addr.arpa.db

  cat > /etc/named.conf << 'NAMEDCONF'
  options {
      listen-on     { 127.0.0.1; 192.168.100.53; };
      listen-on-v6  { ::1; fd00:dead:beef::53; };
      directory     "/var/named";
      allow-query   { any; };
      recursion     no;
  };

  zone "corp.internal" IN {
      type master;
      file "/var/named/corp.internal.db";
  };

  zone "100.168.192.in-addr.arpa" IN {
      type master;
      file "/var/named/100.168.192.in-addr.arpa.db";
  };
  NAMEDCONF

  systemctl enable named
  systemctl restart named
  echo "[OK] named activo → 192.168.100.53:53"

  # ==============================================================
  # 6. CHRONY
  # ==============================================================
  echo "[6/7] Configurando chrony..."

  cat > /etc/chrony.conf << 'CHRONYCONF'
  pool pool.ntp.org iburst
  driftfile /var/lib/chrony/drift
  makestep 1.0 3
  rtcsync
  logdir /var/log/chrony
  CHRONYCONF

  mkdir -p /etc/systemd/system/chronyd.service.d/
  cat > /etc/systemd/system/chronyd.service.d/override.conf << '_EOF_'
  [Service]
  ExecStart=
  ExecStart=/usr/sbin/chronyd -x $OPTIONS
  _EOF_

  systemctl daemon-reload
  systemctl enable chronyd
  systemctl start chronyd 2>/dev/null || true
  echo "[OK] chronyd configurado"

  # ==============================================================
  # 7. SSH (puerto 2222)
  # ==============================================================
  echo "[7/7] Configurando sshd puerto 2222..."

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  # Limpiar cualquier Port existente y setear 2222
  sed -i '/^Port /d'    /etc/ssh/sshd_config
  sed -i '/^#Port /d'   /etc/ssh/sshd_config
  echo "Port 2222"     >> /etc/ssh/sshd_config

  systemctl enable sshd
  systemctl restart sshd
  echo "[OK] sshd activo → puerto 2222"

  # ==============================================================
  # IPTABLES - reglas base permisivas
  # ==============================================================
  iptables -F
  iptables -P INPUT   ACCEPT
  iptables -P OUTPUT  ACCEPT
  iptables -P FORWARD ACCEPT

  iptables -A INPUT -i lo      -j ACCEPT
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -p tcp --dport 80   -j ACCEPT
  iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
  iptables -A INPUT -p udp --dport 53   -j ACCEPT
  iptables -A INPUT -p tcp --dport 53   -j ACCEPT
  iptables -A INPUT -p udp --dport 123  -j ACCEPT
  iptables -A INPUT -p icmp             -j ACCEPT

  # ==============================================================
  # VERIFICACIÓN FINAL
  # ==============================================================
  echo ""
  echo "=============================================="
  echo " VERIFICACIÓN FINAL"
  echo "=============================================="

  # Servicios
  for svc in nginx named chronyd sshd; do
      status=$(systemctl is-active $svc 2>/dev/null)
      if [ "$status" = "active" ]; then
          printf "  %-10s → \e[32m%s\e[0m\n" "[$svc]" "OK"
      else
          printf "  %-10s → \e[31m%s\e[0m\n" "[$svc]" "FAIL ($status)"
      fi
  done

  echo ""

  # Conectividad
  echo -n "  [nginx  ] curl web01:       "
  curl -s --max-time 2 http://192.168.100.20/ | grep -o "Portal Corporativo" || echo "FAIL"

  echo -n "  [ssh    ] puerto 2222:      "
  ss -tlnp | grep -q 2222 && echo "OK" || echo "FAIL"

  echo -n "  [dns    ] A web01:          "
  dig web01.corp.internal @192.168.100.53 +short 2>/dev/null | grep -q "192.168.100.20" && echo "OK" || echo "FAIL"

  echo -n "  [dns    ] AAAA web01:       "
  dig AAAA web01.corp.internal @192.168.100.53 +short 2>/dev/null | grep -q "fd00" && echo "OK" || echo "FAIL"

  echo -n "  [chrony ] tracking:         "
  chronyc tracking 2>/dev/null | grep -q "Reference ID" && echo "OK" || echo "FAIL"

  echo -n "  [hostname]:                 "
  hostname

  echo ""
  echo "=============================================="
  echo " Infra base lista. Ejecuta el script break"
  echo " para iniciar el laboratorio."
  echo "=============================================="

  EOF
  bash /tmp/infra_base.sh && rm -f /tmp/infra_base.sh
Script Break: |-
  cat << 'BREAKOUT' > /tmp/script_break.sh

  #!/bin/bash
  # =============================================================================
  # LFCS NETWORKING LABS
  # LAB 01 - Recuperación tras migración de red
  # NIVEL A - Dificultad 5/10 | Guiado | Un problema por tarea
  # =============================================================================

  set -Eeuo pipefail
  trap 'echo "ERROR en ${BASH_SOURCE}:${LINENO}:${FUNCNAME:-}"' ERR

  if [ "$EUID" -ne 0 ]; then
      echo "Ejecutar como root"
      exit 1
  fi

  # Verificar que la infra base fue ejecutada
  if ! systemctl is-active nginx &>/dev/null && ! command -v nginx &>/dev/null; then
      echo "[ERROR] Ejecuta primero el script infra_base.sh"
      exit 1
  fi

  echo "[BREAK] Aplicando fallos controlados - Lab01 Nivel A..."

  # ==============================================================
  # 1. DETENER SERVICIOS
  # ==============================================================
  #echo "[1] Deteniendo servicios"
  sleep 1
  systemctl stop nginx   2>/dev/null || true
  systemctl stop named   2>/dev/null || true
  systemctl stop chronyd 2>/dev/null || true
  systemctl stop sshd    2>/dev/null || true

  # ==============================================================
  # 2. HOSTNAME INCORRECTO
  # ==============================================================
  #echo "[2] Cambiando hostname"
  sleep 1
  echo "broken-host" > /etc/hostname
  hostname broken-host

  # ==============================================================
  # 3. CORROMPER DNS
  # ==============================================================
  #echo "[3] Rompiendo DNS"
  sleep 1
  sed -i 's/192.168.100.20/10.0.0.99/'      /var/named/corp.internal.db
  sed -i 's/fd00:dead:beef::20/2001:db8::bad/' /var/named/corp.internal.db

  # ==============================================================
  # 4. SSH EN PUERTO INCORRECTO
  # ==============================================================
  #echo "[4] Cambiando SSH"
  sleep 1
  sed -i 's/^Port 2222/Port 2223/' /etc/ssh/sshd_config
  systemctl start sshd 2>/dev/null || true

  # ==============================================================
  # 5. DESHABILITAR IPv6 EN web01
  # ==============================================================
  #echo "[5] IPv6"
  sleep 1
  sysctl -w net.ipv6.conf.dummy0.disable_ipv6=1 >/dev/null

  # ==============================================================
  # 6. FIREWALL ULTRARRESTRICTIVO
  # ==============================================================
  echo "[6] Firewall"
  sleep 1
  iptables -F
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT DROP

  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
  iptables -A OUTPUT -p tcp --sport 2222 -j ACCEPT
  iptables -A INPUT -p icmp -j ACCEPT
  iptables -A OUTPUT -p icmp -j ACCEPT

  # ==============================================================
  # MOSTRAR TICKET
  # ==============================================================
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m LFCS NETWORKING LABS | LAB-01 | NIVEL A (5/10)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET: INC-NET-001\e[0m"
  echo -e " Asunto:    Migración de red - Servicios críticos no operativos"
  echo -e " Severidad: Alta"
  echo -e " Fecha:     $(date '+%Y-%m-%d')"
  echo -e " --------------------------------------------------------------------------------"
  echo -e "\e[1;36m CONTEXTO:\e[0m"
  echo -e ""
  echo -e "   El equipo de infraestructura migró la red corporativa de 10.0.0.0/24"
  echo -e "   a 192.168.100.0/24 con soporte IPv6 (fd00:dead:beef::/64)."
  echo -e "   Al finalizar la ventana de mantenimiento, varios servicios críticos"
  echo -e "   no responden. El equipo de operaciones necesita restaurarlos antes"
  echo -e "   de las 08:00 UTC."
  echo -e ""
  echo -e " --------------------------------------------------------------------------------"
  echo -e "\e[1;36m PROBLEMAS DETECTADOS:\e[0m"
  echo -e ""
  echo -e "   ✗ nginx detenido — el portal web no responde"
  echo -e "   ✗ IPv6 deshabilitado en la interfaz web01"
  echo -e "   ✗ Hostname incorrecto (no es web01.corp.internal)"
  echo -e "   ✗ DNS resuelve web01 a IP incorrecta (10.0.0.99)"
  echo -e "   ✗ SSH escucha en puerto 2223 (debe ser 2222)"
  echo -e "   ✗ Firewall bloquea todo excepto ping"
  echo -e "   ✗ chronyd detenido — sin sincronización horaria"
  echo -e ""
  echo -e " --------------------------------------------------------------------------------"
  echo -e "\e[1;36m CRITERIOS DE ÉXITO:\e[0m"
  echo -e ""
  echo -e "   [ ] curl http://192.168.100.20/         → Portal Corporativo"
  echo -e "   [ ] curl -6 http://[fd00:dead:beef::20]/ → Portal Corporativo"
  echo -e "   [ ] hostname                             → web01.corp.internal"
  echo -e "   [ ] dig web01.corp.internal @192.168.100.53 → 192.168.100.20"
  echo -e "   [ ] ss -tlnp | grep sshd                → puerto 2222"
  echo -e "   [ ] systemctl is-active nginx named chronyd sshd → active"
  echo -e "   [ ] iptables -L INPUT | grep 80          → ACCEPT"
  echo -e "   [ ] chronyc tracking                     → Reference ID OK"
  echo -e ""
  echo -e " --------------------------------------------------------------------------------"
  echo -e "\e[1;33m NIVEL A - GUIADO:\e[0m"
  echo -e "   Cada tarea tiene un solo problema. Resolvé en este orden:"
  echo -e "   1. Hostname  2. IPv6  3. nginx  4. Firewall  5. DNS  6. SSH  7. Chrony"
  echo -e " --------------------------------------------------------------------------------"
  echo -e "\e[1;33m TIEMPO ESTIMADO: 30 minutos\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  BREAKOUT
  chmod +x /tmp/script_break.sh 
  bash /tmp/script_break.sh
Script Validacion: |-
  cat << '_EOF_' > /tmp/script_Validacao.sh

  #!/bin/bash

  PUNTOS=0
  TOTAL=100

  echo "================================================================================="
  echo "=== VALIDANDO RECUPERACIÓN DE INFRAESTRUCTURA - LAB-01 (Nivel A)             ==="
  echo "================================================================================="

  # 1. Web IPv4 (10%)
  echo -n "[10%] Comprobando web en IPv4 (http://192.168.100.20:80/) ... "
  if curl -s -o /dev/null -w '%{http_code}' http://192.168.100.20/ | grep -q '200'; then
      echo "✔ OK"; PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (no responde HTTP 200)"
  fi

  # 2. Web IPv6 (10%)
  echo -n "[10%] Comprobando web en IPv6 (http://[fd00:dead:beef::20]:80/) ... "
  if curl -6 -s -o /dev/null -w '%{http_code}' http://[fd00:dead:beef::20]/ | grep -q '200'; then
      echo "✔ OK"; PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (IPv6 no responde)"
  fi

  # 3. Hostname (5%)
  echo -n "[5%] Hostname del sistema ... "
  HOSTNAME=$(hostname)
  if [ "$HOSTNAME" = "web01.corp.internal" ]; then
      echo "✔ OK ($HOSTNAME)"; PUNTOS=$((PUNTOS + 5))
  else
      echo "❌ FALLO (es '$HOSTNAME', debe ser web01.corp.internal)"
  fi

  # 4. DNS (15%)
  echo -n "[15%] Resolución DNS de web01.corp.internal ... "
  DNS_IPV4=$(dig +short web01.corp.internal @192.168.100.53 2>/dev/null | head -1)
  DNS_IPV6=$(dig +short AAAA web01.corp.internal @192.168.100.53 2>/dev/null | head -1)
  if [ "$DNS_IPV4" = "192.168.100.20" ] && [ "$DNS_IPV6" = "fd00:dead:beef::20" ]; then
      echo "✔ OK (IPv4 $DNS_IPV4, IPv6 $DNS_IPV6)"; PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ FALLO (IPv4: $DNS_IPV4, IPv6: $DNS_IPV6)"
  fi

  # 5. Servicios activos (10%)
  echo -n "[10%] Servicios activos en el host ... "
  SERVICIOS_OK=0
  systemctl is-active nginx --quiet   && SERVICIOS_OK=$((SERVICIOS_OK+1))
  systemctl is-active named --quiet   && SERVICIOS_OK=$((SERVICIOS_OK+1))
  systemctl is-active sshd --quiet    && SERVICIOS_OK=$((SERVICIOS_OK+1))
  systemctl is-active chronyd --quiet && SERVICIOS_OK=$((SERVICIOS_OK+1))
  if [ $SERVICIOS_OK -eq 4 ]; then
      echo "✔ OK (nginx, named, sshd, chronyd activos)"; PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (solo $SERVICIOS_OK/4 servicios activos)"
  fi

  # 6. SSH puerto 2222 — verificar escucha (no login) (15%)
  echo -n "[15%] SSH escuchando en puerto 2222 ... "
  if ss -tlnp | grep -q ':2222'; then
      echo "✔ OK"; PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ FALLO (sshd no escucha en puerto 2222)"
  fi

  # 7. Chrony activo (10%) — container no permite sync real
  echo -n "[10%] Servicio chronyd activo ... "
  if systemctl is-active chronyd --quiet; then
      echo "✔ OK (chronyd activo)"; PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (chronyd no está activo)"
  fi

  # 8. Firewall (15%)
  echo -n "[15%] Política de firewall (reglas INPUT) ... "
  FW_RULES=$(iptables -S INPUT)
  if echo "$FW_RULES" | grep -q -- "--dport 80 -j ACCEPT"   && \
     echo "$FW_RULES" | grep -q -- "--dport 2222 -j ACCEPT" && \
     echo "$FW_RULES" | grep -q -- "--dport 53 -j ACCEPT"   && \
     echo "$FW_RULES" | grep -q -- "--dport 123 -j ACCEPT"; then
      echo "✔ OK (puertos 80,2222,53,123 permitidos)"; PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ FALLO (faltan reglas para puertos 80/2222/53/123)"
  fi

  # 9. Contenido portal (10%)
  echo -n "[10%] Contenido del portal web ... "
  if curl -s http://192.168.100.20/ | grep -qi "Portal Corporativo"; then
      echo "✔ OK (contiene 'Portal Corporativo')"; PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (no se encuentra el texto esperado)"
  fi

  echo "================================================================================="
  echo "CALIFICACIÓN FINAL: $PUNTOS / $TOTAL"
  if [ $PUNTOS -eq $TOTAL ]; then
      echo "🎉 ¡EXCELENTE! Has recuperado completamente la infraestructura. 🎉"
  elif [ $PUNTOS -ge 80 ]; then
      echo "✅ APROBADO - Buen trabajo, pero revisa los puntos fallados."
  elif [ $PUNTOS -ge 50 ]; then
      echo "⚠️  INSUFICIENTE - Revisa los servicios y la configuración de red."
  else
      echo "❌ NO APTO - Vuelve a leer el ticket y corrige los problemas básicos."
  fi
  echo "================================================================================="
  _EOF_
  chmod +x /tmp/script_Validacao.sh
  bash /tmp/script_Validacao.sh
Vagrant: |-
  # -*- mode: ruby -*-
  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    # Caja base común (Rocky Linux 9 / KVM)
    config.vm.box = "generic/rocky9"

    # Configuración por defecto para todas las VMs (libvirt)
    config.vm.provider :libvirt do |libvirt|
      libvirt.memory = 1024
      libvirt.cpus   = 1
    end

    # ==============================================================
    # 1. SERVIDOR DNS + CHRONY + SSH (puerto 2222)
    # ==============================================================
    config.vm.define "dns01" do |dns|
      dns.vm.hostname = "dns01.corp.internal"
      dns.vm.network "private_network", ip: "192.168.100.53"

      dns.vm.provision "shell", inline: <<-SHELL
        set -e
        echo "=== Configurando dns01 ==="

        # Paquetes
        dnf install -y bind bind-utils chrony vim net-tools tcpdump

        # Hostname estático
        hostnamectl set-hostname dns01.corp.internal

        # /etc/hosts con todas las máquinas
        cat >> /etc/hosts << EOF
  192.168.100.20  web01.corp.internal  web01
  192.168.100.21  web02.corp.internal  web02
  192.168.100.53  dns01.corp.internal  dns01
  EOF

        # ----------------------------------------------------------
        # BIND (named) - zona directa e inversa
        # ----------------------------------------------------------
        cat > /var/named/corp.internal.db << 'ZONE'
  $TTL 86400
  @   IN  SOA dns01.corp.internal. admin.corp.internal. (
              2026060801 3600 1800 604800 86400 )
          IN  NS   dns01.corp.internal.

  dns01   IN  A    192.168.100.53
  web01   IN  A    192.168.100.20
  web02   IN  A    192.168.100.21
  ZONE

        cat > /var/named/100.168.192.in-addr.arpa.db << 'RZONE'
  $TTL 86400
  @   IN  SOA dns01.corp.internal. admin.corp.internal. (
              2026060801 3600 1800 604800 86400 )
          IN  NS  dns01.corp.internal.

  20  IN  PTR web01.corp.internal.
  21  IN  PTR web02.corp.internal.
  53  IN  PTR dns01.corp.internal.
  RZONE

        chown named:named /var/named/corp.internal.db
        chown named:named /var/named/100.168.192.in-addr.arpa.db
        chmod 640 /var/named/corp.internal.db
        chmod 640 /var/named/100.168.192.in-addr.arpa.db

        cat > /etc/named.conf << 'NAMEDCONF'
  options {
      listen-on port 53 { 127.0.0.1; 192.168.100.53; };
      listen-on-v6 { none; };
      directory       "/var/named";
      allow-query     { any; };
      recursion       no;
  };

  zone "corp.internal" IN {
      type master;
      file "corp.internal.db";
  };

  zone "100.168.192.in-addr.arpa" IN {
      type master;
      file "100.168.192.in-addr.arpa.db";
  };
  NAMEDCONF

        systemctl enable named
        systemctl restart named

        # ----------------------------------------------------------
        # Chrony (NTP)
        # ----------------------------------------------------------
        cat > /etc/chrony.conf << 'CHRONY'
  pool pool.ntp.org iburst
  driftfile /var/lib/chrony/drift
  makestep 1.0 3
  rtcsync
  CHRONY
        systemctl enable chronyd
        systemctl start chronyd

        # ----------------------------------------------------------
        # SSH en puerto 2222
        # ----------------------------------------------------------
        sed -i '/^Port /d' /etc/ssh/sshd_config
        echo "Port 2222" >> /etc/ssh/sshd_config
        systemctl restart sshd

        # ----------------------------------------------------------
        # IPTables básicas (permisivo)
        # ----------------------------------------------------------
        iptables -F
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -p tcp --dport 53 -j ACCEPT
        iptables -A INPUT -p udp --dport 53 -j ACCEPT
        iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
        iptables -A INPUT -p udp --dport 123 -j ACCEPT
        iptables -A INPUT -p icmp -j ACCEPT

        echo "=== dns01 listo ==="
      SHELL
    end

    # ==============================================================
    # 2. SERVIDOR WEB 01 (nginx)
    # ==============================================================
    config.vm.define "web01" do |web|
      web.vm.hostname = "web01.corp.internal"
      web.vm.network "private_network", ip: "192.168.100.20"

      web.vm.provision "shell", inline: <<-SHELL
        set -e
        echo "=== Configurando web01 ==="

        dnf install -y nginx curl vim net-tools

        hostnamectl set-hostname web01.corp.internal

        cat >> /etc/hosts << EOF
  192.168.100.20  web01.corp.internal  web01
  192.168.100.21  web02.corp.internal  web02
  192.168.100.53  dns01.corp.internal  dns01
  EOF

        # Apuntar resolución DNS al servidor dns01
        echo "nameserver 192.168.100.53" > /etc/resolv.conf
        # Opcional: evitar que NetworkManager sobrescriba
        chattr +i /etc/resolv.conf 2>/dev/null || true

        # Página web personalizada
        cat > /usr/share/nginx/html/index.html << 'HTML'
  <!DOCTYPE html>
  <html>
  <head><title>Web01</title></head>
  <body>
  <h1>Servidor Web01</h1>
  <p>Hostname: web01.corp.internal</p>
  <p>IP: 192.168.100.20</p>
  </body>
  </html>
  HTML

        # Configuración de nginx escuchando en su IP
        cat > /etc/nginx/nginx.conf << 'NGINX'
  user nginx;
  worker_processes auto;
  error_log /var/log/nginx/error.log;
  pid /run/nginx.pid;

  events {
      worker_connections 1024;
  }

  http {
      include       /etc/nginx/mime.types;
      default_type  application/octet-stream;
      sendfile      on;
      keepalive_timeout 65;

      server {
          listen       192.168.100.20:80;
          server_name  web01.corp.internal;
          root         /usr/share/nginx/html;
          index        index.html;
      }
  }
  NGINX

        systemctl enable nginx
        systemctl restart nginx

        # SSH puerto 2222
        sed -i '/^Port /d' /etc/ssh/sshd_config
        echo "Port 2222" >> /etc/ssh/sshd_config
        systemctl restart sshd

        # IPTables
        iptables -F
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
        iptables -A INPUT -p icmp -j ACCEPT

        echo "=== web01 listo ==="
      SHELL
    end

    # ==============================================================
    # 3. SERVIDOR WEB 02 (nginx)
    # ==============================================================
    config.vm.define "web02" do |web|
      web.vm.hostname = "web02.corp.internal"
      web.vm.network "private_network", ip: "192.168.100.21"

      web.vm.provision "shell", inline: <<-SHELL
        set -e
        echo "=== Configurando web02 ==="

        dnf install -y nginx curl vim net-tools

        hostnamectl set-hostname web02.corp.internal

        cat >> /etc/hosts << EOF
  192.168.100.20  web01.corp.internal  web01
  192.168.100.21  web02.corp.internal  web02
  192.168.100.53  dns01.corp.internal  dns01
  EOF

        echo "nameserver 192.168.100.53" > /etc/resolv.conf
        chattr +i /etc/resolv.conf 2>/dev/null || true

        cat > /usr/share/nginx/html/index.html << 'HTML'
  <!DOCTYPE html>
  <html>
  <head><title>Web02</title></head>
  <body>
  <h1>Servidor Web02</h1>
  <p>Hostname: web02.corp.internal</p>
  <p>IP: 192.168.100.21</p>
  </body>
  </html>
  HTML

        cat > /etc/nginx/nginx.conf << 'NGINX'
  user nginx;
  worker_processes auto;
  error_log /var/log/nginx/error.log;
  pid /run/nginx.pid;

  events {
      worker_connections 1024;
  }

  http {
      include       /etc/nginx/mime.types;
      default_type  application/octet-stream;
      sendfile      on;
      keepalive_timeout 65;

      server {
          listen       192.168.100.21:80;
          server_name  web02.corp.internal;
          root         /usr/share/nginx/html;
          index        index.html;
      }
  }
  NGINX

        systemctl enable nginx
        systemctl restart nginx

        sed -i '/^Port /d' /etc/ssh/sshd_config
        echo "Port 2222" >> /etc/ssh/sshd_config
        systemctl restart sshd

        iptables -F
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
        iptables -A INPUT -p icmp -j ACCEPT

        echo "=== web02 listo ==="
      SHELL
    end
  end
---

[[Laboratorios del LFCS]]
---
During this lab exercise, I worked through a simulated infrastructure incident where a network migration from `10.0.0.0/24` to `192.168.100.0/24` had left several critical services non-operational.

I started by correcting the system hostname. Since the environment was a container rather than a full VM, `hostnamectl` was restricted, so I handled it by editing `/etc/hostname` directly and applying the change to the runtime with the `hostname` command — adapting my approach based on what the environment actually allowed.

Next, I enabled IPv6 on the web interface. The issue was that `net.ipv6.conf.dummy0.disable_ipv6` had been set to `1` at the kernel level via sysctl. I cleared it at runtime with `sysctl -w` and persisted the change in `/etc/sysctl.conf`, then successfully assigned the `fd00:dead:beef::20/64` address to the interface.

For nginx, the service was simply stopped. I started and enabled it, then validated that both IPv4 and IPv6 HTTP responses returned the expected corporate portal content.

On the firewall side, `iptables` had a DROP policy with only ping allowed. I added ACCEPT rules for ports 80, 2222, 53 (TCP/UDP), and 123 (UDP) to restore access to all critical services.

The DNS issue required editing the BIND zone file at `/var/named/corp.internal.db`. The `web01` A record was pointing to the old IP `10.0.0.99`, and the AAAA record contained a documentation address `2001:db8::bad`. I corrected both to `192.168.100.20` and `fd00:dead:beef::20`, incremented the SOA serial, and restarted `named`. Post-fix, `dig` confirmed correct resolution.

For SSH, I updated `/etc/ssh/sshd_config` to move the listening port from `2223` to `2222` and restarted the daemon. Connectivity was confirmed locally.

Finally, with `chronyd`, I identified that a systemd override was passing the `-x` flag, which disables clock adjustment. In a real VM this would be the fix to remove — however, in this containerized environment the kernel blocks `adjtimex` calls entirely, meaning `-x` is actually required. This was a good example of understanding _why_ a configuration exists before changing it.

The final validated score was **75/100**, with the remaining points blocked by container-level restrictions on SSH external connectivity and NTP clock adjustment — both confirmed as environment limitations rather than misconfiguration on my part.