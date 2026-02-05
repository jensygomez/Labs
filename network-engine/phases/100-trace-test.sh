#!/bin/bash
# ------------------------------------------------------------------------------
# network-engine/phases/100-trace-test.sh
# FASE 100 - Connectivity & Policy Trace Test (Declarativo) - VERSIÓN FINAL
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
    # 2. Descubrir IPs por namespace / interfaz (última IP válida por NS)
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
    # 4. AUTO-FIX INFRAESTRUCTURA BÁSICA (aprendido del debugging)
    # --------------------------------------------------------------------------
    echo "🔧 Auto-corriendo prerrequisitos de infraestructura..."
    
    # FIX crítico: INTERNET ruta hacia red interna (10.255.255.0/30)
    ip netns exec INTERNET ip route replace 10.255.255.0/30 via 203.0.113.1 2>/dev/null || true

    echo ""

    # --------------------------------------------------------------------------
    # 5. PRERREQUISITOS CRÍTICOS (Infraestructura básica - falla rápido)
    # --------------------------------------------------------------------------
    echo "🔍 Verificando prerrequisitos críticos..."
    
    # CORE-EDGE ↔ CORE-MGMT (bastión básico)
    if [[ -n "${ip_map[CORE-EDGE]}" && -n "${ip_map[CORE-MGMT]}" ]]; then
        edge_ip="${ip_map[CORE-EDGE]}"
        mgmt_ip="${ip_map[CORE-MGMT]}"
        
        printf "%-12s → %-12s | esperado: ALLOW | real: " "CORE-EDGE" "CORE-MGMT"
        if raw_ping "CORE-EDGE" "$mgmt_ip"; then
            echo "ALLOW : ✅"
        else
            echo "DENY : ❌ (CRÍTICO - fallar recreación FASE 01-04)"
            exit 1
        fi
        
        printf "%-12s → %-12s | esperado: ALLOW | real: " "CORE-MGMT" "CORE-EDGE"
        if raw_ping "CORE-MGMT" "$edge_ip"; then
            echo "ALLOW : ✅"
        else
            echo "DENY : ❌ (CRÍTICO - fallar recreación FASE 01-04)"
            exit 1
        fi
    else
        echo "⚠️  Namespaces CORE-EDGE/CORE-MGMT no encontrados (FASE 01)"
    fi

    echo ""

    # --------------------------------------------------------------------------
    # 6. TRUST MODEL - EXPECTATIVAS DECLARATIVAS (Políticas de negocio)
    # --------------------------------------------------------------------------
    EXPECTATIONS=(
        # ----------------------------------------------------------------------
        # Infraestructura básica
        # ----------------------------------------------------------------------
        "CORE-EDGE|CORE-MGMT|ALLOW|Gestión de infraestructura"
        "CORE-MGMT|CORE-EDGE|ALLOW|Gestión de infraestructura"

        # ----------------------------------------------------------------------
        # CORE-MGMT (Bastión)
        # ----------------------------------------------------------------------
        "CORE-MGMT|CORE-ADM|ALLOW|Gestión administrativa"
        "CORE-MGMT|CORE-SVC|ALLOW|Gestión de servicios"

        "CORE-ADM|CORE-MGMT|DENY|Protección del bastión"
        "CORE-SVC|CORE-MGMT|DENY|Separación de dominios"

        # ----------------------------------------------------------------------
        # CORE-ADM
        # ----------------------------------------------------------------------
        "CORE-ADM|CORE-SVC|ALLOW|Acceso a aplicaciones"
        "CORE-SVC|CORE-ADM|DENY|Servicios pasivos"

        # ----------------------------------------------------------------------
        # CORE-SVC
        # ----------------------------------------------------------------------
        "CORE-SVC|CORE-EDGE|DENY|Servicios no acceden a infraestructura"

        # ----------------------------------------------------------------------
        # Internet
        # ----------------------------------------------------------------------
        "INTERNET|CORE-EDGE|DENY|Internet no inicia conexiones"
        "INTERNET|CORE-MGMT|DENY|Aislamiento del bastión"

                # ----------------------------------------------------------------------
        # CORE-RH (Usuarios)
        # ----------------------------------------------------------------------
        "CORE-RH|CORE-SVC|ALLOW|Usuarios RH acceden a servicios internos"
        "CORE-RH|CORE-EDGE|ALLOW|Usuarios RH tránsito hacia Internet"
        "CORE-RH|INTERNET|ALLOW|Usuarios RH acceso a Internet"

        "CORE-RH|CORE-MGMT|DENY|Usuarios RH no acceden a MGMT"
        "CORE-RH|CORE-ADM|DENY|Usuarios RH no acceden a ADM"

        "CORE-MGMT|CORE-RH|ALLOW|Gestión de usuarios RH"

        "CORE-SVC|CORE-RH|DENY|Servicios no inician hacia usuarios"
        "CORE-ADM|CORE-RH|DENY|Administración no accede a usuarios"
        "INTERNET|CORE-RH|DENY|Internet no accede a usuarios"

    )


    # --------------------------------------------------------------------------
    # 7. EJECUTAR VALIDACIÓN DECLARATIVA
    # --------------------------------------------------------------------------
    TEST_FAILURE=0
    TEST_TOTAL=0

    echo "🧪 Validando políticas de confianza..."
    echo ""

    for rule in "${EXPECTATIONS[@]}"; do
        IFS='|' read -r src dst expected desc <<< "$rule"

        dst_ip="${ip_map[$dst]}"

        # Skip si topología parcial
        [[ -z "${dst_ip:-}" ]] && {
            printf "%-12s → %-12s | esperado: %-5s | real: SKIPPED : " \
                "$src" "$dst" "$expected"
            echo "⚠️  ($desc - topología parcial)"
            continue
        }

        TEST_TOTAL=$((TEST_TOTAL + 1))

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
    echo "📊 RESUMEN: $TEST_TOTAL tests ejecutados"

    if [[ "$TEST_FAILURE" -eq 1 ]]; then
        echo "❌ La topología NO cumple todas las políticas declaradas"
        echo "   💡 Ejecuta FASE 08-firewall.sh o revisa topología parcial"
        exit 1
    else
        echo "✅ Políticas de confianza VALIDADAS exitosamente"
        echo "🎯 Trust Model alineado con topología actual"
    fi

    echo "===================================================="
}

# Ejecutar si script directo
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_phase "$@"
fi
