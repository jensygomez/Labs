#!/bin/bash

echo "======================================="
echo "    REINICIANDO NODOS RHCSA (Docker)"
echo "======================================="

# Lista de nodos
NODES="node1 node2 node3 node4"

echo "[+] Eliminando contenedores anteriores..."
for n in $NODES; do
    docker rm -f $n 2>/dev/null && echo "  - Eliminado: $n"
done

echo "[+] Recreando contenedores limpios..."

for n in $NODES; do
    docker run -d --name $n --network rhel_lab_net phoenix-lab sleep infinity
    echo "  - Creado: $n"
done

echo "======================================="
echo "   LISTO. NODOS 100% LIMPIOS"
echo "======================================="
echo "Para entrar a un nodo:"
echo "  docker exec -it node1 bash"
