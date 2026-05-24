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
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 16 - 05 - 2026 | 35 min | 7 %   |               |
|                |        |       |               |
[[Laboratorios del LFCS]]
### 📝 Resumen

Este laboratorio cubre dos pilares fundamentales de la administración de sistemas Linux: la gestión de procesos y el análisis de logs del sistema. A través de 13 ejercicios prácticos, se trabaja con herramientas como `ps`, `systemctl` y `journalctl` para monitorear, controlar y enviar señales a procesos. También se practican filtros avanzados en logs, extracción de información crítica como PIDs, direcciones IP de conexiones SSH, y redirección de salidas a archivos específicos. Los conceptos clave incluyen valores de prioridad (nice), información de recursos de procesos, y búsqueda de patrones en archivos de log del sistema.

El laboratorio integra comandos de gestión de procesos con análisis de logs, simulando tareas reales de troubleshooting que un sysadmin Linux debe dominar diariamente. Desde identificar procesos por PID hasta extraer información de seguridad de logs de SSH, cada tarea prepara para auditorías, optimización de recursos y resolución de problemas en entornos de producción.

### 💻 Ejemplos de Comandos

bash

```bash
# Ver todos los procesos con sus nice values
ps aux

# Obtener información de CPU y memoria del PID 1
ps -p 1 -o pid,user,cmd,%cpu,%mem

# Buscar proceso por nombre y obtener su PID
ps aux | grep rpcbind | grep -v grep

# Ejecutar un comando en background
sleep 3000 &

# Enviar señal SIGHUP a un proceso
kill -HUP <PID>

# Buscar logs de SSH con journalctl
journalctl -u ssh.service | grep -i connected

# Buscar archivos en /var/log que contengan "reboot"
grep -r "reboot" /var/log
```