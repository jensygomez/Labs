#!/bin/bash
# create-snapshot.sh - Crea snapshot de Golden Base

SNAPSHOT_NAME="golden-base"

echo "=========================================="
echo "📸 Creando snapshot '$SNAPSHOT_NAME'"
echo "=========================================="

for i in $(seq 1 10); do
  NODE=$(printf "server%02d" $i)
  
  echo "   → Procesando $NODE..."
  
  # Detener el contenedor
  lxc stop $NODE --force 2>/dev/null
  
  # Eliminar snapshot previo si existe
  lxc delete $NODE/$SNAPSHOT_NAME 2>/dev/null || true
  
  # Crear snapshot
  if lxc snapshot $NODE $SNAPSHOT_NAME 2>/dev/null; then
    echo "   ✅ $NODE"
  else
    echo "   ❌ $NODE falló"
  fi
  
  # Iniciar el contenedor
  lxc start $NODE 2>/dev/null
done

echo ""
echo "✅ Snapshots creados correctamente"
echo "📊 Estado final:"
lxc list

