---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Create and Enforce MAC Using SELinux
Typo: Video
Fecha: 29/04/2026
Estado: completado
Dificultad: Media
Calificación: N/A
Time: 37 min
tags:
---
SELinux (Security Enhanced Linux) es un módulo de control de acceso obligatorio (MAC) que se implementa a nivel del kernel para reforzar la seguridad del sistema. El video mostró cómo desactivar AppArmor en Ubuntu e instalar SELinux desde cero. Después de la instalación, se verificó el estado con `sestatus` (inicialmente desabilitado) y se activó con `selinux-activate`, requiriendo un reinicio de la VM. Una vez reiniciada, SELinux quedó en modo PERMISSIVE, permitiendo auditar políticas sin bloquear acciones. Se demostró cómo verificar contextos de seguridad con comandos como `ps -eZ | grep sshd_t` para procesos, y se utilizó `audit2allow` para generar módulos personalizados basados en logs de auditoría.

Los contextos de seguridad son la base de SELinux y se componen de usuario, rol y tipo. Usando `ls -Z /var/log/auth.log` se observó el contexto completo como `system_u:object_r:var_log_t:s0`. Para modificar etiquetas individuales se usó `chcon` (change context) con sus flags `-u` (usuario), `-r` (rol) y `-t` (tipo). El video enfatizó que antes de aplicar cambios, es necesario consultar qué contextos están disponibles en el sistema usando `seinfo -u` (usuarios), `seinfo -r` (roles) y `seinfo -t` (tipos), ya que no hay una forma evidente de saber cuál aplicar sin revisar la documentación.

Para aplicar contextos de seguridad correctos a múltiples archivos o directorios, se mostró el uso de `restorecon -R` que restaura los contextos según la política SELinux vigente. También se demostró `setenforce 1` para cambiar de modo PERMISSIVE a ENFORCING, donde SELinux bloquea activamente las acciones no permitidas. Para que el cambio sea permanente, se debe editar la configuración del archivo `/etc/selinux/config` estableciendo `SELINUX=enforcing`. Este enfoque integral garantiza que todas las políticas de acceso obligatorio se apliquen correctamente y de forma persistente.

## Comandos Clave

bash

```bash
# Verificar estado de SELinux
sestatus

# Activar SELinux
sudo selinux-activate

# Ver contextos de seguridad en procesos
ps -eZ | grep sshd_t

# Ver contextos de seguridad en archivos
ls -Z /var/log/auth.log

# Cambiar contexto de seguridad
sudo chcon -u unconfined_u /var/log/auth.log
sudo chcon -r object_r /var/log/auth.log
sudo chcon -t user_home_t /var/log/auth.log

# Listar contextos disponibles en el sistema
seinfo -u    # usuarios
seinfo -r    # roles
seinfo -t    # tipos

# Generar módulo de auditoría
sudo audit2allow --all mymodule

# Cambiar a modo enforcing
sudo setenforce 1

# Restaurar contextos de archivos de forma recursiva
sudo restorecon -R /ruta/del/directorio
```