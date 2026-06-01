---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Manage Partitions and Swap Space
Fecha de Inicio: 2026-04-20
Dificultad: Básico Alto
Tareas del Lab: "9"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `20/04/2026` | 20 min | 20 %  |               |
| `19/05/2026` | 20 min | 44 %  |               |
| `01/06/2026` | 20 min | 88 %  |               |

[[Laboratorios del LFCS]]

---




## Gestión Práctica de Particiones y Swap en Dispositivo Virtual

Este laboratorio proporciona experiencia hands-on en la gestión completa del ciclo de vida de particiones utilizando herramientas de Linux. Las tareas comienzan con conceptos fundamentales como listar dispositivos con `lsblk` e identificar la partición raíz (`/`), avanzando hacia la creación de tres particiones primarias en `/dev/vdd` con tamaños específicos (10MB, 21MB y 15MB), y luego manipulando estas particiones mediante redimensionamiento y eliminación. El laboratorio enfatiza la importancia de entender la estructura de directorios `/dev/` y cómo cada partición se representa como un archivo dentro del sistema de archivos Linux, reforzando que todo en Linux es un archivo.

La segunda mitad del laboratorio integra conceptos de swap con la manipulación de particiones, requiriendo formatear una partición como espacio swap con `mkswap`, activarla con `swapon`, y documentar la ubicación del swapfile del sistema en archivos específicos. Esta combinación práctica de tareas simula escenarios reales donde un administrador de sistemas debe crear, modificar y optimizar el almacenamiento y la memoria virtual en un servidor. La calificación de 7/10 indica áreas de mejora, probablemente en precisión con los tamaños de partición o en la secuencia de comandos de configuración de swap.

## Comandos Clave Utilizados

```bash
# Q1: Muestra de forma estructurada en árbol todos los dispositivos de bloque (discos y particiones) disponibles en el sistema.
lsblk --all

# Q2: Prepara y da formato de área de intercambio (swap) de Linux a un dispositivo o partición específica.
# Ejemplo de uso conceptual: sudo mkswap /dev/sdb1
sudo mkswap --check /dev/null 2>/dev/null

# Q3: Encuentra el dispositivo de bloque donde está montada la raíz (/), extrae solo su nombre corto (ej. vda1) y lo guarda en /root/part.
lsblk --noheadings --output NAME,MOUNTPOINT | grep -E "/$" | awk '{print $1}' | tr -d '└─├─' > /root/part

# Q4: Identifica las áreas swap activas en el sistema, extrae la ruta exacta del archivo/partición swapfile y la guarda en /root/swap.
sudo swapon --show=NAME --noheadings | head -n 1 > /root/swap

# Q5: Crea tres particiones primarias consecutivas en /dev/vdd usando parted (10MB, 21MB y 15MB) con alineación óptima.
sudo parted --script /dev/vdd mklabel mdos mkpart primary ext4 1MiB 11MiB mkpart primary ext4 11MiB 32MiB mkpart primary ext4 32MiB 47MiB

# Q6: Elimina de forma directa y no interactiva la primera partición (la de 10MB creada en el espacio del 1MiB al 11MiB).
sudo parted --script /dev/vdd rm 1

# Q7: Inicializa la segunda partición (/dev/vdd2) como swap y le indica al Kernel de Linux que la active inmediatamente para su uso.
sudo mkswap /dev/vdd2 && sudo swapon --verbose /dev/vdd2

# Q8: Desactiva de inmediato el uso de la partición /dev/vdd2 como memoria de intercambio del sistema.
sudo swapoff --verbose /dev/vdd2

# Q9: Redimensiona la tercera partición (/dev/vdd3) para expandir su tamaño final hasta los 21MB requeridos de forma directa.
sudo parted --script /dev/vdd resizepart 3 53MiB
```
