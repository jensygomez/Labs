---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Lab - Configure Networking, Start/Stop/Check Status of Network Services
Fecha de Inicio: 2026-04-20
Dificultad: Intermedio-Baja
Tareas Totales: "14"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 20 - 04 - 2026 | 35 min | 50 %  |               |
| 18 - 05 -2026  | 40 min | 50 %  |               |
| `28/05/2026`   | 20 min | 85 %  |               |


---

[[Laboratorios del LFCS]]

Throughout this networking exercise, I realized that configuring a Linux system is fundamentally about understanding **layers of abstraction and explicit intention**. When I identified which processes were listening on specific ports using `ss`, I wasn't just gathering information—I was reading the system's actual state of readiness. This is critical in production environments: a port listening means vulnerability exposure, and without tools like `ss --listening --tcp --udp --numeric --processes`, you're flying blind. I learned that this single command reveals the truth of what your system is actually doing, regardless of what you think it should be doing.

The real insight came when working with Netplan and network interfaces. Modern Linux doesn't force you into static configurations—it offers you **the responsibility of choice**. When I modified `/etc/netplan/99-custom.yaml` to change the IP from `10.0.10.5/24` to `192.168.10.10/24`, and then applied it with `sudo netplan apply`, I understood that this declarative approach reflects Linux philosophy: write down your intent clearly, let the system validate it, and only then apply it. The fact that I had to use `sudo networkctl reconfigure enp6s0` to force the change taught me resilience—sometimes the system needs explicit reloading, and understanding *when* to force reconfiguration versus when to let the system settle is the difference between a working network and a broken one.

What shaped my perspective most was hostname resolution and DNS. Adding entries to `/etc/hosts` for static resolution, then configuring global DNS through both `/etc/resolv.conf` and `/etc/systemd/resolved.conf`—this taught me that in Linux, there are often multiple ways to achieve the same goal, and understanding their priority and scope is essential. A sysadmin doesn't just know commands; they understand the **order of operations**, the **conflict resolution**, and the **persistence model** behind each configuration. When managing production servers, particularly in a NOC-to-sysadmin transition, this distinction becomes everything.
## **Comandos Utilizados:**

```bash
Ver configuración estática de resolución de nombres
sudo cat /etc/hosts

Verificar todos los procesos escuchando en TCP y UDP con información de puertos
sudo ss --listening --tcp --udp --numeric --processes

Filtrar proceso escuchando en puerto específico (ej. puerto 22)
sudo ss -ltunp | grep :22

Guardar PID del proceso en puerto 22
echo "1113" > /home/bob/pid

Identificar proceso escuchando en puerto 53 (DNS)
sudo ss -ltunp | grep :53

Guardar PID del proceso en puerto 53
echo "642" > /home/bob/process_pid

Identificar nombre del proceso escuchando en puerto 8080
sudo ss -ltunp | grep 8080

Agregar resolución estática para example.com apuntando a 8.8.8.8
echo "8.8.8.8 example.com" | sudo tee --append /etc/hosts

Añadir IP temporal a interfaz eth1 con notación CIDR
sudo ip addr add 192.168.9.3/24 dev eth1

Crear configuración Netplan permanente para interfaz enp6s0
sudo vi /etc/netplan/99-custom.yaml

Aplicar cambios de configuración de red
sudo netplan apply

Asegurar permisos correctos en archivo Netplan
sudo chmod 600 /etc/netplan/99-custom.yaml

Forzar recarga de configuración en interfaz específica
sudo networkctl reconfigure enp6s0

Ver tabla de rutas del sistema
ip route

Guardar rutas en archivo
ip route > /home/bob/route.txt

Listar todos los puertos abiertos escuchando (entrantes)
sudo ss -ltunp

Guardar puertos abiertos en archivo
sudo ss -ltunp > /home/bob/incoming.txt

Ver archivo de resolvers del sistema
sudo cat /etc/resolv.conf

Agregar resolver DNS global (método systemd-resolved)
echo "nameserver 8.8.8.8" | sudo tee --append /etc/resolv.conf

Agregar DNS global en archivo de configuración systemd
echo "DNS=8.8.8.8" | sudo tee --append /etc/systemd/resolved.conf
```

---



