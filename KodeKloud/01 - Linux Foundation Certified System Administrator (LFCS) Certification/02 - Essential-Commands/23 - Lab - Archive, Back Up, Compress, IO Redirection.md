---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Archive, Back Up, Compress, IO Redirection
Fecha de Inicio: 2026-05-12
Dificultad: Basico-Medio
Tareas Totales: "15"
tags:
  - Linux
  - Linux/LFCS-Certification
  - Linux/LFCS-Certification/Essential-Commands
  - Linux/LFCS-Certification/Essential-Commands/Laboratorio
---
# Lab 23 - Archive, Back Up, Compress, IO Redirection

## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas                     |
| :--------- | :----- | :---- | :-------------------------------- |
| 2026-05-12 | 45 min | 16%   | Problemas con redirección stderr. |
| 2026-05-13 | --     | --    | *Esperando resultado de hoy...*   |
|            |        |       |                                   |

---

## 🛠️ Comandos Clave (Tu Manual de Consulta)
*(Aquí dejas los comandos que ya tienes, son tu referencia única)*
```bash
# Crear archivo tar comprimido con gzip
tar -cvzf logs.tar.gz /var/log/
# ... todos tus comandos clave aquí ...

### Resumen

Este laboratorio cubre operaciones fundamentales con archivos comprimidos y redirección de entrada/salida en Linux. Las tareas incluyen crear archivos tar simples y comprimidos (.tar.gz), extraer contenido de archivos comprimidos, listar contenidos sin extraer, y redirigir salida de comandos (stdout y stderr) a archivos. Conceptos esenciales para un Sysadmin que necesita automatizar backups y gestionar logs. Se identificaron dificultades principalmente en la redirección de flujos de entrada/salida y opciones de comandos tar.

En esta primera repetición se lograron completar 6 de 15 tareas en 45 minutos, con solo 1 completada sin asistencia. Las tareas más accesibles fueron la creación de archivos tar y su compresión, mientras que la redirección de stderr/stdout requiere refuerzo. Mañana se repetirá el laboratorio completo enfocándose en entender los operadores de redirección (`>`, `2>`, `2>&1`) y las flags principales de tar.

### Comandos Clave

bash

```bash
# Crear archivo tar simple
tar -cvf logs.tar /var/log/

# Crear archivo tar comprimido con gzip
tar -cvzf logs.tar.gz /var/log/

# Extraer archivo tar.gz a directorio específico
tar -xvzf archive.tar.gz -C /tmp

# Listar contenido sin extraer y guardar en archivo
tar -tvf logs.tar > tar_data.txt

# Ejecutar script guardando solo stdout
./script.sh > output_stdout.txt

# Ejecutar script guardando stdout y stderr
./script.sh > output.txt 2>&1
```