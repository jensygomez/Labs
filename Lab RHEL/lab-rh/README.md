# Laboratorio RHCSA en Docker

Este proyecto contiene un laboratorio completo para practicar RHCSA usando contenedores Rocky Linux 9.

## 🚀 Cómo construir la imagen

docker build -t phoenix-lab .

## 🚀 Ejecutar un contenedor

docker run -it --name node1 phoenix-lab bash

## 🚀 Crear varios nodos

docker run -it --name node1 phoenix-lab bash
docker run -it --name node2 phoenix-lab bash
docker run -it --name node3 phoenix-lab bash
docker run -it --name node4 phoenix-lab bash

## 🚀 Ingresar a un nodo ya existente
docker start -ai node1

## 🧹 Contenedor que se borra al salir
docker run --rm -it phoenix-lab bash

## Carpetas
- /docs → Teoría día por día
- /ejercicios → Tareas por día
- /scripts → Scripts automáticos
- /notas → Apuntes personales
