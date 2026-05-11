---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Manage Containers and VMs
Typo: Laboratorio
Fecha: 01/05/2026
Estado: completado
Dificultad: Media
Calificación: 3/15
Time:
tags:
  - "#Linux/LFCS-Certification/Operations-Deployment/Laboratorio"
---

Este laboratorio abarcó dos aspectos clave de la gestión de infraestructura: la administración de contenedores Docker y máquinas virtuales con virsh/KVM. Se practicaron comandos esenciales como `docker ps -a` para listar contenedores, `docker stop` y `docker rm` para detener y eliminar contenedores, así como `docker rmi` para remover imágenes. También se exploró la gestión del ciclo de vida de máquinas virtuales incluyendo operaciones de arranque, parada y configuración de políticas de reinicio automático.

Las áreas de mayor dificultad fueron la creación de máquinas virtuales con configuración personalizada, la asignación de recursos (memoria y vCPUs), y la configuración de autoarranque en el boot del sistema. La comprensión de las opciones de mapeo de puertos en Docker (`-p`) y las flags de ejecución (`-d` para detach) resultó fundamental para desplegar contenedores correctamente. Este laboratorio subraya la importancia de dominar estas herramientas para la administración de servidores Linux modernos.

## Ejemplos de comandos:

```bash
# Listar todos los contenedores (incluyendo detenidos)
sudo docker ps -a

# Detener y eliminar un contenedor
sudo docker stop website
sudo docker rm website

# Remover una imagen Docker
sudo docker rmi nginx:latest

# Listar máquinas virtuales
sudo virsh list --all

# Iniciar una máquina virtual
sudo virsh start VM1
```
