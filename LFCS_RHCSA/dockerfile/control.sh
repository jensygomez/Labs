#!/bin/bash
set -e

# ==========================================
# 1. CONFIGURACIÓN DE ENTORNO Y CLAVE API
# ==========================================
IMAGE_NAME="k8s-control"
CONTAINER_NAME="k8s-control-container"

# Verificar si la clave está en el entorno del host. Si no, pedirla de forma segura.
if [ -z "$KODEKEY_API_KEY" ]; then
  echo "⚠️  KODEKEY_API_KEY no detectada en el entorno del host."
  echo "   (Recuerda que esta clave rota semanalmente por seguridad)."
  read -s -p "   Pega tu nueva KODEKEY_API_KEY aquí: " KODEKEY_API_KEY
  echo "" # Salto de línea tras la entrada oculta
  if [ -z "$KODEKEY_API_KEY" ]; then
    echo "❌ Error: No se proporcionó una clave. Abortando."
    exit 1
  fi
fi

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
echo "🚀 Lanzando nodo de control Kubernetes con Podman..."
echo "📂 Directorio de trabajo: $(pwd)/terraform"

podman run -it --rm \
  --name $CONTAINER_NAME \
  --userns=keep-id \
  --device /dev/net/tun \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v "$(pwd):/workspace:Z" \
  -w "/workspace/terraform" \
  -e HOME=/workspace \
  -e KODEKEY_API_KEY="$KODEKEY_API_KEY" \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  -e ANSIBLE_CONFIG=/workspace/ansible/ansible.cfg \
  -e GIT_SSH_COMMAND="ssh -F /workspace/.ssh/config" \
  -e ANSIBLE_SSH_ARGS="-F /workspace/.ssh/config -o IdentitiesOnly=yes" \
  -e ANSIBLE_SSH_COMMON_ARGS="-F /workspace/.ssh/config" \
  $IMAGE_NAME \
  /bin/bash
