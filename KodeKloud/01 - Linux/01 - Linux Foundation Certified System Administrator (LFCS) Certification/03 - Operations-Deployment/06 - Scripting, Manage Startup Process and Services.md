---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Scripting, Manage Startup Process and Services
Fecha de Inicio: 2026-05-15
Dificultad: Intermedio-Medio
Tareas Totales: "14"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito   | Notas Rápidas |
| :----------- | :----- | :------ | :------------ |
| `15/05/26`   | 40 min | 0 %     |               |
| `24/05/26`   | 40 min | 35 %    |               |
| `29/05/2026` | 40 min | 78.57 % |               |
|              |        |         |               |

[[Laboratorios del LFCS]]

---

In this laboratory, I practiced essential system administration tasks related to startup processes and service management. I learned how to schedule a system shutdown, change the default boot target from text-only (multi-user) to graphical desktop, and cancel scheduled tasks. I also worked with systemd services by checking their status, finding process PIDs, masking and unmasking services, and editing service unit files to modify restart behavior and dependencies. These skills reflect the Linux philosophy of having complete control over when and how the system starts and runs services.

I also strengthened my Bash scripting abilities. I created scripts to perform practical tasks such as creating compressed archives, modifying directory permissions, and checking service status. I paid special attention to using the correct shebang and making scripts executable. This lab emphasized writing simple but useful automation scripts, which is a core skill for any Linux administrator who wants to work efficiently.

Overall, this lab helped me understand how to manage the boot process and services in modern Linux systems using systemd. In a technical interview, I can confidently explain how to control system startup, create useful scripts, and properly manage services — including editing unit files to improve reliability and security. These are highly valued skills for real production environments.

---

### 1. Gestión del Apagado y Sistema

Shell

```
# HINT: Control de energía. Invoca la herramienta del sistema para programar un apagado con un temporizador de 2 horas en formato relativo, o aborta el proceso antes de que expire.
# SINOPSIS: $ sudo [CMD] --flags [TIME_VALUE]
# SINOPSIS: $ sudo [CMD] -c
```

### 2. Configuración de la Interfaz Gráfica (Target)

Shell

```
# HINT: Localización y cambio de estado del init. Busca el archivo por nombre desde la raíz del sistema de archivos. Luego, cambia de forma persistente el objetivo de arranque predeterminado al modo gráfico.
# SINOPSIS: $ sudo [CMD] [START_PATH] -name [FILENAME]
# SINOPSIS: $ sudo [CMD] set-default [TARGET_UNIT]
```

### 3. Automatización y Redirección (`script.sh`)

Shell

```
# HINT: Permisos y flujos. Otorga flags de ejecución al script. Luego, usa un pipe hacia un binario que actúe como "T" para concatenar una línea de empaquetado (tar) al final de un archivo protegido.
# SINOPSIS: $ [CMD] +x [FILE]
# SINOPSIS: $ echo "[TAR_CMD] [FLAGS] [ARGS]" | sudo [CMD] --append [FILE]
```

### 4. Diagnóstico de SSH y Captura de PID (`script2.sh`)

Shell

```
# HINT: Estado de daemons y persistencia. Revisa la actividad del servicio, verifica si arrancará automáticamente con el sistema y redirige un string para añadirlo al final de tu script de pruebas sin borrar nada.
# SINOPSIS: $ sudo [CMD] status [SERVICE]
# SINOPSIS: $ sudo [CMD] is-enabled [SERVICE]
# SINOPSIS: $ echo "..." [OPERATOR] [FILE]
```

### 5. Auditoría de Permisos en Directorios

Shell

```
# HINT: Inspección de metadatos. Lista de forma exhaustiva (incluyendo ocultos y dueños) un directorio cuyo acceso requiera elevar privilegios debido a restricciones del sistema de archivos.
# SINOPSIS: $ sudo [CMD] -la [TARGET_DIR]
```

### 6. Despliegue de Scripts con Permisos Octales (`script10.sh`)

Shell

```
# HINT: Permisos discretos. Aplica la máscara numérica para que el script sea ejecutable por todos pero modificable solo por el dueño. Luego, ejecútalo invocando su intérprete.
# SINOPSIS: $ sudo [CMD] [OCTAL_MODE] [FILE]
# SINOPSIS: $ [INTERPRETER] [FILE]
```

### 7. Control Avanzado de Servicios (Masking y Restarts)

Shell

```
# HINT: Ciclo de vida de unidades. Enmascara completamente un servicio para que no pueda ser iniciado, revierte el enmascaramiento y luego reinicia el daemon de sshd para aplicar cambios.
# SINOPSIS: $ sudo [CMD] mask [SERVICE]
# SINOPSIS: $ sudo [CMD] unmask [SERVICE]
# SINOPSIS: $ sudo [CMD] restart [SERVICE]
```

### 8. Localización de Archivos de Unidad de Systemd (`kkloud`)

Shell

```
# HINT: ¡Cuidado con los typos del laboratorio! Si sospechas del nombre, usa la herramienta de búsqueda acotando el inicio a la ruta estándar de configuraciones de systemd (en lugar de buscar desde la raíz `/`). Cuando localices el archivo `.service` real, inspecciónalo y edítalo.
# SINOPSIS: $ sudo [CMD] [SYSTEMD_CONF_DIR] -name "[PATTERN_WITH_WILDCARD]"
# SINOPSIS: $ sudo [CMD] [FILE_PATH]
# SINOPSIS: $ sudo [CMD] [FILE_PATH]
```

