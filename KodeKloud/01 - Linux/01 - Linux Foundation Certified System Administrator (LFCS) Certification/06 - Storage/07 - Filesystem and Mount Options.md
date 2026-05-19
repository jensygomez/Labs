---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Filesystem and Mount Options
Typo: Video
Fecha: 2026-05-08
Estado: completado
Dificultad: Básico Medio
Calificación:
Tareas del Lab:
Time: 10 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux"
  - "#Linux/LFCS-Certification"
---
## Opciones de Montaje y Configuración Avanzada de Filesystems

Las opciones de montaje permiten controlar cómo Linux interactúa con un filesystem, proporcionando flexibilidad para optimizar rendimiento, seguridad y comportamiento del sistema. El comando `mount` acepta múltiples opciones mediante el flag `-o` que modifican el comportamiento del filesystem montado. Opciones comunes incluyen `ro` (read-only, solo lectura), `noexec` (impide ejecutar archivos binarios en esa partición), y `nosuid` (desactiva los bits SUID y SGID), siendo estas últimas particularmente importantes para seguridad al montar directorios compartidos o no confiables. Por ejemplo, `sudo mount -o ro,noexec,nosuid /dev/vdb2 /mnt` monta una partición en modo solo lectura, sin capacidad de ejecutar programas y sin permisos elevados, creando un entorno restrictivo ideal para datos sensibles o directorios de terceros.

El comando `findmnt` proporciona una vista completa y estructurada de todos los filesystems montados en el sistema, mostrando detalles como punto de montaje, tipo de filesystem, opciones activas y dispositivo de origen. Al usar `findmnt -t xfs,ext4` se filtra para mostrar solo filesystems específicos, permitiendo auditar rápidamente qué particiones están montadas con qué opciones. Entender y configurar correctamente estas opciones es crítico para administración de sistemas, ya que protegen contra ejecución no autorizada de código, limitaciones de acceso y control de recursos, siendo especialmente importante en entornos multiusuario o servidores donde la seguridad es paramount.

## Comandos de Ejemplo

```bash
# Ver todos los filesystems montados con detalles
findmnt

# Filtrar filesystems por tipo (XFS y ext4)
findmnt -t xfs,ext4

# Montar con múltiples opciones restrictivas
sudo mount -o ro,noexec,nosuid /dev/vdb2 /mnt

# Montar en modo read-only
sudo mount -o ro /dev/vdb2 /mnt

# Montar sin permitir ejecución de binarios
sudo mount -o noexec /dev/vdb2 /mnt

# Montar sin permisos SUID/SGID
sudo mount -o nosuid /dev/vdb2 /mnt

# Montar con opciones adicionales (remount para cambiar opciones de montaje actual)
sudo mount -o remount,ro /mnt

# Ver opciones de un filesystem montado específico
findmnt /mnt

# Verificar en /etc/fstab con opciones personalizadas
# UUID=abc123  /data  ext4  ro,noexec,nosuid  0  2
```