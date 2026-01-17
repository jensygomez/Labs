#!/bin/bash
set -euo pipefail

# ============================================================================
# ARGUMENTOS
# ============================================================================
VM_NAME="$1"
BASE_IMAGE="$2"
CLOUDINIT_DIR="$3"

TF_ROOT="$(cd "$(dirname "$0")/.." && pwd)/scenarios/terraform"
MODULE_DIR="$TF_ROOT/modules/rocky_vm"

USER_DATA="$CLOUDINIT_DIR/user-data"
META_DATA="$CLOUDINIT_DIR/meta-data"

# ============================================================================
# VALIDACIONES
# ============================================================================
[[ -f "$USER_DATA" ]] || {
  echo "❌ user-data no encontrado: $USER_DATA" >&2
  exit 1
}

[[ -f "$META_DATA" ]] || {
  echo "❌ meta-data no encontrado: $META_DATA" >&2
  exit 1
}

# ============================================================================
# TERRAFORM WORKDIR (aislado por VM)
# ============================================================================
TF_WORKDIR="/mnt/vms/labs/tmp/terraform/$VM_NAME"
mkdir -p "$TF_WORKDIR"
cd "$TF_WORKDIR"

# ============================================================================
# TERRAFORM FILES
# ============================================================================
cat > main.tf <<EOF
module "vm" {
  source = "$MODULE_DIR"

  vm_name              = "$VM_NAME"
  base_image           = "$BASE_IMAGE"
  cloudinit_user_data  = file("$USER_DATA")
  cloudinit_meta_data  = file("$META_DATA")
}
EOF

terraform init -input=false -no-color
terraform apply -auto-approve -no-color
