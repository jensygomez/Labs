---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Kernel Runtime Parameters and SELinux AppArmor
Fecha de Inicio: 2026-04-30
Dificultad: Avanzado-Bajo
Tareas Totales: "9"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| `30/04/26` | 30 min | 0 %   |               |
| `16/05/26` | 40 min | 0 %   |               |
| `26/05/26` | 20 min | 11 %  |               |
| `31/05/26` | 20 min | 33 %  |               |

[[Laboratorios del LFCS]]


---

During this hands-on assessment, I worked through a comprehensive security hardening scenario that reinforced my understanding of Linux kernel-level access control mechanisms. Rather than merely executing commands, I focused on comprehending the _why_ behind each configuration: SELinux operates as a mandatory access control layer that enforces policy decisions at the kernel level, preventing privilege escalation and unauthorized process execution regardless of traditional UNIX permissions. I identified that the sshd process operates under the `system_u:system_r:sshd_t` context, understanding that this type-based enforcement is critical in production environments where a compromised service cannot accidentally or maliciously access unintended resources. This taught me that security in Linux is not about knowing commands—it's about understanding that every label, every context, and every policy decision serves a specific containment strategy.

The second aspect of this work centered on kernel parameter persistence and runtime tuning, which revealed a deeper principle: temporary system modifications without persistence are merely testing grounds, not production-ready solutions. I disabled kernel module loading via `kernel.modules_disabled` and adjusted `vm.swappiness` to 10, but critically, I made the swappiness change persistent by appending it to `/etc/sysctl.conf`. This distinction matters profoundly in production—a sysadmin who only knows how to make temporary changes will leave systems vulnerable during reboots, when policy enforcement resets. I also verified the `net.ipv6.conf.lo.seg6_enabled` parameter, learning that sysctl is not just a configuration tool but the interface through which I communicate with the kernel about how it should manage its own behavior. This reflects the Linux philosophy: configuration should be declarative and recoverable.

The final challenge—restoring correct SELinux labels across `/var/log` while respecting role-based access—emphasized that security hardening is about _precision_, not blanket restrictions. Using `restorecon -R`, I restored only the type labels, leaving user and role intact, because arbitrary changes destroy policy coherence. I also changed the context of `/var/index.html` to `httpd_sys_content_t` using `chcon --type`, understanding that this prevents the web server from accessing system files even if the httpd process itself is compromised. This exercise showed me that a competent Linux sysadmin thinks in layers: process confinement, resource isolation, and policy recovery—not just command syntax.

---

## **💻 Comandos Clave**

```bash
# Q1: Encuentra la etiqueta completa de SELinux para el proceso en ejecución sshd y la guarda en el archivo especificado.
sudo ps --context ax | grep "sshd" | grep --invert-match "grep" | awk '{print $1}' > /home/bob/sshd

# Q2: Desactiva la carga de nuevos módulos de kernel en tiempo de ejecución configurando el parámetro en 1 (Verdadero).
sudo sysctl --write kernel.modules_disabled=1

# Q3: Extrae únicamente el tipo ("type") de SELinux del archivo /bin/sudo (el tercer elemento: user:role:type:level) y lo guarda.
ls --context /bin/sudo | awk '{print $1}' | cut --delimiter=":" --fields=3 > /home/bob/selabel

# Q4: Fuerza al sistema a cargar de forma activa el valor actual del parámetro runtime de red IPv6 indicado.
sudo sysctl --write net.ipv6.conf.lo.seg6_enabled=1

# Q5: Cambia la agresividad del espacio de intercambio (swappiness) a 10 y lo añade de forma persistente en /etc/sysctl.conf.
sudo sysctl --write vm.swappiness=10 && echo "vm.swappiness=10" | sudo tee --append /etc/sysctl.conf

# Q6: Cambia manualmente el contexto/etiqueta de SELinux del archivo HTML apuntando específicamente al tipo de contenido web (--type).
sudo chcon --type=httpd_sys_content_t /var/index.html

# Q7: Modifica de manera temporal el estado global de SELinux a modo Permisivo (0), donde se permiten las acciones pero se registran las alertas.
sudo setenforce 0

# Q8: Lista los usuarios de SELinux, busca el usuario staff_u y guarda exclusivamente los roles asignados a él en el archivo del usuario bob.
sudo semanage user --list | grep "staff_u" > /home/bob/serole

# Q9: Restaura de forma recursiva (--recursive) las etiquetas por defecto de SELinux del directorio /var/log basándose en las políticas del sistema.
sudo restorecon --recursive /var/log/
```

---

