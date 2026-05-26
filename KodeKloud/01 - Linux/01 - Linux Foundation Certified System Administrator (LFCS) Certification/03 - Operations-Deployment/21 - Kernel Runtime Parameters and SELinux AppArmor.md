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

[[Laboratorios del LFCS]]


---

During this hands-on assessment, I worked through a comprehensive security hardening scenario that reinforced my understanding of Linux kernel-level access control mechanisms. Rather than merely executing commands, I focused on comprehending the _why_ behind each configuration: SELinux operates as a mandatory access control layer that enforces policy decisions at the kernel level, preventing privilege escalation and unauthorized process execution regardless of traditional UNIX permissions. I identified that the sshd process operates under the `system_u:system_r:sshd_t` context, understanding that this type-based enforcement is critical in production environments where a compromised service cannot accidentally or maliciously access unintended resources. This taught me that security in Linux is not about knowing commands—it's about understanding that every label, every context, and every policy decision serves a specific containment strategy.

The second aspect of this work centered on kernel parameter persistence and runtime tuning, which revealed a deeper principle: temporary system modifications without persistence are merely testing grounds, not production-ready solutions. I disabled kernel module loading via `kernel.modules_disabled` and adjusted `vm.swappiness` to 10, but critically, I made the swappiness change persistent by appending it to `/etc/sysctl.conf`. This distinction matters profoundly in production—a sysadmin who only knows how to make temporary changes will leave systems vulnerable during reboots, when policy enforcement resets. I also verified the `net.ipv6.conf.lo.seg6_enabled` parameter, learning that sysctl is not just a configuration tool but the interface through which I communicate with the kernel about how it should manage its own behavior. This reflects the Linux philosophy: configuration should be declarative and recoverable.

The final challenge—restoring correct SELinux labels across `/var/log` while respecting role-based access—emphasized that security hardening is about _precision_, not blanket restrictions. Using `restorecon -R`, I restored only the type labels, leaving user and role intact, because arbitrary changes destroy policy coherence. I also changed the context of `/var/index.html` to `httpd_sys_content_t` using `chcon --type`, understanding that this prevents the web server from accessing system files even if the httpd process itself is compromised. This exercise showed me that a competent Linux sysadmin thinks in layers: process confinement, resource isolation, and policy recovery—not just command syntax.

---

## **💻 Comandos Clave**

```bash
# Consultar contexto SELinux de un archivo
ls -lZ /bin/sudo

# Cambiar contexto SELinux de un archivo
sudo chcon -t httpd_sys_content_t /var/index.html

# Listar etiquetas SELinux de un proceso
ps -eZ | grep sshd

# Ver parámetros del kernel actualmente
sysctl net.ipv6.conf.lo.seg6_enabled

# Establecer parámetro kernel temporalmente
sudo sysctl -w vm.swappiness=10

# Hacer persistente un parámetro del kernel
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Deshabilitar carga de módulos kernel
sudo sysctl -w kernel.modules_disabled=1

# Ver modo SELinux actual
getenforce

# Cambiar SELinux a Permissive (temporal)
sudo setenforce Permissive

# Restaurar contextos SELinux por defecto
sudo restorecon -Rv /var/log

# Ver roles SELinux de un usuario
sudo semanage user -l | grep staff_u
```

---

