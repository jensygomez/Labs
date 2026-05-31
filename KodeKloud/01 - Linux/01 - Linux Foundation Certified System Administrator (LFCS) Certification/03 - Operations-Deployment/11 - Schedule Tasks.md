---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Schedule Tasks
Fecha de Inicio: 2026-04-27
Dificultad: Intermedio-Baja
Tareas Totales: "12"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| `27/04/26` | 25 min | 0 %   |               |
| `16/05/26` | 25 min | 12%   |               |
| `25/05/26` | 45 min | 25 %  |               |
| `31/05/26` | 40 min | 41 %  |               |
|            |        |       |               |

[[Laboratorios del LFCS]]

---

---


Through this lab, I have developed a deeper understanding of how critical task scheduling is in maintaining a resilient Linux infrastructure. I learned that cron, anacron, and at are not simply tools to memorize, but rather philosophical approaches to automation that address different operational realities. While cron executes jobs at fixed times assuming the system is always running, anacron provides a safety net for systems that may be offline, ensuring jobs eventually execute regardless of downtime. This distinction is fundamental: it represents the difference between planned redundancy and guaranteed execution—concepts that are essential when managing production servers where uptime and data integrity cannot be compromised.


What struck me most is understanding the responsibility embedded in task scheduling. When I configured cron jobs to run at specific times or anacron jobs to execute with deliberate delays, I realized I was building the nervous system of infrastructure automation. The ability to schedule a database cleanup job, a service restart, or system maintenance requires not only technical precision but also deep awareness of system load, dependency chains, and failure scenarios. I grasped that scheduling is about communication with future systems—ensuring that critical operations execute when needed, in the right order, and with proper isolation from other processes. This perspective shifted my view from "how do I run a command periodically" to "how do I ensure this system remains predictable and maintainable?"


In my role as NOC Level 1 at Accenture, I now recognize how these scheduling mechanisms directly impact incident response and system reliability. I understand why anacron's timestamp-checking mechanism in `/var/spool/anacron/` is critical for detecting if jobs have actually executed, and why forcing re-execution with `anacron -f` requires careful consideration. I see that managing crontabs across multiple users demands discipline and documentation, and that the `at` utility serves specific scenarios where one-time scheduled execution is needed. This knowledge positions me to move beyond intermediate support into proactive infrastructure management—identifying scheduling gaps, preventing cascading failures, and building systems that self-heal intelligently.

---

## 🔧 Comandos Principales Utilizados:

```bash
# Q1: El comando se ejecutará a las 3:00 AM (--minute=0 --hour=3) el día 15 de cada mes (--day=15), sin importar el mes o el día de la semana.
# Ejecución: A las 03:00 del día 15 de cada mes.

# Q2: Para ver el crontab del usuario root estando logueado como 'alex' (requiere privilegios de sudo).
sudo crontab --user=root --list

# Q3: El archivo de log que se debe analizar para verificar si los trabajos de anacron se ejecutaron con éxito es /var/log/syslog (o /var/log/cron en sistemas RedHat/CentOS).
# Comando para revisarlo: sudo grep "anacron" /var/log/syslog

# Q4: Forzar a anacron a ejecutar todos los trabajos inmediatamente, ignorando las marcas de tiempo de la última ejecución (--force).
sudo anacron --force

# Q5: Listar los trabajos programados en 'at' para el usuario bob y redirigir/guardar la salida en el archivo de texto especificado.
sudo atq --user=bob > /home/bob/at_jobs.txt

# Q6: Eliminar todos los trabajos de 'at' del usuario bob (atrm no tiene bandera larga para usuarios, usamos un bucle o comando directo si somos root).
sudo atrm $(atq --user=bob | cut --fields=1)

# Q7: Añadir la tarea al crontab de root para que corra todos los días a las 21:30 (30 21 * * *).
sudo crontab --user=root -l 2>/dev/null | { cat; echo "30 21 * * * /usr/bin/touch test_passed"; } | sudo crontab --user=root -

# Q8: Para añadir este trabajo de anacron, se debe agregar la siguiente línea al archivo de configuración de anacron (normalmente en /etc/anacrontab).
# Línea a añadir: 10	5	db_cleanup	/usr/bin/touch /root/anacron_created_this.
sudo echo "10 5 db_cleanup /usr/bin/touch /root/anacron_created_this." >> /etc/anacrontab

# Q9: Programar la ejecución del comando usando la utilidad 'at' para las 15:30 del 20 de agosto de 2054 como usuario root.
echo "/usr/bin/touch atscheduler" | sudo at 15:30 2054-08-20

# Q10: Añadir una tarea cron para root que se ejecute a las 12:00 AM (00:00) el primer día de cada mes (0 0 1 * *).
sudo crontab --user=root -l 2>/dev/null | { cat; echo "0 0 1 * * /usr/bin/touch monthly"; } | sudo crontab --user=root -

# Q11: Añadir una tarea cron para root que se ejecute a las 11:00 AM todos los domingos (0 11 * * 0).
sudo crontab --user=root -l 2>/dev/null | { cat; echo "0 11 * * 0 /usr/bin/touch weekly"; } | sudo crontab --user=root -

# Q12: Añadir una tarea cron para el usuario 'bob' para reiniciar nginx los domingos a las 6:00 AM y a las 11:00 PM (0 6,23 * * 0).
sudo crontab --user=bob -l 2>/dev/null | { cat; echo "0 6,23 * * 0 sudo /usr/bin/systemctl restart nginx"; } | sudo crontab --user=bob -
```

---

