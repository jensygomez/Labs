---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Create and Manage Containers
Typo: Video
Fecha: 30/04/2026
Estado: completado
Dificultad: Intermedio
Calificación: N/A
Time: 33 min
tags:
---
Los contenedores encapsulan aplicaciones completas permitiendo portabilidad entre diferentes entornos. En este video se cubrió el ciclo completo de trabajo con Docker: búsqueda de imágenes en Docker Hub, descarga con `docker pull` (incluyendo tags específicos de versión), y gestión básica con `docker images` y `docker rmi`. El flujo fundamental es identificar la imagen que necesitas, hacer pull, y luego desplegarla.

El proceso de creación y ejecución de contenedores es sencillo con `docker run`, aunque el verdadero control viene con flags como `--detach` para ejecutar en background, `--publish` para mapear puertos, y `--name` para nombrar la instancia. Se demostró con un servidor Nginx expuesto en localhost:8080, validando la funcionalidad con peticiones GET. Además, se introdujo la creación de imágenes personalizadas mediante Dockerfile, usando instrucciones como `FROM` para la imagen base y `COPY` para incluir archivos, compilando todo con `docker build`.

**Ejemplo de comando:**

bash

```bash
docker run --detach --publish 8080:80 --name mywebserver nginx
docker build --tag jeremy/customnginximage:1.0 .
```