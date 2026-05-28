---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Lab - Configure User Resource Limits
Fecha: 2002-04-20
Dificultad: Intermedio-Medio
Tareas Totales: "11"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `20/04/2026` | 20 min | 27 %  |               |
| `1705/2026`  | 25 min | 27 %  |               |
| `28/05/2026` | 20 min | 45 %  |               |

[[Laboratorios del LFCS]]



**Throughout this exercise, I came to understand that security in Linux is not about memorizing commands—it's about grasping the principle that every user interaction with the system must be explicitly authorized and audited. When I configured process limits for users through `/etc/security/limits.conf`, I realized I was implementing a boundary: a philosophical commitment that no single user can monopolize system resources and destabilize the entire infrastructure. This isn't just defensive practice; it's about building resilience into the system architecture itself.**

**The sudoers file taught me something deeper about the principle of least privilege. Rather than granting blanket administrative access, I learned to ask myself critical questions: _What is the minimal permission this user actually needs?_ Restricting `trinity` to only the `/usr/bin/mount` command isn't about being restrictive—it's about reducing the attack surface and creating accountability. In a production environment with hundreds of users and multiple servers, this distinction becomes the difference between a compromised system and one that remains operational during a security incident.**

**What struck me most was understanding that these mechanisms—limits, sudoers policies, PAM enforcement—are not isolated tools. They work together as a cohesive security posture that reflects Linux's foundational philosophy: transparency, predictability, and explicit control. As a NOC professional moving toward sysadmin responsibilities, I now see that managing Linux servers means thinking like an architect of constraints, not just an executor of commands.**



## **Comandos utilizados:**

```bash
Ver todos los límites de seguridad de la sesión actual
ulimit -a

Guardar los límites actuales en archivo
ulimit -a > /home/bob/limits

Establecer límite duro y suave de procesos para usuario trinity (una sola línea)
echo "trinity hard,soft nproc 30" >> /etc/security/limits.conf

Permitir que trinity ejecute cualquier comando sudo sin contraseña
echo "trinity ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

Permitir que trinity ejecute solo el comando mount con sudo
echo "trinity ALL=(ALL) NOPASSWD: /usr/bin/mount" >> /etc/sudoers

Establecer límite duro de tamaño de archivo para stephen (4 MiB)
echo "stephen hard fsize 4096" >> /etc/security/limits.conf

Establecer límite suave de procesos para grupo salesteam
echo "@salesteam soft nproc 20" >> /etc/security/limits.conf

Permitir que salesteam ejecute cualquier sudo command
echo "%salesteam ALL=(ALL) ALL" >> /etc/sudoers

Permitir que trinity ejecute sudo como usuario sam
echo "trinity ALL=(sam) ALL" >> /etc/sudoers

Editar sudoers de forma segura (método recomendado)
visudo

Recargar límites de seguridad sin reiniciar
systemctl restart systemd-logind
```

---

```