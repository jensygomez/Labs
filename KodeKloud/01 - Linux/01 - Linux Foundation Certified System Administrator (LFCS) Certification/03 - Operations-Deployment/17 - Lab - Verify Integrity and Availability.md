---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Verify Integrity and Availability
Fecha de Inicio: 2026-04-29
Dificultad: Intermedio-Baja
Tareas Totales: "6"
tags:
  - Linux
  - Linux/LFCS-Certification
  - Linux/LFCS-Certification/Operations-Deployment
  - Linux/LFCS-Certification/Operations-Deployment/Lab-Verify-Integrity-and-Availability
  - Linux/LFCS-Certification/Operations-Deployment/Lab-Verify-Integrity-and-Availability/Laboratorio
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 16 - 05 - 2026 | 30 min | 0 %   |               |
|                |        |       |               |
### 📝 Resumen

Este laboratorio se centra en la verificación de integridad y disponibilidad de sistemas Linux, habilidades críticas para mantener la salud operacional de servidores en producción. A través de 6 ejercicios prácticos, se trabaja con herramientas de monitoreo de recursos como `df` (espacio en disco), `du` (uso de directorios), `free` (memoria RAM), `uptime` (tiempo de disponibilidad del sistema), `lscpu` (información de CPU), y `xfs_repair`/`xfs_admin` (integridad de filesystems XFS). Cada tarea requiere extraer información específica del sistema y almacenarla en archivos para auditoría y documentación.

El laboratorio simula escenarios reales de troubleshooting: identificar particiones llenas que afectan disponibilidad, verificar integridad de filesystems antes de fallos críticos, monitorear recursos de hardware, y documentar el estado del sistema. Dominar estas herramientas permite detectar proactivamente problemas de capacidad, validar filesystems corruptos, y mantener registros históricos de la salud del sistema—fundamentales para SLAs y compliance en entornos empresariales.

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