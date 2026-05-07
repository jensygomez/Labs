---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: List, Create, Delete, and Modify Physical Storage Partitions
Typo: Video
Fecha: 07/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 15 min
tags:
  - linux
  - lfcs
  - storage
  - partitions
  - fdisk
  - lsblk
---

## Particionamiento de Discos en Linux

El particionamiento es el proceso de dividir un disco físico en secciones lógicas independientes, necesario cuando múltiples sistemas operativos o sistemas de archivos diferentes deben coexistir en el mismo disco. Por ejemplo, en un SSD de 2TB donde se requiere tanto Windows (NTFS) como Ubuntu (ext4), es necesario particionar el disco para asignar espacios separados a cada sistema. En Linux, todo se representa como archivo en el directorio `/dev/`, donde los discos aparecen como `sda`, `sdb`, `sdc`, etc., y sus particiones como `sda1`, `sda2`, `sdb1`, etc.

Para gestionar particiones en Linux existen herramientas esenciales: `lsblk` permite listar de forma jerárquica todos los dispositivos de almacenamiento y sus particiones, mientras que `fdisk` proporciona control completo para crear, eliminar y modificar particiones. Adicionalmente, `cfdisk` ofrece una interfaz interactiva más amigable. Al crear particiones es importante elegir entre dos esquemas: MBR (Master Boot Record), recomendado para computadores antiguos, y GPT (GUID Partition Table), el estándar moderno y recomendado para equipos actuales por su mayor capacidad y flexibilidad.

## Comandos de Ejemplo

```bash
# Listar dispositivos y particiones en formato jerárquico
lsblk

# Ver todas las particiones de un disco específico
sudo fdisk -l /dev/sdb

# Abrir interfaz interactiva para particionar (recomendado)
sudo cfdisk /dev/sdb

# Opción avanzada para particionamiento
sudo fdisk /dev/sdb
```