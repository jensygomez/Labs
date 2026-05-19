---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Port Redirection and Network Address Translation (NAT)
Typo: Video
Fecha: 05/05/2026
Estado: completado
Dificultad: Intermedio-Alto
Calificación:
Time: 30 min
tags:
  - "#Linux/LFCS-Certification/Networking"
---

## Resumen

Port Redirection y NAT son técnicas fundamentales que permiten exponer servicios privados a través de una interfaz pública. El concepto central es que los puertos privados de un servidor pueden ser redirigidos a través de una puerta de enlace (gateway) hacia internet, utilizando técnicas de encapsulación de paquetes. NAT (Network Address Translation) actúa modificando las direcciones IP de origen y destino en los paquetes, permitiendo que una red privada se comunique con el exterior como si fuera una única entidad. La técnica de "masquerading" es clave aquí: el servidor actúa como intermediario, haciendo que el tráfico externo parezca originarse desde la puerta de enlace en lugar de desde máquinas internas.

La implementación en Linux requiere activar el IP Forwarding en `/etc/sysctl.conf` o `/etc/sysctl.d/99-sysctl.conf` y utilizar el Netfilter Framework a través del comando `iptables`. Las reglas de NAT se aplican a diferentes chains (PREROUTING, POSTROUTING, FORWARD), permitiendo un control granular del flujo de tráfico. Para que estas reglas persistan tras reinicios del sistema, es necesario instalar `iptables-persistent`, que guarda las configuraciones de forma permanente. Este conocimiento es crítico para administrar servidores con múltiples interfaces de red o para implementar gateways corporativos.

## Ejemplos de comandos

```bash
# Activar IP Forwarding (temporal)
sudo sysctl -w net.ipv4.ip_forward=1

# Activar IP Forwarding (permanente)
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl --system

# Configurar MASQUERADING en interfaz externa
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -J MASQUERADE

# Ver tabla de rutas y gateway
ip route show
# Salida: default via 192.168.1.1 dev eth0 proto dhcp src 192.168.1.100 metric 100

# Listar reglas NAT actuales
sudo iptables -t nat -L -n -v

# Instalar iptables-persistent para persistencia
sudo apt install iptables-persistent

# Guardar reglas de iptables (si ya está instalado)
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```
