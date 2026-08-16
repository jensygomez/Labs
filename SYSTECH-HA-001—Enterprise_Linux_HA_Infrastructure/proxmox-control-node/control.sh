#!/usr/bin/env bash

IMAGE_NAME="localhost/proxmox-control-node:latest"

# Construir imagen si no existe
if [[ "$(podman images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "[+] Construyendo imagen del Control Node..."
  podman build -t $IMAGE_NAME .
fi

# Lanzar contenedor interactivo
podman run -it --rm \
  -v "$(pwd)":/workspace \
  -v ~/.ssh:/root/.ssh:ro \
  --net=host \
  $IMAGE_NAME
