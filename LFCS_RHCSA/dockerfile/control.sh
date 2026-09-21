#!/bin/bash
set -e

# ==========================================
# 1. CONFIGURACIÓN DE ENTORNO
# ==========================================
export TF_VAR_proxmox_api_url="https://100.93.29.93:8006/" # Ajusta si tu IP cambió
IMAGE_NAME="lfcs-control"
CONTAINER_NAME="lfcs-control-container"

# ==========================================
# 2. CONSTRUCCIÓN DE IMAGEN
# ==========================================
if ! podman image inspect $IMAGE_NAME >/dev/null 2>&1; then
  echo "🛠️  Construyendo imagen $IMAGE_NAME con Podman..."
  podman build -t $IMAGE_NAME -f dockerfile/Dockerfile .
else
  echo "✅ Imagen $IMAGE_NAME ya existe."
fi

# ==========================================
# 3. EJECUCIÓN DEL CONTENEDOR
# ==========================================
echo "🚀 Lanzando nodo de control LFCS con Podman..."
echo "📂 Directorio de trabajo: $(pwd)/Linux_Foundation/terraform"

podman run -it --rm \
  --name $CONTAINER_NAME \
  --userns=keep-id \
  --device /dev/net/tun \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v "$(pwd):/workspace:Z" \
  -w "/workspace/001-Linux_Foundation/terraform" \
  -e HOME=/workspace \
  -e TF_VAR_proxmox_api_url \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  -e ANSIBLE_CONFIG=/workspace/001-Linux_Foundation/ansible/ansible.cfg \
  -e GIT_SSH_COMMAND="ssh -F /workspace/.ssh/config" \
  -e ANSIBLE_SSH_ARGS="-F /workspace/.ssh/config -o IdentitiesOnly=yes" \
  -e ANSIBLE_SSH_COMMON_ARGS="-F /workspace/.ssh/config" \
  $IMAGE_NAME \
  /bin/bash
