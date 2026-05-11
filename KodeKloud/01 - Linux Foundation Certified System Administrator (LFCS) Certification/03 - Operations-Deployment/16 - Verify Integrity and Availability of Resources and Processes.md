---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Verify Integrity and Availability of Resources and Processes
Typo: Video
Fecha: 29/04/2026
Estado: completado
Dificultad: Intermedio-Baja
Calificación: N/A
tags:
  - "#Linux/LFCS-Certification/Operations-Deployment"
---
Para monitorear la salud del sistema es fundamental verificar los recursos disponibles. El almacenamiento se puede evaluar con `df -h` para ignorar tmpfs, y `du -sh` para obtener el tamaño de directorios específicos. La memoria se revisa con `free -h`, prestando atención a las columnas "available" y "free", las cuales indican la memoria realmente disponible para el sistema. El procesador se monitorea con `uptime`, que muestra el "load average" en tres intervalos diferentes (1, 5 y 15 minutos), permitiendo detectar si el sistema está sobrecargado. Para más detalles del procesador, se utiliza `lscpu`.

La integridad del sistema de archivos es crítica para mantener la disponibilidad. Para reparar sistemas de archivos XFS se usa `xfs_repair -v /dev/vdbX`, mientras que para ext4 se utiliza `fsck.ext4 -v -f -p /dev/vdbX`. Para verificar que el sistema funciona correctamente y todas sus dependencias están activas, se ejecuta `systemctl list-dependencies`, que muestra las relaciones entre servicios y asegura que todo está funcionando en armonía.

```bash
# Almacenamiento
df -h
du -sh /ruta/

# Memoria
free -h

# Procesador
uptime
lscpu

# Reparación de sistemas de archivos
xfs_repair -v /dev/vdb1
fsck.ext4 -v -f -p /dev/vdb2

# Verificar dependencias del sistema
systemctl list-dependencies
```
