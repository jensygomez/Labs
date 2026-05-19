---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Create and Configure File Systems
Typo: Video
Fecha: 07/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Task:
Time: 20 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux"
  - "#Linux/LFCS-Certification"
---

## Creación y Configuración de Sistemas de Archivos

Un sistema de archivos es la estructura que Linux utiliza para organizar, almacenar y acceder a archivos en una partición del disco. Diferentes distribuciones de Linux utilizan sistemas de archivos distintos por defecto: Red Hat y sus derivados utilizan **XFS**, mientras que Ubuntu utiliza **ext4**. Ambos sistemas de archivos se crean mediante el comando `mkfs` seguido del tipo específico (mkfs.xfs o mkfs.ext4), que formatea una partición previamente creada para que pueda almacenar datos. Cada sistema de archivos puede configurarse con parámetros adicionales al momento de su creación, como etiquetas descriptivas usando el flag `-L`, lo que permite identificar discos de manera más legible en lugar de solo números.

Un aspecto crucial en la creación de sistemas de archivos es la configuración de **inodes**, que son estructuras que almacenan metadatos sobre cada archivo (permisos, propietario, tamaño, etc.). Por defecto, el número de inodes puede ser limitado, lo que eventualmente impediría crear nuevos archivos aunque haya espacio disponible en disco. Para sistemas de archivos XFS, se aumenta el tamaño del inode con `-i size=512`, mientras que en ext4 se especifica el número total de inodes con `-N 500000`. Después de crear un sistema de archivos XFS, puede administrarse y modificarse mediante herramientas como `xfs_admin`, proporcionando flexibilidad para ajustar parámetros sin necesidad de recrear el filesystem.

## Comandos de Ejemplo

```bash
# Crear sistema de archivos XFS en una partición
sudo mkfs.xfs /dev/sdb1

# Crear sistema de archivos ext4 en una partición
sudo mkfs.ext4 /dev/sdb2

# Crear XFS con etiqueta descriptiva
sudo mkfs.xfs -L "datos_empresa" /dev/sdb1

# Crear XFS aumentando el tamaño del inode (para archivos grandes)
sudo mkfs.xfs -i size=512 /dev/sdb1

# Crear ext4 con número específico de inodes (para evitar "sin inodes")
sudo mkfs.ext4 -N 500000 /dev/sdb2

# Administrar parámetros de un filesystem XFS existente
sudo xfs_admin -L "nueva_etiqueta" /dev/sdb1

# Ver información del filesystem
sudo xfs_info /dev/sdb1
```