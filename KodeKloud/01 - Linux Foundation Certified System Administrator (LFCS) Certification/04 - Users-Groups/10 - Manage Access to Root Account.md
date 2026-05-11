---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Manage Access to Root Account
Typo: Video
Fecha: 02/05/2026
Estado: completado
Dificultad: Básico Bajo
Calificación:
Time: 5 min
tags:
  - "#Linux/LFCS-Certification/Users-Groups"
---
**Acceso a la Cuenta Root en Linux**

El video cubre los diferentes métodos para obtener acceso a la cuenta root en sistemas Linux. Los comandos principales son `su -` (o `su -l`) que cambian directamente al usuario root, mientras que `sudo --login` (o `sudo -i`) proporcionan acceso root a través de sudo sin cambiar de usuario completamente. Para salir de la sesión root se utiliza `logout`. Es importante conocer estas alternativas porque en muchos sistemas, el comando `su -` puede estar deshabilitado por políticas de seguridad.

En casos donde no podamos acceder directamente con `su -`, `sudo --login` es la alternativa principal. Si necesitamos restablecer acceso al root, podemos usar `sudo passwd root` para establecer o cambiar la contraseña, o `sudo passwd --unlock root` para desbloquear la cuenta si está bloqueada. Otro método alternativo es utilizar `sudo ls /root/` para verificar permisos sin cambiar de usuario. Estos comandos son esenciales para la administración básica de acceso en sistemas Linux.

**Comandos de Ejemplo:**

bash

```bash
# Cambiar a usuario root
su -
su -l

# Alternativa con sudo
sudo --login
sudo -i

# Salir de sesión root
logout

# Gestionar contraseña de root
sudo passwd root
sudo passwd --unlock root

# Verificar acceso sin cambiar de usuario
sudo ls /root/
```