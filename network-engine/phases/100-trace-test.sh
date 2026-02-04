#!/bin/bash
# ------------------------------------------------------------------------------
# FASE 100 - Connectivity & Policy Trace Test (Declarativo) - VERSION REFACTORIZADA
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
    # 4. PRERREQUISITOS BÁSICOS (CRÍTICOS - fallar rápido)
    # --------------------------------------------------------------------------
    echo "🔍 Verificando prerrequisitos básicos..."
    
    # CORE-EDGE ↔ CORE-MGMT (base de bastión)
    if [[ -n "${ip_map[CORE-EDGE]}" && -n "${ip_map[CORE-MGMT]}" ]]; then
        edge_ip="${ip_map[CORE-EDGE]}"
        mgmt_ip="${ip_map[CORE-MGMT]}"
        
        printf "%-12s → %-12s | esperado: ALLOW | real: " "CORE-EDGE" "CORE-MGMT"
        if raw_ping "CORE-EDGE" "$mgmt_ip"; then
            echo "ALLOW : ✅"
        else
            echo "DENY : ❌ (CRÍTICO - MGMT básico falla)"
            exit 1
        fi
        
        printf "%-12s → %-12s | esperado: ALLOW | real: " "CORE-MGMT" "CORE-EDGE"
        if raw_ping "CORE-MGMT" "$edge_ip"; then
            echo "ALLOW : ✅"
        else
            echo "DENY : ❌ (CRÍTICO - MGMT básico falla)"
            exit 1
        fi
    else
        echo "⚠️  Namespaces CORE-EDGE/CORE-MGMT no encontrados"
    fi

    echo ""

    # --------------------------------------------------------------------------
    # 5. Declaración de EXPECTATIVAS (INTENCIÓN DE DISEÑO)
    # --------------------------------------------------------------------------
    EXPECTATIONS=(
        # Infraestructura básica
        "CORE-EDGE|CORE-MGMT|ALLOW|Infraestructura básica"
        "CORE-MGMT|CORE-EDGE|ALLOW|Infraestructura básica"
        
        # Gestión (bastión puede todo)
        "CORE-MGMT|CORE-ADM|ALLOW|Soporte administrativo"
        "CORE-MGMT|CORE-SVC|ALLOW|Gestión servicios"
        "CORE-MGMT|CORE-RH|ALLOW|Soporte usuarios"

        # Administración (servicios + limitado)
        "CORE-ADM|CORE-SVC|ALLOW|Apps internas"
        "CORE-ADM|CORE-MGMT|DENY|No privilegios gestión"

        # Usuarios (servicios + internet)
        "CORE-RH|CORE-SVC|ALLOW|Uso de servicios"
        "CORE-RH|INTERNET|ALLOW|Salida internet"
        "CORE-RH|CORE-ADM|DENY|Separación departamentos"

        # Servicios (pasivos)
        "CORE-SVC|CORE-MGMT|DENY|Servicios no inician"
        "CORE-SVC|CORE-ADM|DENY|Servicios no inician"

        # Internet (solo respuestas)
        "INTERNET|CORE-EDGE|ALLOW|Respuestas stateful"
        "INTERNET|CORE-MGMT|DENY|Sin acceso directo"
    )

    # --------------------------------------------------------------------------
    # 6. Ejecutar tests declarativos
    # --------------------------------------------------------------------------
    TEST_FAILURE=0

    echo "🧪 Ejecutando tests declarativos..."
    echo ""

    for rule in "${EXPECTATIONS[@]}"; do
        IFS='|' read -r src dst expected desc <<< "$rule"

        dst_ip="${ip_map[$dst]}"

        # Si no existe IP destino, saltar (topología parcial)
        [[ -z "${dst_ip:-}" ]] && {
            echo "⚠️  $src → $dst | IP destino no encontrada (topología parcial)"
            continue
        }

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
        echo "🎯 Políticas de confianza VALIDADAS"
    fi

    echo "===================================================="
}

# Ejecutar si script directo
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_phase "$@"
fi
