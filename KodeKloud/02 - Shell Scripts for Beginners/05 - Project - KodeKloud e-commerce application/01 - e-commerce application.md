---
Curso: Shell Scripts for Beginners
Modulo: Project - KodeKloud e-commerce application
Tema: Project - KodeKloud e-commerce application
Fecha: 2026-05-12
tags:
  - Linux
  - Linux/Project
  - Linux/Project/Project
  - Linux/Project/Project/Dificultad/Basico-Medio
  - Linux/Project/Project/Time/10min
  - Linux/Project/Project/Apache
  - Linux/Project/Project/MariaDB
  - Linux/Project/Project/php
---
## Introducción al Proyecto e-commerce

En este video se introduce un proyecto práctico ficticio diseñado para reforzar habilidades en Linux y la pila LAMP. El objetivo es automatizar mediante shell scripts la instalación y configuración de un servidor web Apache, una base de datos MariaDB y PHP en CentOS. Este tipo de proyectos es fundamental para un SysAdmin Linux, ya que replica escenarios reales donde necesitas provisionar servidores desde cero de forma eficiente y reproducible.

El flujo del proyecto sigue una secuencia lógica: primero se utiliza CentOS como base, seguido de la instalación y configuración de httpd (Apache), luego MariaDB para la capa de datos, y finalmente PHP para la capa de aplicación. Este stack es el corazón de muchas aplicaciones web tradicionales, y aprender a automatizar su instalación mediante scripts te preparará para tareas más complejas de orquestación y despliegue.

## Comando de ejemplo

```bash
#!/bin/bash
# Script básico para instalar la pila LAMP
sudo yum install -y httpd mariadb-server php php-mysql
sudo systemctl start httpd
sudo systemctl start mariadb
sudo systemctl enable httpd mariadb
```

---

**Notas adicionales:**
- Este proyecto es ideal para consolidar conceptos de scripting en Linux
- Prepárate para trabajar con servicios systemd
- La automatización de instalaciones es una habilidad crítica en operaciones