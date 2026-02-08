#!/bin/bash
# network-engine/lib/guard.sh
require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: Este script debe ejecutarse con privilegios de root (sudo)." >&2
    exit 1
  fi
}