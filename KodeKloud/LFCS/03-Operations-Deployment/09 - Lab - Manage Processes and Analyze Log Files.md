#lab  #lfcs #linux   #operations     #processes        #completed       #with-help     #time:20min      

**Tiempo:** 20 minutos | **Completado:** ✅ Con ayuda

**Módulo:** [[Operations - MOC]] 

---

## Resumen

Este laboratorio cubrió la gestión de procesos en Linux y el análisis de logs del sistema. Aprendimos a visualizar procesos con `ps aux`, modificar prioridades con `nice` y `renice`, buscar procesos específicos con `pgrep`, listar archivos abiertos con `lsof`, enviar señales con `kill`, buscar en logs con `grep` y `journalctl`, y ejecutar procesos en background. Los conceptos clave fueron entender que `/var/log/` es el directorio principal de logs, que `journalctl` es la herramienta moderna para logs del sistema, y que las nice values van de -20 (máxima prioridad) a +19 (mínima).

---

## Comandos clave

|Tarea|Comando|
|---|---|
|Ver todos los procesos|`ps aux`|
|Cambiar prioridad|`renice -n 9 -p PID`|
|Buscar PID por nombre|`pgrep rpcbind`|
|Archivos abiertos|`lsof -p PID > archivo.txt`|
|Señal a proceso|`kill -SIGHUP PID`|
|Buscar en logs|`grep "texto" /var/log/auth.log`|
|Logs por prioridad|`journalctl -p err`|
|Procesos en background|`sleep 3000 &`|

---
