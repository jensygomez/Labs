---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Manage Containers and VMs
Fecha de Inicio: 2026-04-10
Dificultad: Básico Medio
Tareas Totales: "10"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 17 - 05 - 2026 | 10 min | 90 %  |               |
|                |        |       |               |

[[Laboratorios del LFCS]]

---

---

## 📝 Resumen

Este laboratorio fundamenta las habilidades esenciales de un Sysadmin principiante en Linux: autenticación remota, acceso a documentación del sistema y navegación básica de la terminal. El lab cubre el uso de SSH para conectarse remotamente a otros sistemas, exploración de manual pages con `man` y `apropos` para buscar comandos y opciones disponibles, trabajo con archivos ocultos en directorios, y configuración del hostname del sistema. Aunque son 10 tareas aparentemente simples, cada una representa un skill crítico que necesitarás diariamente: entender cómo buscar ayuda en la terminal, conectarte a servidores remotos, interpretar opciones de comandos y documentar cambios en tu sistema. Sin estas bases sólidas, es muy difícil avanzar en administración Linux.

El flujo del laboratorio comienza con búsquedas en documentación (man pages, apropos), continúa con conexiones SSH remotas y troubleshooting de conectividad, y termina con comprensión de configuraciones del sistema (hostname, archivos ocultos, indexación de manual pages). Lo valioso aquí no es memorizar respuestas, sino entender dónde buscar información cuando la necesites: cómo usar `man -k` (equivalente a apropos), cómo interpretar errores de SSH con la opción `-v`, y cómo mantener tu documentación del sistema actualizada. Con 90% de éxito en tu primer intento, demuestras que ya tienes intuición en estos conceptos fundamentales.

## 💻 Comandos Clave

```bash
# === DOCUMENTACION Y AYUDA ===
# Buscar manual pages por palabra clave
man -k ssh
apropos ssh

# Ver manual de un comando específico
man ssh

# Ver todas las secciones del manual
man man

# Buscar en qué sección está un comando
whatis ssh

# Reconstruir la base de datos de manual pages
sudo mandb

# === SSH ===
# Conectar SSH a un host remoto
ssh bob@node01

# Conectar SSH con output verboso para debugging
ssh -v alex@localhost

# Ver versión de SSH
ssh -V

# Crear archivo remoto vía SSH
ssh bob@node01 "touch /home/bob/myfile"

# === SISTEMA Y CONFIGURACION ===
# Ver hostname actual
hostname

# Cambiar hostname estáticamente
sudo hostnamectl set-hostname new-hostname

# Cambiar hostname (método antiguo)
sudo nano /etc/hostname

# === EXPLORACION DE DIRECTORIOS ===
# Listar archivos incluyendo ocultos
ls -la /home/bob/data/

# Contar archivos ocultos
ls -la /home/bob/data/ | grep "^\." | wc -l

# === BUSQUEDA ===
# Buscar archivo de configuración NFS
apropos nfs
man nfs

# Ver archivo fstab (configuración de mounts)
cat /etc/fstab
man fstab
```

---

**Inicio Lab:** 2026-04-10 | **Última sesión:** 17-05-2026 (10 min) | **Progreso:** 90%