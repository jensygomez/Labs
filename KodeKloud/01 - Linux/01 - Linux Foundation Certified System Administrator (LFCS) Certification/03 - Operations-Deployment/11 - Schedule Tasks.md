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
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 16 - 05 - 2026 | 25 min |  0 %  |               |
|                |        |       |               |

[[Laboratorios del LFCS]]

  ### 📝 Resumen

Este laboratorio se enfoca en la programación de tareas en Linux, una habilidad esencial para automatizar operaciones repetitivas en servidores. Cubre tres mecanismos principales: **crontab** para tareas recurrentes con precisión de minutos, **at** para ejecuciones únicas en fechas/horas específicas, y **anacron** para trabajos que se ejecutan independientemente del estado del sistema. A través de 12 ejercicios, se practica la sintaxis de cron (minuto, hora, día del mes, mes, día de la semana), creación de jobs para diferentes usuarios (root, bob, alex), y gestión de tareas programadas. Casos de uso incluyen reinicio automático de servicios, creación de archivos de prueba en horarios específicos, y limpieza de bases de datos con intervalos definidos.

El laboratorio integra conceptos de seguridad (ejecución con sudo), auditoría (verificación de logs en /var/log/cron), y troubleshooting de tareas fallidas. Dominar estas herramientas es crítico para un sysadmin Linux: permite automatizar backups, rotación de logs, actualizaciones de sistemas, y monitoreo sin intervención manual. La diferencia entre crontab (requiere que el sistema esté activo) y anacron (tolera sistemas apagados) es fundamental para entornos de producción heterogéneos.

### 💻 Ejemplos de Comandos

bash

```bash
# Ver sintaxis cron: minuto hora día_mes mes día_semana comando
# Ejemplo: ejecutar comando cada día a las 21:30
crontab -e
# 30 21 * * * /usr/bin/touch test_passed

# Editar crontab del usuario root como otro usuario
sudo crontab -u root -e

# Ver crontab del usuario actual
crontab -l

# Programar comando único con at (15:30 del 20 de agosto de 2054)
at 15:30 20.08.2054
# /usr/bin/touch atscheduler

# Ver trabajos at programados
atq

# Remover todos los jobs de at del usuario bob
atrm $(atq | grep bob | awk '{print $1}')

# Agregar job anacron (cada 10 días, delay 5 min, id: db_cleanup)
# Se edita /etc/anacrontab o /etc/anacron.d/
10 5 db_cleanup /usr/bin/touch /root/anacron_created_this

# Forzar ejecución de todos los jobs anacron
anacron -f
```