# Laboratorio RHCSA en Docker

## 🚀 Crear imagen
docker build -t phoenix-lab .

## 🚀 Crear contenedores
docker run -d --name node1 phoenix-lab tail -f /dev/null
docker run -d --name node2 phoenix-lab tail -f /dev/null
docker run -d --name node3 phoenix-lab tail -f /dev/null
docker run -d --name node4 phoenix-lab tail -f /dev/null

## 🚀 Acceder a un nodo
docker exec -it node1 bash
docker exec -it node2 bash

## ❌ Borrar contenedores
docker rm -f node1 node2 node3 node4
