
#lfcs #linux #operations #Operations-Deployments #TaskScheduling #Cron #Anacron #At  #lab 

**Curso:** Prep Course - Linux Foundation Certified System Administrator (LFCS) Certification **Módulo:** Operations Deployment **Laboratorio:** Schedule Tasks **Duración:** 20 minutos **Resultado:** Bajo - Necesita refuerzo **Fecha:** 27 Abril 2026

## Resumen

Este laboratorio cubre los tres mecanismos principales de programación de tareas en Linux: **cron** (tareas repetitivas), **anacron** (tareas para sistemas que no están siempre encendidos) y **at** (tareas puntuales). Son conceptos fundamentales para cualquier sysadmin que necesita automatizar procesos, gestionar backups y mantener sistemas sin intervención manual. Las preguntas prácticas exigían tanto comprensión teórica como capacidad de ejecutar comandos correctamente.

El desempeño bajo refleja que aún no domino completamente la sintaxis de cron y los comandos específicos de anacron y at. Estos son pilares de la automatización en Linux y necesito dedicar más tiempo a la práctica hands-on en mi VM Rocky Linux 9.7. Especialmente las preguntas 4, 5, 6 y 7 revelan gaps en el conocimiento de la utilidad `at` y la configuración de crontab.

## Respuestas Correctas

|Q|Pregunta|Respuesta Correcta|
|---|---|---|
|1|¿Cuándo corre: `0 3 15 * * /usr/bin/touch test_passed`?|15 de cada mes a las 3 AM|
|2|¿Ver crontab del root estando logueado como alex?|`sudo crontab -u root -l`|
|3|¿Qué archivo analizar para verificar anacron?|`/var/log/anacron`|

## Respuestas Que Necesito Dominar

### Q4: Force anacron para rerun todos los jobs

```bash
anacron -f
```

La opción `-f` fuerza la ejecución inmediata, ignorando los tiempos de ejecución anterior.

### Q5: Ver scheduled jobs de at utility

```bash
atq  # O también: at -l
```

Para guardar en `/home/bob/at_jobs.txt`: `atq > /home/bob/at_jobs.txt`

### Q6: Remover todos los at jobs del usuario bob

```bash
atrm $(atq | grep -E '^[0-9]+' | awk '{print $1}')
```

O más simple: `for job in $(atq | awk '{print $1}'); do atrm $job; done`

### Q7: Agregar cron a root para correr diariamente a 21:30

```bash
sudo crontab -e
# Agregar esta línea:
30 21 * * * /usr/bin/touch test_passed
```

### Q8: Crear anacron job cada 10 días con 5 min delay

Editar `/etc/anacrontab` como root:

```
10  5   db_cleanup   /usr/bin/touch /root/anacron_created_this
```

### Q9: Usar at para ejecutar comando el 20 agosto 2054 a las 15:30

```bash
sudo at 15:30 aug 20 2054
# Luego ingresar el comando en el prompt
/usr/bin/touch atscheduler
# Presionar Ctrl+D para terminar
```

### Q10: Cron para correr a las 00:00 del 1er día de cada mes

```bash
0 0 1 * * /usr/bin/touch monthly
```

### Q11: Cron para correr a las 11:00 AM cada domingo

```bash
0 11 * * 0 /usr/bin/touch weekly
```

### Q12: Cron para bob - restart nginx domingos a 6am y 11pm

```bash
# Como root:
sudo crontab -u bob -e
# Agregar:
0 6 * * 0 /usr/bin/systemctl restart nginx
0 23 * * 0 /usr/bin/systemctl restart nginx
```

## Próximos Pasos

1. **Practicar en VM:** Ejecutar cada comando en Rocky Linux 9.7 hasta interiorizarlos
2. **Memorizar sintaxis cron:** `min hour day month day-of-week command`
3. **Entender diferencias:** cron vs anacron vs at
4. **Revisar logs:** Verificar `/var/log/cron` y `/var/log/anacron`