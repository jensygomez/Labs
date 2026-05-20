---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - File Permissions, Search for Files
Fecha: 2026-05-11
Dificultad:
Tareas del Lab: "16"
---

## 📊 Bitácora de Intentos
|    Fecha     | Tiempo | Éxito | Task |
| :----------: | :----: | :---: | :--: |
| `11/05/2026` | 20 min | 50 %  |  16  |
| `20/05/2026` |  min   |   %   |  16  |

[[Laboratorios del LFCS]]


---


## Resumen

En este laboratorio se trabajó con permisos de archivos y búsqueda de archivos en Linux. Se practicó principalmente con el comando `find` para localizar archivos según criterios de tamaño, permisos, tiempo de modificación y nombre. También se exploró la configuración de permisos especiales como setuid, setgid y sticky bit usando `chmod`. La mayoría de las tareas involucraron redirigir el output a archivos específicos para almacenar resultados y comparar diferentes sintaxis de permisos (octal vs simbólica).

Las 16 preguntas cubrieron desde búsquedas básicas hasta operaciones complejas, como encontrar archivos con permisos específicos (0640, 0777), archivos modificados en rangos de tiempo (últimos 30 minutos, 2 horas), archivos dentro de rangos de tamaño (5-10MB, 20MB exactos), y aplicar permisos especiales sin notación octal. El laboratorio reforzó la importancia de usar `find` con múltiples criterios y la correcta aplicación de permisos para directorios críticos.

## Comandos Clave

```bash
# Buscar archivos por permisos
sudo find /usr/ -type f -perm 0640

# Buscar archivos por tamaño en rango
sudo find /usr/ -type f -size +5M -size -10M > size.txt

# Buscar archivos modificados en últimas 2 horas
sudo find /usr/ -type f -mmin -120

# Aplicar permisos especiales (simbólico)
sudo chmod u+s,g+s,o+t /home/bob/datadir

# Buscar y redirigir output
sudo find /var/ -type f -perm 0777 > /home/bob/permissions.txt
```