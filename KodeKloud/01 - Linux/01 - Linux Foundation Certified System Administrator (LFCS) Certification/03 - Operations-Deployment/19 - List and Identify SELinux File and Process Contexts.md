---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: List and Identify SELinux File and Process Contexts
Typo: Video
Fecha: 29/04/2026
Estado: completado
Dificultad: Intermedio
Calificación: N/A
Time: N/A
tags:
  - "#Linux/LFCS-Certification/Operations-Deployment"
---
### Contenido

SELinux (Security Enhanced Linux) es un módulo de seguridad que extiende los permisos tradicionales de Linux (lectura, escritura, ejecución) con un sistema más granular basado en contextos. A diferencia de los permisos DAC estándar, SELinux implementa control de acceso obligatorio (MAC) mediante tres componentes: **usuario, rol y tipo**, separados por dos puntos (ej: `system_u:system_r:kernel_t:s0`). Esto permite que solo ciertos usuarios accedan a ciertos roles y tipos, limitando las acciones que los procesos autorizados pueden realizar incluso si tienen permisos generales.

Para inspeccionar estos contextos en archivos y procesos, se usa el comando `ls -Z`, que muestra el contexto completo incluyendo el nivel de seguridad. Las políticas de SELinux no solo aplican a archivos y procesos, sino también a los usuarios del sistema, permitiendo ver estas asignaciones con `sudo semanage login -l`. Finalmente, puedes verificar el estado de SELinux con `getenforce`, que devuelve tres opciones posibles: **Enforcing** (aplica políticas), **Permissive** (solo registra violaciones) y **Disabled** (SELinux desactivado).

#### Comandos clave

bash

```bash
# Ver contextos de archivos y procesos
ls -Z

# Ver políticas de SELinux para usuarios del sistema
sudo semanage login -l

# Verificar estado actual de SELinux
getenforce
```