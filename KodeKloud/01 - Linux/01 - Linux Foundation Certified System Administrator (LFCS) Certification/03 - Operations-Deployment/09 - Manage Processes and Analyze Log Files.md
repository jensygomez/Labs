---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Manage Processes and Analyze Log Files
Fecha de Inicio: 2026-05-16
Dificultad: Intermedio-Baja
Tareas Totales: "13"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| `16/05/26` | 35 min | 7 %   |               |
| `25/05/26` | 40 min | 23 %  |               |
[[Laboratorios del LFCS]]


![[Lab - Manage Processes and Analyze Log Files.mp3]]

---

In this laboratory, I focused on managing processes and analyzing log files, two critical skills for any Linux administrator. I learned how to view all running processes along with their nice values, change process priority using `nice`, identify PIDs, and send signals such as SIGHUP to services. I also practiced running processes in the background and checking resource usage of specific processes like PID 1. These tasks reinforced the Linux philosophy that the system administrator has full control over what runs on the machine and how resources are allocated.

I also gained practical experience working with system logs. I searched for specific information in traditional log files under `/var/log` and used `journalctl` to filter logs by priority (errors, info, etc.) and content. This included finding the last successful SSH connection IP and searching for reboot records. Understanding both classic log files and the modern systemd journal is essential for troubleshooting and auditing system behavior effectively.

This lab helped me connect process management with log analysis, showing how both are used together when diagnosing issues in real environments. In a technical interview, I can clearly explain how to monitor and control processes, adjust priorities, work with signals, and efficiently search through logs using both traditional tools and `journalctl`. These are highly practical skills that demonstrate I can maintain system stability and quickly resolve problems.

---

**Key commands to remember:**

- `ps -eo pid,comm,nice`
- `nice -n 9 sshd`
- `lsof -p 1 > files.txt`
- `journalctl -p err` / `journalctl -p info`
- `grep -r "reboot" /var/log/`
- `kill -HUP <PID>`
- `sleep 3000 &`
