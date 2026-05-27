
---
Curso: Docker Certified Associate Exam Course
Módulo: Docker Engine
Tema: Basic Container Operations
Type: Video
Fecha: 28/04/2026
Estado: completado
Dificultad: Básico
tags:
  
---

## Resumen

Docker utiliza una estructura de comandos jerárquica: `docker <docker-object> <sub-command> [options] <arguments/commands>`. El sistema almacena información de contenedores en `/var/lib/docker/containers`. Es fundamental dominar la nueva sintaxis de Docker, enfocándose en comandos clave como `create`, `ls` y `start`. El uso de opciones como `-a` (mostrar todos los contenedores), `-aq` (mostrar solo IDs) y `--name` (asignar nombre personalizado) permite un control preciso sobre los contenedores. Para que un contenedor permanezca activo en modo interactivo, se utiliza la opción `-it`, mientras que `-d` ejecuta el contenedor en segundo plano.

La combinación de `docker container run` permite crear e iniciar un contenedor en un único comando, eliminando la necesidad de ejecutar `create` y `start` por separado. Los contenedores pueden ser renombrados después de su creación, y evitar nombres aleatorios es posible especificando un nombre personalizado desde el inicio. El manejo eficiente de estas opciones es esencial para cualquier operación básica en Docker y constituye la base para trabajar con contenedores en entornos de producción.

## Comandos de ejemplo

```bash
# Crear un contenedor con nombre personalizado
docker container create --name mi-ubuntu ubuntu

# Listar todos los contenedores
docker container ls -a

# Crear e iniciar un contenedor interactivo
docker container run -it --name my-app ubuntu

# Ejecutar contenedor en segundo plano
docker container run -d --name background-app ubuntu

# Renombrar un contenedor
docker rename mi-ubuntu nuevo-nombre
```