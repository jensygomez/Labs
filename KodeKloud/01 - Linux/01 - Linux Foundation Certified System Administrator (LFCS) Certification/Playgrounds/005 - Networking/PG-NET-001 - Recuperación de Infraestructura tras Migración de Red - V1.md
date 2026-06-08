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
Script:
Script Validacion:
---

[[Laboratorios del LFCS]]
---
