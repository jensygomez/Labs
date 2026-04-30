---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Installing an Operating System on a Virtual Machine
Typo: Video
Fecha: 30/04/2026
Estado: completado
Dificultad: Básico
Calificación: N/A
Time: 8 min
tags:
  - linux
  - lfcs
  - operations
  - Operations-Deployments
  - virtualization
  - virt-install
---



Este video introduce la instalación de sistemas operativos en máquinas virtuales usando herramientas de virtualización en Linux. Se mostró el proceso de instalación de Debian 12 utilizando `virt-install`, una herramienta que automatiza la creación y configuración de VMs en KVM. El comando original utilizaba una ubicación local del ISO de instalación netinst, permitiendo controlar parámetros críticos como memoria, CPUs, tamaño de disco y configuración de gráficos.

El enfoque práctico del video también demostró cómo adaptar la instalación para descargar el SO directamente desde una URL en lugar de usar un archivo ISO local. Una vez ejecutado el comando con la URL correcta, se abre automáticamente una interfaz interactiva que guía el proceso de instalación del sistema operativo, simplificando significativamente el despliegue de VMs en entornos de producción.

## Comando de ejemplo

```bash
virt-install --osinfo debian12 --name debia1 --memory 1024 --vcpus 1 --disk size=10 --location /var/lib/libvirt/boot/debian12-netinst.iso --graphics none --extra-args "console=ttyS0"
```