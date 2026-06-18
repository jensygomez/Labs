---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Filesystem Features and Mount Options
Fecha de Inicio: 2026-05-08
Dificultad: Básico Alto
Tareas del Lab: "5"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `08/05/2026` | 15 min | 20 %  |               |
| `19/05/2026` | 15 min | 40 %  |               |
| `01/06/2026` | 20 min | 100 % |               |

[[Laboratorios del LFCS]]

---

## Control Granular de Filesystems mediante Opciones de Montaje

Este laboratorio enfatiza el control preciso sobre cómo los filesystems se montan y comportan en el sistema mediante opciones de montaje específicas. Las primeras tareas requieren inspeccionar opciones de montaje existentes (particularmente `/dev/vda1` en raíz), desmontaje y remontaje de particiones con diferentes conjuntos de opciones, y cambio dinámico de permisos usando `mount -o remount`. La práctica de desmontar y remontar la misma partición con opciones distintas (`ro`, `rw`, `noexec`, `nosuid`) desarrolla comprensión sobre cómo estas opciones afectan la accesibilidad y seguridad en tiempo real. La calificación de 80% indica buen desempeño, posiblemente con errores menores en sintaxis de fstab o en la identificación precisa de todas las opciones de montaje.

La tarea final requiere configuración permanente en `/etc/fstab`, combinando las opciones de montaje aprendidas en las tareas previas con la configuración de boot automático. Este laboratorio simula escenarios administrativos comunes donde se necesita cambiar políticas de montaje (de lectura a escritura, agregar restricciones de seguridad) sin reiniciar el sistema. La capacidad de usar `mount -o remount` permite testing y ajustes ágiles, mientras que la configuración en `/etc/fstab` garantiza consistencia después de reinicios, siendo crítico en entornos de producción donde la downtime es costosa.

## Comandos Clave Utilizados

```bash
# Q1: Encuentra todas las opciones de montaje activas para el disco raíz usando findmnt y extrae solo la cadena de opciones para guardarla en /root/moptions.
sudo findmnt --noheadings --output OPTIONS /dev/vda1 > /root/moptions

# Q2: Desmonta de forma segura el dispositivo /dev/vdd1 que se encuentra actualmente asignado al punto de montaje /mnt/.
sudo umount /dev/vdd1

# Q3: Monta el dispositivo /dev/vdd1 en /mnt/ aplicando restricciones estrictas de solo lectura (--options ro), sin ejecución de binarios (noexec) y omitiendo bits SUID (nosuid).
sudo mount --options ro,noexec,nosuid /dev/vdd1 /mnt/

# Q4: Remonta el sistema de archivos activo en /mnt/ modificando sus parámetros en caliente a modo lectura-escritura (--options remount,rw) sin necesidad de desmontarlo.
sudo mount --options remount,rw /dev/vdd1 /mnt/

# Q5: Registra el montaje persistente de /dev/vdd1 en el archivo /etc/fstab combinando las opciones por defecto y la restricción de solo lectura (defaults,ro).
echo "/dev/vdd1 /mnt ext4 defaults,ro 0 2" | sudo tee --append /etc/fstab
```