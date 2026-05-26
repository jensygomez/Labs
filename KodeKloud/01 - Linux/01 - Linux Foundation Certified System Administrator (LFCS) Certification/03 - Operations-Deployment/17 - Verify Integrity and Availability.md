---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Verify Integrity and Availability
Fecha de Inicio: 2026-04-29
Dificultad: Intermedio-Medio
Tareas Totales: "6"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| `29/04/26` | 30 min | 0 %   |               |
| `16/05/26` | 30 min | 0 %   |               |
| `26/05/26` | 30 min | 66 %  |               |

[[Laboratorios del LFCS]]


---

In this system diagnostics assessment, I moved beyond package management into the operational reality of what it means to maintain a Linux infrastructure. I discovered that monitoring disk utilization isn't simply about running `df` or `du`; it's about understanding the critical difference between filesystem-level metrics and actual directory footprints. When I extracted the percentage of used space on the root partition and the storage consumed by `/bin/`, I recognized these are early-warning signals for capacity planning and system degradation. A partition that creeps toward 90% used can trigger cascading failures in production—from log rotation failures to temporary file creation issues—which is why a competent sysadmin must establish thresholds and automated alerts long before crisis arrives.

Memory and uptime analysis taught me that system resources tell a story about stability and load patterns. By querying total RAM through `free` and system uptime through `uptime`, I learned to read the pulse of an infrastructure. A system that shows high memory usage paired with short uptime might indicate a memory leak or crashed service that was auto-restarted; conversely, high uptime with stable memory suggests a well-tuned environment. These metrics are foundational to capacity planning and incident response—I cannot intelligently scale infrastructure or troubleshoot performance issues without understanding what resources are currently available and how long the system has been running under its current configuration.

The final challenges—identifying CPU topology through `lscpu` and verifying XFS filesystem integrity—reinforced that modern infrastructure requires deep visibility into hardware and storage layers. Checking CPU cores per socket isn't academic; it directly impacts how I tune multi-threaded applications and allocate workloads across sockets to minimize latency. Running `xfs_repair` in read-only mode to detect filesystem corruption without taking systems offline exemplifies the principle that prevention and early detection protect availability far better than reactive repair. This assessment solidified my conviction that a true sysadmin must think systemically—every command reveals interconnected layers, and missing any layer risks cascading failures in production.

---
### 💻 Ejemplos de Comandos

bash

```bash
# Ver porcentaje de espacio usado en partición /
df -h / | tail -1 | awk '{print $5}'

# Verificar uso de espacio del directorio /bin/
du -sh /bin/

# Ver memoria RAM total en MB
free -m | grep Mem | awk '{print $2}'

# Ver tiempo de disponibilidad del sistema
uptime

# Ver cores por socket
lscpu | grep "Core(s) per socket"

# Verificar integridad de filesystem XFS
xfs_repair -n /dev/vdd  # -n para modo lectura

# Reparar filesystem XFS (requiere desmontado)
xfs_repair /dev/vdd

# Guardar salida en archivo
df -h / | tail -1 | awk '{print $5}' > /home/bob/used
du -sh /bin/ | awk '{print $1}' > /home/bob/bin
free -m | grep Mem | awk '{print $2}' > /home/bob/memory
uptime | awk '{print $(NF-2)}' > /home/bob/up
lscpu | grep "Core(s) per socket" | awk '{print $NF}' > /home/bob/cpu
xfs_repair -n /dev/vdd > /home/bob/fscheck
```