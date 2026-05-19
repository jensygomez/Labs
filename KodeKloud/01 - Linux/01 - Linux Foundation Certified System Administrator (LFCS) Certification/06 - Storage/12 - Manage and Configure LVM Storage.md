---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Manage and Configure LVM Storage
Typo: Video
Fecha: 2026-05-09
Estado: completado
Dificultad: Básico Alto
Calificación:
Tareas del Lab:
Time: 15 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux"
  - "#Linux/LFCS-Certification"
---

## Logical Volume Manager (LVM) - Flexibilidad de Almacenamiento

LVM es una capa de abstracción que permite flexibilidad total sobre el almacenamiento en disco. El problema que resuelve es fundamental: con particiones tradicionales, una vez asignado espacio, cambiar su tamaño es complicado y riesgoso. LVM introduce tres capas: Physical Volumes (PV) son discos o particiones físicas, Volume Groups (VG) agrupan múltiples PVs en un pool lógico, y Logical Volumes (LV) son particiones virtuales creadas dentro del VG que pueden crecer o reducirse dinámicamente. La unidad básica es el Physical Extent (PE), bloques pequeños que permiten granularidad en asignación.

La ventaja operacional es inmensa: puedes expandir un LV simplemente asignándole más espacio del VG, y si el VG se queda sin espacio, agregas otro disco físico mediante `vgextend`. Esto permite que el almacenamiento crezca según demanda sin downtime. También puedes reducir LVs si necesitas recuperar espacio. Para administradores de sistemas, LVM es esencial porque elimina la rigidez de particiones tradicionales, permitiendo ajustar capacidades en tiempo real sin afectar servicios en ejecución.

## Workflow Esencial de LVM

```bash
# Instalar LVM
sudo apt install lvm2

# Escanear discos disponibles
sudo lvmdiskscan

# Crear Physical Volumes (PV)
sudo pvcreate /dev/sdb /dev/sdc

# Crear Volume Group con múltiples PVs
sudo vgcreate my_volume /dev/sdb /dev/sdc

# Expandir Volume Group con nuevo disco
sudo vgextend my_volume /dev/sdd

# Crear Logical Volume (LV) de 2GB
sudo lvcreate --size 2G --name partition2 my_volume

# Extender LV a 3GB (redimensiona filesystem también)
sudo lvresize --resizefs --size 3G my_volume/partition2

# Verificar estructura LVM
sudo pvs
sudo vgs
sudo lvs
```