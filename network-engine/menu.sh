# rsync -avz ./ root@192.168.122.100:/root/network-engine/
# network-engine/menu.sh
#!/bin/bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

ENGINE="$BASE_DIR/engine.sh"

run_engine() {
  exec sudo bash "$ENGINE"
}

test_idempotency() {
  local runs=50
  echo "🧪 Test de idempotencia ($runs ejecuciones)"

  for i in $(seq 1 "$runs"); do
    echo "▶ Run $i"
    if ! bash "$ENGINE" >/dev/null 2>&1; then
      echo "❌ FALLO en run #$i"
      exit 1
    fi
  done

  echo "✅ Test de idempotencia SUPERADO"
}

menu() {
  while true; do
    echo ""
    echo "=============================="
    echo " Network Lab - Control Panel"
    echo "=============================="
    echo "1) Ejecutar motor"
    echo "2) Test idempotencia (50x)"
    echo "0) Salir"
    echo "------------------------------"
    read -rp "Selecciona una opción: " opt

    case "$opt" in
      1) run_engine ;;
      2) test_idempotency ;;
      0) exit 0 ;;
      *) echo "❌ Opción inválida" ;;
    esac
  done
}

menu
