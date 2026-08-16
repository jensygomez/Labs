#!/bin/bash
# dockerfile/control.sh (Versión Podman + MXLinux)
# Nodo de control para SYSTECH-HA-001 (OpenTofu + Ansible)

set -e

# ==========================================
# 1. CONFIGURACIÓN DE ENTORNO
# ==========================================
export TF_VAR_proxmox_api_url="https://192.168.18.100:8006/"
export TF_VAR_proxmox_api_token="root@pam!tofu-token=6e1122a5-702d-439f-95f0-b206be6e6a10"
export TF_VAR_ssh_public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+gsGnVlOOJXtW6Wz87hc1CPhOz++T2lCoB6F3Eksbg jensyg@lxd-fleet"

IMAGE_NAME="systech-control"
CONTAINER_NAME="systech-ha-control"

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
echo "🚀 Lanzando nodo de control con Podman..."
echo "📂 Directorio de trabajo: $(pwd)/terraform"
echo "🔑 Usando llave: id_lxd_fleet (ed25519)"

podman run -it --rm \
    --name $CONTAINER_NAME \
    --network host \
    --userns=keep-id \
    -v "$(pwd):/workspace:Z" \
    -v "$HOME/.ssh/id_lxd_fleet:/root/.ssh/id_lxd_fleet:ro" \
    -v "$HOME/.ssh/config:/root/.ssh/config:ro" \
    -w "/workspace/terraform" \
    -e TF_VAR_proxmox_api_url \
    -e TF_VAR_proxmox_api_token \
    -e TF_VAR_ssh_public_key \
    -e ANSIBLE_HOST_KEY_CHECKING=False \
    -e ANSIBLE_CONFIG=/workspace/ansible.cfg \
    $IMAGE_NAME \
    /bin/bash
