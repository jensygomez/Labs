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
| Fecha        | Tiempo | Éxito   | Notas Rápidas |
| :----------- | :----- | :------ | :------------ |
| `16/05/26`   | 35 min | 7 %     |               |
| `25/05/26`   | 40 min | 23 %    |               |
| `31/05/2026` | 40 min | 38.46 % |               |
[[Laboratorios del LFCS]]


In this laboratory, I focused on managing processes and analyzing log files, two critical skills for any Linux administrator. I learned how to view all running processes along with their nice values, change process priority using `nice`, identify PIDs, and send signals such as SIGHUP to services. I also practiced running processes in the background and checking resource usage of specific processes like PID 1. These tasks reinforced the Linux philosophy that the system administrator has full control over what runs on the machine and how resources are allocated.

I also gained practical experience working with system logs. I searched for specific information in traditional log files under `/var/log` and used `journalctl` to filter logs by priority (errors, info, etc.) and content. This included finding the last successful SSH connection IP and searching for reboot records. Understanding both classic log files and the modern systemd journal is essential for troubleshooting and auditing system behavior effectively.

This lab helped me connect process management with log analysis, showing how both are used together when diagnosing issues in real environments. In a technical interview, I can clearly explain how to monitor and control processes, adjust priorities, work with signals, and efficiently search through logs using both traditional tools and `journalctl`. These are highly practical skills that demonstrate I can maintain system stability and quickly resolve problems.

---

**Key commands to remember:**

```bash
# Task 1 — Ver procesos del sistema
ps aux

# Task 2 — Iniciar proceso con prioridad reducida
sudo nice --adjustment=9 sshd

# Task 3 — Cambiar prioridad de proceso en ejecución
sudo renice --priority=9 1117

# Task 4 — Listar archivos abiertos por PID 1
sudo lsof -p 1 > /home/bob/files.txt

# Task 5 — Encontrar PID de rpcbind
sudo systemctl status rpcbind
echo "605" > /home/bob/pid.txt

# Task 6 — Encontrar última IP conectada por SSH
sudo journalctl --unit=ssh.service --no-pager | grep "Accepted" | tail --lines=1
echo "192.168.92.13" > /home/bob/ip.txt

# Task 7 — Enviar señal SIGHUP al proceso SSH
sudo kill --signal=SIGHUP 1117

# Task 8 — Buscar string reboot en /var/log/
sudo grep --recursive --text 'reboot' /var/log/ > /home/bob/reboot.log

# Task 9 — Logs de error con journalctl
sudo journalctl --priority=err > /home/bob/.priority/priority.log

# Task 10 — Logs info filtrados por letra c
sudo journalctl --priority=info --grep='^c' > /home/bob/.priority/boot.log

# Task 11 — Ver recursos del proceso PID 1
sudo ps u 1 > /home/bob/resources.txt

# Task 12 — Correr proceso en background
sudo sleep 3000 &```

