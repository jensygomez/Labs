---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Remote File Systems --> NFS
Typo: Laboratorio
Fecha: 2026-05-09
Estado: completado
Dificultad: Intermedio-Baja
Calificación: 0%
Tareas del Lab: "8"
Time:
tags:
  - "#Linux/LFCS-Certification/Storage"
  - "#Linux/LFCS-Certification/Storage/Laboratorio"
  - "#Linux"
  - "#Linux/LFCS-Certification"
---


## NFS Configuration & Mounting

Este laboratorio abarcó la configuración completa de un servidor NFS desde cero. Se trabajó con el archivo `/etc/exports` para definir qué directorios compartir y con qué permisos. Los conceptos clave fueron entender cómo especificar rangos CIDR (ej: 10.0.0.0/24) y direcciones IP específicas, aplicar permisos read-only y read-write, y usar opciones como `no_root_squash` para controlar privilegios de root en clientes remotos. El flujo completo incluye crear la configuración, reexportarla con `exportfs -r`, montarla manualmente en clientes, y finalmente automatizar el montaje en el fstab.

La automatización es crucial en entornos de producción. El montaje manual enseña cómo funcionan las NFS, pero la persistencia requiere configurar `/etc/fstab` con los parámetros correctos. Se practicó montar comparticiones NFS desde directorios remotos a locales, entender la relación servidor-cliente, y cómo el sistema gestiona automáticamente estas conexiones al iniciar. Este lab proporciona una base sólida para administración de almacenamiento compartido en entornos Linux corporativos.

## Comandos de Ejemplo

```bash
# Verificar configuración NFS actual
cat /etc/exports

# Reexportar cambios en la configuración
exportfs -r

# Montar manualmente una compartición NFS
mount -t nfs 127.0.0.1:/home /mnt

# Verificar montajes activos
mount | grep nfs

# Agregar entrada en fstab para montaje automático
127.0.0.1:/home /mnt nfs defaults 0 0
```