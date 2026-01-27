
#!/bin/bash

set -Eeuo pipefail

# ==============================================================================
# BLOQUE 1 - CHECK ROOT
# ==============================================================================

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Ejecuta como root"
    exit 1
  fi
}
