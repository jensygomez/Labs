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
| `16/05/26` | 25 min | 0%    |               |
| `25/05/26` | 45 min | 25 %  |               |
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
# Sintaxis fundamental cron: minuto(0-59) hora(0-23) día_mes(1-31) mes(1-12) día_semana(0-7)
# Ejemplo Q1: 0 3 15 * * = 3:00 AM del día 15 de cada mes
crontab -e                                    # Editar crontab del usuario actual
sudo crontab -u root -e                       # Ver/editar crontab de root como otro usuario
crontab -l                                    # Listar crontab actual
sudo crontab -u root -l                       # Listar crontab de root
cat /var/spool/anacron/*                      # Verificar ejecución anacron (Q3)
anacron -f                                    # Forzar re-ejecución de todos los jobs anacron (Q4)
atq                                           # Ver jobs programados en at (Q5)
at 15:30 20.08.2054                          # Programar job único con at (Q9)
atrm $(atq | awk '{print $1}')               # Remover todos los jobs at del usuario actual
# Ejemplos de cron entries finales: 30 21 * * * /usr/bin/touch test_passed (diario 21:30)
# 0 0 1 * * /usr/bin/touch monthly (1er día mes medianoche) | 0 11 * * 0 /usr/bin/touch weekly (domingos 11 AM)
```

---

