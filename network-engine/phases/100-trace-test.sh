#!/bin/bash
# ------------------------------------------------------------------------------
# FASE 100 - Connectivity & Policy Trace Test (Declarativo)
# ------------------------------------------------------------------------------
run_phase() {

    echo "===================================================="
    echo "[FASE 100] CONNECTIVITY MATRIX + DECLARATIVE TESTS"
    echo "===================================================="

    # --------------------------------------------------------------------------
    # 1. Descubrir namespaces dinámicamente
    # --------------------------------------------------------------------------
    namespaces=($(ip netns list | awk '{print $1}'))

    declare -A ip_map

    # --------------------------------------------------------------------------
    # 2. Descubrir IPs por namespace / interfaz
    # --------------------------------------------------------------------------
    for ns in "${namespaces[@]}"; do
        ips=$(ip netns exec "$ns" ip -4 addr show \
            | awk '/inet / {print $2,$NF}' | cut -d/ -f1)

        while read -r ip iface; do
            [[ -z "$ip" ]] && continue

            # key por interfaz
            ip_map["${ns}_${iface}"]="$ip"
            # key por namespace (última IP válida)
            ip_map["$ns"]="$ip"
        done <<< "$ips"
    done

    # --------------------------------------------------------------------------
    # 3. Función base de ping (no declarativa)
    # --------------------------------------------------------------------------
    raw_ping() {
        local src_ns="$1"
        local dst_ip="$2"

        timeout 2 ip netns exec "$src_ns" ping -c 1 -W 1 "$dst_ip" &>/dev/null
    }

    # --------------------------------------------------------------------------
    # 4. Declaración de EXPECTATIVAS (INTENCIÓN DE DISEÑO)
    # --------------------------------------------------------------------------
    # FORMATO: SRC|DST|ALLOW|DESCRIPCIÓN
    EXPECTATIONS=(
        # Gestión
        "CORE-MGMT|CORE-RH|ALLOW|Soporte a usuarios"
        "CORE-MGMT|CORE-ADM|ALLOW|Soporte administrativo"

        # Administración
        "CORE-ADM|CORE-SVC|ALLOW|Apps internas"
        "CORE-ADM|CORE-MGMT|DENY|No privilegios"

        # Usuarios
        "CORE-RH|CORE-SVC|ALLOW|Uso de servicios"
        "CORE-RH|INTERNET|ALLOW|Salida internet"

        # Aislamientos
        "CORE-RH|CORE-ADM|DENY|Separación departamentos"
        "CORE-ADM|CORE-RH|DENY|Separación departamentos"

    )

    # --------------------------------------------------------------------------
    # 5. Ejecutar tests declarativos
    # --------------------------------------------------------------------------
    TEST_FAILURE=0

    echo "🧪 Ejecutando tests declarativos..."
    echo ""

    for rule in "${EXPECTATIONS[@]}"; do
        IFS='|' read -r src dst expected desc <<< "$rule"

        dst_ip="${ip_map[$dst]}"

        # Si no existe IP destino, ignorar (topología parcial)
        [[ -z "${dst_ip:-}" ]] && continue

        if raw_ping "$src" "$dst_ip"; then
            real="ALLOW"
        else
            real="DENY"
        fi

        printf "%-12s → %-12s | esperado: %-5s | real: %-5s : " \
            "$src" "$dst" "$expected" "$real"

        if [[ "$expected" == "$real" ]]; then
            echo "✅"
        else
            echo "❌  ($desc)"
            TEST_FAILURE=1
        fi
    done

    echo ""
    echo "----------------------------------------------------"

    if [[ "$TEST_FAILURE" -eq 1 ]]; then
        echo "❌ La topología NO cumple la intención declarada"
        exit 1
    else
        echo "✅ La topología cumple la intención declarada"
    fi

    echo "===================================================="
}

