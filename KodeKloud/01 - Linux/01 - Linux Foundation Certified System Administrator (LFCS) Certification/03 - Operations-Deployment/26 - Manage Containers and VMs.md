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
Question 1 of 15

What does this command do?  
  

```sh
virsh destroy TestMachine
```

   
  
**A.** It deletes the virtual machine called TestMachine.  
  
  
**B.** It forces a power off for the virtual machine called TestMachine.  
  
  
**C.** It destroys all data stored in the virtual machine called TestMachine.  
  
  
**D.** It deletes both the virtual machine called TestMachine and the data stored on it.

============

Question 2 of 15

Which of the following commands would you use to set the virtual machine called `VM1` to automatically start up at boot?

===================
Question 3 of 15

Which of the following commands is used to list all docker containers (including stopped containers) present on a system?

============

Question 4 of 15

Pull `docker.io/library/nginx` image on this system.

===============

Question 5 of 15

Create and run a new Docker container based on the `docker.io/library/nginx` image. Three command line options should be used:  
  

**A.** The option to detach from this container's input/output (so you're not stuck inside the container once you run your command)  
  
  
**B.** The option to map port `1234` on the host to port `80` on the container  
  
  
**C.** The option to name this new container as `website`

=============


Question 6 of 15

Remove the `docker.io/library/nginx` docker image.

=============

Question 7 of 15

Remove all docker containers (including running, stopped containers) from this system.

================


Question 8 of 15

Use the image called `httpd` to create and run an `Apache web server`. Bind port `9080` on the host to `port 80` of the container. Set the restart policy so that this container always restarts if it stops unexpectedly or the system reboots. Name the container `webinstance1`.

===============

Question 9 of 15

We have `virsh utility` installed that lets us interact with virtual machines and `qemu-kvm` installed that lets us create and run them.

  

Check if any virtual machine is present on this system (stopped or running). If yes, then save its name in the `/home/bob/vm` file.

================
Question 10 of 15

In the previous question, you might have noticed that `VM1` is in `shut off` state; start this VM.

==============
Question 11 of 15

Now, completely remove the VM1 virtual machine.

============
Question 12 of 15

We have a configuration file `/opt/testmachine2.xml` on this system.

  

Create a virtual machine using this configuration file, and make sure to start it.

================

Question 13 of 15

Right now, when we start up or reboot this system, the virtual machines on it have to be manually started.  
But we want `VM2` virtual machine to start up automatically at boot.


==========

Question 14 of 15

Change the memory size for `VM2`; set its value to `80M`.

  

Make sure the changes are in effect; you can verify the same using `sudo virsh dominfo VM2` command.


==========


Question 15 of 15

There is a cloud image available in **`/var/lib/libvrt/images/`** folder use that image to spin up the virtual machine with the following details

```text
Name - kk-ubuntu
Memory - 1024 
vcpus - 1 
disk path - /var/lib/libvirt/images/ubuntu-22.04-minimal-cloudimg-amd64.img
os-variant - ubuntu22.04 
graphics -  none 
network - default
```

  

Note: It will take some time for the process to be completed.













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

