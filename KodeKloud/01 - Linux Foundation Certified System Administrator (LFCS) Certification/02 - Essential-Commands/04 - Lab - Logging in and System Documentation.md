---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Logging in and System Documentation
Typo: Laboratorio
Fecha: 2026-05-10
tags:
  - Linux/LFCS-Certification/Essential-Commands
  - Laboratorio/Repetido/1
---
Este laboratorio se enfocó en dominar los comandos esenciales para navegación del sistema y troubleshooting. Las tareas cubrieron desde usar `man` para consultar documentación de comandos (como encontrar opciones de SSH), hasta el uso de `apropos` para buscar páginas del manual por palabras clave. Un punto clave fue entender que `apropos` requiere que las páginas de manual estén indexadas, lo cual se resuelve ejecutando `mandb` para reconstruir la base de datos. También practicaste conectividad SSH remota entre hosts, incluyendo troubleshooting de conexiones rechazadas con flags de verbosidad.

El laboratorio consolidó habilidades fundamentales de un sysadmin: consultar documentación del sistema de forma eficiente, debuggear conexiones remotas y entender cómo el sistema indexa su información. Estas herramientas (`man`, `apropos`, `ssh -v`) son tu pan de cada día en troubleshooting real. El 100% demuestra que comprendiste bien cómo navegar la documentación del sistema y resolver problemas básicos de conectividad.

**Comandos clave:**

bash

```bash
# Ver versión de un comando
ssh -V

# Buscar comandos relacionados (requiere indexación)
apropos nfs
mandb  # Actualizar índice de man pages

# SSH con salida verbosa para debugging
ssh -v bob@node01

# Crear archivo remoto vía SSH
ssh bob@node01 "touch /home/bob/myfile"
```
