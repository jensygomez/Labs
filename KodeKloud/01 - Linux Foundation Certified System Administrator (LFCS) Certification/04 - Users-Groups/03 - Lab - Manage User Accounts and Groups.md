---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Lab - Manage User Accounts and Groups
Typo: Laboratorio
Fecha: 01/05/2026
Estado: completado
Dificultad: Intermedio
Calificación: 11/13
Time: 30 min
tags:
  - "#Linux/LFCS-Certification/Users-Groups/Laboratorio"
---

## Resumen

En este laboratorio se profundizó en la gestión completa de cuentas de usuario y grupos en Linux, utilizando herramientas como `useradd`, `usermod`, `groupadd` y `groupmod`. Se cubrieron aspectos críticos como la expiración de cuentas, la configuración de shells personalizados, la asignación de UIDs/GIDs específicos, y la gestión de membresías en grupos primarios y secundarios. Las acciones realizadas incluyeron crear usuarios con configuraciones especiales, modificar propiedades existentes, renombrar grupos preservando identificadores, y establecer políticas de expiración de contraseñas para obligar cambios periódicos.

El laboratorio reforzó la importancia de entender la estructura de identificadores en Linux y cómo los permisos y accesos se vinculan directamente a la membresía en grupos. Conceptos como cuenta de sistema versus cuenta de usuario regular, la diferencia entre grupo primario y secundario, y la expiración anticipada de contraseñas son fundamentales para un SysAdmin Linux. También se practicó con comandos como `id`, `usermod --expiredate`, `groupmod --new-name`, y opciones de expiración de contraseña para cumplir políticas de seguridad.

## Comandos Clave

bash

```bash
# Establecer fecha de expiración de cuenta
sudo usermod --expiredate 2030-03-01 jane

# Crear usuario con UID y grupos específicos
sudo useradd --uid 5322 --groups soccer sam

# Crear grupo con GID personalizado
sudo groupadd --gid 9875 cricket

# Renombrar grupo preservando GID
sudo groupmod --new-name soccer cricket

# Configurar shell personalizado y home directory
sudo useradd -m -s /bin/csh jack

# Establecer aviso de expiración de contraseña
sudo chage -W 2 jane
```