---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: pid
Fecha: 2004-05-17
Estado: completado
Type: Video
Dificultad: Básico Medio
tags:
---


---

Un PID (Process ID) es el identificador único asignado a cada proceso en el sistema. Cuando ejecutas un script bash, se crean procesos hijos con sus propios PIDs independientes. No todos los comandos dentro de un script generan un PID nuevo; algunos se ejecutan dentro del proceso actual. El TTY (TeleTYpe) indica la terminal asociada al proceso. El operador ampersand (`&`) permite ejecutar un proceso en background, devolviendo el control de la terminal inmediatamente, a diferencia de la ejecución normal en foreground donde el shell espera a que termine.

Para monitorear y debuggear procesos es fundamental conocer herramientas como `ps` (Process Status), que muestra los procesos activos con flags como `-e` para todos los procesos y `-f` para información detallada de cada uno. El comando `top` ofrece una vista dinámica en tiempo real. Para un análisis más profundo de llamadas del sistema y timing, `strace` es invaluable, permitiendo rastrear child processes con `-f`, información de timing con `-T`, y especificar el PID padre con `-p`.

**Comando de ejemplo:**

```bash
# Ver todos los procesos con información detallada
ps -ef | grep <nombre_script>

# Monitorear un PID específico con timing y child processes
strace -Tfp 1234

# Ejecutar script en background y obtener su PID
./script.sh &
# Luego verificar con
ps -ef | grep $$
```