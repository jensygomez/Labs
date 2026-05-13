---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Use Remote Filesystems --->NFS
Typo: Video
Fecha: 2026-05-08
Estado: completado
Dificultad: Intermedio-Baja
Calificación:
Tareas del Lab:
Time: 15 min
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux/LFCS-Certification/Storage/Remote-Filesystems"
  - "#Linux/LFCS-Certification/Storage/Network-File-System"
  - "#Linux/LFCS-Certification/Storage/Networking"
  - "#Linux/LFCS-Certification/Storage/Server-Client"
  - "#Linux"
  - "#Linux/LFCS-Certification"
---


## NFS: Network File System para Almacenamiento Distribuido

NFS (Network File System) es un protocolo que permite compartir filesystems entre múltiples máquinas en una red, solucionando la necesidad de almacenar datos de forma centralizada y accesible desde diversos servidores. A diferencia de almacenamiento local en disco, NFS utiliza una arquitectura servidor-cliente donde el servidor NFS almacena y gestiona los datos, mientras que los clientes montan esos directorios remotos como si fueran locales. Esta arquitectura es fundamental en entornos empresariales donde múltiples servidores necesitan acceder a datos compartidos (backups, logs, aplicaciones), eliminando la necesidad de duplicar información y simplificando la administración centralizada. El protocolo utiliza TCP/IP para comunicación de red, lo que lo hace flexible y escalable para infraestructuras complejas.

En el lado del servidor, se instala `nfs-kernel-server` y se configura el archivo `/etc/exports`, que define qué directorios se compartirán y con qué restricciones. Cada línea en `/etc/exports` especifica el directorio a exportar, seguido de los clientes que tienen acceso (direcciones IP o rangos) y opciones entre paréntesis como `rw` (lectura-escritura), `ro` (solo lectura), `sync` (sincronización inmediata) o `no_root_squash` (permite acceso root remoto). En el lado del cliente, se instala `nfs-common` y se configura el montaje en `/etc/fstab` usando la sintaxis `servidor:/ruta nfs defaults 0 0`, permitiendo que el filesystem remoto se monte automáticamente en boot. Esta configuración bidireccional es esencial para que los datos remotos sean accesibles de manera transparente, como si fueran almacenamiento local.

## Comandos de Ejemplo

```bash
# === LADO DEL SERVIDOR ===

# Instalar servidor NFS
sudo apt install nfs-kernel-server

# Editar archivo de configuración de exportaciones
sudo vim /etc/exports

# Ejemplo de línea en /etc/exports:
# /datos  192.168.1.0/24(rw,sync,no_root_squash)
# /backup  *(ro,sync,root_squash)

# Exportar los cambios
sudo exportfs -ra

# Verificar directorios exportados
sudo exportfs -v

# Reiniciar servicio NFS
sudo systemctl restart nfs-kernel-server

# === LADO DEL CLIENTE ===

# Instalar cliente NFS
sudo apt install nfs-common

# Crear punto de montaje
sudo mkdir -p /mnt/nfs_datos

# Montar filesystem remoto (temporal)
sudo mount -t nfs 192.168.1.100:/datos /mnt/nfs_datos

# Configurar montaje permanente en /etc/fstab
sudo vim /etc/fstab

# Ejemplo de línea en /etc/fstab:
# 192.168.1.100:/datos  /mnt/nfs_datos  nfs  defaults  0  0

# Montar usando fstab
sudo mount -a

# Verificar montaje
mount | grep nfs
df -h | grep nfs
```