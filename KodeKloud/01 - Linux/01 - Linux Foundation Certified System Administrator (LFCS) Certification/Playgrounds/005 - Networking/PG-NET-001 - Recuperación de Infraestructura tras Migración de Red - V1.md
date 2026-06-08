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

  # Bridge (con MAC fija opcional)
  ip link add corp-br0 type bridge
  ip link set dev corp-br0 address 02:00:00:00:00:01  # opcional
  ip link set corp-br0 down
  ip addr replace 192.168.100.1/24 dev corp-br0
  ip link set corp-br0 up

  # Crear veths con nombres cortos (máx 15 chars)
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

  # Accesos rápidos
  mkdir -p /tmp/bin
  for ns in admin-client web01 dns01; do
      cat > /tmp/bin/ssh-$ns <<EOF
  #!/bin/bash
  ip netns exec $ns bash
  EOF
      chmod +x /tmp/bin/ssh-$ns
  done
  echo 'export PATH=/tmp/bin:$PATH' >> ~/.bashrc
  export PATH=/tmp/bin:$PATH

  echo "Despliegue exitoso"
Script Break: |-
  cat > /tmp/lab-net-break.sh << 'EOF'

  #!/bin/bash
  set -e

  if [ "$EUID" -ne 0 ]; then
      echo "Ejecutar como root"
      exit 1
  fi

  # Verificar que los namespaces existen
  for ns in admin-client web01 dns01; do
      if ! ip netns list | grep -q "$ns"; then
          echo "[ERROR] El namespace $ns no existe. Ejecuta primero la base de red."
          exit 1
      fi
  done

  echo "[BREAK] Aplicando fallos controlados..."

  # 1. Detener servicios (usando kill o pkill, no systemctl)
  ip netns exec web01 pkill -f nginx 2>/dev/null || true
  ip netns exec dns01 pkill -f named 2>/dev/null || true
  ip netns exec web01 pkill -f chronyd 2>/dev/null || true

  # 2. Cambiar puerto SSH
  ip netns exec web01 sed -i 's/^Port 2222/Port 2223/' /etc/ssh/sshd_config 2>/dev/null || true
  ip netns exec web01 /usr/sbin/sshd 2>/dev/null || true

  # 3. Hostname incorrecto
  ip netns exec web01 hostname broken-web 2>/dev/null || true

  # 4. Romper DNS (si existía la zona)
  ip netns exec dns01 bash -c "
  if [ -f /var/named/corp.internal.db ]; then
      sed -i 's/192.168.100.20/10.0.0.99/' /var/named/corp.internal.db
      sed -i 's/fd00:dead:beef::20/2001:db8::bad/' /var/named/corp.internal.db
      pkill -HUP named 2>/dev/null || true
  fi
  "

  # 5. Firewall restrictivo (solo ping)
  ip netns exec web01 iptables -F
  ip netns exec web01 iptables -P INPUT DROP
  ip netns exec web01 iptables -P FORWARD DROP
  ip netns exec web01 iptables -P OUTPUT DROP
  ip netns exec web01 iptables -A INPUT -i lo -j ACCEPT
  ip netns exec web01 iptables -A OUTPUT -o lo -j ACCEPT
  ip netns exec web01 iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
  ip netns exec web01 iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

  # 6. IPv6 deshabilitado en el bridge
  sysctl -w net.ipv6.conf.corp-br0.disable_ipv6=1 >/dev/null

  # 7. Página web de error
  ip netns exec web01 bash -c "echo '503 Servicio no disponible' > /usr/share/nginx/html/index.html 2>/dev/null || true"

  # Mostrar ticket
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🔧 LABORATORIO DE RECUPERACIÓN (PG-NET-001) - MODO BREAK\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-MIGRA-2026\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Migración de red corporativa - Servicios críticos no operativos"
  echo -e " \e[1mSeveridad:\e[0m Alta"
  echo -e ""
  echo -e " \e[1mProblemas detectados (debes corregir):\e[0m"
  echo -e "   ✗ El servidor web no responde (nginx detenido)."
  echo -e "   ✗ IPv6 no funciona (deshabilitado en el bridge)."
  echo -e "   ✗ El hostname no es web01.corp.internal."
  echo -e "   ✗ DNS resuelve web01 a IP incorrecta."
  echo -e "   ✗ Servicios named, nginx, chronyd no están activos."
  echo -e "   ✗ SSH escucha en puerto 2223 (debe ser 2222)."
  echo -e "   ✗ Firewall bloquea todo excepto ping."
  echo -e "   ✗ No hay sincronización horaria."
  echo -e "   ✗ La página web muestra error 503."
  echo -e ""
  echo -e " \e[1mCriterios de éxito:\e[0m"
  echo -e "  [ ] web01 responde en IPv4 puerto 80"
  echo -e "  [ ] web01 responde en IPv6"
  echo -e "  [ ] hostnamectl set-hostname web01.corp.internal"
  echo -e "  [ ] dig web01.corp.internal @192.168.100.53 → IP correcta"
  echo -e "  [ ] systemctl status nginx, named, sshd, chronyd activos"
  echo -e "  [ ] ssh -p 2222 root@192.168.100.20 funciona"
  echo -e "  [ ] chronyc tracking sincronizado"
  echo -e "  [ ] iptables permite 80,2222,53,123"
  echo -e "  [ ] curl http://web01.corp.internal/ muestra página correcta"
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;33m👉 Accesos:\e[0m ssh-admin, ssh-web01, ssh-dns01"
  echo -e "\e[1;36m================================================================================\e[0m"
  EOF

  chmod +x /tmp/lab-net-break.sh
Script Validacion:
---

[[Laboratorios del LFCS]]
---
