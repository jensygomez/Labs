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
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| `30/04/26` | 40 min | 0 %   |               |
| `17/05/26` | 40 min | 40 %  |               |
| `26/05/26` | 30 min | 60 %  |               |

[[Laboratorios del LFCS]]

---

During this technical assessment, I worked through infrastructure provisioning scenarios that deepened my understanding of how modern Linux systems manage compute resources across multiple abstraction layers. Rather than simply knowing container and virtualization commands, I learned to distinguish between ephemeral containerized workloads and persistent virtual machine infrastructure—a critical architectural distinction in production environments. When I created and managed Docker containers with `docker run -d -p 1234:80 --name website`, I understood that containerization trades infrastructure isolation for resource efficiency and rapid deployment cycles. Conversely, when I provisioned VMs using `virsh` and `virt-install`, I recognized that virtual machines provide stronger isolation boundaries at the cost of greater overhead, making them suitable for workloads requiring full operating system separation or legacy application support. This exercise taught me that infrastructure decisions are not about tool familiarity, but about aligning container or VM strategies with specific workload requirements.

The second dimension of this work involved state management and persistence—understanding that infrastructure, unlike code, must survive restarts and unexpected failures. I configured Docker containers with `--restart always` to ensure they recover automatically, and I set VMs to autostart at boot using `sudo virsh autostart`, recognizing that production systems cannot depend on manual intervention. When I modified VM memory using `sudo virsh setmem VM2 80M`, I verified changes were persisted using `sudo virsh dominfo`, learning that infrastructure modifications must be atomic and verifiable, not assumed. I also created VMs from both XML configuration files and cloud images using `virt-install`, understanding that infrastructure-as-code principles apply equally to virtualization—configuration should be declarative, reproducible, and version-controllable. This reflects deeper Linux philosophy: infrastructure must be programmable and recoverable.

The final challenge—spinning up a complete cloud image VM with specific resource allocations and networking—demonstrated that modern Linux administrators orchestrate entire environments, not individual machines. Using `virt-install` with cloud images, I provisioned a fully configured Ubuntu system with precise CPU, memory, and disk specifications in a single declarative command. This showed me that containerization and virtualization are not competing technologies but complementary tools in a layered infrastructure stack: containers for stateless, ephemeral workloads; VMs for persistent, isolated environments; and both managed through the same declarative, scriptable interfaces. A competent Linux infrastructure engineer thinks in terms of resource orchestration, failure recovery, and automation—not individual machine administration.

---

## **💻 Comandos Clave**

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
