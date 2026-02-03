#!/bin/bash
# network-engine/lib/guard.sh
#!/bin/bash
# network-engine/lib/guard.sh

# Quitamos el set -Eeuo y los source redundantes. 
# El engine ya se encarga de las rutas y la configuración.

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: Este script debe ejecutarse con privilegios de root (sudo)." >&2
    exit 1
  fi
}