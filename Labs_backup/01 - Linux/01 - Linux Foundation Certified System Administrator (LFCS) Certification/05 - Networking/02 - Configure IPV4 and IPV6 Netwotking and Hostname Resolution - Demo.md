---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Configure IPV4 and IPV6 Netwotking and Hostname Resolution - Demo
Typo: Video
Fecha: 03/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 30 min
tags:
---
El video cubre los fundamentos de configuración de red en Ubuntu, comenzando con el uso de `ip link` para visualizar las interfaces de red (loopback y físicas) y `ip addr` para ver direcciones IP asignadas y estado de conexión. Se explica cómo agregar y eliminar direcciones IP manualmente en las interfaces, teniendo en cuenta que una interfaz puede poseer múltiples direcciones IPv4 e IPv6 simultáneamente, aunque estos cambios son temporales si no se persisten.

Para hacer permanentes las configuraciones de red en Ubuntu, se utiliza Netplan como gestor de configuraciones. El proceso incluye crear un archivo YAML en `/etc/netplan/99-mysettings.yaml` con las configuraciones deseadas, validarlas con `sudo netplan try --timeout 30`, y una vez aplicadas, verificar rutas con `ip route`, DNS con `resolvectl status`, y resolver hostnames editando `/etc/hosts` para navegar por servidores usando nombres en lugar de direcciones IP.

**Ejemplos de comandos:**

bash

```bash
# Ver interfaces de red
ip link
ip addr

# Agregar una dirección IP temporalmente
sudo ip addr add 192.168.1.100/24 dev ensp08

# Levantar una interfaz
sudo ip link set dev ensp08 up

# Ver configuración actual de Netplan
sudo netplan get

# Validar y aplicar cambios de Netplan
sudo netplan try --timeout 30

# Ver tabla de rutas
ip route

# Ver configuración DNS
resolvectl status

# Editar resolución de hostnames
sudo nano /etc/hosts
```