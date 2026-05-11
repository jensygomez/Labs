---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Create Filesystems and Mount Them at Boot
Typo: Laboratorio
Fecha: 2026-05-08
Estado: completado
Dificultad: Básico Alto
Calificación: 66 %
Tareas del Lab: "9"
Time: 20 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux/LFCS-Certification/Storage/FileSystems"
  - "#Linux/LFCS-Certification/Storage/Swap"
  - "#Linux/LFCS-Certification/Storage/Laboratorio"
  - "#Linux/LFCS-Certification/Storage/UUID"
  - "#Linux/LFCS-Certification/Storage/fstab"
  - "#Linux/LFCS-Certification/Storage/mount"
  - "#Linux/LFCS-Certification/Storage/mkfs"
---

## Creación de Filesystems y Configuración de Montaje Automático en Boot

Este laboratorio integra la creación de sistemas de archivos con su configuración permanente en `/etc/fstab`, simulando tareas reales de administración de almacenamiento. Las primeras tareas se enfocan en la creación de filesystems específicos: un filesystem XFS con etiqueta "DataDisk" en `/dev/vdd` y un filesystem ext4 con 2048 inodes en `/dev/vde`, demostrando cómo diferentes tipos de filesystems se crean con sintaxis y opciones distintas. Luego se practican operaciones de montaje temporal con `mount` y `umount` en el directorio `/mnt/`, que proporcionan experiencia hands-on sobre cómo los filesystems se hacen accesibles al sistema. Una pregunta conceptual sobre la sintaxis correcta de labels (`-L` mayúscula vs `-l` minúscula) refuerza la importancia de precisión en los comandos.

La segunda mitad del laboratorio requiere configurar montajes automáticos en `/etc/fstab` para persistencia a través de reinicios, incluyendo crear el punto de montaje `/test` antes de configurar la entrada en fstab y habilitar verificación de filesystem en boot. Finalmente, se configura `/dev/vdd` como swap automático en el arranque, demostrando que swap también debe persistir en fstab. La calificación de 66% sugiere dificultades con la sintaxis de fstab, el uso de UUID, o la verificación correcta de filesystems. Este laboratorio es crítico porque simula escenarios de producción donde administradores deben diseñar esquemas de almacenamiento que sobrevivan a reinicios sin intervención manual.

## Comandos Clave Utilizados

```bash
# Q1: Archivo para configurar montajes automáticos
# Respuesta: /etc/fstab

# Q2: Opción correcta para label en XFS
# Respuesta: B. Debe ser -L (mayúscula), no -l (minúscula)

# Q3: Crear XFS con label
sudo mkfs.xfs -L "DataDisk" /dev/vdd

# Q4: Crear ext4 con número específico de inodes
sudo mkfs.ext4 -N 2048 /dev/vde

# Q5: Montar partición temporalmente
sudo mount /dev/vdd /mnt/

# Q6: Desmontar filesystem
sudo umount /mnt/

# Q7: Configurar montaje permanente en fstab
sudo mkdir -p /test
sudo vim /etc/fstab
# Agregar línea (usar UUID):
# UUID=<uuid-vde>  /test  ext4  defaults  0  2

# Verificar fstab sin reiniciar
sudo mount -a

# Q8: Configurar swap automático en fstab
# Agregar línea en /etc/fstab:
# UUID=<uuid-vdd>  none  swap  defaults  0  0

# Recargar configuración de systemd
sudo systemctl daemon-reload

# Obtener UUID de particiones
sudo blkid /dev/vdd
sudo blkid /dev/vde
```