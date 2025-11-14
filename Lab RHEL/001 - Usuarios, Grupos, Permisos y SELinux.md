# Laboratorio RHCSA – Ejercicio Individual

**Estilo Examen Real EX200** **Sistema**: RHEL 9.6 (instalación limpia) **Acceso**: root **Puntos**: 40 **Tiempo**: 45 minutos

----------

## Escenario

Estás administrando el servidor **serverb.lab.example.com**. El equipo de desarrollo necesita un espacio compartido para código Python.

----------

## Tareas (lee todas antes de empezar)

1.  **Configura el hostname** del sistema a serverb.lab.example.com de forma **persistente**. Asegúrate de que el sistema arranque por defecto en **modo multiusuario** (sin GUI).
2.  **Crea el grupo**devteam con GID **15000**.
3.  **Crea los usuarios**:
    -   lara → UID: 1201, grupo primario: devteam, con directorio home y shell /bin/bash
    -   nina → UID: 1202, grupo primario: devteam, **sin directorio home**, shell /bin/bash
4.  Establece la contraseña de lara como: **R3dH@t!2025** Haz que su contraseña expire en **20 días**.
5.  Crea el directorio **/srv/devcode** con las siguientes características:
    -   Propietario: root
    -   Grupo: devteam
    -   Permisos: 2770 (SGID activado, grupo puede escribir)
    -   Todos los nuevos archivos deben heredar el grupo devteam
6.  Crea un archivo **/srv/devcode/webapp.py**:
    -   Propietario:Confusion lara
    -   Grupo: devteam
    -   Permisos: 660
7.  **Usa ACL** para dar a nina permisos de **lectura y escritura** sobre webapp.py (sin cambiar propietario ni grupo).
8.  Ajusta el **contexto SELinux** del directorio /srv/devcode (y todo su contenido) para que pueda ser servido por **httpd** en el futuro. Usa el tipo: httpd_sys_content_t Aplica el cambio **recursivamente y persistentemente**.

----------

## Verificación (ejecuta al final)

bash

```
# Guarda esto en un script o ejecútalo línea por línea
hostnamectl status | grep "Static hostname"
systemctl get-default
getent group devteam
id lara
id nina
chage -l lara
ls -ld /srv/devcode
ls -l /srv/devcode/webapp.py
getfacl /srv/devcode/webapp.py
ls -Zd /srv/devcode
```

----------

## Fin del ejercicio

> **No uses Google, no uses man si no estás seguro, no mires soluciones.** **En el examen real, solo tienes el sistema y tu memoria.**

----------

## Limpieza (para repetir)

bash

```
rm -rf /srv/devcode
userdel -r lara 2>/dev/null
userdel nina 2>/dev/null
groupdel devteam 2>/dev/null
semanage fcontext -d "/srv/devcode(/.*)?" 2>/dev/null
restorecon -Rv /srv 2>/dev/null
hostnamectl set-hostname localhost.localdomain
systemctl set-default graphical.target
```
