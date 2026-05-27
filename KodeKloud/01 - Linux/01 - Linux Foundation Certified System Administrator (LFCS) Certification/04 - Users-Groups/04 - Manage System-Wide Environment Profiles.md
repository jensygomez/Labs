---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Manage System-Wide Environment Profiles
Typo: Video
Fecha: 01/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 6 min
tags:
---

Se exploraron las variables de entorno del sistema y cómo estas se almacenan en memoria para cada usuario. El comando `printenv` permite visualizar todas las variables de entorno configuradas, mientras que `history` muestra el historial de comandos ejecutados. Un aspecto clave es que al usar variables de entorno como `$HOME` en scripts, se garantiza que estos se ejecuten correctamente independientemente del usuario que los lance, mejorando la portabilidad y robustez del código. La personalización de variables de entorno se realiza a través del archivo `/etc/environment`, que contiene las configuraciones a nivel del sistema. Este archivo es fundamental para establecer variables globales que afecten a todos los usuarios y sesiones del sistema, permitiendo una gestión centralizada de la configuración del entorno de trabajo en Rocky Linux.

## Ejemplo de comando 

```bash 
printenv 
printenv HOME 
echo $HOME 
```
