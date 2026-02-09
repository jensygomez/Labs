#!/bin/bash
# lib/core.sh - Gestión de ciclo de vida de nodos


[[ -z "$YQ" ]] && YQ="$BASE_DIR/.bin/yq"
# Usamos la ruta que definimos en el orquestador
YQ="./.bin/yq"

create_namespaces() {
    # Usamos BASE_DIR para encontrar siempre el YAML y el binario
    local nodes=$($YQ '.nodes[].name' "$BASE_DIR/topology/nodes.yml")

    for name in $nodes; do
        if ! ip netns list | grep -q "$name"; then
            ip netns add "$name"
            ip netns exec "$name" ip link set lo up
            echo "   ✅ Namespace [$name] creado."
        fi
    done
}

cleanup_namespaces() {
    echo "🧹 Iniciando limpieza de namespaces..."
    
    # Extraer nombres de nodos del YAML para saber qué borrar
    local nodes=$($YQ '.nodes[].name' topology/nodes.yml)

    for name in $nodes; do
        if ip netns list | grep -q "$name"; then
            ip netns del "$name"
            echo "   🗑️  Nodo [$name] eliminado."
        else
            echo "   ℹ️  Nodo [$name] no existe, nada que hacer."
        fi
    done

    # Limpieza extra: borrar interfaces veth que hayan quedado en el host (si las hay)
    # Esto evita conflictos al recrear el laboratorio
    ip -all netns delete 2>/dev/null
    echo "✨ Limpieza total completada."
}