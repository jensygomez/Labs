---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Advanced Permissions
Typo: Laboratorio
Fecha: 2026-05-09
Estado: completado
Dificultad: Intermedio-Medio
Calificación: 50 % de aciertos
Tareas del Lab: "8"
Time: 15 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux/LFCS-Certification/Storage/Laboratorio"
  - "#Linux"
  - "#Linux/LFCS-Certification"
---
**Resumen:**

Este laboratorio integró conceptos clave de permisos avanzados y almacenamiento RAID en Linux. Las tareas enfocadas en ACLs requirieron manipulación precisa de permisos a nivel de usuario y grupo, tanto para archivos individuales como para directorios completos de forma recursiva. El dominio de `setfacl`, `getfacl` y la remoción selectiva de permisos ACL son operaciones críticas cuando se necesita control granular de acceso en ambientes multi-usuario, especialmente en servidores de archivos compartidos donde los permisos tradicionales resultan insuficientes.

La segunda parte del laboratorio introdujo conceptos de RAID con `mdadm`, herramienta esencial para configurar arrays de almacenamiento redundante en sistemas Linux. Comprender RAID 1 (mirroring) y cómo crear arrays con múltiples dispositivos físicos es fundamental para implementar soluciones de alta disponibilidad y recuperación ante fallos. El laboratorio consolidó tanto la seguridad de acceso a datos como la redundancia de almacenamiento, pilares del trabajo de un Sysadmin Linux en producción.

**Comandos de ejemplo:**

bash

```bash
# ACL - Permisos recursivos en directorio
sudo setfacl --recursive --modify user:john:rwx /home/bob/collection

# ACL - Permisos para grupo
sudo setfacl --modify group:mail:rx specialfile

# ACL - Visualizar permisos
getfacl specialfile

# ACL - Remover permisos de usuario
sudo setfacl --remove user:john specialfile

# RAID - Crear array RAID 1 (mirror)
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/vdd /dev/vde

# RAID - Ver estado de arrays
sudo mdadm --detail /dev/md0
cat /proc/mdstat
```