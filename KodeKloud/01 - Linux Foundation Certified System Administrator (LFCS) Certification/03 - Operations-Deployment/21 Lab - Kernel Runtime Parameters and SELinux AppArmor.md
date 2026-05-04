---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Kernel Runtime Parameters and SELinux/AppArmor
Typo: Laboratorio
Fecha: 30/04/2026
Estado: completado
Dificultad: Media
Calificación: 0%
Time: 30 min
tags:
  - linux
  - lfcs
  - "#operations"
  - "#Operations-Deployments"
  - "#SELinux"
  - Kernel-Parameters
  - Sysctl
---
Este laboratorio se enfoca en la configuración de parámetros de tiempo de ejecución del kernel y la gestión de contextos SELinux en el sistema. Los temas principales incluyen la manipulación de procesos SELinux (como obtener etiquetas del proceso sshd), la desactivación de módulos del kernel mediante kernel.modules_disabled, y la configuración de parámetros críticos como net.ipv6.conf.lo.seg6_enabled y vm.swappiness. Se practicó tanto la modificación temporal como persistente de estos parámetros usando sysctl. La gestión de contextos SELinux fue central: cambiar etiquetas de archivos (como /var/index.html a httpd_sys_content_t), identificar roles de usuarios SELinux (staff_u), restaurar contextos por defecto en directorios como /var/log, y alternar entre modos SELinux (Enforcing y Permissive). El lab combina conceptos de seguridad del kernel y control de acceso obligatorio, siendo esencial para entender cómo Linux maneja permisos a nivel de sistema operativo.
# Comandos clave 



```bash
# Obtener etiqueta SELinux de un proceso
ps -eZ | grep sshd

# Ver y modificar parámetros del kernel
sysctl -a | grep vm.swappiness
sysctl -w vm.swappiness=10

# Hacer persistente un parámetro del kernel
echo "vm.swappiness=10" >> /etc/sysctl.conf 
sysctl -p

# Cambiar contexto SELinux de un archivo
chcon -t httpd_sys_content_t /var/index.html

# Alternar modo SELinux a Permissive
semanage permissive -a httpd_t

# Restaurar contextos SELinux por defecto
restorecon -Rv /var/log



