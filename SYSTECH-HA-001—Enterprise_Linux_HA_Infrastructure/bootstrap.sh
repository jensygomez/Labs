#!/bin/bash
set -e

SECRETS_DIR="./secrets"
SECRETS_FILE="$SECRETS_DIR/systech-secrets.yml"
SSH_KEY_DIR="./.ssh_tmp"
IMAGE_NAME="systech-control"

if [ -f "$SECRETS_FILE" ]; then
    echo "⚠️  $SECRETS_FILE ya existe. Si deseas recrearlo, bórralo primero."
    exit 1
fi

# Construir imagen si no existe (necesario para usar ansible-vault)
if ! podman image inspect $IMAGE_NAME >/dev/null 2>&1; then
    echo "🛠️  Construyendo imagen $IMAGE_NAME con Podman..."
    podman build -t $IMAGE_NAME -f dockerfile/Dockerfile .
fi

mkdir -p "$SECRETS_DIR"
mkdir -p "$SSH_KEY_DIR"

echo "🔑 Generando identidad SSH SYSTECH (ed25519)..."
ssh-keygen -t ed25519 -f "$SSH_KEY_DIR/id_systech_control" -N "" -C "systech-control"

PRIV_KEY=$(cat "$SSH_KEY_DIR/id_systech_control")
PUB_KEY=$(cat "$SSH_KEY_DIR/id_systech_control.pub")

echo "🔐 Por favor, introduce el Token de la API de Proxmox:"
read -r -s PROXMOX_TOKEN
echo

# Crear YAML en texto plano temporalmente
cat <<EOF > "$SECRETS_FILE.plaintext"
---
proxmox_api_token: "$PROXMOX_TOKEN"
ssh_private_key: |
$(echo "$PRIV_KEY" | sed 's/^/    /')
ssh_public_key: "$PUB_KEY"
EOF

echo "🛡️  Cifrando secretos con Ansible Vault..."
podman run -it --rm \
    -v "$(pwd):/workspace:Z" \
    -w "/workspace" \
    --entrypoint /bin/bash \
    $IMAGE_NAME \
    -c "ansible-vault encrypt secrets/systech-secrets.yml.plaintext --output=secrets/systech-secrets.yml"

# Limpieza
rm -f "$SECRETS_FILE.plaintext"
rm -rf "$SSH_KEY_DIR"

echo "✅ ¡Bootstrap completado! Vault cifrado creado en $SECRETS_FILE"
echo "📝 Recuerda añadir la siguiente Clave Pública a tus authorized_keys en Proxmox/Objetivos:"
echo "$PUB_KEY"
