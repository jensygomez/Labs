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

  # Limpieza previa
  for ns in admin-client web01 dns01; do
      ip netns del $ns 2>/dev/null || true
  done
  ip link del corp-br0 2>/dev/null || true

  # Instalar iputils (ping) si no existe
  if ! command -v ping &>/dev/null; then
      echo "[INFO] Instalando ping..."
      yum install -y iputils
  fi

  # Crear namespaces
  ip netns add admin-client
  ip netns add web01
  ip netns add dns01

  # Bridge
  ip link add corp-br0 type bridge
  ip link set dev corp-br0 address 02:00:00:00:00:01
  ip link set corp-br0 down
  ip addr replace 192.168.100.1/24 dev corp-br0
  ip link set corp-br0 up

  # Crear veths
  ip link add veth-adm type veth peer name eth0 netns admin-client
  ip link set veth-adm master corp-br0
  ip link set veth-adm up

  ip link add veth-web type veth peer name eth0 netns web01
  ip link set veth-web master corp-br0
  ip link set veth-web up

  ip link add veth-dns type veth peer name eth0 netns dns01
  ip link set veth-dns master corp-br0
  ip link set veth-dns up

  # Configurar IPs
  ip netns exec admin-client ip addr add 192.168.100.10/24 dev eth0
  ip netns exec admin-client ip link set lo up
  ip netns exec admin-client ip link set eth0 up
  ip netns exec admin-client ip route add default via 192.168.100.1

  ip netns exec web01 ip addr add 192.168.100.20/24 dev eth0
  ip netns exec web01 ip link set lo up
  ip netns exec web01 ip link set eth0 up
  ip netns exec web01 ip route add default via 192.168.100.1

  ip netns exec dns01 ip addr add 192.168.100.53/24 dev eth0
  ip netns exec dns01 ip link set lo up
  ip netns exec dns01 ip link set eth0 up
  ip netns exec dns01 ip route add default via 192.168.100.1

  # Accesos rápidos (Corregido sin cat anidado)
  mkdir -p /tmp/bin
  for ns in admin-client web01 dns01; do
      printf "#!/bin/bash\nip netns exec %s bash\n" "$ns" > /tmp/bin/ssh-$ns
      chmod +x /tmp/bin/ssh-$ns
  done

  # Evitar duplicar PATH en .bashrc
  if ! grep -q '/tmp/bin' ~/.bashrc; then
      echo 'export PATH=/tmp/bin:$PATH' >> ~/.bashrc
  fi
  export PATH=/tmp/bin:$PATH

  echo "Despliegue exitoso"
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
