---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Manage Partitions and Swap Space
Typo: Laboratorio
Fecha: 07/05/2026
Estado: completado
Dificultad: Básico Alto
Calificación: 88,88 %
Task: "9"
Time: 20 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux/LFCS-Certification/Storage/Laboratorio"
  - "#Linux"
  - "#Linux/LFCS-Certification"
---


## Gestión Práctica de Particiones y Swap en Dispositivo Virtual

Este laboratorio proporciona experiencia hands-on en la gestión completa del ciclo de vida de particiones utilizando herramientas de Linux. Las tareas comienzan con conceptos fundamentales como listar dispositivos con `lsblk` e identificar la partición raíz (`/`), avanzando hacia la creación de tres particiones primarias en `/dev/vdd` con tamaños específicos (10MB, 21MB y 15MB), y luego manipulando estas particiones mediante redimensionamiento y eliminación. El laboratorio enfatiza la importancia de entender la estructura de directorios `/dev/` y cómo cada partición se representa como un archivo dentro del sistema de archivos Linux, reforzando que todo en Linux es un archivo.

La segunda mitad del laboratorio integra conceptos de swap con la manipulación de particiones, requiriendo formatear una partición como espacio swap con `mkswap`, activarla con `swapon`, y documentar la ubicación del swapfile del sistema en archivos específicos. Esta combinación práctica de tareas simula escenarios reales donde un administrador de sistemas debe crear, modificar y optimizar el almacenamiento y la memoria virtual en un servidor. La calificación de 7/10 indica áreas de mejora, probablemente en precisión con los tamaños de partición o en la secuencia de comandos de configuración de swap.

## Comandos Clave Utilizados

```bash
# Q1: Listar dispositivos de bloque (discos y particiones)
lsblk

# Q3: Identificar partición raíz y guardar en archivo
df / | grep /dev/ | awk '{print $1}' > /root/part

# Q4: Encontrar swapfile y guardar su ruta
swapon --show | grep -oP '\/\S+' > /root/swap

# Q5: Crear particiones con cfdisk (interfaz interactiva)
sudo cfdisk /dev/vdd

# Q2: Formatear partición como swap
sudo mkswap /dev/vdd2

# Q7: Activar swap
sudo swapon --verbose /dev/vdd2

# Q9: Redimensionar partición (usando cfdisk o parted)
sudo cfdisk /dev/vdd  # O usar parted para redimensionamiento avanzado
```
