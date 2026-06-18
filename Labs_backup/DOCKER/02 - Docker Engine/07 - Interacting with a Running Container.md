---
Curso: Docker Certified Associate Exam Course
Modulo: Docker Engine
Tema: Interacting with a Running Container
Typo: Video
Fecha: 30/04/2026
Estado: completado
Dificultad: Básico
Calificación: N/A
Time: 5 min
tags:
---
### Interactuando con Contenedores en Ejecución:

El video cubrió las herramientas esenciales para interactuar con contenedores Docker desde el host, un aspecto crítico para troubleshooting en entornos de producción. Se demostró cómo listar contenedores activos, ejecutar comandos dentro de ellos sin acceso directo a la terminal, e incluso obtener una sesión interactiva completa. Estas técnicas permiten diagnosticar problemas, verificar estados de aplicaciones y ejecutar comandos de mantenimiento sin detener o comprometer los contenedores. La práctica de usar `docker container exec` es fundamental para un sysadmin Linux, ya que proporciona una forma segura y controlada de acceder a recursos dentro de contenedores en ejecución. Ya sea ejecutando un comando puntual como `hostname` para verificar la configuración del contenedor, o abriendo una sesión bash interactiva completa para inspeccionar logs y archivos de configuración, estas herramientas son indispensables en el día a día del troubleshooting de aplicaciones containerizadas. 
### Comandos Clave
```bash

# Listar contenedores con detalles extendidos 
docker container ls -l

# Ejecutar e iniciar un contenedor interactivo 
docker container run -it 

# Ejecutar comando puntual dentro de un contenedor 
docker container exec 145fgh3ae4 hostname

# Obtener sesión bash interactiva dentro de un contenedor 
docker container exec -it 145fgh3ae4 /bin/bash
´´´
