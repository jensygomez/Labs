---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Start, Stop, and Check Status of Network Services
Typo: Video
Fecha: 03/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 9 min
tags:
  - linux
  - lfcs
  - networking
  - systemctl
  - network-services
---
Los servicios de red son programas que se ejecutan en background esperando conexiones en puertos específicos. Para identificar qué servicios están escuchando en tu sistema, utilizamos `sudo ss -ltunp` que nos muestra todos los sockets TCP y UDP activos. Este comando es esencial en troubleshooting de conectividad ya que nos revela qué puertos están abiertos, qué procesos los están utilizando y sus PIDs asociados.

Una vez identificados los servicios en ejecución, es fundamental verificar su estado individual usando `sudo systemctl status [servicio]`. Este comando nos proporciona información detallada: si el servicio está activo o inactivo, desde cuándo está corriendo, su consumo de recursos y logs recientes. Esto es crítico para diagnosticar problemas de conectividad o cuando un servicio necesario no está respondiendo.

**Ejemplo de comando:**

bash

```bash
# Listar todos los servicios escuchando (TCP, UDP, con nombres de procesos)
sudo ss -ltunp

# Verificar el estado de un servicio específico (ej: SSH)
sudo systemctl status ssh

# Alternativa: ver sockets con netstat (deprecated pero aún usado)
netstat -tulpn
```