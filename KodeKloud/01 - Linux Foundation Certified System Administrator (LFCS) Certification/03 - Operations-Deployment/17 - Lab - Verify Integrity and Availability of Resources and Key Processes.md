---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Verify Integrity and Availability of Resources and Key Processes
Typo: Laboratorio
Fecha: 29/04/2026
Estado: completado
Dificultad: Media
Calificación: 1/6
Time: 20 min
tags:
  - "#Linux/LFCS-Certification/Operations-Deployment/Laboratorio"
---
En este laboratorio se practicó la identificación y monitoreo de recursos críticos del sistema usando comandos esenciales de diagnóstico. Se trabajó con `df` para verificar el uso de particiones, `du` para analizar consumo de directorios, `free` para monitoreo de memoria RAM, `uptime` para tiempo de actividad del sistema, y `lscpu` para información de núcleos de procesador. Cada resultado se guardó en archivos específicos en /home/bob/, simulando un proceso real de recopilación de métricas para auditorías de salud del sistema.

La práctica refuerza habilidades fundamentales de troubleshooting y monitoreo que un Sysadmin Linux debe dominar para mantener la integridad y disponibilidad de recursos. Estos comandos son la base para scripts de monitoreo automatizado, alertas de capacidad y reportes de estado del sistema en entornos de producción. Adicionalmente, se verificó la integridad de sistemas de archivos XFS con herramientas de chequeo, consolidando el conocimiento sobre mantenimiento preventivo.

**Comandos de ejemplo:**

bash

```bash
# Verificar uso de partición
df -h /

# Analizar tamaño de directorio
du -h /bin/

# Monitoreo de memoria en MB
free -m

# Tiempo de actividad del sistema
uptime

# Información de CPU
lscpu

# Verificar integridad de filesystem XFS
xfs_repair -n /dev/vdd
```