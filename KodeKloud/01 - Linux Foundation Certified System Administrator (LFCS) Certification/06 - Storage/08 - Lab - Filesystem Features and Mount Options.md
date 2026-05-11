---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Filesystem Features and Mount Options
Typo: Laboratorio
Fecha: 2026-05-08
Estado: completado
Dificultad: Básico Alto
Calificación: 80 %
Tareas del Lab: "5"
Time: 15 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux/LFCS-Certification/Storage/Laboratorio"
  - "#Linux/LFCS-Certification/Storage/FileSystems"
  - "#Linux/LFCS-Certification/Storage/Security"
  - "#Linux/LFCS-Certification/Storage/Mount-Options"
  - "#Linux/LFCS-Certification/Storage/mount"
  - "#Linux/LFCS-Certification/Storage/fstab"
  - "#Linux/LFCS-Certification/Storage/Remount"
---

## Control Granular de Filesystems mediante Opciones de Montaje

Este laboratorio enfatiza el control preciso sobre cómo los filesystems se montan y comportan en el sistema mediante opciones de montaje específicas. Las primeras tareas requieren inspeccionar opciones de montaje existentes (particularmente `/dev/vda1` en raíz), desmontaje y remontaje de particiones con diferentes conjuntos de opciones, y cambio dinámico de permisos usando `mount -o remount`. La práctica de desmontar y remontar la misma partición con opciones distintas (`ro`, `rw`, `noexec`, `nosuid`) desarrolla comprensión sobre cómo estas opciones afectan la accesibilidad y seguridad en tiempo real. La calificación de 80% indica buen desempeño, posiblemente con errores menores en sintaxis de fstab o en la identificación precisa de todas las opciones de montaje.

La tarea final requiere configuración permanente en `/etc/fstab`, combinando las opciones de montaje aprendidas en las tareas previas con la configuración de boot automático. Este laboratorio simula escenarios administrativos comunes donde se necesita cambiar políticas de montaje (de lectura a escritura, agregar restricciones de seguridad) sin reiniciar el sistema. La capacidad de usar `mount -o remount` permite testing y ajustes ágiles, mientras que la configuración en `/etc/fstab` garantiza consistencia después de reinicios, siendo crítico en entornos de producción donde la downtime es costosa.

## Comandos Clave Utilizados

```bash
# Q1: Identificar opciones de montaje de /dev/vda1 y guardar
findmnt -n /dev/vda1 -o OPTIONS > /root/moptions
# O alternativa:
mount | grep "on / " | awk -F'(' '{print $2}' | sed 's/)$//' > /root/moptions

# Q2: Desmontar partición
sudo umount /mnt/

# Q3: Montar con opciones de seguridad restrictivas
sudo mount -o ro,noexec,nosuid /dev/vdd1 /mnt

# Q4: Remount para cambiar de read-only a read-write
sudo mount -o remount,rw /mnt

# Verificar que ahora es read-write
touch /mnt/testfile

# Q5: Configurar montaje permanente en /etc/fstab
sudo vim /etc/fstab
# Agregar línea (reemplazar UUID según corresponda):
# UUID=<uuid-vdd1>  /mnt  ext4  defaults,ro  0  2

# Validar fstab sin reiniciar
sudo mount -a

# Ver opciones de montaje actual
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS /mnt

# Remount con múltiples cambios
sudo mount -o remount,rw,exec,nosuid /mnt
```