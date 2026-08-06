#!/usr/bin/env bash
set -o errexit
set -o pipefail

PROFILE_NAME="lab-profile"
IMAGE="images:almalinux/9"

NODES=(lb01 lb02 app01 app02 app03 app04 storage01 backup01 infra01 bastion01)

declare -A FLEET_IPS=(
    ["lb01"]="10.10.10.11"
    ["lb02"]="10.10.10.12"
    ["app01"]="10.10.10.21"
    ["app02"]="10.10.10.22"
    ["app03"]="10.10.10.23"
    ["app04"]="10.10.10.24"
    ["storage01"]="10.10.10.31"
    ["backup01"]="10.10.10.32"
    ["infra01"]="10.10.10.41"
    ["bastion01"]="10.10.10.51"
)

declare -A FLEET_EXTRA=(
    ["lb01"]="haproxy keepalived"
    ["lb02"]="haproxy keepalived"
    ["storage01"]="nfs-utils"
    ["backup01"]="nfs-utils restic"
    ["infra01"]="bind bind-utils chrony"
)

echo "==> Verificando perfil LXD '${PROFILE_NAME}'..."
if ! lxc profile show "$PROFILE_NAME" &>/dev/null; then
    echo "==> Creando perfil '${PROFILE_NAME}'..."
    lxc profile create "$PROFILE_NAME"
    lxc profile edit "$PROFILE_NAME" < profile-lab.yml
fi

echo "==> Desplegando Flota Corporativa (10 Nodos)..."

for node in "${NODES[@]}"; do
    ip="${FLEET_IPS[$node]}"
    extra="${FLEET_EXTRA[$node]:-}"

    # Destruir instancia previa si existía
    lxc delete "$node" --force 2>/dev/null || true

    echo "==> [$node] Creando contenedor con IP $ip..."
    lxc launch "$IMAGE" "$node" --profile "$PROFILE_NAME" -d eth0,ipv4.address="$ip"

    if [ -n "$extra" ]; then
        echo "    Instalando paquetes extra en $node: $extra"
        lxc exec "$node" -- dnf install -y $extra >/dev/null 2>&1 &
    fi
done

echo ""
echo "==> ✅ Toda la flota corporativa está levantada y configurada."
