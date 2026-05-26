---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Scripting, Manage Startup Process and Services
Fecha de Inicio: 2026-05-15
Dificultad: Intermedio-Medio
Tareas Totales: "14"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| `15/05/26` | 40 min | 35 %  |               |
| `24/05/26` | 40 min | 35 %  |               |

[[Laboratorios del LFCS]]

**Here’s your summary in Advanced B2 English, first person singular:**

---

In this laboratory, I practiced essential system administration tasks related to startup processes and service management. I learned how to schedule a system shutdown, change the default boot target from text-only (multi-user) to graphical desktop, and cancel scheduled tasks. I also worked with systemd services by checking their status, finding process PIDs, masking and unmasking services, and editing service unit files to modify restart behavior and dependencies. These skills reflect the Linux philosophy of having complete control over when and how the system starts and runs services.

I also strengthened my Bash scripting abilities. I created scripts to perform practical tasks such as creating compressed archives, modifying directory permissions, and checking service status. I paid special attention to using the correct shebang and making scripts executable. This lab emphasized writing simple but useful automation scripts, which is a core skill for any Linux administrator who wants to work efficiently.

Overall, this lab helped me understand how to manage the boot process and services in modern Linux systems using systemd. In a technical interview, I can confidently explain how to control system startup, create useful scripts, and properly manage services — including editing unit files to improve reliability and security. These are highly valued skills for real production environments.

---

**Key commands to remember:**

- `shutdown -h +120` / `shutdown -c`
- `systemctl set-default graphical.target`
- `./script.sh` or `bash script.sh`
- `systemctl status sshd`
- `systemctl mask apache2` / `systemctl unmask apache2`
- `tar -czf archive.tar.gz dir1`
- `chmod u=x,go= directory`

---
