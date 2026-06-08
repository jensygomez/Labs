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
  cat > /etc/systemd/system/chronyd.service.d/override.conf << 'EOF'
  [Service]
  ExecStart=
  ExecStart=/usr/sbin/chronyd -x $OPTIONS
  EOF

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
  cat << 'EOF' > /tmp/script_break.sh
  #!/bin/bash

  set -e

  if [ "$EUID" -ne 0 ]; then
      echo "Ejecutar como root"
      exit 1
  fi

  # Verificar que los namespaces existen
  for ns in admin-client web01 dns01; do
      if ! ip netns list | grep -q "$ns"; then
          echo "[ERROR] El namespace $ns no existe. Ejecuta primero lfcs-net-base.sh"
          exit 1
      fi
  done

  echo "[BREAK] Aplicando fallos controlados para el laboratorio..."

  # ============================================
  # 1. DETENER SERVICIOS (sin systemctl)
  # ============================================
  ip netns exec web01 pkill -f nginx 2>/dev/null || true
  ip netns exec dns01 pkill -f named 2>/dev/null || true
  ip netns exec web01 pkill -f chronyd 2>/dev/null || true

  # ============================================
  # 2. CAMBIAR PUERTO SSH
  # ============================================
  ip netns exec web01 sed -i 's/^Port 2222/Port 2223/' /etc/ssh/sshd_config 2>/dev/null || true
  ip netns exec web01 /usr/sbin/sshd 2>/dev/null || true

  # ============================================
  # 3. HOSTNAME INCORRECTO
  # ============================================
  ip netns exec web01 hostname broken-web 2>/dev/null || true

  # ============================================
  # 4. CORROMPER DNS (cambiar IP de web01)
  # ============================================
  ip netns exec dns01 bash -c "
  if [ -f /var/named/corp.internal.db ]; then
      sed -i 's/192.168.100.20/10.0.0.99/' /var/named/corp.internal.db
      sed -i 's/fd00:dead:beef::20/2001:db8::bad/' /var/named/corp.internal.db
      pkill -HUP named 2>/dev/null || true
  fi
  "

  # ============================================
  # 5. FIREWALL ULTRARRESTRICTIVO (solo ping)
  # ============================================
  ip netns exec web01 iptables -F
  ip netns exec web01 iptables -P INPUT DROP
  ip netns exec web01 iptables -P FORWARD DROP
  ip netns exec web01 iptables -P OUTPUT DROP
  ip netns exec web01 iptables -A INPUT -i lo -j ACCEPT
  ip netns exec web01 iptables -A OUTPUT -o lo -j ACCEPT
  ip netns exec web01 iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
  ip netns exec web01 iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

  # ============================================
  # 6. DESHABILITAR IPv6 EN EL BRIDGE
  # ============================================
  sysctl -w net.ipv6.conf.corp-br0.disable_ipv6=1 >/dev/null

  # ============================================
  # 7. PÁGINA WEB DE ERROR
  # ============================================
  ip netns exec web01 bash -c "echo '503 Servicio no disponible - Mantenimiento' > /usr/share/nginx/html/index.html 2>/dev/null || true"

  # ============================================
  # 8. MOSTRAR TICKET MEJORADO (con historia)
  # ============================================
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🔧 LABORATORIO DE RECUPERACIÓN (PG-NET-001) - MODO BREAK\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-MIGRA-2026\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Migración de red corporativa - Servicios críticos no operativos"
  echo -e " \e[1mSeveridad:\e[0m Alta"
  echo -e " \e[1mFecha:\e[0m 2026-06-08"
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m 📖 CONTEXTO DEL INCIDENTE:\e[0m"
  echo -e ""
  echo -e "   El área de infraestructura realizó una migración planificada de toda la red"
  echo -e "   corporativa desde el rango 10.0.0.0/24 a 192.168.100.0/24 e implementación"
  echo -e "   de IPv6 (fd00:dead:beef::/64) por requisitos de crecimiento y compliance."
  echo -e ""
  echo -e "   Durante la ventana de mantenimiento (02:00 - 04:00 UTC), se reconfiguraron"
  echo -e "   los namespaces de red, el bridge y los veths. Sin embargo, al finalizar,"
  echo -e "   varios servicios críticos no responden según lo esperado:"
  echo -e ""
  echo -e "     - El portal web interno (web01) no entrega contenido."
  echo -e "     - El DNS interno (dns01) resuelve con direcciones antiguas."
  echo -e "     - El firewall quedó en modo ultra-restrictivo bloqueando accesos."
  echo -e "     - La sincronización horaria está deshabilitada."
  echo -e "     - El acceso SSH de administración cambió de puerto."
  echo -e ""
  echo -e "   El equipo de operaciones reporta que los desarrolladores no pueden acceder"
  echo -e "   al portal y los logs del sistema muestran errores de conexión. El directorio"
  echo -e "   corporativo exige que el 100% de estos servicios estén operativos antes de"
  echo -e "   las 08:00 UTC. Quedan 90 minutos."
  echo -e ""
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m 🔍 PROBLEMAS DETECTADOS (debes corregir):\e[0m"
  echo -e ""
  echo -e "   ✗ El servidor web no responde (nginx detenido)."
  echo -e "   ✗ IPv6 no funciona (deshabilitado en el bridge)."
  echo -e "   ✗ El hostname no es web01.corp.internal."
  echo -e "   ✗ DNS resuelve web01 a IP incorrecta (10.0.0.99 en lugar de 192.168.100.20)."
  echo -e "   ✗ Servicios named, nginx, chronyd no están activos."
  echo -e "   ✗ SSH escucha en puerto 2223 (debe ser 2222)."
  echo -e "   ✗ Firewall bloquea todo excepto ping."
  echo -e "   ✗ No hay sincronización horaria (chronyd detenido)."
  echo -e "   ✗ La página web muestra error 503."
  echo -e ""
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m ✅ CRITERIOS DE ÉXITO (validación manual):\e[0m"
  echo -e ""
  echo -e "   [ ] web01 responde en IPv4 puerto 80 (curl 192.168.100.20)"
  echo -e "   [ ] web01 responde en IPv6 (curl -6 http://[fd00:dead:beef::20]/)"
  echo -e "   [ ] El hostname del namespace web01 es web01.corp.internal"
  echo -e "   [ ] dig web01.corp.internal @192.168.100.53 → IP 192.168.100.20 y IPv6 correcta"
  echo -e "   [ ] Servicios nginx, named, sshd, chronyd activos y habilitados"
  echo -e "   [ ] Acceso SSH desde admin-client: ssh -p 2222 root@192.168.100.20"
  echo -e "   [ ] Sincronización horaria verificada con chronyc tracking"
  echo -e "   [ ] Reglas iptables permiten tráfico a puertos 80, 2222, 53 (UDP/TCP), 123 (UDP)"
  echo -e "   [ ] curl http://web01.corp.internal/ muestra la página corporativa"
  echo -e ""
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m 🛠️ RECURSOS Y ACCESOS:\e[0m"
  echo -e ""
  echo -e "   • Acceso a namespaces: ssh-admin, ssh-web01, ssh-dns01"
  echo -e "   • El bridge y las rutas IPv4/IPv6 ya están configurados."
  echo -e "   • Herramientas sugeridas: ip, ss, iptables, dig, curl, chronyc, journalctl."
  echo -e ""
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;33m ⏱️ TIEMPO ESTIMADO DE RESOLUCIÓN: 45 minutos\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/script_break.sh && rm -f /tmp/script_break.sh
Script Validacion: |-
  #!/bin/bash
  # Script de validación para laboratorio PG-NET-001 (Recuperación de infraestructura)

  PUNTOS=0
  TOTAL=100

  echo "================================================================================="
  echo "=== VALIDANDO RECUPERACIÓN DE INFRAESTRUCTURA - PG-NET-001                     ==="
  echo "================================================================================="

  # Helper: comprobar si un comando dentro de namespace tiene éxito
  check_ns_cmd() {
      local ns=$1
      local cmd=$2
      ip netns exec "$ns" bash -c "$cmd" &>/dev/null
  }

  # 1. Web responde en IPv4 (10%)
  echo -n "[10%] Comprobando web en IPv4 (192.168.100.20:80) ... "
  if check_ns_cmd admin-client "curl -s -o /dev/null -w '%{http_code}' 192.168.100.20 | grep -q '200'"; then
      echo "✔ OK"
      PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (no responde HTTP 200)"
  fi

  # 2. Web responde en IPv6 (10%)
  echo -n "[10%] Comprobando web en IPv6 (fd00:dead:beef::20:80) ... "
  if check_ns_cmd admin-client "curl -6 -s -o /dev/null -w '%{http_code}' http://[fd00:dead:beef::20]/ | grep -q '200'"; then
      echo "✔ OK"
      PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (no responde IPv6 o no es código 200)"
  fi

  # 3. Hostname correcto (web01.corp.internal) (5%)
  echo -n "[5%] Hostname del namespace web01 ... "
  HOSTNAME=$(ip netns exec web01 hostname 2>/dev/null)
  if [ "$HOSTNAME" = "web01.corp.internal" ]; then
      echo "✔ OK ($HOSTNAME)"
      PUNTOS=$((PUNTOS + 5))
  else
      echo "❌ FALLO (es '$HOSTNAME', debe ser web01.corp.internal)"
  fi

  # 4. Resolución DNS interna (15%)
  echo -n "[15%] Resolución DNS de web01.corp.internal ... "
  DNS_IPV4=$(ip netns exec admin-client dig +short web01.corp.internal @192.168.100.53 2>/dev/null | head -1)
  DNS_IPV6=$(ip netns exec admin-client dig +short AAAA web01.corp.internal @192.168.100.53 2>/dev/null | head -1)
  if [ "$DNS_IPV4" = "192.168.100.20" ] && [ "$DNS_IPV6" = "fd00:dead:beef::20" ]; then
      echo "✔ OK (IPv4 $DNS_IPV4, IPv6 $DNS_IPV6)"
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ FALLO (IPv4: $DNS_IPV4, IPv6: $DNS_IPV6) esperaba 192.168.100.20 y fd00:dead:beef::20"
  fi

  # 5. Servicios críticos activos (nginx, named, sshd, chronyd) (10%)
  echo -n "[10%] Servicios activos en web01 y dns01 ... "
  SERVICIOS_OK=0
  check_ns_cmd web01 "systemctl is-active nginx --quiet" && SERVICIOS_OK=$((SERVICIOS_OK+1))
  check_ns_cmd web01 "systemctl is-active sshd --quiet" && SERVICIOS_OK=$((SERVICIOS_OK+1))
  check_ns_cmd web01 "systemctl is-active chronyd --quiet" && SERVICIOS_OK=$((SERVICIOS_OK+1))
  check_ns_cmd dns01 "systemctl is-active named --quiet" && SERVICIOS_OK=$((SERVICIOS_OK+1))
  if [ $SERVICIOS_OK -eq 4 ]; then
      echo "✔ OK (nginx, sshd, chronyd, named activos)"
      PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (solo $SERVICIOS_OK/4 servicios activos)"
  fi

  # 6. Acceso SSH en puerto corporativo 2222 (15%)
  echo -n "[15%] SSH en puerto 2222 desde admin-client a web01 ... "
  if check_ns_cmd admin-client "timeout 3 ssh -o StrictHostKeyChecking=no -p 2222 root@192.168.100.20 'exit' 2>/dev/null"; then
      echo "✔ OK"
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ FALLO (no se pudo conectar en puerto 2222)"
  fi

  # 7. Sincronización horaria (chronyd) (10%)
  echo -n "[10%] Sincronización horaria en web01 ... "
  if check_ns_cmd web01 "chronyc tracking | grep -q 'Leap status.*Normal'"; then
      echo "✔ OK"
      PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (chronyd no sincronizado o no activo)"
  fi

  # 8. Firewall cumple política (permite 80,2222,53,123) (15%)
  echo -n "[15%] Política de firewall en web01 ... "
  WEB01_FW=$(ip netns exec web01 iptables -S INPUT)
  if echo "$WEB01_FW" | grep -q -- "--dport 80 -j ACCEPT" && \
     echo "$WEB01_FW" | grep -q -- "--dport 2222 -j ACCEPT" && \
     echo "$WEB01_FW" | grep -q -- "--dport 53 -j ACCEPT" && \
     echo "$WEB01_FW" | grep -q -- "--dport 123 -j ACCEPT"; then
      echo "✔ OK (puertos 80,2222,53,123 permitidos)"
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ FALLO (reglas incompletas o incorrectas)"
  fi

  # 9. Portal web responde contenido esperado (10%)
  echo -n "[10%] Contenido del portal web ... "
  if check_ns_cmd admin-client "curl -s http://192.168.100.20/ | grep -qi 'infraestructura'"; then
      echo "✔ OK (contiene texto esperado)"
      PUNTOS=$((PUNTOS + 10))
  else
      echo "❌ FALLO (página no contiene la palabra 'infraestructura' o similar)"
  fi

  # Resultado final
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
---

[[Laboratorios del LFCS]]
---
