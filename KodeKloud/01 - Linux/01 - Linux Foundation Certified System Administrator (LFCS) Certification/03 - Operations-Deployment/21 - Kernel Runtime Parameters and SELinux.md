---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Kernel Runtime Parameters and SELinux
Fecha de Inicio: 2026-04-30
Dificultad: Intermedio-Medio
Tareas Totales: "9"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 16 - 05 - 2026 | 40 min | 0 %   |               |
|                |        |       |               |

[[Laboratorios del LFCS]]


---

## 📝 Resumen

Este laboratorio cubre dos áreas críticas para la administración de sistemas Linux: la configuración de parámetros del kernel en tiempo de ejecución y la gestión de SELinux. Los parámetros del kernel permiten ajustar el comportamiento del sistema (como swappiness y configuración de módulos) de forma temporal o persistente usando `sysctl`, mientras que SELinux proporciona control de acceso granular mediante etiquetas de contexto. En este lab se practican 9 tareas que incluyen cambiar contextos SELinux en archivos, verificar etiquetas en procesos, ajustar parámetros de kernel y cambiar el modo SELinux, habilidades esenciales para un Sysadmin que necesita optimizar seguridad y rendimiento del sistema.

La práctica comienza identificando etiquetas SELinux en procesos (sshd) y archivos (/bin/sudo), continuando con la deshabilitación de carga de módulos del kernel y el ajuste del parámetro vm.swappiness para optimizar el uso de memoria. Luego se trabaja con cambios de contexto SELinux en archivos web (/var/index.html), cambio de modo SELinux a Permissive, identificación de roles SELinux para usuarios específicos y finalmente la restauración de etiquetas por defecto en directorios del sistema (/var/log) usando herramientas como `semanage`, `chcon` y `restorecon`.

## 💻 Comandos Clave

```bash
# Consultar contexto SELinux de un archivo
ls -lZ /bin/sudo

# Cambiar contexto SELinux de un archivo
sudo chcon -t httpd_sys_content_t /var/index.html

# Listar etiquetas SELinux de un proceso
ps -eZ | grep sshd

# Ver parámetros del kernel actualmente
sysctl net.ipv6.conf.lo.seg6_enabled

# Establecer parámetro kernel temporalmente
sudo sysctl -w vm.swappiness=10

# Hacer persistente un parámetro del kernel
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Deshabilitar carga de módulos kernel
sudo sysctl -w kernel.modules_disabled=1

# Ver modo SELinux actual
getenforce

# Cambiar SELinux a Permissive (temporal)
sudo setenforce Permissive

# Restaurar contextos SELinux por defecto
sudo restorecon -Rv /var/log

# Ver roles SELinux de un usuario
sudo semanage user -l | grep staff_u
```

---

**Inicio Lab:** 2026-04-30 | **Sesión:** 16-05-2026 (40 min)