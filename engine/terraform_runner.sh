# engine/terraform_runner.sh


#!/bin/bash
set -euo pipefail

# ============================================================================
# terraform_runner.sh
# Refactorizado para levantar varias VMs de un laboratorio de forma automática
# ============================================================================
# ARGUMENTOS:
#   $1 = nivel del lab (ej: Junior)
#   $2 = ID del lab (ej: J01)
#   $3 = base image (ej: /mnt/vms/rocky-ir-base-junior-v1.qcow2)
# ============================================================================
LEVEL="$1"
LAB_ID="$2"
BASE_IMAGE="$3"

ENGINE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLOUDINIT_BASE="/mnt/vms/labs/tmp/cloudinit"

# ============================================================================
# ROLES A LEVANTAR POR LAB
# ============================================================================
ROLES=("web" "db" "dns" "proxy")

# ============================================================================
# LOOP: POR CADA ROLE
# ============================================================================
for ROLE in "${ROLES[@]}"; do
    VM_NAME="lab-${LAB_ID,,}-${ROLE}-01"
    CLOUDINIT_DIR="$CLOUDINIT_BASE/$VM_NAME"

    [[ -f "$CLOUDINIT_DIR/user-data" ]] || {
        echo "❌ user-data no encontrado para $VM_NAME"
        exit 1
    }
    [[ -f "$CLOUDINIT_DIR/meta-data" ]] || {
        echo "❌ meta-data no encontrado para $VM_NAME"
        exit 1
    }

    # Crear workdir aislado para Terraform
    TF_WORKDIR="/mnt/vms/labs/tmp/terraform/$VM_NAME"
    mkdir -p "$TF_WORKDIR"
    cd "$TF_WORKDIR"

    # ✅ VERSIÓN FINAL CORRECTA
    cat > main.tf <<EOF
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
  uri = "qemu:///system"
}

module "vm" {
  source = "$ENGINE_DIR/scenarios/terraform/modules/rocky_vm"

  vm_name             = "$VM_NAME"
  base_image          = "$BASE_IMAGE"
  cloudinit_user_data = file("$CLOUDINIT_DIR/user-data")
  cloudinit_meta_data = file("$CLOUDINIT_DIR/meta-data")
}
EOF

    echo "🔨 Inicializando Terraform para $VM_NAME..."
    terraform init -input=false -no-color
    terraform apply -auto-approve -no-color
    echo "✅ VM '$VM_NAME' aprovisionada con Terraform"
done

echo "🚀 Todas las VMs del laboratorio '$LAB_ID' han sido levantadas"
