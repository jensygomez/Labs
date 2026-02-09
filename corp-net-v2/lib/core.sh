#!/bin/bash
# lib/core.sh - Procesamiento de YAML con yq local

# Usamos la variable YQ definida en engine.sh o la buscamos de nuevo
YQ="./.bin/yq"

create_namespaces() {
    echo "📂 Leyendo nodos desde topology/nodes.yml..."
    
    # Obtenemos nombres de nodos en formato texto
    local nodes=$($YQ '.nodes[].name' topology/nodes.yml)

    for name in $nodes; do
        if ! ip netns list | grep -q "$name"; then
            ip netns add "$name"
            ip netns exec "$name" ip link set lo up
            echo "✅ Namespace [$name] creado."
        else
            echo "ℹ️  Namespace [$name] ya existe."
        fi
    done
}