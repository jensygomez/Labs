---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Lab - Configure User Resource Limits and User Privileges
Typo: Laboratorio
Fecha: 02/05/2026
Estado: completado
Dificultad: Intermedio-Baja
Calificación: 27 %
Time: 20 min
tags:
  - "#Linux/LFCS-Certification/Users-Groups/Laboratorio"
---

## Resumen

Este laboratorio se enfoca en la gestión de límites de recursos y privilegios de usuarios en Linux. Se trabajó con el archivo de límites de seguridad (`/etc/security/limits.conf`) para controlar el número máximo de procesos, tamaño de archivos y otros recursos que pueden consumir usuarios específicos o grupos. Se aprendió a establecer tanto límites "hard" (forzados por el kernel) como "soft" (advertencias del sistema) en una sola línea de configuración. Además, se practicó la modificación del archivo `sudoers` para otorgar diferentes niveles de privile­gios, desde ejecución sin contraseña hasta restricción a comandos específicos como `/usr/bin/mount`.

El laboratorio también cubrió la resolución de problemas cuando las políticas no se aplican correctamente, validando que los usuarios pertenezcan a los grupos configurados y que los cambios en `limits.conf` se hayan guardado apropiadamente. Estos conocimientos son fundamentales para administrar sistemas Linux multiusuario de forma segura, permitiendo que cada usuario tenga acceso controlado a recursos y operaciones administrativas según su rol y responsabilidades.

## Comando Ejemplo

bash

```bash
# Ver límites actuales de la sesión de un usuario
ulimit -a

# Guardar límites en archivo
ulimit -a > /home/bob/limits

# Configurar límite de procesos en limits.conf
echo "trinity hard nproc 30" >> /etc/security/limits.conf
echo "trinity soft nproc 30" >> /etc/security/limits.conf

# O en una sola línea (ambos límites)
echo "trinity nproc 30" >> /etc/security/limits.conf

# Permitir usuario en sudoers sin contraseña
echo "trinity ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Restringir a un comando específico
echo "trinity ALL=(ALL) NOPASSWD: /usr/bin/mount" >> /etc/sudoers

# Editar sudoers de forma segura
visudo
```