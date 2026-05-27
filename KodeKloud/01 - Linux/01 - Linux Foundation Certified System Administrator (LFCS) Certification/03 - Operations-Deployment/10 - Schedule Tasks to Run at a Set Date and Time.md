
**Módulo:** Operations Deployment | **Curso:** LFCS Certification Prep Course



Existen tres herramientas principales para agendar tareas en Linux: **cron** (tareas periódicas recurrentes, ideal para ejecutar un proceso cada domingo a las 3 AM), **anacron** (ejecuta tareas incluso si el sistema estuvo apagado, necesita instalación manual en Ubuntu a diferencia de cron) y **at** (para tareas únicas/puntuales que se ejecutan una sola vez). Cron usa el archivo `crontab -e` con formato de minuto, hora, día del mes, mes, día de la semana y comando; anacron fue creado para sistemas que no están siempre encendidos. Se puede configurar cron para múltiples usuarios, editar sus archivos individuales y removerlos. La sintaxis de anacron se valida con la flag `-T`. Anacron utiliza directorios especiales como daily, hourly para organizar tareas. At viene preinstalado en Ubuntu y es ideal para tareas puntuales.

---

