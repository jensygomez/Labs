---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Configure User Resource Limits
Typo: Video
Fecha: 02/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 10 min
tags:
---


En ambientes con múltiples usuarios conectados simultáneamente, es crítico monitorear y limitar el consumo de recursos de hardware para evitar que un usuario monopolice la CPU, memoria o procesos, afectando la experiencia de los demás. Linux proporciona el archivo `/etc/security/limits.conf` como mecanismo de control, donde cada línea define restricciones específicas con cuatro columnas: `<domain> <type> <item> <value>`. El dominio identifica al usuario o grupo, el tipo puede ser soft (límite flexible), hard (límite obligatorio) o "-" (aplica ambos), y el item especifica qué se limita (nproc para número de procesos, fsize para tamaño de archivo, cpu para tiempo de CPU).

La implementación práctica es directa: edita `/etc/security/limits.conf` y agrega la restricción deseada. Por ejemplo, para limitar el usuario trinity a 3 procesos máximo, se añade la línea `trinity - nproc 3`. Al cambiar a ese usuario y ejecutar comandos, el límite entra en vigencia inmediatamente. Si se intenta ejecutar más procesos de los permitidos, el sistema rechaza la operación, protegiendo así los recursos del servidor y garantizando equidad entre usuarios.

**Ejemplo de comando:**
```bash
# Ver límites actuales del usuario trinity
sudo -iu trinity
ulimit -a

# Intentar un comando que requiera múltiples procesos (fallará si excede el límite)
ls -a | grep bash | less
```