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
  set -e

  if [ "$EUID" -ne 0 ]; then
      echo "Ejecutar como root"
      exit 1
  fi

  # ============================================================
  # LIMPIEZA PREVIA
  # ============================================================
  echo "[INFO] Limpiando entorno anterior..."
  for ns in admin-client web01 dns01; do
      ip netns del $ns 2>/dev/null || true
  done
  ip link del corp-br0 2>/dev/null || true

  # Matar procesos que puedan haber quedado de corridas anteriores
  pkill -f "nginx" 2>/dev/null || true
  pkill -f "named" 2>/dev/null || true
  pkill -f "chronyd" 2>/dev/null || true
  pkill -f "sshd" 2>/dev/null || true

  # ============================================================
  # INSTALAR DEPENDENCIAS
  # ============================================================
  echo "[INFO] Instalando paquetes necesarios..."
  dnf install -y nginx bind bind-utils chrony openssh-server iputils iproute 2>/dev/null

  # Asegurarse de que nginx NO corre en el host (solo correrá en el namespace)
  systemctl stop nginx 2>/dev/null || true
  systemctl disable nginx 2>/dev/null || true

  # ============================================================
  # CREAR NAMESPACES
  # ============================================================
  echo "[INFO] Creando namespaces..."
  ip netns add admin-client
  ip netns add web01
  ip netns add dns01

  # ============================================================
  # BRIDGE
  # ============================================================
  echo "[INFO] Configurando bridge corp-br0..."
  ip link add corp-br0 type bridge
  ip link set dev corp-br0 address 02:00:00:00:00:01
  ip link set corp-br0 down
  ip addr replace 192.168.100.1/24 dev corp-br0
  ip -6 addr add fd00:dead:beef::1/64 dev corp-br0 2>/dev/null || true
  ip link set corp-br0 up

  # Habilitar IPv6 en el bridge
  sysctl -w net.ipv6.conf.corp-br0.disable_ipv6=0 >/dev/null

  # ============================================================
  # VETH PAIRS + IPs
  # ============================================================
  echo "[INFO] Creando veth pairs..."

  # admin-client
  ip link add veth-adm type veth peer name eth0 netns admin-client
  ip link set veth-adm master corp-br0
  ip link set veth-adm up
  ip netns exec admin-client ip link set lo up
  ip netns exec admin-client ip link set eth0 up
  ip netns exec admin-client sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
  ip netns exec admin-client sysctl -w net.ipv6.conf.eth0.disable_ipv6=0 >/dev/null
  ip netns exec admin-client ip addr add 192.168.100.10/24 dev eth0
  ip netns exec admin-client ip -6 addr add fd00:dead:beef::10/64 dev eth0
  ip netns exec admin-client ip route add default via 192.168.100.1

  # web01
  ip link add veth-web type veth peer name eth0 netns web01
  ip link set veth-web master corp-br0
  ip link set veth-web up
  ip netns exec web01 ip link set lo up
  ip netns exec web01 ip link set eth0 up
  ip netns exec web01 sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
  ip netns exec web01 sysctl -w net.ipv6.conf.eth0.disable_ipv6=0 >/dev/null
  ip netns exec web01 ip addr add 192.168.100.20/24 dev eth0
  ip netns exec web01 ip -6 addr add fd00:dead:beef::20/64 dev eth0
  ip netns exec web01 ip route add default via 192.168.100.1

  # dns01
  ip link add veth-dns type veth peer name eth0 netns dns01
  ip link set veth-dns master corp-br0
  ip link set veth-dns up
  ip netns exec dns01 ip link set lo up
  ip netns exec dns01 ip link set eth0 up
  ip netns exec dns01 sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
  ip netns exec dns01 sysctl -w net.ipv6.conf.eth0.disable_ipv6=0 >/dev/null
  ip netns exec dns01 ip addr add 192.168.100.53/24 dev eth0
  ip netns exec dns01 ip -6 addr add fd00:dead:beef::53/64 dev eth0
  ip netns exec dns01 ip route add default via 192.168.100.1

  # ============================================================
  # HOSTNAME
  # ============================================================
  ip netns exec web01 hostname web01.corp.internal
  echo "web01.corp.internal" | ip netns exec web01 tee /etc/hostname >/dev/null

  ip netns exec dns01 hostname dns01.corp.internal
  echo "dns01.corp.internal" | ip netns exec dns01 tee /etc/hostname >/dev/null

  # ============================================================
  # /etc/hosts en cada namespace
  # ============================================================
  for ns in web01 dns01 admin-client; do
      ip netns exec $ns bash -c "cat > /etc/hosts << 'HOSTS'
  127.0.0.1   localhost
  ::1         localhost
  192.168.100.20  web01.corp.internal web01
  192.168.100.53  dns01.corp.internal dns01
  HOSTS"
  done

  # ============================================================
  # NGINX dentro del namespace web01
  # ============================================================
  echo "[INFO] Configurando nginx en web01..."

  # Crear directorio de logs y PID para nginx en namespace
  mkdir -p /var/log/nginx /run

  # Contenido web corporativo
  cat > /usr/share/nginx/html/index.html << 'HTML'
  <!DOCTYPE html>
  <html lang="es">
  <head>
      <meta charset="UTF-8">
      <title>Portal Corporativo - Corp Internal</title>
      <style>
          body { font-family: sans-serif; background: #f0f4f8; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
          .card { background: white; border-radius: 8px; padding: 40px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); text-align: center; }
          h1 { color: #2c5282; } p { color: #4a5568; }
          .badge { background: #48bb78; color: white; padding: 4px 12px; border-radius: 20px; font-size: 0.85em; }
      </style>
  </head>
  <body>
      <div class="card">
          <h1>Portal Corporativo</h1>
          <p>Bienvenido a <strong>web01.corp.internal</strong></p>
          <p><span class="badge">OPERATIVO</span></p>
          <p style="font-size:0.8em;color:#a0aec0;">192.168.100.20 | fd00:dead:beef::20</p>
      </div>
  </body>
  </html>
  HTML

  # Config nginx para escuchar en IP del namespace
  cat > /etc/nginx/nginx.conf << 'NGINXCONF'
  user nginx;
  worker_processes 1;
  error_log /var/log/nginx/error.log;
  pid /run/nginx-web01.pid;

  events {
      worker_connections 128;
  }

  http {
      include       /etc/nginx/mime.types;
      default_type  application/octet-stream;
      access_log    /var/log/nginx/access.log;
      sendfile      on;
      keepalive_timeout 65;

      server {
          listen 192.168.100.20:80;
          listen [fd00:dead:beef::20]:80;
          server_name web01.corp.internal;
          root /usr/share/nginx/html;
          index index.html;

          location / {
              try_files $uri $uri/ =404;
          }
      }
  }
  NGINXCONF

  # Esperar a que la IPv6 esté completamente disponible
  sleep 1
  ip netns exec web01 ip -6 addr show eth0 | grep -q "fd00:dead:beef::20" || {
      echo "[WARN] IPv6 no asignada aún, reintentando..."
      ip netns exec web01 ip -6 addr add fd00:dead:beef::20/64 dev eth0 2>/dev/null || true
      sleep 1
  }

  # Iniciar nginx dentro del namespace web01
  ip netns exec web01 /usr/sbin/nginx -c /etc/nginx/nginx.conf
  echo "[OK] nginx iniciado en web01"

  # ============================================================
  # SSHD en web01 (puerto 2222)
  # ============================================================
  echo "[INFO] Configurando sshd en web01 (puerto 2222)..."

  # Generar host keys si no existen
  [ ! -f /etc/ssh/ssh_host_rsa_key ] && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' -q
  [ ! -f /etc/ssh/ssh_host_ed25519_key ] && ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' -q

  cat > /etc/ssh/sshd_config.web01 << 'SSHDCONF'
  Port 2222
  ListenAddress 192.168.100.20
  HostKey /etc/ssh/ssh_host_rsa_key
  HostKey /etc/ssh/ssh_host_ed25519_key
  PermitRootLogin yes
  PasswordAuthentication yes
  PidFile /run/sshd-web01.pid
  SSHDCONF

  ip netns exec web01 /usr/sbin/sshd -f /etc/ssh/sshd_config.web01
  echo "[OK] sshd iniciado en web01 en puerto 2222"

  # ============================================================
  # BIND (named) en dns01
  # ============================================================
  echo "[INFO] Configurando BIND en dns01..."

  mkdir -p /var/named

  # Zona directa corp.internal
  cat > /var/named/corp.internal.db << 'ZONE'
  $TTL 86400
  @   IN  SOA dns01.corp.internal. admin.corp.internal. (
              2026060801  ; Serial
              3600        ; Refresh
              1800        ; Retry
              604800      ; Expire
              86400 )     ; Minimum TTL

      IN  NS  dns01.corp.internal.

  dns01   IN  A       192.168.100.53
  dns01   IN  AAAA    fd00:dead:beef::53
  web01   IN  A       192.168.100.20
  web01   IN  AAAA    fd00:dead:beef::20
  ZONE

  # Zona reversa 192.168.100.x
  cat > /var/named/100.168.192.in-addr.arpa.db << 'RZONE'
  $TTL 86400
  @   IN  SOA dns01.corp.internal. admin.corp.internal. (
              2026060801 3600 1800 604800 86400 )
      IN  NS  dns01.corp.internal.

  20  IN  PTR web01.corp.internal.
  53  IN  PTR dns01.corp.internal.
  RZONE

  # Config named
  cat > /etc/named.web01.conf << 'NAMEDCONF'
  options {
      listen-on     { 192.168.100.53; };
      listen-on-v6  { fd00:dead:beef::53; };
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

  chown -R named:named /var/named 2>/dev/null || true

  ip netns exec dns01 /usr/sbin/named -c /etc/named.web01.conf -u named 2>/dev/null || \
  ip netns exec dns01 /usr/sbin/named -c /etc/named.web01.conf
  echo "[OK] named iniciado en dns01"

  # ============================================================
  # CHRONYD en web01
  # ============================================================
  echo "[INFO] Configurando chronyd en web01..."

  cat > /etc/chrony.web01.conf << 'CHRONYCONF'
  server time.cloudflare.com iburst
  server pool.ntp.org iburst
  driftfile /var/lib/chrony/drift-web01
  makestep 1.0 3
  rtcsync
  bindaddress 192.168.100.20
  CHRONYCONF

  mkdir -p /var/lib/chrony
  ip netns exec web01 /usr/sbin/chronyd -f /etc/chrony.web01.conf
  echo "[OK] chronyd iniciado en web01"

  # ============================================================
  # IPTABLES en web01 (reglas base permisivas para servicios)
  # ============================================================
  echo "[INFO] Configurando iptables en web01..."
  ip netns exec web01 iptables -F
  ip netns exec web01 iptables -P INPUT ACCEPT
  ip netns exec web01 iptables -P OUTPUT ACCEPT
  ip netns exec web01 iptables -P FORWARD ACCEPT

  # Reglas explícitas por servicio
  ip netns exec web01 iptables -A INPUT -i lo -j ACCEPT
  ip netns exec web01 iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  ip netns exec web01 iptables -A INPUT -p tcp --dport 80   -j ACCEPT
  ip netns exec web01 iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
  ip netns exec web01 iptables -A INPUT -p udp --dport 123  -j ACCEPT
  ip netns exec web01 iptables -A INPUT -p icmp -j ACCEPT
  echo "[OK] iptables configurado en web01"

  # ============================================================
  # ACCESOS RÁPIDOS (ssh-web01, ssh-dns01, ssh-admin)
  # ============================================================
  mkdir -p /tmp/bin
  for ns in admin-client web01 dns01; do
      printf "#!/bin/bash\nip netns exec %s bash\n" "$ns" > /tmp/bin/ssh-$ns
      chmod +x /tmp/bin/ssh-$ns
  done

  if ! grep -q '/tmp/bin' ~/.bashrc; then
      echo 'export PATH=/tmp/bin:$PATH' >> ~/.bashrc
  fi
  export PATH=/tmp/bin:$PATH

  # ============================================================
  # VERIFICACIÓN FINAL
  # ============================================================
  echo ""
  echo "========================================"
  echo " ESTADO DEL DESPLIEGUE"
  echo "========================================"
  echo -n "[web01] nginx:   "; ip netns exec web01 pgrep -x nginx  >/dev/null && echo "OK" || echo "FAIL"
  echo -n "[web01] sshd:    "; ip netns exec web01 pgrep -x sshd   >/dev/null && echo "OK" || echo "FAIL"
  echo -n "[web01] chronyd: "; ip netns exec web01 pgrep -x chronyd >/dev/null && echo "OK" || echo "FAIL"
  echo -n "[dns01] named:   "; ip netns exec dns01 pgrep -x named  >/dev/null && echo "OK" || echo "FAIL"
  echo ""
  echo -n "[web01] IPv4 HTTP: "; curl -s --max-time 2 http://192.168.100.20/ | grep -q "Portal" && echo "OK" || echo "FAIL"
  echo -n "[web01] SSH port:  "; ip netns exec web01 ss -tlnp | grep -q 2222 && echo "2222 OK" || echo "FAIL"
  echo -n "[dns01] A record:  "
  ip netns exec dns01 /usr/bin/dig web01.corp.internal @192.168.100.53 +short 2>/dev/null | grep -q "192.168.100.20" && echo "OK" || echo "FAIL"
  echo ""
  echo "[INFO] Despliegue completado."
  echo "[INFO] Accesos: ssh-web01 | ssh-dns01 | ssh-admin"
  echo "========================================"

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
