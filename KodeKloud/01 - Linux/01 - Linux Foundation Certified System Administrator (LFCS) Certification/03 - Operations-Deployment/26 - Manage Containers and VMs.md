---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Manage Containers and VMs
Fecha de Inicio: 2026-04-30
Dificultad: Intermedio-Alto
Tareas Totales: "15"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 17 - 05 - 2026 | 40 min | 40 %  |               |
|                |        |       |               |

[[Laboratorios del LFCS]]

---


## 📝 Resumen

Este laboratorio cubre la gestión integral de contenedores Docker y máquinas virtuales (VMs) usando libvirt/KVM en sistemas Linux, herramientas fundamentales para un Sysadmin moderno. El lab se divide en dos partes principales: la primera enfocada en Docker donde se practican operaciones como descargar imágenes, crear y ejecutar contenedores con opciones de mapeo de puertos, políticas de reinicio y gestión del ciclo de vida; la segunda parte aborda virtualización con virsh y qemu-kvm, permitiendo crear, configurar, iniciar y gestionar máquinas virtuales, incluyendo la automatización de inicio al boot y la modificación de recursos (memoria, vCPUs). Estas 15 tareas representan el flujo completo de un Sysadmin que debe administrar tanto infraestructura containerizada como basada en máquinas virtuales.

El aprendizaje progresa desde conceptos teóricos (qué hace ciertos comandos) hasta operaciones prácticas avanzadas: primero se valida comprensión de herramientas (virsh destroy, listar contenedores), luego se practican operaciones Docker fundamentales (pull de imágenes, crear contenedores con puertos y políticas de reinicio, eliminar recursos), y finalmente se domina la gestión de VMs (crear desde archivos XML, modificar recursos en tiempo real, establecer autostart al boot, provisionar máquinas desde imágenes cloud). Al completar este lab, tendrás experiencia en los dos paradigmas de virtualización más usados en la nube y data centers modernos.

## 💻 Comandos Clave

```bash
# === DOCKER ===
# Descargar imagen Docker
docker pull docker.io/library/nginx

# Crear y ejecutar contenedor (detached, mapeo puertos, nombre)
docker run -d -p 1234:80 --name website docker.io/library/nginx

# Ejecutar contenedor con política de reinicio automático
docker run -d -p 9080:80 --restart always --name webinstance1 docker.io/library/httpd

# Listar todos los contenedores (incluyendo stopped)
docker ps -a

# Eliminar contenedor
docker rm <container_id>

# Eliminar todos los contenedores
docker rm $(docker ps -aq)

# Eliminar imagen Docker
docker rmi docker.io/library/nginx

# === VIRTUALIZATION (VIRSH/KVM) ===
# Listar máquinas virtuales (running y stopped)
sudo virsh list --all

# Información detallada de una VM
sudo virsh dominfo VM2

# Iniciar una VM
sudo virsh start VM1

# Detener una VM (graceful shutdown)
sudo virsh shutdown VM1

# Apagar forzadamente una VM
sudo virsh destroy TestMachine

# Crear VM desde archivo XML de configuración
sudo virsh create /opt/testmachine2.xml

# Modificar memoria de una VM (temporal)
sudo virsh setmem VM2 80M

# Establecer autostart para VM al boot
sudo virsh autostart VM2

# Deshabilitar autostart
sudo virsh autostart --disable VM2

# Eliminar completamente una VM
sudo virsh undefine VM1

# Crear VM desde imagen cloud
sudo virt-install \
  --name kk-ubuntu \
  --memory 1024 \
  --vcpus 1 \
  --disk /var/lib/libvirt/images/ubuntu-22.04-minimal-cloudimg-amd64.img \
  --os-variant ubuntu22.04 \
  --graphics none \
  --network default \
  --import
```

---

**Inicio Lab:** 2026-04-30 | **Última sesión:** 17-05-2026 (40 min) | **Progreso:** 40%