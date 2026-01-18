# engine/terraform_runner.sh

#!/bin/bash
set -euo pipefail

# ============================================================================
# terraform_runner.sh
# Clona UNA VM base sana y la levanta como laboratorio
# ============================================================================
# ARGUMENTOS:
#   $1 = LEVEL   (ej: Junior)
#   $2 = LAB_ID  (ej: J01)
#   $3 = VARIANT (ej: V01)
#   $4 = BASE_IMAGE (ej: /mnt/vms/rocky-ir-base-junior-v1.qcow2)
# ============================================================================

LEVEL="$1"
LAB_ID="$2"
VARIANT="$3"
BASE_IMAGE="$4"

ENGINE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CLOUDINIT_DIR="/mnt/vms/labs/tmp/cloudinit/${LAB_ID}-${VARIANT}"
VM_NAME="lab-${LAB_ID,,}-${VARIANT,,}"
TF_WORKDIR="/mnt/vms/labs/tmp/terraform/${VM_NAME}"

# ============================================================================
# VALIDACIONES
# ============================================================================
[[ -f "$CLOUDINIT_DIR/user-data" ]] || {
  echo "❌ user-data no encontrado en $CLOUDINIT_DIR" >&2
  exit 1
}

[[ -f "$CLOUDINIT_DIR/meta-data" ]] || {
  echo "❌ meta-data no encontrado en $CLOUDINIT_DIR" >&2
  exit 1
}

[[ -f "$BASE_IMAGE" ]] || {
  echo "❌ Base image no encontrada: $BASE_IMAGE" >&2
  exit 1
}

# ============================================================================
# PREPARAR WORKDIR TERRAFORM
# ============================================================================
rm -rf "$TF_WORKDIR"
mkdir -p "$TF_WORKDIR"
cd "$TF_WORKDIR"

cat > main.tf <<EOF
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
  }
}

provider "libvirt" {}

module "lab_vm" {
  source = "$ENGINE_DIR/scenarios/terraform/modules/rocky_vm"

  vm_name             = "$VM_NAME"
  base_image          = "$BASE_IMAGE"
  cloudinit_user_data = file("$CLOUDINIT_DIR/user-data")
  cloudinit_meta_data = file("$CLOUDINIT_DIR/meta-data")
}
EOF

# ============================================================================
# EJECUCIÓN
# ============================================================================
echo "🔨 Inicializando Terraform para $VM_NAME..."
terraform init -input=false -no-color

echo "🚀 Aplicando Terraform para $VM_NAME..."
terraform apply -auto-approve -no-color

echo "✅ Laboratorio '$LAB_ID ($VARIANT)' levantado correctamente"
