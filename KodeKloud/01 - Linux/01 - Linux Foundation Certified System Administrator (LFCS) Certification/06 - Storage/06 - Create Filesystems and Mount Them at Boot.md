---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Create Filesystems and Mount Them at Boot
Fecha de Inicio: 2026-05-08
Dificultad: Básico Alto
Tareas del Lab: "9"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `08/05/2026` | 20 min | 35 %  |               |
| `19/05/2026` | 20 min | 55 %  |               |
| `01/06/2026` | 20 min | 89 %  |               |

[[Laboratorios del LFCS]]

---


Este laboratorio integra la creación de sistemas de archivos con su configuración permanente en `/etc/fstab`, simulando tareas reales de administración de almacenamiento. Las primeras tareas se enfocan en la creación de filesystems específicos: un filesystem XFS con etiqueta "DataDisk" en `/dev/vdd` y un filesystem ext4 con 2048 inodes en `/dev/vde`, demostrando cómo diferentes tipos de filesystems se crean con sintaxis y opciones distintas. Luego se practican operaciones de montaje temporal con `mount` y `umount` en el directorio `/mnt/`, que proporcionan experiencia hands-on sobre cómo los filesystems se hacen accesibles al sistema. Una pregunta conceptual sobre la sintaxis correcta de labels (`-L` mayúscula vs `-l` minúscula) refuerza la importancia de precisión en los comandos.

La segunda mitad del laboratorio requiere configurar montajes automáticos en `/etc/fstab` para persistencia a través de reinicios, incluyendo crear el punto de montaje `/test` antes de configurar la entrada en fstab y habilitar verificación de filesystem en boot. Finalmente, se configura `/dev/vdd` como swap automático en el arranque, demostrando que swap también debe persistir en fstab. La calificación de 66% sugiere dificultades con la sintaxis de fstab, el uso de UUID, o la verificación correcta de filesystems. Este laboratorio es crítico porque simula escenarios de producción donde administradores deben diseñar esquemas de almacenamiento que sobrevivan a reinicios sin intervención manual.

## Comandos Clave Utilizados

```bash
# Q1: El archivo de configuración que define los montajes automáticos del sistema durante el arranque es: /etc/fstab

# Q2: Respuesta correcta: A. La etiqueta "BackupVolume" excede el límite máximo de caracteres permitido para un volumen XFS (máximo 12 bytes/caracteres).

# Q3: Crea un sistema de archivos XFS forzando (--force) la escritura y asignándole la etiqueta "DataDisk".
sudo mkfs.xfs --force -L "DataDisk" /dev/vdd

# Q4: Crea un sistema de archivos ext4 especificando explícitamente el número exacto de nodos-i (inodes) requeridos mediante la opción --number-of-inodes.
sudo mkfs.ext4 --number-of-inodes=2048 /dev/vde

# Q5: Monta el dispositivo de bloques /dev/vdd en el directorio de montaje temporal estándar del sistema /mnt/.
sudo mount /dev/vdd /mnt/

# Q6: Desmonta de forma segura el sistema de archivos que se encuentra actualmente activo en el directorio /mnt/.
sudo umount /mnt/

# Q7: Crea el directorio /test, extrae el UUID del disco /dev/vde y lo añade limpiamente al archivo /etc/fstab indicando que se revise en el boot (parámetro 2).
sudo mkdir --parents /test && echo "UUID=$(blkid --value --match-tag UUID /dev/vde) /test ext4 defaults 0 2" | sudo tee --append /etc/fstab

# Q8: Registra de forma persistente en el /etc/fstab el dispositivo /dev/vdd para que el sistema operativo lo monte automáticamente como memoria swap al arrancar.
echo "/dev/vdd none swap defaults 0 0" | sudo tee --append /etc/fstab

# Q9: Cambia de manera segura la etiqueta (label) de un sistema de archivos XFS existente en /dev/vdd a "SwapFS" usando la herramienta de administración de XFS.
sudo xfs_admin -L "SwapFS" /dev/vdd
```