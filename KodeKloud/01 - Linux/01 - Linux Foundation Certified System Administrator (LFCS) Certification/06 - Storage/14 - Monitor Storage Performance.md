---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Monitor Storage Performance
Typo: Video
Fecha: 2026-05-09
Estado: completado
Dificultad: Básico Alto
Calificación:
Tareas del Lab:
Time: 20 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux"
  - "#Linux/LFCS-Certification"
---
**Resumen:**

El monitoreo del rendimiento de almacenamiento es esencial para identificar cuellos de botella en el sistema. En Linux, podemos utilizar herramientas como `sysstat` (iostat) y `pidstat` para analizar las operaciones de entrada/salida del disco. El comando `iostat` muestra métricas clave como TPS (Transferencias por Segundo), KB_read/s (kilobytes leídos por segundo) y KB_wrtn/s (kilobytes escritos por segundo), permitiéndonos entender cómo el sistema está usando los dispositivos de almacenamiento. Estas métricas son fundamentales para detectar si el disco es un cuello de botella en nuestro ambiente.

Adicionalmente, `pidstat` con la opción `-d` nos permite identificar qué procesos específicos están consumiendo recursos de I/O, facilitando el troubleshooting cuando detectamos anomalías. Conocer estas herramientas es crítico para un Sysadmin Linux, ya que muchas degradaciones de rendimiento están directamente relacionadas con problemas de I/O en disco. El comando `dmsetup info` complementa este análisis permitiéndonos inspeccionar dispositivos mapeados cuando trabajamos con LVM u otros sistemas de almacenamiento avanzados.

**Comando de ejemplo:**

bash

```bash
# Simular carga de I/O y monitorear en tiempo real
dd if=/dev/zero of=DELETEME bs=1 count=1000000 oflag=dsync &
sudo iostat 1                    # Mostrar estadísticas cada 1 segundo
sudo pidstat -d 1                # Mostrar procesos consumiendo I/O cada 1 segundo
sudo dmsetup info /dev/dm-0      # Inspeccionar dispositivo mapeado

# Variaciones útiles
sudo iostat -h                   # Formato legible para humanos
sudo pidstat -d --human          # Procesos en formato legible
sudo iostat -p ALL               # Todas las particiones
sudo iostat -p sda               # Dispositivo específico
```