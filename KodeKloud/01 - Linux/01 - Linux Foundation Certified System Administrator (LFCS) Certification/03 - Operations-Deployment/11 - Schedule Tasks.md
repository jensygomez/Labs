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
| `25/05/26` |        |       |               |

[[Laboratorios del LFCS]]

---


---



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