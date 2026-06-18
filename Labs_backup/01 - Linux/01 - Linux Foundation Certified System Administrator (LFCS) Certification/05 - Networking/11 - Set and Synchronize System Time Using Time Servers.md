---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Set and Synchronize System Time Using Time Servers
Typo: Video
Fecha: 06/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 10 min
tags:
---

La sincronización de la hora en sistemas Linux es fundamental para el correcto funcionamiento de aplicaciones, logs y servicios. Diferentes máquinas y zonas horarias pueden causar desincronización, por lo que es necesario establecer servidores NTP (Network Time Protocol) confiables. La utilidad `timedatectl` permite gestionar tanto la zona horaria como la sincronización automática de la hora del sistema.

Para configurar manualmente el servidor NTP, se accede al archivo de configuración de systemd-timesyncd. Este servicio se encarga de mantener sincronizado el reloj del sistema con servidores de tiempo remotos. Es importante verificar que el servicio esté activo y que los servidores NTP configurados sean alcanzables desde la red del sistema.

**Ejemplo de comandos básicos:**

bash

```bash
# Ver estado actual de la hora y zona horaria
timedatectl

# Establecer zona horaria
sudo timedatectl set-timezone America/Los_Angeles

# Editar configuración de servidor NTP
sudo vim /etc/systemd/timesyncd.conf

# Reiniciar servicio de sincronización
sudo systemctl restart systemd-timesyncd

# Verificar sincronización
timedatectl show-timesync
```

