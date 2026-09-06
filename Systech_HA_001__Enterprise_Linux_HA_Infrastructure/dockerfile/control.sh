#!/bin/bash
set -e
# ==========================================
# 1. CONFIGURACIÓN DE ENTORNO
# ==========================================
export TF_VAR_proxmox_api_url="https://192.168.18.100:8006/"
IMAGE_NAME="systech-control"
CONTAINER_NAME="systech-ha-control"

# ==========================================
# 2. CONSTRUCCIÓN DE IMAGEN
# ==========================================
if ! podman image inspect $IMAGE_NAME >/dev/null 2>&1; then
  echo "🛠️  Construyendo imagen $IMAGE_NAME con Podman..."
  podman build -t $IMAGE_NAME -f dockerfile/Dockerfile .
else
  echo "✅ Imagen $IMAGE_NAME ya existe. (Si actualizaste el Dockerfile, bórrala con: podman rmi $IMAGE_NAME)"
fi

# ==========================================
# 3. EJECUCIÓN DEL CONTENEDOR
# ==========================================
echo "🚀 Lanzando nodo de control con Podman..."
echo "📂 Directorio de trabajo: $(pwd)/terraform"
echo "🔑 La identidad SSH, Token de Proxmox y Tailscale Key se inyectarán desde el Vault."

podman run -it --rm \
  --name $CONTAINER_NAME \
  --userns=keep-id \
  --device /dev/net/tun \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v "$(pwd):/workspace:Z" \
  -w "/workspace/terraform" \
  -e HOME=/workspace \
  -e TF_VAR_proxmox_api_url \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  -e ANSIBLE_CONFIG=/workspace/ansible.cfg \
  -e GIT_SSH_COMMAND="ssh -F /workspace/.ssh/config" \
  -e ANSIBLE_SSH_ARGS="-F /workspace/.ssh/config -o IdentitiesOnly=yes" \
  -e ANSIBLE_SSH_COMMON_ARGS="-F /workspace/.ssh/config" \
  $IMAGE_NAME \
  /bin/bash
