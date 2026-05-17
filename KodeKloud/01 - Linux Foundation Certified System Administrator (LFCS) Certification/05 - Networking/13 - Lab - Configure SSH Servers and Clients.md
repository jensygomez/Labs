---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Lab - Configure SSH Servers and Clients
Typo: Laboratorio
Fecha: 07/05/2026
Estado: completado
Dificultad: Intermedio-Baja
Calificación: 8,3 %
Time: 40 min
tags:
  - "#Linux/LFCS-Certification/Networking"
  - "#Linux/LFCS-Certification/Networking/Laboratorio"
---

## SSH Server y Squid Proxy - Configuración Avanzada

Este laboratorio abarcó la configuración integral del servidor SSH y el proxy Squid en Rocky Linux. Se realizaron modificaciones críticas en `/etc/ssh/sshd_config` para mejorar la seguridad del servidor, incluyendo la deshabilitación de logins por contraseña, restricción de acceso root, limitación de intentos de autenticación a 4 por conexión, y configuración de IPv4. Adicionalmente, se habilitó X11 forwarding en la configuración del cliente SSH (`/etc/ssh/ssh_config`). Cada cambio requirió reiniciar el servicio sshd para aplicar las modificaciones.

La segunda parte del laboratorio se enfocó en configurar Squid como servidor proxy, implementando listas de control de acceso (ACL) y reglas http_access. Se crearon ACLs personalizadas (como "vpn" con IP 203.0.110.5), se negó acceso a redes locales específicas, se bloqueó facebook.com y se permitió acceso a dominios externos. Las reglas en Squid siguen una lógica de "allow/deny" basada en los criterios definidos en las ACLs, permitiendo controlar granularmente quién puede acceder a qué recursos a través del proxy.

## Comandos de ejemplo

```bash
# Editar configuración SSH Server
sudo nano /etc/ssh/sshd_config

# Verificar y aplicar cambios
sudo sshd -t  # Test de sintaxis
sudo systemctl restart sshd

# Editar configuración SSH Client
sudo nano /etc/ssh/ssh_config

# Instalar y habilitar Squid
sudo dnf install squid -y
sudo systemctl start squid
sudo systemctl enable squid

# Editar configuración Squid
sudo nano /etc/squid/squid.conf

# Recargar configuración Squid
sudo systemctl reload squid
```

