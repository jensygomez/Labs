#!/usr/bin/env bash
# fetch_evidence.sh
# Mismo patrón que tus validadores LFCS: un solo fetch por nodo,
# consolidado en evidence.txt, con bloques delimitados por hostname
# para poder hacer grep scoped por nodo/check después.
#
# Uso: bash evidence/fetch_evidence.sh   (correr desde la raíz del lab)

set -o errexit
set -o pipefail

OUTFILE="$(dirname "$0")/evidence.txt"
NODES="node01 node02 node03 node04"

: > "$OUTFILE"   # limpiar/crear

for node in $NODES; do
  echo "==> Recolectando evidencia de $node..."
  {
    echo "###NODE_START:${node}"
    echo "--- hostname ---"
    vagrant ssh "$node" -c "hostname" 2>/dev/null
    echo "--- mount | grep data ---"
    vagrant ssh "$node" -c "mount | grep data || echo 'NO_DATA_MOUNT'" 2>/dev/null
    echo "--- fstab (líneas de /data) ---"
    vagrant ssh "$node" -c "grep '/data' /etc/fstab || echo 'NO_FSTAB_ENTRY'" 2>/dev/null
    echo "--- showmount -e contra node04 (192.168.122.14) ---"
    vagrant ssh "$node" -c "showmount -e 192.168.122.14 || echo 'STORAGE_UNREACHABLE'" 2>/dev/null
    echo "--- systemctl status app-backend ---"
    vagrant ssh "$node" -c "systemctl status app-backend.service --no-pager -l || true" 2>/dev/null
    echo "--- systemctl status legacy-daemon ---"
    vagrant ssh "$node" -c "systemctl status legacy-daemon.service --no-pager -l || true" 2>/dev/null
    echo "--- contenido /data/status ---"
    vagrant ssh "$node" -c "cat /data/status 2>/dev/null || echo 'STATUS_FILE_NOT_FOUND'" 2>/dev/null
    echo "###NODE_END:${node}"
    echo ""
  } >> "$OUTFILE"
done

echo "✅ Evidencia consolidada en $OUTFILE"
echo "   Grep scoped por nodo: sed -n '/###NODE_START:node02/,/###NODE_END:node02/p' evidence.txt"
