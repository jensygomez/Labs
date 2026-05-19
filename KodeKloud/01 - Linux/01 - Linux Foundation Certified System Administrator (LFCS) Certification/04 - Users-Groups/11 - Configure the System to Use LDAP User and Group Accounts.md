---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Configure the System to Use LDAP User and Group Accounts
Typo: Video
Fecha: 02/05/2026
Estado: completado
Dificultad: Intermedio-Baja
Calificación:
Time: 20 min
tags:
  - "#Linux/LFCS-Certification/Users-Groups"
---
## Problema y Solución

En entornos empresariales con múltiples servidores, la gestión de usuarios de forma local (a través de `/etc/passwd`) se vuelve inmanejable. Cada vez que un usuario nuevo se suma, se va de la empresa, o necesita cambiar permisos en algunos servidores, hay que actualizar manualmente cada máquina. La solución es implementar **LDAP (Lightweight Directory Access Protocol)**, un servidor centralizado que actúa como fuente única de verdad para usuarios y grupos. Una vez configurado el servidor LDAP, los usuarios creados allí aparecen automáticamente disponibles en todos los clientes LDAP conectados, simplificando enormemente la administración a escala.

## Implementación y Verificación

El video mostró una instalación práctica de LDAP usando Docker, permitiendo crear usuarios en el servidor central y verificar su disponibilidad en otros sistemas. La configuración se realiza a través del archivo `/etc/nsswitch.conf`, que indica al sistema dónde buscar información de usuarios y grupos. Para verificar que los usuarios LDAP están disponibles, se utiliza el comando `getent passwd --service ldap`. Sin embargo, aunque los directorios home se crean en el servidor LDAP, no aparecen automáticamente en la máquina cliente donde el usuario se autentica. Para resolver esto, se implementa el módulo **PAM (Pluggable Authentication Modules)**, que gestiona la creación de directorios home dinámicamente al primer login del usuario LDAP.

## Comando de Verificación

bash

```bash
# Verificar usuarios LDAP disponibles en el sistema
getent passwd --service ldap

# Ver usuarios combinados (locales + LDAP)
getent passwd

# Consultar configuración de búsqueda
cat /etc/nsswitch.conf | grep passwd
```