---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Manage and Configure Virtual Machines
Typo: Video
Fecha: 30/04/2026
Estado: completado
Dificultad:
Calificación: N/A
Time: 12 min
tags:
  - linux
  - lfcs
  - operations
  - Operations-Deployments
  - kvm
  - qemu
  - virtualization
---
Las máquinas virtuales son fundamentales en la infraestructura moderna de servidores. Los proveedores de nube utilizan supercomputadores para ofrecer recursos virtualizados (vCPU, RAM) según las necesidades de cada cliente. En Linux, **QEMU-KVM** es la solución nativa para virtualización, mientras que **virsh** es la herramienta CLI para gestionar estas máquinas. El virt-manager proporciona interfaz gráfica, pero en entornos de producción se trabaja principalmente desde terminal.

En la práctica, se creó una máquina virtual mediante un archivo XML básico usando `virsh define testmachine.xml`. Se exploraron comandos esenciales como `virsh list`, `virsh start/stop`, `virsh autostart`, además de configuraciones avanzadas para modificar recursos: aumentar vCPUs con `virsh setvcpus nombre 2 --config --maximum` y ajustar RAM con `virsh setmem`. Estos comandos permiten adaptar los recursos de la VM sin necesidad de recrearla.

**Ejemplo de comando:**

bash

```bash
virsh define testmachine.xml
virsh setvcpus testmachine 2 --config --maximum
virsh setmem testmachine 2097152 --config --maximum
virsh autostart --disable testmachine
```