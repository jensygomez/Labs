---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Configure Systems to Mount Filesystems at or During Boot
Typo: Video
Fecha: 2026-05-08
Estado: completado
Dificultad: Básico Medio
Calificación:
Task:
Time: 15 min
---
## Montaje Permanente de Sistemas de Archivos en el Arranque

Después de crear un sistema de archivos en una partición, Linux debe montarlo para hacerlo accesible al usuario. El comando `mount` vincula una partición a un punto de montaje en el árbol de directorios, permitiendo acceso inmediato a los archivos almacenados. Por ejemplo, `sudo mount /dev/vdb1 /mnt/` monta la partición vdb1 en el directorio `/mnt/`, haciendo posible crear archivos y navegar en esa ubicación. Sin embargo, este montaje es temporal y desaparece después de reiniciar el sistema, requiriendo que sea configurado manualmente nuevamente después de cada reinicio, lo cual es impracticable en ambientes de producción donde se necesita persistencia y disponibilidad continua.

Para hacer que el montaje sea permanente y automático durante el arranque del sistema, se configura el archivo `/etc/fstab` (file system table), que contiene seis columnas críticas: identificador de la partición, punto de montaje, tipo de sistema de archivos, opciones de montaje, orden de backup y prioridad de verificación de errores. Crucialmente, se recomienda usar **UUID** (Identificador Único Universal) en lugar del nombre del dispositivo (como `/dev/vdb1`), ya que los nombres de dispositivos pueden cambiar entre reinicios o cuando se agregan nuevos discos, mientras que el UUID permanece inmutable. Después de modificar `/etc/fstab`, se ejecuta `sudo systemctl daemon-reload` para que systemd reconozca los cambios y pueda montarlos correctamente en el siguiente arranque.

## Comandos de Ejemplo

```bash
# Montar una partición de forma temporal
sudo mount /dev/vdb1 /mnt/

# Verificar que el montaje fue exitoso
sudo touch /mnt/testfile
ls -la /mnt/testfile

# Obtener el UUID de una partición
sudo blkid /dev/vdb1

# Editar el archivo fstab para montaje permanente
sudo vim /etc/fstab

# Ejemplo de línea en /etc/fstab usando UUID
# UUID=a1b2c3d4-e5f6-7890-abcd-ef1234567890  /mnt  ext4  defaults  0  2

# Recargar la configuración de systemd después de cambios en fstab
sudo systemctl daemon-reload

# Verificar que fstab está correctamente configurado (sin reiniciar)
sudo mount -a

# Ver todos los filesystems montados y sus puntos de montaje
mount | grep /mnt
```